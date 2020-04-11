package de.johrpan.musicus

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.DocumentsContract
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

class Document(private val id: String, private val name: String, private val parentId: String?, private val isDirectory: Boolean) {
    fun toMap(): Map<String, Any?> {
        return mapOf(
                "id" to id,
                "name" to name,
                "parentId" to parentId,
                "isDirectory" to isDirectory
        )
    }
}

class MainActivity : FlutterActivity() {
    private val CHANNEL = "de.johrpan.musicus/platform"
    private val AODT_REQUEST = 0

    private var aodtResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "openTree") {
                aodtResult = result
                // We will get the result within onActivityResult
                openTree()
            } else if (call.method == "getChildren") {
                val treeUri = Uri.parse(call.argument<String>("treeUri"))
                val parentId = call.argument<String>("parentId")
                val children = getChildren(treeUri, parentId)
                result.success(children.map { it.toMap() })
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == AODT_REQUEST) {
            if (resultCode == Activity.RESULT_OK && data?.data != null) {
                // Drop all old URIs
                contentResolver.persistedUriPermissions.forEach {
                    contentResolver.releasePersistableUriPermission(it.uri, Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
                }

                // We already checked for null
                val uri = data.data!!
                contentResolver.takePersistableUriPermission(uri, Intent.FLAG_GRANT_WRITE_URI_PERMISSION)

                aodtResult?.success(uri.toString())
            } else {
                aodtResult?.success(null)
            }
        }
    }

    /**
     * Open a document tree using the storage access framework
     *
     * The result is handled within [onActivityResult]
     */
    private fun openTree() {
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE)
        intent.addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
        intent.addFlags(Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)

        startActivityForResult(intent, AODT_REQUEST)
    }

    /**
     * List children of a directory
     *
     * @param treeUri The treeUri from the ACTION_OPEN_DOCUMENT_TREE request
     * @param parentId Document ID of the parent directory or null for the top level directory
     * @return List of directories and files within the directory
     */
    private fun getChildren(treeUri: Uri, parentId: String?): List<Document> {
        val realParentId = parentId ?: DocumentsContract.getTreeDocumentId(treeUri)
        val children = ArrayList<Document>()
        val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(treeUri, realParentId)

        val cursor = contentResolver.query(
                childrenUri,
                arrayOf(DocumentsContract.Document.COLUMN_DOCUMENT_ID,
                        DocumentsContract.Document.COLUMN_DISPLAY_NAME,
                        DocumentsContract.Document.COLUMN_MIME_TYPE),
                null, null, null)

        if (cursor != null) {
            while (cursor.moveToNext()) {
                val id = cursor.getString(0)
                val name = cursor.getString(1)
                val isDirectory = cursor.getString(2) == DocumentsContract.Document.MIME_TYPE_DIR

                // Use parentId here to let the consumer know that we are at the top level.
                children.add(Document(id, name, parentId, isDirectory))
            }

            cursor.close()
        }

        return children
    }
}
