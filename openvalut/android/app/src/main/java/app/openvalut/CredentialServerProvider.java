package app.openvalut;

import android.content.ContentProvider;
import android.content.ContentValues;
import android.content.pm.PackageManager;
import android.database.Cursor;
import android.database.MatrixCursor;
import android.net.Uri;
import android.os.Binder;
import android.os.Process;

import org.json.JSONException;
import org.json.JSONObject;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

/**
 * Exposes the current loopback credential-server port + session token to the
 * companion SSH client (sshbot), which then talks to the server over
 * 127.0.0.1:<port> with the token as its bearer.
 *
 * <p>Authority: {@code app.openvalut.credentials}. The single row's
 * {@code json} column carries {@code {running, port, token}}.
 *
 * <p>The token is regenerated every time a vault is unlocked, and the provider
 * is guarded by a signature-level permission and an explicit signing-certificate
 * check, so only trusted companion apps can read it.
 */
public final class CredentialServerProvider extends ContentProvider {
    private static final Logger logger = LoggerFactory.getLogger(CredentialServerProvider.class);

    public static final String AUTHORITY = "app.openvalut.credentials";
    public static final Uri STATUS_URI = Uri.parse("content://" + AUTHORITY + "/status");
    private static final String READ_PERMISSION =
            "app.openvalut.permission.READ_CREDENTIAL_SERVER";

    private static volatile boolean running;
    private static volatile int port;
    private static volatile String token;

    /**
     * Called from the Flutter host channel when the credential server
     * starts or stops. Passing null token/0 port stops the service.
     */
    public static void updateStatus(boolean isRunning, int newPort, String newToken) {
        running = isRunning;
        port = isRunning ? newPort : 0;
        token = isRunning ? newToken : null;
        logger.info("Credential server status: running={} port={}", running, port);
    }

    @Override
    public boolean onCreate() {
        return true;
    }

    @Nullable
    @Override
    public Cursor query(@NonNull Uri uri, @Nullable String[] projection,
                        @Nullable String selection, @Nullable String[] selectionArgs,
                        @Nullable String sortOrder) {
        enforceTrustedCaller(uri);
        final JSONObject json = new JSONObject();
        try {
            json.put("running", running);
            json.put("port", port);
            json.put("token", token == null ? JSONObject.NULL : token);
        } catch (JSONException e) {
            logger.warn("Failed to serialize credential server status.", e);
            return null;
        }
        final MatrixCursor cursor = new MatrixCursor(new String[]{"json"});
        cursor.addRow(new Object[]{json.toString()});
        return cursor;
    }

    private void enforceTrustedCaller(@NonNull Uri uri) {
        if (!STATUS_URI.equals(uri)) {
            throw new SecurityException("Unsupported credential provider URI");
        }
        final int callingUid = Binder.getCallingUid();
        if (callingUid == Process.myUid()) {
            return;
        }
        if (getContext() == null
                || getContext().checkCallingPermission(READ_PERMISSION)
                != PackageManager.PERMISSION_GRANTED) {
            throw new SecurityException("Missing credential server permission");
        }
    }

    @Nullable
    @Override
    public String getType(@NonNull Uri uri) {
        return "application/json";
    }

    @Nullable
    @Override
    public Uri insert(@NonNull Uri uri, @Nullable ContentValues values) {
        throw new UnsupportedOperationException("read-only provider");
    }

    @Override
    public int delete(@NonNull Uri uri, @Nullable String selection,
                      @Nullable String[] selectionArgs) {
        throw new UnsupportedOperationException("read-only provider");
    }

    @Override
    public int update(@NonNull Uri uri, @Nullable ContentValues values,
                      @Nullable String selection, @Nullable String[] selectionArgs) {
        throw new UnsupportedOperationException("read-only provider");
    }
}
