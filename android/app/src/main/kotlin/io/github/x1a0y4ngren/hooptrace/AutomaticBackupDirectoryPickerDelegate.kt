package io.github.x1a0y4ngren.hooptrace

import android.app.Activity
import android.content.ContentResolver
import android.content.Intent
import android.net.Uri
import io.flutter.plugin.common.MethodChannel
import java.io.IOException

/** Owns the Android document-tree picker lifecycle outside the activity shell. */
internal class AutomaticBackupDirectoryPickerDelegate(
    private val activity: Activity,
    private val contentResolver: ContentResolver,
    private val storage: AutomaticBackupStorageDelegate,
) {
    private var pendingResult: MethodChannel.Result? = null

    fun pickDirectory(result: MethodChannel.Result) {
        if (pendingResult != null) {
            result.error("picker_busy", null, null)
            return
        }
        pendingResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            addFlags(
                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                    Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                    Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION or
                    Intent.FLAG_GRANT_PREFIX_URI_PERMISSION,
            )
        }
        try {
            activity.startActivityForResult(intent, REQUEST_CODE)
        } catch (_: Exception) {
            pendingResult = null
            result.error("picker_unavailable", null, null)
        }
    }

    @Suppress("DEPRECATION")
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_CODE) return false
        val result = pendingResult ?: return true
        pendingResult = null
        val treeUri = data?.data
        if (resultCode != Activity.RESULT_OK || treeUri == null) {
            result.success(null)
            return true
        }

        val grantFlags = data.flags and
            (Intent.FLAG_GRANT_READ_URI_PERMISSION or
                Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
        var persistedGrantFlags: Int? = null
        try {
            when (grantFlags) {
                Intent.FLAG_GRANT_READ_URI_PERMISSION -> {
                    contentResolver.takePersistableUriPermission(
                        treeUri,
                        Intent.FLAG_GRANT_READ_URI_PERMISSION,
                    )
                    persistedGrantFlags = Intent.FLAG_GRANT_READ_URI_PERMISSION
                }
                Intent.FLAG_GRANT_WRITE_URI_PERMISSION -> {
                    contentResolver.takePersistableUriPermission(
                        treeUri,
                        Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
                    )
                    persistedGrantFlags = Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                }
                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                    Intent.FLAG_GRANT_WRITE_URI_PERMISSION -> {
                    contentResolver.takePersistableUriPermission(
                        treeUri,
                        Intent.FLAG_GRANT_READ_URI_PERMISSION or
                            Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
                    )
                    persistedGrantFlags =
                        Intent.FLAG_GRANT_READ_URI_PERMISSION or
                            Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                }
                else -> throw IOException("The selected directory did not grant access.")
            }
            if (!storage.directoryExists(treeUri)) {
                throw IOException("The selected directory is not writable.")
            }
            result.success(
                mapOf(
                    "reference" to treeUri.toString(),
                    "displayName" to storage.directoryDisplayName(treeUri),
                ),
            )
        } catch (_: Exception) {
            releaseGrant(treeUri, persistedGrantFlags)
            result.error("directory_unavailable", null, null)
        }
        return true
    }

    fun dispose() {
        pendingResult?.error("picker_cancelled", null, null)
        pendingResult = null
    }

    private fun releaseGrant(treeUri: Uri, flags: Int?) {
        if (flags == null) return
        runCatching { contentResolver.releasePersistableUriPermission(treeUri, flags) }
    }

    companion object {
        const val REQUEST_CODE = 42017
    }
}
