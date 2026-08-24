package io.github.x1a0y4ngren.hooptrace

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/** Flutter shell; Android-specific storage and picker behavior live in delegates. */
class MainActivity : FlutterActivity() {
    private lateinit var backupChannel: AutomaticBackupChannelDelegate
    private lateinit var directoryPicker: AutomaticBackupDirectoryPickerDelegate

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        AndroidWindowPolicy.apply(window)
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
    }

    @Suppress("DEPRECATION")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (::directoryPicker.isInitialized) {
            directoryPicker.onActivityResult(requestCode, resultCode, data)
        }
    }

    override fun onDestroy() {
        if (::directoryPicker.isInitialized) directoryPicker.dispose()
        if (::backupChannel.isInitialized) backupChannel.dispose()
        super.onDestroy()
    }

    companion object {
        internal const val BACKUP_CHANNEL =
            AutomaticBackupWorkPolicy.storageChannelName
    }
}
