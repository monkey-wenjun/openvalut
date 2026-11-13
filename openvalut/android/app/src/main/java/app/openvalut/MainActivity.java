package app.openvalut;

import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.os.Bundle;
import android.os.SystemClock;
import android.provider.Settings;

import org.jetbrains.annotations.NotNull;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import io.flutter.embedding.android.FlutterFragmentActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterFragmentActivity {
    private static final String CHANNEL = "app.openvalut/misc";
    private static final String AUTOFILL_METADATA_EXTRA = "AutofillMetadata";
    private static final Logger logger = LoggerFactory.getLogger(MainActivity.class);
    private MethodChannel miscChannel;

    // The autofill metadata of the most recent autofill intent, so Dart can
    // read it even if the autofill_service plugin channel is unavailable.
    private static volatile String latestAutofillMetadataJson;

    private static boolean isAutofillIntent(Intent intent) {
        return "/autofill".equals(intent.getStringExtra("initial_route"))
                || "/autofill".equals(intent.getStringExtra("route"));
    }

    private static void captureAutofillMetadata(Intent intent) {
        if (isAutofillIntent(intent)) {
            latestAutofillMetadataJson = intent.getStringExtra(AUTOFILL_METADATA_EXTRA);
        }
    }

    /**
     * The metadata static is only valid for the intent that is being handled
     * right now. When the user opens the app on their own (launcher icon,
     * notification, deep link), any leftover autofill metadata from an earlier
     * request must be cleared, otherwise Dart would mistake the normal launch
     * for an autofill launch and pop the picker unprompted.
     */
    private static void clearStaleAutofillMetadata(Intent intent) {
        if (!isAutofillIntent(intent)) {
            latestAutofillMetadataJson = null;
        }
    }

    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        logger.info("onNewIntent " + intent + " extras: " + intent.getExtras());
        clearStaleAutofillMetadata(intent);
        captureAutofillMetadata(intent);
        if (miscChannel != null) {
            if (isAutofillIntent(intent)) {
                try {
                    logger.info("Autofill intent detected, notifying Dart.");
                    // Tell Dart to push the autofill selector. The Flutter
                    // engine's own onNewIntent handling only forwards deeplink
                    // data URIs, not the initial_route extra, so the selector
                    // would never appear when reusing the already-unlocked
                    // instance.
                    miscChannel.invokeMethod("onAutofillIntent", latestAutofillMetadataJson);
                } catch (Exception e) {
                    logger.warn("Failed to notify Dart about autofill intent.", e);
                }
            } else {
                // The user opened the app on their own. Drop any picker that
                // was left open from an earlier autofill session so a normal
                // launch never looks like an autofill prompt.
                try {
                    miscChannel.invokeMethod("dismissAutofillPicker", null);
                } catch (Exception e) {
                    logger.warn("Failed to dismiss autofill picker.", e);
                }
            }
        }
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        Intent intent = getIntent();
        logger.info("onCreate " + intent);
        // A fresh activity must never inherit metadata from an older autofill
        // session; only the current intent counts.
        latestAutofillMetadataJson = null;
        captureAutofillMetadata(intent);
        if (intent != null) {
            logger.info("onCreate Intent extras: " + intent.getExtras());
        }
    }

    @Override
    protected void onDestroy() {
        logger.info("onDestroy");
        super.onDestroy();
    }

    @Override
    public void configureFlutterEngine(@NotNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        miscChannel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL);
        miscChannel.setMethodCallHandler((call, result) -> {
            if ("startKeepAlive".equals(call.method)) {
                KeepAliveService.start(this);
                result.success(true);
                return;
            }
            if ("stopKeepAlive".equals(call.method)) {
                KeepAliveService.stop(this);
                result.success(true);
                return;
            }
            if ("getAutofillMetadataJson".equals(call.method)) {
                result.success(latestAutofillMetadataJson);
                return;
            }
            if ("getInstalledApps".equals(call.method)) {
                result.success(getInstalledApps());
                return;
            }
            if ("isFirebaseTestLab".equals(call.method)) {
                result.success("true".equals(Settings.System.getString(getContentResolver(), "firebase.test.lab")));
                return;
            }
            if ("getBootId".equals(call.method)) {
                result.success(bootId());
                return;
            }
            if ("updateCredentialServer".equals(call.method)) {
                final Map<String, Object> args = call.arguments();
                final boolean isRunning = Boolean.TRUE.equals(args.get("running"));
                final int newPort = args.get("port") instanceof Number ? ((Number) args.get("port")).intValue() : 0;
                final String newToken = (String) args.get("token");
                CredentialServerProvider.updateStatus(isRunning, newPort, newToken);
                result.success(null);
                return;
            }
            result.notImplemented();
        });
    }

    /**
     * Identifier of the current boot session.
     *
     * Stable while the device stays powered on and different after every
     * reboot, so the app can refuse fingerprint / remembered unlock until the
     * master password has been entered again. Android does not expose
     * /proc/sys/kernel/random/boot_id to apps, so the boot counter set by the
     * system on every boot is used, with the wall clock boot instant as a
     * fallback on devices that do not publish it.
     */
    private String bootId() {
        try {
            final int bootCount = Settings.Global.getInt(getContentResolver(), "boot_count", -1);
            if (bootCount >= 0) {
                return "android-boot-" + bootCount;
            }
        } catch (Exception e) {
            logger.warn("Unable to read boot_count, falling back to boot time.", e);
        }
        final long bootWallClockMillis = System.currentTimeMillis() - SystemClock.elapsedRealtime();
        return "android-boottime-" + bootWallClockMillis;
    }

    /**
     * Installed apps the user can actually open (launcher activities), as
     * label + packageName pairs sorted by label. Used by the entry editor to
     * link a credential to a native app without the user typing a package
     * name, which is stored as an androidapp:// url for the autofill matcher.
     */
    private List<Map<String, String>> getInstalledApps() {
        final PackageManager pm = getPackageManager();
        final Intent launcherIntent = new Intent(Intent.ACTION_MAIN)
                .addCategory(Intent.CATEGORY_LAUNCHER);
        // LinkedHashMap keeps first-seen order and dedupes apps with several
        // launcher activities (e.g. work profile copies).
        final Map<String, String> labelByPackage = new LinkedHashMap<>();
        for (ResolveInfo info : pm.queryIntentActivities(launcherIntent, 0)) {
            final String pkg = info.activityInfo.packageName;
            labelByPackage.putIfAbsent(pkg, info.loadLabel(pm).toString());
        }
        final List<Map<String, String>> apps = new ArrayList<>();
        labelByPackage.forEach((pkg, label) -> {
            Map<String, String> app = new LinkedHashMap<>();
            app.put("packageName", pkg);
            app.put("label", label);
            apps.add(app);
        });
        apps.sort(Comparator.comparing(
                (Map<String, String> app) -> app.get("label"),
                String.CASE_INSENSITIVE_ORDER));
        return apps;
    }
}
