package io.github.x1a0y4ngren.hooptrace

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/** Flutter shell; Android-specific storage and picker behavior live in delegates. */
class MainActivity : FlutterActivity() {
    private val suppressEntryAnimation = synchronized(MainActivity::class.java) {
        val alreadyClaimed = entryAnimationClaimed
        entryAnimationClaimed = true
        alreadyClaimed
    }
    private lateinit var backupChannel: AutomaticBackupChannelDelegate
    private lateinit var directoryPicker: AutomaticBackupDirectoryPickerDelegate
    private var entryMotionChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        AndroidWindowPolicy.apply(window)
    }

    override fun getDartEntrypointArgs(): List<String>? {
        val arguments = super.getDartEntrypointArgs().orEmpty().toMutableList()
        if (suppressEntryAnimation) {
            arguments += ENTRY_ANIMATION_DISABLED_ARGUMENT
        }
        val value = getSharedPreferences(ENTRY_MOTION_PREFERENCES, MODE_PRIVATE)
            .getString(ENTRY_MOTION_KEY, null)
        if (value == "standard" || value == "reduced") {
            arguments += "$ENTRY_MOTION_ARGUMENT_PREFIX$value"
        }
        return arguments.ifEmpty { null }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val storage = AutomaticBackupStorageDelegate(contentResolver)
        directoryPicker = AutomaticBackupDirectoryPickerDelegate(
            activity = this,
            contentResolver = contentResolver,
            storage = storage,
        )
        val workManager = object : AutomaticBackupWorkManagerFacade {
            override fun schedule() = AutomaticBackupWorkManager.schedule(this@MainActivity)

            override fun cancel() = AutomaticBackupWorkManager.cancel(this@MainActivity)
        }
        backupChannel = AutomaticBackupChannelDelegate(
            storage = storage,
            picker = directoryPicker,
            workManager = workManager,
        )
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BACKUP_CHANNEL)
            .setMethodCallHandler(backupChannel::handle)
        entryMotionChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            ENTRY_MOTION_CHANNEL,
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                val preferences = getSharedPreferences(
                    ENTRY_MOTION_PREFERENCES,
                    MODE_PRIVATE,
                )
                when (call.method) {
                    "read" -> result.success(
                        if (preferences.contains(ENTRY_MOTION_KEY)) {
                            preferences.getString(ENTRY_MOTION_KEY, null)
                        } else {
                            null
                        },
                    )
                    "write" -> {
                        val value = call.arguments as? String
                        if (value != "standard" && value != "reduced") {
                            result.error("invalid_motion", "Unsupported motion preference", null)
                        } else if (preferences.edit().putString(ENTRY_MOTION_KEY, value).commit()) {
                            result.success(null)
                        } else {
                            result.error("write_failed", "Could not cache motion preference", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    @Suppress("DEPRECATION")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (::directoryPicker.isInitialized) {
            directoryPicker.onActivityResult(requestCode, resultCode, data)
        }
    }

    override fun onDestroy() {
        entryMotionChannel?.setMethodCallHandler(null)
        entryMotionChannel = null
        if (::directoryPicker.isInitialized) directoryPicker.dispose()
        if (::backupChannel.isInitialized) backupChannel.dispose()
        super.onDestroy()
    }

    companion object {
        internal const val BACKUP_CHANNEL =
            AutomaticBackupWorkPolicy.storageChannelName
        internal const val ENTRY_MOTION_CHANNEL =
            "io.github.x1a0y4ngren.hooptrace/entry_motion_preference"
        private const val ENTRY_MOTION_PREFERENCES = "entry_motion_preference"
        private const val ENTRY_MOTION_KEY = "motion"
        private const val ENTRY_MOTION_ARGUMENT_PREFIX = "--hooptrace-entry-motion="
        private const val ENTRY_ANIMATION_DISABLED_ARGUMENT =
            "--hooptrace-entry-animation=disabled"
        private var entryAnimationClaimed = false
    }
}
