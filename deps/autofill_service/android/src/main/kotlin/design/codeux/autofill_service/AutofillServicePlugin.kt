package design.codeux.autofill_service

import android.annotation.SuppressLint
import android.app.Activity.RESULT_OK
import android.app.Presentation
import android.app.assist.AssistStructure
import android.content.Context
import android.content.Intent
import android.content.IntentSender
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.provider.Settings
import android.service.autofill.Dataset
import android.service.autofill.AutofillService
import android.service.autofill.FillResponse
import android.service.autofill.Presentations
import android.view.autofill.AutofillId
import android.view.autofill.AutofillManager
import android.view.autofill.AutofillManager.EXTRA_AUTHENTICATION_RESULT
import android.view.autofill.AutofillValue
import android.widget.RemoteViews
import androidx.annotation.RequiresApi
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import mu.KotlinLogging
import org.json.JSONObject

private val logger = KotlinLogging.logger {}

data class PwDataset(
    val label: String,
    val username: String,
    val password: String,
    val otp: String = ""
)

@RequiresApi(Build.VERSION_CODES.O)
class AutofillServicePluginImpl(val context: Context) : MethodCallHandler,
        PluginRegistry.ActivityResultListener, PluginRegistry.NewIntentListener, ActivityAware {

    companion object {
        // some creative way so we have some more or less unique result code? 🤷️
        val REQUEST_CODE_SET_AUTOFILL_SERVICE =
            AutofillServicePlugin::class.java.hashCode() and 0xffff

        /// A fill request is treated as belonging to the current autofill
        /// session when it arrived within this window before the autofill
        /// intent. Both cold and warm start launch the auth activity right
        /// after the fill request, so the request normally PRECEDES the
        /// intent — requiring it to come after would wrongly mark the current
        /// session's delayed sender as stale (which dropped the fill on
        /// OTP-only 2FA pages that never re-issue a fill request).
        const val DELAYED_SENDER_FRESH_WINDOW_MS = 10_000L

    }

    private val autofillManager by lazy {
        requireNotNull(context.getSystemService(AutofillManager::class.java)) }
    private val autofillPreferenceStore by lazy { AutofillPreferenceStore.getInstance(context) }
    private var requestSetAutofillServiceResult: Result? = null
    private var lastIntent: Intent? = null

    /// When OpenVault started handling an autofill intent. The delayed fill
    /// sender stored by the service is only trustworthy after this point.
    @Volatile
    var autofillIntentAt: Long = 0L

    private var activityBinding: ActivityPluginBinding? = null
    private val activity get() = activityBinding?.activity

    override fun onMethodCall(call: MethodCall, result: Result) {
        logger.info { "Autofill method call: ${call.method}" }
        when (call.method) {
            "hasAutofillServicesSupport" ->
                result.success(true)
            "hasEnabledAutofillServices" ->
                result.success(autofillManager.hasEnabledAutofillServices())
            "disableAutofillServices" -> {
                autofillManager.disableAutofillServices()
                result.success(null)
            }
            "requestSetAutofillService" -> {
                val intent = Intent(Settings.ACTION_REQUEST_SET_AUTOFILL_SERVICE)
                intent.data = Uri.parse("package:com.example.android.autofill.service")
                logger.debug { "enableService(): intent=$intent" }
                requestSetAutofillServiceResult = result
                requireNotNull(activity, { "No Activity available." })
                        .startActivityForResult(intent,
                                REQUEST_CODE_SET_AUTOFILL_SERVICE
                        )
                // result will be delivered in onActivityResult!
            }
            "getBrowserAutofillStatus" -> {
                result.success(BrowserAutofill.queryStatus(context).map { it.toMap() })
            }
            "openBrowserAutofillSettings" -> {
                val packageName = call.argument<String>("packageName")
                    ?: throw IllegalArgumentException("Missing `packageName` argument.")
                val intent = BrowserAutofill.settingsIntent(packageName)
                val activity = this.activity
                if (activity == null) {
                    logger.warn { "No activity available to open $intent" }
                    result.success(false)
                    return
                }
                try {
                    activity.startActivity(intent)
                    result.success(true)
                } catch (e: Exception) {
                    logger.warn(e) { "Unable to open browser settings $intent" }
                    result.success(false)
                }
            }
            // method available while we are handling an autofill request.
            "getAutofillMetadata" -> {
                // When the app is already running, the autofill intent arrives
                // through onNewIntent and activity.intent may still hold the
                // previous intent — lastIntent is the one that carries the
                // browser context.
                val metadata = (lastIntent ?: activity?.intent)
                    ?.getStringExtra(AutofillMetadata.EXTRA_NAME)
                    ?.let(AutofillMetadata.Companion::fromJsonString)
                if (metadata != null) {
                    autofillIntentAt = SystemClock.elapsedRealtime()
                }
                logger.debug { "Got metadata: $metadata" }
                result.success(metadata?.toMap())
            }
            "resultWithDataset" -> {
                resultWithDataset(call, result)
            }
            "getPreferences" -> {
                result.success(
                    autofillPreferenceStore.autofillPreferences.toMap()
                )
            }
            "setPreferences" -> {
                val prefs = call.argument<Map<String, Any>>("preferences")?.let { data ->
                    AutofillPreferences.fromJsonValue(data)
                } ?: throw IllegalArgumentException("Invalid preferences object.")
                autofillPreferenceStore.autofillPreferences = prefs
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }
    private fun resultWithDataset(call: MethodCall, result: Result) {
        val label = call.argument<String>("label") ?: "Autofill"
        val username = call.argument<String>("username") ?: ""
        val password = call.argument<String>("password") ?: ""
        val otp = call.argument<String>("otp") ?: ""
        logger.info { "resultWithDataset label=$label username=${username?.length} password=${password?.length} otp=${otp?.length}" }
        if (password.isBlank() && otp.isBlank()) {
            logger.warn { "No known password or otp." }
        }
        resultWithDatasets(listOf(PwDataset(label, username, password, otp)), result)
    }

    private fun resultWithDatasets(pwDatasets: List<PwDataset>, result: Result) {

        val structureParcel: AssistStructure? =
            lastIntent?.extras?.getParcelable(AutofillManager.EXTRA_ASSIST_STRUCTURE)
                ?: activity?.intent?.extras?.getParcelable(
                    AutofillManager.EXTRA_ASSIST_STRUCTURE
                )
        if (structureParcel == null) {
            logger.info { "No structure available. (activity: $activity)" }
            result.success(false)
            return
        }

        val activity = requireNotNull(this.activity)

        val structure = AssistStructureParser(structureParcel)

        val autofillIds =
            (lastIntent ?: activity.intent)?.extras?.getParcelableArrayList<AutofillId>(
                "autofillIds"
            )
        logger.debug { "structure: $structure /// autofillIds: $autofillIds" }
        logger.info { "packageName: ${context.packageName} lastIntent=${lastIntent != null} activityIntent=${activity.intent}" }

        val remoteViews = {
            RemoteViewsHelper.viewsWithNoAuth(
                context.packageName, "Fill Me"
            )
        }
//        structure.fieldIds.values.forEach { it.sortByDescending { it.heuristic.weight } }

        // Prefer sending a delayed response through the fill request's
        // delayed intent sender: the result reaches the browser without
        // finishing the activity, so the app can stay alive and unlocked for
        // the next autofill request.
        val intentSender = FlutterMyAutofillService.delayedFillIntentSender
        val senderIsFresh = intentSender != null &&
            FlutterMyAutofillService.lastFillRequestAt >=
            autofillIntentAt - DELAYED_SENDER_FRESH_WINDOW_MS
        if (senderIsFresh) {
            if (sendDelayedResponse(
                    intentSender!!, pwDatasets, structure, remoteViews, activity
                )
            ) {
                result.success(true)
            } else {
                deliverViaAuthResult(pwDatasets, structure, remoteViews, activity, result)
            }
            return
        }

        // The stored sender belongs to an older autofill session. When
        // OpenVault moves to the background the framework re-issues a fresh
        // fill request (observed ~50ms after moveTaskToBack), and only that
        // session's delayed sender is accepted. So: return to the source app
        // immediately, wait for the fresh request, and commit with its
        // sender. Trying the stale sender is pointless — the framework
        // answers "Service did not request to wait" and drops it.
        logger.info { "Stale delayed sender; returning to source app and waiting for a fresh fill request." }
        val delivered = java.util.concurrent.atomic.AtomicBoolean(false)
        FlutterMyAutofillService.pendingDelayedSend = { freshSender ->
            val ok = sendDelayedResponse(
                freshSender, pwDatasets, structure, remoteViews, activity
            )
            if (ok) {
                delivered.set(true)
                result.success(true)
            } else {
                result.success(false)
            }
        }
        activity.moveTaskToBack(true)
        // Reliable fallback. Some devices/browsers never re-issue a fill
        // request after the auth activity goes to the background, in which
        // case the delayed sender never becomes valid and the commit would
        // otherwise be dropped. Deliver the response the classic way instead —
        // as the authentication result of the auth activity. This always
        // lands, at the cost of finishing the activity (the next autofill
        // re-unlocks the vault).
        Handler(Looper.getMainLooper()).postDelayed({
            if (delivered.get()) {
                return@postDelayed
            }
            // No fresh fill request arrived. The stored sender often still
            // belongs to the session the user is filling from (an OTP-only
            // 2FA page that never re-issues a fill request), so try it once
            // before falling back to the auth-result path.
            val stored = FlutterMyAutofillService.delayedFillIntentSender
            if (stored != null &&
                sendDelayedResponse(stored, pwDatasets, structure, remoteViews, activity)
            ) {
                delivered.set(true)
                result.success(true)
                return@postDelayed
            }
            val pending = FlutterMyAutofillService.pendingDelayedSend
            if (pending != null) {
                FlutterMyAutofillService.pendingDelayedSend = null
                logger.warn { "No fresh fill request arrived; falling back to setResult + finish." }
                deliverViaAuthResult(pwDatasets, structure, remoteViews, activity, result)
            } else {
                // The pending send was attempted but the framework rejected
                // it; deliver through the auth activity instead. The method
                // channel result was already answered by the failed send.
                logger.warn { "Delayed autofill response rejected; delivering via setResult + finish." }
                deliverViaAuthResult(pwDatasets, structure, remoteViews, activity, null)
            }
        }, 2500)
    }

    private fun deliverViaAuthResult(
        pwDatasets: List<PwDataset>,
        structure: AssistStructureParser,
        remoteViews: () -> RemoteViews,
        activity: android.app.Activity,
        result: Result?,
    ) {
        val datasetResponse = FillResponse.Builder()
            .setAuthentication(
                structure.autoFillIds.toTypedArray(),
                null,
                null as RemoteViews?
            )
            .apply {
                addDatasets(pwDatasets, structure, remoteViews)
            }
            .build()
        val replyIntent = Intent().apply {
            putExtra(EXTRA_AUTHENTICATION_RESULT, datasetResponse)
        }
        activity.setResult(RESULT_OK, replyIntent)
        activity.finish()
        result?.success(true)
    }

    private fun sendDelayedResponse(
        intentSender: IntentSender,
        pwDatasets: List<PwDataset>,
        structure: AssistStructureParser,
        remoteViews: () -> RemoteViews,
        activity: android.app.Activity,
    ): Boolean {
        val commitResponse = FillResponse.Builder()
            .apply {
                addDatasets(pwDatasets, structure, remoteViews)
            }
            .build()
        val delayedIntent = Intent()
            .putExtra(AutofillService.EXTRA_FILL_RESPONSE, commitResponse)
        return try {
            logger.info { "Sending delayed autofill response without finishing the activity." }
            intentSender.sendIntent(context, 0, delayedIntent, null, null)
            activity.moveTaskToBack(true)
            true
        } catch (e: Exception) {
            logger.warn(e) { "Delayed autofill response failed." }
            false
        }
    }

    private fun FillResponse.Builder.addDatasets(
        pwDatasets: List<PwDataset>,
        structure: AssistStructureParser,
        remoteViews: () -> RemoteViews,
    ) {
        pwDatasets.forEach { pw ->
            addDataset(Dataset.Builder(remoteViews()).apply {
                setId("test ${pw.username}")
                structure.allNodes.forEach { node ->
                    if (node.isFocused && node.autofillId != null) {
                        logger.debug("Setting focus node. {}", node.autofillId)
                        setValue(
                            node.autofillId!!,
                            AutofillValue.forText(pw.username),
                            RemoteViews(
                                context.packageName,
                                R.layout.multidataset_service_list_item
                            ).apply {
                                setTextViewText(R.id.text, pw.label + "(focus)")
                            })

                    }
                }
                val filledAutofillIds = mutableSetOf<AutofillId>()
                structure.fieldIds.flatMap { entry ->
                    entry.value.map { entry.key to it }
                }.sortedByDescending { it.second.heuristic.weight }.forEach allIds@{ (type, field) ->
                    val isNewAutofillId = filledAutofillIds.add(field.autofillId)
                    logger.debug { "Adding data set at weight ${field.heuristic.weight} for ${type.toString().padStart(10)} for ${field.autofillId} ${field.heuristic.message} ${"Ignored".takeIf { !isNewAutofillId } ?: ""}" }

                    if (!isNewAutofillId) {
                        return@allIds
                    }

                    val autoFillValue = when (type) {
                        AutofillInputType.Password -> pw.password
                        AutofillInputType.Otp -> pw.otp
                        else -> pw.username
                    }
                    setValue(
                        field.autofillId,
                        AutofillValue.forText(autoFillValue),
                        RemoteViews(
                            context.packageName,
                            R.layout.multidataset_service_list_item
                        ).apply {
                            setTextViewText(R.id.text, pw.label)
                        })
                }
            }.build())
        }
    }

    override fun onNewIntent(intent: Intent): Boolean {
        lastIntent = intent
        // A running OpenVault receives autofill requests through onNewIntent
        // (not getAutofillMetadata), so stamp the time here too — otherwise
        // the delayed sender freshness check compares against a stale value
        // and commits with an expired session sender.
        if (intent.hasExtra(AutofillMetadata.EXTRA_NAME)) {
            autofillIntentAt = SystemClock.elapsedRealtime()
        }
        logger.info {
            "We got a new intent. $intent (extras: ${intent.extras?.keySet()?.map {
                it to intent.extras?.get(
                    it
                )
            }})"
        }
        return false
    }


    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        logger.debug(
            "got activity result for $requestCode" +
                " (our: $REQUEST_CODE_SET_AUTOFILL_SERVICE) result: $resultCode"
        )
        if (requestCode == REQUEST_CODE_SET_AUTOFILL_SERVICE) {
            requestSetAutofillServiceResult?.let { result ->
                requestSetAutofillServiceResult = null
                result.success(resultCode == RESULT_OK)
            } ?: logger.warn { "Got activity result, but did not have a requestResult set." }
            return true
        }
        return false
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        binding.addActivityResultListener(this)
        binding.addOnNewIntentListener(this)
    }

    override fun onDetachedFromActivity() {
        activityBinding?.removeActivityResultListener(this)
        activityBinding?.removeOnNewIntentListener(this)
        activityBinding = null
    }

    override fun onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }
}

class AutofillServicePlugin : FlutterPlugin, ActivityAware {

    private var impl: AutofillServicePluginImpl? = null
    private var channel: MethodChannel? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        logger.info { "AutofillServicePlugin attached to engine." }
        val channel = MethodChannel(binding.binaryMessenger, "codeux.design/autofill_service")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            impl = AutofillServicePluginImpl(binding.applicationContext)
            channel.setMethodCallHandler(impl)
            logger.info { "AutofillServicePlugin handler registered." }
        } else {
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasAutofillServicesSupport" ->
                        result.success(false)
                    "hasEnabledAutofillServices" ->
                        result.success(null)
                    else -> result.notImplemented()
                }
            }
        }
        this.channel = channel
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        logger.info { "AutofillServicePlugin detached from engine." }
        channel?.setMethodCallHandler(null)
        channel = null
    }

    @SuppressLint("NewApi")
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        impl?.onAttachedToActivity(binding)
    }

    @SuppressLint("NewApi")
    override fun onDetachedFromActivityForConfigChanges() {
        impl?.onDetachedFromActivityForConfigChanges()
    }

    @SuppressLint("NewApi")
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        impl?.onReattachedToActivityForConfigChanges(binding)
    }

    @SuppressLint("NewApi")
    override fun onDetachedFromActivity() {
        impl?.onDetachedFromActivity()
    }
}
