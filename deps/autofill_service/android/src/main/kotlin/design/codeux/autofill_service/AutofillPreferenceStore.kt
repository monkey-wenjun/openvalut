package design.codeux.autofill_service

import android.content.*
import androidx.core.content.edit
import mu.KotlinLogging
import org.json.JSONArray
import org.json.JSONObject

private val logger = KotlinLogging.logger {}

data class AutofillPreferences(
    val enableDebug: Boolean = false,
    val ignoredPackages: Set<String> = emptySet()
) {

    companion object {
        private const val PREF_JSON_NAME = "AutofillPreferences"
        private const val ENABLE_DEBUG = "enableDebug"
        private const val IGNORED_PACKAGES = "ignoredPackages"

        fun fromPreferences(prefs: SharedPreferences): AutofillPreferences =
            prefs.getString(PREF_JSON_NAME, null)?.let { json ->
                // Must not throw: this runs in the field initializer behind
                // getInstance(), i.e. inside the autofill service's onCreate.
                // A legacy or half-written blob has to degrade to defaults,
                // not take the whole service down with no visible reason.
                runCatching { fromJsonString(json) }.getOrElse {
                    logger.warn(it) { "Discarding unreadable autofill preferences." }
                    AutofillPreferences()
                }
            } ?: AutofillPreferences()

        private fun fromJsonString(jsonString: String) = JSONObject(jsonString).let {
            AutofillPreferences(
                enableDebug = it.optBoolean(ENABLE_DEBUG, false),
                ignoredPackages = it.optJSONArray(IGNORED_PACKAGES).asPackageSet()
            )
        }

        fun fromJsonValue(data: Map<String, Any>) = AutofillPreferences(
            enableDebug = (data[ENABLE_DEBUG] as? Boolean) ?: false,
            // Flutter sends an ArrayList, never a Set.
            ignoredPackages = (data[IGNORED_PACKAGES] as? List<*>)?.asPackageSet() ?: emptySet()
        )

        /** Package names are compared case-insensitively on purpose: the list is
         *  hand-editable through the method channel and a case mismatch fails as
         *  "I did add it, why does it still pop up", which costs nothing to avoid. */
        private fun JSONArray?.asPackageSet(): Set<String> =
            if (this == null) emptySet()
            else (0 until length()).mapNotNull { optString(it, null) }
                .mapTo(mutableSetOf()) { it.lowercase() }

        private fun List<*>.asPackageSet(): Set<String> =
            mapNotNull { it as? String }.mapTo(mutableSetOf()) { it.lowercase() }
    }

    fun saveToPreferences(prefs: SharedPreferences) {
        prefs.edit {
            putString(PREF_JSON_NAME, toJson())
        }
    }

    fun toMap() =
        mapOf(
            ENABLE_DEBUG to enableDebug,
            IGNORED_PACKAGES to ignoredPackages.toList(),
        )

    private fun toJson(): String = JSONObject(toMap()).toString()
}

class AutofillPreferenceStore private constructor(private val prefs: SharedPreferences) {


    companion object {

        private const val SHARED_PREFS_NAME = "design.codeux.autofill.prefs"

        private val lock = Any()
        private var instance: AutofillPreferenceStore? = null

        fun getInstance(context: Context): AutofillPreferenceStore =
            instance ?: getInstance(context.getSharedPreferences(SHARED_PREFS_NAME, Context.MODE_PRIVATE))

        private fun getInstance(prefs: SharedPreferences): AutofillPreferenceStore {
            synchronized(lock) {
                return instance ?: {
                    logger.debug { "Creating new AutofillPreferenceStore." }
                    val ret = AutofillPreferenceStore(prefs)
                    instance = ret
                    ret
                }()
            }
        }

    }

    var autofillPreferences: AutofillPreferences = AutofillPreferences.fromPreferences(prefs)
        set(value) {
            field = value
            value.saveToPreferences(prefs)
        }
}