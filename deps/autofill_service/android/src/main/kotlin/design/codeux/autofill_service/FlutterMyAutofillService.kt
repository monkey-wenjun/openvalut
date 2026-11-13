package design.codeux.autofill_service

import android.annotation.TargetApi
import android.app.PendingIntent
import android.app.assist.AssistStructure
import android.content.ComponentName
import android.content.Intent
import android.content.IntentSender
import android.content.pm.PackageManager
import android.os.Build
import android.os.CancellationSignal
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.os.TransactionTooLargeException
import android.service.autofill.*
import android.view.View
import android.view.autofill.AutofillId
import android.view.autofill.AutofillManager
import android.widget.RemoteViews
import androidx.annotation.DrawableRes
import androidx.annotation.RequiresApi
import mu.KotlinLogging
import org.json.JSONArray
import org.json.JSONObject


private val logger = KotlinLogging.logger {}

/** The framework package shows up as `viewNode.idPackage` for every node that
 *  has no resource id — which inside a WebView is all of them. Never treat it
 *  as "the app on screen". */
private const val FRAMEWORK_PACKAGE = "android"

@RequiresApi(api = Build.VERSION_CODES.O)
class FlutterMyAutofillService : AutofillService() {

    companion object {
        @Volatile
        var instance: FlutterMyAutofillService? = null
            private set

        /// Filled when the browser asks for credentials, so the plugin can
        /// commit a dataset later without the auth activity finishing.
        @Volatile
        var delayedFillIntentSender: IntentSender? = null
            private set

        /// Timestamp of the most recent onFillRequest, used to tell whether
        /// the stored sender belongs to the autofill session the user is
        /// currently interacting with.
        @Volatile
        var lastFillRequestAt: Long = 0L
            private set

        /// A commit waiting for a fresh fill request: the user picked an
        /// entry while the stored sender was stale (the new fill request
        /// arrives right after OpenVault comes to the foreground). The plugin
        /// stores a lambda here and we fire it as soon as onFillRequest runs.
        @Volatile
        var pendingDelayedSend: ((IntentSender) -> Unit)? = null

        fun notifyFillRequest(sender: IntentSender?) {
            lastFillRequestAt = SystemClock.elapsedRealtime()
            delayedFillIntentSender = sender
        }

        /// Fires a pending commit once the framework has registered the
        /// delayed-fill wait for the current fill request. Must run after
        /// onFillRequest returns (that is when the framework registers the
        /// wait); sending a moment earlier makes the framework answer
        /// "Service did not request to wait" and drop the response.
        fun firePendingDelayedSend(sender: IntentSender?) {
            pendingDelayedSend?.let { pending ->
                pendingDelayedSend = null
                if (sender != null) {
                    Handler(Looper.getMainLooper()).postDelayed({
                        logger.info("Firing pending delayed autofill send.")
                        pending(sender)
                    }, 150)
                }
            }
        }
    }

    private lateinit var autofillPreferenceStore: AutofillPreferenceStore
    private var unlockLabel = "Autofill"

    override fun onCreate() {
        super.onCreate()
        instance = this
        logger.debug { "Autofill service was created." }
        autofillPreferenceStore = AutofillPreferenceStore.getInstance(applicationContext)
    }

    override fun onDestroy() {
        logger.info("Autofill service destroyed.")
        instance = null
        super.onDestroy()
    }

    override fun onConnected() {
        super.onConnected()
        logger.debug("onConnected.")
        val self = ComponentName(this, javaClass)

        val metaData = packageManager.getServiceInfo(self, PackageManager.GET_META_DATA).metaData
        metaData.getString("design.codeux.autofill_service.unlock_label")?.let {
            unlockLabel = it
        }
        logger.info("Unlock label will be $unlockLabel")
    }

    override fun onFillRequest(
        request: FillRequest,
        cancellationSignal: CancellationSignal,
        callback: FillCallback
    ) {
        logger.info { "Got fill request id=${request.id} delayedFillIntentSender=${request.delayedFillIntentSender}" }

        // The user can put apps on an ignore list: no autofill UI there at all,
        // even when the structure does carry a password or an OTP field (that
        // is exactly the case that triggers a request). Deliberately above
        // `notifyFillRequest`: recording this session's sender would let a
        // commit meant for another app be delivered into an ignored window.
        val ignoredPackages = autofillPreferenceStore.autofillPreferences.ignoredPackages
        if (ignoredPackages.isNotEmpty()) {
            // Only the activity package is trustworthy here. `parser.packageName`
            // is polluted by idPackage — "android" inside a WebView, the WebView
            // provider on some OEMs — so vetoing on it would silence browsers
            // whenever an ignored app hosts a web view.
            val requesting = request.fillContexts
                .mapNotNull { it.structure.activityComponent?.packageName }
                .filter { it != FRAMEWORK_PACKAGE && it != packageName }
                .distinct()
            if (requesting.isNotEmpty()) {
                if (requesting.any { it.lowercase() in ignoredPackages }) {
                    logger.info { "Vetoing fill request for ignored app $requesting." }
                    callback.onSuccess(null)
                    return
                }
            } else {
                // No trustworthy package (system window, overlay): fail open.
                // Guessing here would silence autofill globally and invisibly.
                logger.info { "Fill request without an activity package; not vetoing." }
            }
        }

        notifyFillRequest(request.delayedFillIntentSender)
//        applicationContext.packageManager.getLaunchIntentForPackage(applicationContext.packageName)

        val context = request.fillContexts.last()
        val parser = AssistStructureParser(context.structure)

        // idPackage can be missing or framework-owned (e.g. "android") on
        // views without a resource id, so the activity's package is the
        // authoritative source for matching an entry's androidapp:// url.
        context.structure.activityComponent?.packageName?.let { appPackage ->
            parser.packageName.add(appPackage)
        }

var useLabel = unlockLabel
        val hasPassword = !parser.fieldIds[AutofillInputType.Password].isNullOrEmpty()
        val hasOtp = !parser.fieldIds[AutofillInputType.Otp].isNullOrEmpty()
        // OTP-only pages (the second step of a 2FA login) must still launch
        // the app so the user can pick an entry and fill the code; only drop
        // the request when there is nothing to fill at all.
        if (!hasPassword && !hasOtp) {
            val detectedFields = parser.fieldIds.flatMap { it.value }.size
            logger.debug { "got autofillPreferences: ${autofillPreferenceStore.autofillPreferences}" }
            if (!autofillPreferenceStore.autofillPreferences.enableDebug) {
                callback.onSuccess(null)
                // A pending commit picked in OpenValut carries its own
                // structure from the original fill request; a re-issued
                // request that fails to spot a password field must still
                // deliver it, otherwise the fill is dropped.
                firePendingDelayedSend(request.delayedFillIntentSender)
                return
            }
            useLabel = "Debug: No password fields detected ($detectedFields total)."
        }

        logger.debug { "Trying to fetch package info." }
        val activityName =
            packageManager.getApplicationInfo(packageName, PackageManager.GET_META_DATA).run {
                metaData.getString("design.codeux.autofill_service.ACTIVITY_NAME")
            } ?: "design.codeux.OpenVault.MainActivity"
        logger.debug("got activity $activityName")

        val startIntent = Intent()
        // TODO: Figure this out how to do this without hard coding everything..
        startIntent.setClassName(applicationContext, activityName)
        startIntent.action = Intent.ACTION_RUN
        // Launch into the app's own task instead of the browser's task.
        // MainActivity is singleTask, so when the app is already running this
        // delivers onNewIntent to the existing activity — the Flutter engine
        // (and the open vault) is reused and the fill happens directly,
        // without a second unlock. Without NEW_TASK the auth activity would be
        // created in the browser's task, which spins up a fresh engine and
        // re-runs the whole unlock flow even though the process is alive.
        startIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        startIntent.putExtra("route", "/autofill")
        startIntent.putExtra("initial_route", "/autofill")
        parser.packageName.firstOrNull()?.let {
            startIntent.putExtra(
                "autofillPackageName",
                it
            )
        }
        if (parser.webDomain.size > 1) {
            logger.warn { "Found multiple autofillWebDomain: ${parser.webDomain}" }
        }
        parser.webDomain
            .firstOrNull { it.domain.isNotBlank() }
            ?.let { startIntent.putExtra("autofillWebDomain", it.domain) }
        // We serialize to string, because the Parcelable made some serious problems.
        // https://stackoverflow.com/a/39478479/109219
        startIntent.putExtra(
            AutofillMetadata.EXTRA_NAME,
            AutofillMetadata(parser.packageName, parser.webDomain).toJsonString()
        )
        startIntent.putExtra(AutofillManager.EXTRA_ASSIST_STRUCTURE, context.structure)
//        startIntent.putParcelableArrayListExtra("autofillIds", ArrayList(parser.autoFillIds))
        val intentSender: IntentSender = PendingIntent.getActivity(
            this,
            0,
            startIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_CANCEL_CURRENT
        ).intentSender
        logger.debug { "startIntent:$startIntent (${startIntent.extras}) - sender: $intentSender" }

        val autoFillIds = parser.autoFillIds.distinct()

        // Build a FillResponse object that requires authentication.
        val fillResponseBuilder: FillResponse.Builder = FillResponse.Builder()
            .setAuthentication(
                autoFillIds.toTypedArray(),
                intentSender,
                RemoteViewsHelper.viewsWithAuth(packageName, useLabel)
            )
            // Allow committing the fill result later via the fill request's
            // delayedFillIntentSender, so the app can fill without finishing
            // the activity (keeping itself alive and unlocked).
            .setFlags(FillResponse.FLAG_DELAY_FILL)
        logger.info {
            "remoteView for packageName: $packageName -- " +
                    "detected autofill packageName: ${parser.packageName} " +
                    "webDomain: ${parser.webDomain}" +
                    "autoFillIds: ${autoFillIds.size}"
        }

        val fillResponse = fillResponseBuilder.build()

        try {
            callback.onSuccess(fillResponse)
            // The framework registers the delayed-fill wait right after the
            // response is accepted; a pending user commit (picked while the
            // sender was stale) can only be delivered afterwards.
            firePendingDelayedSend(request.delayedFillIntentSender)
        } catch (e: TransactionTooLargeException) {
            throw RuntimeException(
                "Too many auto fill ids discovered ${autoFillIds.size} for " +
                        "${parser.webDomain},  ${parser.packageName}",
                e
            )
        }
    }

    override fun onSaveRequest(request: SaveRequest, callback: SaveCallback) {
        logger.info { "onSaveRequest. but not yet implemented." }
        callback.onFailure("Not implemented")
    }


}

data class AutofillMetadata(
    val packageNames: Set<String>,
    val webDomains: Set<WebDomain>
) {
    companion object {
        const val EXTRA_NAME = "AutofillMetadata"
        private const val PACKAGE_NAMES = "packageNames"
        private const val WEB_DOMAINS = "webDomains"

        fun fromJsonString(json: String) =
            JSONObject(json).run {
                AutofillMetadata(
                    packageNames = optJSONArray(PACKAGE_NAMES).map { array, index ->
                        array.getString(index)
                    }.toSet(),
                    webDomains = optJSONArray(WEB_DOMAINS).map { array, index ->
                        WebDomain.fromJson(array.getJSONObject(index))
                    }.toSet()
                )
            }
    }

    fun toMap(): Map<Any, Any> = mapOf(
        PACKAGE_NAMES to packageNames.toList(),
        WEB_DOMAINS to webDomains.map { it.toMap() },
    )

    fun toJsonString(): String = JSONObject(toMap()).toString()
}

fun <T> JSONArray.map(f: (array: JSONArray, index: Int) -> T): List<T> {
    return (0 until length()).map { index ->
        f(this, index)
    }
}


/**
 * This is a class containing helper methods for building Autofill Datasets and Responses.
 */
object RemoteViewsHelper {

    fun viewsWithAuth(packageName: String, text: String): RemoteViews {
        return simpleRemoteViews(packageName, text, R.drawable.ic_lock_black_24dp)
    }

    fun viewsWithNoAuth(packageName: String, text: String): RemoteViews {
        return simpleRemoteViews(packageName, text, R.drawable.ic_person_black_24dp)
    }

    private fun simpleRemoteViews(
        packageName: String, remoteViewsText: String,
        @DrawableRes drawableId: Int
    ): RemoteViews {
        val presentation = RemoteViews(
            packageName,
            R.layout.multidataset_service_list_item
        )
        presentation.setTextViewText(R.id.text, remoteViewsText)
        presentation.setImageViewResource(R.id.icon, drawableId)
        return presentation
    }
}

data class AutofillHeuristic(
    val weight: Int,
    val message: String?,
    val predicate: AssistStructure.ViewNode.(node: AssistStructure.ViewNode) -> Boolean
)

private fun MutableList<AutofillHeuristic>.heuristic(
    weight: Int,
    message: String? = null,
    predicate: AssistStructure.ViewNode.(node: AssistStructure.ViewNode) -> Boolean
) =
    add(AutofillHeuristic(weight, message, predicate))


@TargetApi(Build.VERSION_CODES.O)
private fun MutableList<AutofillHeuristic>.autofillHint(weight: Int, vararg hints: String) =
    heuristic(weight, "hint=${hints.joinToString("|")}") {
        autofillHints?.any { actual -> hints.any { it.equals(actual, ignoreCase = true) } } == true
    }

@TargetApi(Build.VERSION_CODES.O)
private fun MutableList<AutofillHeuristic>.idEntry(weight: Int, match: String) =
    heuristic(weight) { idEntry == match }

@TargetApi(Build.VERSION_CODES.O)
private fun AssistStructure.ViewNode.htmlAttribute(attr: String): String? =
    htmlInfo?.attributes?.firstOrNull { it.first == attr }?.second

@TargetApi(Build.VERSION_CODES.O)
private fun MutableList<AutofillHeuristic>.htmlAttribute(weight: Int, attr: String, value: String) =
    heuristic(weight, "html[$attr=$value]") {
        htmlAttribute(attr).equals(value, ignoreCase = true)
    }

@TargetApi(Build.VERSION_CODES.O)
private fun MutableList<AutofillHeuristic>.htmlAttributeContains(
    weight: Int,
    attr: String,
    value: String
) =
    heuristic(weight, "html[$attr*=$value]") {
        htmlAttribute(attr)?.lowercase()?.contains(value) == true
    }

/**
 * Chromium based browsers pass their own field classification along with the virtual view
 * structure. The values are the (stable) names of chromium's `FieldType` enum.
 * https://chromium.googlesource.com/chromium/src/+/HEAD/components/android_autofill/README.md
 */
@TargetApi(Build.VERSION_CODES.O)
private fun MutableList<AutofillHeuristic>.browserPrediction(weight: Int, types: Set<String>) =
    BROWSER_PREDICTION_ATTRIBUTES.forEachIndexed { index, attr ->
        heuristic(weight - index, "html[$attr in $types]") {
            val prediction = htmlAttribute(attr)?.uppercase()
            prediction != null && types.contains(prediction)
        }
    }

private val BROWSER_PREDICTION_ATTRIBUTES = listOf(
    "computed-autofill-hints",
    "ua-autofill-hints",
    "crowdsourcing-autofill-hints",
)

@TargetApi(Build.VERSION_CODES.O)
private fun MutableList<AutofillHeuristic>.defaults(hint: String, match: String) {
    autofillHint(900, hint)
    idEntry(800, match)
    heuristic(700) { idEntry?.lowercase()?.contains(match) == true }
}

@TargetApi(Build.VERSION_CODES.O)
enum class AutofillInputType(val heuristics: List<AutofillHeuristic>) {
    // Password must always win over UserName/Email on the same node, so all of its
    // heuristics are weighted above the ones which only look at names and hints.
    Password(mutableListOf<AutofillHeuristic>().apply {
        defaults(View.AUTOFILL_HINT_PASSWORD, "password")
        // html autocomplete attribute, as forwarded by browsers.
        autofillHint(890, "current-password", "new-password")
        htmlAttribute(880, "type", "password")
        browserPrediction(
            870, setOf(
                "PASSWORD",
                "ACCOUNT_CREATION_PASSWORD",
                "NEW_PASSWORD",
                "PROBABLY_NEW_PASSWORD",
                "CONFIRMATION_PASSWORD",
            )
        )
        heuristic(
            240,
            "text variation password"
        ) { inputType.hasFlag(android.text.InputType.TYPE_TEXT_VARIATION_PASSWORD) }
        heuristic(239) { inputType.hasFlag(android.text.InputType.TYPE_TEXT_VARIATION_WEB_PASSWORD) }
        heuristic(238) { inputType.hasFlag(android.text.InputType.TYPE_TEXT_VARIATION_VISIBLE_PASSWORD) }
    }),
    Email(mutableListOf<AutofillHeuristic>().apply {
        defaults(View.AUTOFILL_HINT_EMAIL_ADDRESS, "mail")
        autofillHint(600, "email")
        htmlAttribute(500, "type", "email")
        browserPrediction(450, setOf("EMAIL_ADDRESS", "USERNAME_AND_EMAIL_ADDRESS"))
        htmlAttributeContains(400, "name", "mail")
        htmlAttributeContains(390, "id", "mail")
        heuristic(250, "hint=mail") {
            hint?.lowercase()?.contains("mail") == true
        }
        htmlAttributeContains(240, "label", "mail")
    }),
    UserName(mutableListOf<AutofillHeuristic>().apply {
        defaults(View.AUTOFILL_HINT_USERNAME, "user")
        browserPrediction(
            450, setOf(
                "USERNAME",
                "USERNAME_AND_EMAIL_ADDRESS",
                "SINGLE_USERNAME",
                "SINGLE_USERNAME_FORGOT_PASSWORD",
                "SINGLE_USERNAME_WITH_INTERMEDIATE_VALUES",
            )
        )
        htmlAttributeContains(400, "name", "user")
        htmlAttributeContains(390, "id", "user")
        htmlAttributeContains(380, "name", "login")
        htmlAttributeContains(370, "id", "login")
        heuristic(300) { hint?.lowercase()?.contains("login") == true }
        htmlAttributeContains(230, "label", "user")
        htmlAttributeContains(220, "label", "login")
    }),
    // One-time codes (2FA / TOTP). Weighted above UserName/Email so a code
    // input is never filled with the username, and honored on pages that have
    // no password field at all (the second step of a 2FA login).
    Otp(mutableListOf<AutofillHeuristic>().apply {
        // Chromium/WebView forwards autofillHints=["one-time-code"] and
        // computed-autofill-hints="HTML_TYPE_ONE_TIME_CODE" for an input with
        // autocomplete="one-time-code"; "smsOTPCode" is what some devices map
        // it to. Recognise all three so a 2FA code field is never missed.
        autofillHint(850, "smsOTPCode", "one-time-code")
        htmlAttribute(840, "autocomplete", "one-time-code")
        browserPrediction(830, setOf("ONE_TIME_CODE", "HTML_TYPE_ONE_TIME_CODE"))
        htmlAttributeContains(820, "name", "otp")
        htmlAttributeContains(810, "id", "otp")
        htmlAttributeContains(800, "name", "code")
        htmlAttributeContains(790, "id", "code")
        heuristic(780, "id=verif") { idEntry?.lowercase()?.contains("verif") == true }
        heuristic(770, "id=2fa") { idEntry?.lowercase()?.contains("2fa") == true }
        heuristic(760, "id=twofactor") { idEntry?.lowercase()?.contains("twofactor") == true }
        heuristic(750, "id=token") { idEntry?.lowercase()?.contains("token") == true }
        heuristic(740, "id=pin") { idEntry?.lowercase()?.contains("pin") == true }
    }),
}


fun Int?.hasFlag(flag: Int) = this != null && flag and this == flag
@Suppress("unused")
fun Int.withFlag(flag: Int) = this or flag
@Suppress("unused")
fun Int.minusFlag(flag: Int) = this and flag.inv()


data class MatchedField(val heuristic: AutofillHeuristic, val autofillId: AutofillId)
