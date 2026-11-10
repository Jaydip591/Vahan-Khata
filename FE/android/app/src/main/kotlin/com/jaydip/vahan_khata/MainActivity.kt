package com.jaydip.vahan_khata

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Opens a UPI app (Google Pay by default) with the amount filled in and hands its answer back
 * to Flutter. The UPI app returns a "response" text such as
 * "txnId=..&responseCode=00&Status=SUCCESS&txnRef=..&ApprovalRefNo=..".
 */
class MainActivity : FlutterActivity() {
    private val upiRequest = 4711
    private var pending: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "vahan_khata/upi")
            .setMethodCallHandler { call, result ->
                if (call.method != "pay") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                if (pending != null) {
                    result.error("BUSY", "A payment is already open", null)
                    return@setMethodCallHandler
                }
                val uri = Uri.parse(call.argument<String>("uri"))
                val pkg = call.argument<String>("package")
                val intent = Intent(Intent.ACTION_VIEW, uri)
                pending = result
                try {
                    if (pkg != null) {
                        try {
                            startActivityForResult(Intent(intent).setPackage(pkg), upiRequest)
                            return@setMethodCallHandler
                        } catch (_: ActivityNotFoundException) {
                            // That app is not installed: let the person choose another one.
                        }
                    }
                    startActivityForResult(Intent.createChooser(intent, null), upiRequest)
                } catch (_: ActivityNotFoundException) {
                    pending = null
                    result.error("NO_UPI_APP", "No UPI app on this phone", null)
                }
            }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != upiRequest) return
        val result = pending ?: return
        pending = null
        val extras = data?.extras
        val response = data?.getStringExtra("response")
            ?: extras?.keySet()?.joinToString("&") { "$it=${extras.getString(it) ?: ""}" }
        result.success(mapOf("resultOk" to (resultCode == RESULT_OK), "response" to response))
    }
}
