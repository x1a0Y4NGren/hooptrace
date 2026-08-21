package io.github.x1a0y4ngren.hooptrace

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.DocumentsContract
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.IOException

class MainActivity : FlutterActivity() {
    private var pendingDirectoryResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BACKUP_CHANNEL)
            .setMethodCallHandler(::handleBackupMethod)
    }

    private fun handleBackupMethod(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "pickDirectory" -> pickDirectory(result)
            "directoryExists" -> runStorageOperation(result) {
                val directory = call.requireString("directory")
                directoryExists(Uri.parse(directory))
            }
            "writeBackup" -> runStorageOperation(result) {
                val directory = call.requireString("directory")
                val fileName = call.requireString("fileName")
                val bytes = call.argument<ByteArray>("bytes")
                    ?: throw IllegalArgumentException("Missing bytes")
                writeBackup(Uri.parse(directory), fileName, bytes)
            }
            else -> result.notImplemented()
        }
    }

    private fun pickDirectory(result: MethodChannel.Result) {
        if (pendingDirectoryResult != null) {
            result.error("picker_busy", "A directory picker is already open.", null)
            return
        }
        pendingDirectoryResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            addFlags(
                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                    Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                    Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION or
                    Intent.FLAG_GRANT_PREFIX_URI_PERMISSION,
            )
        }
        try {
            startActivityForResult(intent, DIRECTORY_REQUEST_CODE)
        } catch (error: Exception) {
            pendingDirectoryResult = null
            result.error("picker_unavailable", error.message, null)
        }
    }

    @Deprecated("Deprecated in Android, retained for FlutterActivity compatibility")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != DIRECTORY_REQUEST_CODE) return
        val result = pendingDirectoryResult ?: return
        pendingDirectoryResult = null
        val treeUri = data?.data
        if (resultCode != Activity.RESULT_OK || treeUri == null) {
            result.success(null)
            return
        }
        try {
            val grantFlags = data.flags and
                (Intent.FLAG_GRANT_READ_URI_PERMISSION or
                    Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
            contentResolver.takePersistableUriPermission(treeUri, grantFlags)
            if (!directoryExists(treeUri)) {
                throw IOException("The selected directory is not writable.")
            }
            result.success(
                mapOf(
                    "reference" to treeUri.toString(),
                    "displayName" to directoryDisplayName(treeUri),
                ),
            )
        } catch (error: Exception) {
            result.error("directory_unavailable", error.message, null)
        }
    }

    private fun directoryExists(treeUri: Uri): Boolean {
        val hasWritePermission = contentResolver.persistedUriPermissions.any {
            it.uri == treeUri && it.isWritePermission
        }
        if (!hasWritePermission) return false
        val directoryUri = treeDocumentUri(treeUri)
        return contentResolver.query(
            directoryUri,
            arrayOf(DocumentsContract.Document.COLUMN_DOCUMENT_ID),
            null,
            null,
            null,
        )?.use { cursor -> cursor.moveToFirst() } == true
    }

    private fun directoryDisplayName(treeUri: Uri): String {
        val directoryUri = treeDocumentUri(treeUri)
        val name = contentResolver.query(
            directoryUri,
            arrayOf(DocumentsContract.Document.COLUMN_DISPLAY_NAME),
            null,
            null,
            null,
        )?.use { cursor ->
            if (cursor.moveToFirst()) cursor.getString(0) else null
        }
        return name?.takeIf { it.isNotBlank() } ?: "已授权文件夹"
    }

    private fun writeBackup(treeUri: Uri, requestedName: String, bytes: ByteArray): String {
        if (!directoryExists(treeUri)) {
            throw IOException("The selected directory permission is unavailable.")
        }
        val directoryUri = treeDocumentUri(treeUri)
        val fileName = uniqueFileName(treeUri, requestedName)
        val temporaryName = ".$fileName.partial"
        val temporaryUri = DocumentsContract.createDocument(
            contentResolver,
            directoryUri,
            JSON_MIME_TYPE,
            temporaryName,
        ) ?: throw IOException("The document provider could not create a backup file.")

        try {
            writeDocument(temporaryUri, bytes)
            val renamedUri = runCatching {
                DocumentsContract.renameDocument(
                    contentResolver,
                    temporaryUri,
                    fileName,
                )
            }.getOrNull()
            if (renamedUri != null) return renamedUri.toString()

            runCatching { DocumentsContract.deleteDocument(contentResolver, temporaryUri) }
            return createAndWriteDocument(directoryUri, fileName, bytes).toString()
        } catch (error: Exception) {
            runCatching { DocumentsContract.deleteDocument(contentResolver, temporaryUri) }
            throw error
        }
    }

    private fun createAndWriteDocument(
        directoryUri: Uri,
        fileName: String,
        bytes: ByteArray,
    ): Uri {
        val destinationUri = DocumentsContract.createDocument(
            contentResolver,
            directoryUri,
            JSON_MIME_TYPE,
            fileName,
        ) ?: throw IOException("The document provider could not create a backup file.")
        try {
            writeDocument(destinationUri, bytes)
            return destinationUri
        } catch (error: Exception) {
            runCatching { DocumentsContract.deleteDocument(contentResolver, destinationUri) }
            throw error
        }
    }

    private fun writeDocument(documentUri: Uri, bytes: ByteArray) {
        contentResolver.openOutputStream(documentUri, "wt")?.use { stream ->
            stream.write(bytes)
            stream.flush()
        } ?: throw IOException("The document provider could not open the backup file.")
    }

    private fun uniqueFileName(treeUri: Uri, requestedName: String): String {
        val existingNames = mutableSetOf<String>()
        val treeDocumentId = DocumentsContract.getTreeDocumentId(treeUri)
        val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(
            treeUri,
            treeDocumentId,
        )
        contentResolver.query(
            childrenUri,
            arrayOf(DocumentsContract.Document.COLUMN_DISPLAY_NAME),
            null,
            null,
            null,
        )?.use { cursor ->
            while (cursor.moveToNext()) existingNames += cursor.getString(0)
        }
        if (requestedName !in existingNames) return requestedName

        val extensionIndex = requestedName.lastIndexOf('.')
        val baseName = if (extensionIndex > 0) {
            requestedName.substring(0, extensionIndex)
        } else {
            requestedName
        }
        val extension = if (extensionIndex > 0) {
            requestedName.substring(extensionIndex)
        } else {
            ""
        }
        var suffix = 1
        while ("$baseName-$suffix$extension" in existingNames) suffix++
        return "$baseName-$suffix$extension"
    }

    private fun treeDocumentUri(treeUri: Uri): Uri {
        return DocumentsContract.buildDocumentUriUsingTree(
            treeUri,
            DocumentsContract.getTreeDocumentId(treeUri),
        )
    }

    private fun MethodCall.requireString(name: String): String {
        return argument<String>(name)?.takeIf { it.isNotBlank() }
            ?: throw IllegalArgumentException("Missing $name")
    }

    private fun <T> runStorageOperation(
        result: MethodChannel.Result,
        operation: () -> T,
    ) {
        Thread {
            try {
                val value = operation()
                runOnUiThread { result.success(value) }
            } catch (error: Exception) {
                runOnUiThread {
                    result.error("storage_error", error.message, null)
                }
            }
        }.start()
    }

    companion object {
        private const val BACKUP_CHANNEL =
            "io.github.x1a0y4ngren.hooptrace/automatic_backup"
        private const val DIRECTORY_REQUEST_CODE = 42017
        private const val JSON_MIME_TYPE = "application/json"
    }
}
