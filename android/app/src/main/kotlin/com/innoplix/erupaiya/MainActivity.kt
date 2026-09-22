package com.innoplix.erupaiya

import android.content.pm.ActivityInfo
import android.os.Bundle
import android.os.CancellationSignal
import android.os.Handler
import android.os.Looper
import android.os.ParcelFileDescriptor
import android.print.PageRange
import android.print.PrintAttributes
import android.print.PrintDocumentInfo
import android.print.LayoutResultCallbackProxy
import android.print.PrintDocumentAdapter
import android.print.WriteResultCallbackProxy
import android.view.WindowManager
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.activity.result.contract.ActivityResultContracts
import com.google.android.gms.auth.api.identity.GetPhoneNumberHintIntentRequest
import com.google.android.gms.auth.api.identity.Identity
import com.google.android.gms.tasks.OnFailureListener
import com.google.android.gms.tasks.OnSuccessListener
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import androidx.activity.result.IntentSenderRequest
import java.io.File
import java.util.concurrent.atomic.AtomicBoolean

class MainActivity: FlutterFragmentActivity() {
    private val channel = "com.innoplix.erupaiya/screen_security"
    private val receiptChannel = "com.innoplix.erupaiya/receipt_print"
    private val phoneHintChannel = "com.innoplix.erupaiya/phone_hint"
    private var pendingPhoneHintResult: MethodChannel.Result? = null

    private val phoneHintLauncher =
        registerForActivityResult(ActivityResultContracts.StartIntentSenderForResult()) { activityResult ->
            val result = pendingPhoneHintResult
            pendingPhoneHintResult = null
            if (result == null) return@registerForActivityResult

            if (activityResult.resultCode == RESULT_OK && activityResult.data != null) {
                try {
                    val phoneNumber =
                        Identity.getSignInClient(this).getPhoneNumberFromIntent(activityResult.data)
                    result.success(phoneNumber)
                } catch (e: Exception) {
                    result.success(null)
                }
            } else {
                result.success(null)
            }
        }

    override fun onCreate(savedInstanceState: Bundle?) {
        requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_PORTRAIT
        super.onCreate(savedInstanceState)
//        val isDebuggable =
//            (applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
//        if (!isDebuggable) {
//            window.setFlags(
//                WindowManager.LayoutParams.FLAG_SECURE,
//                WindowManager.LayoutParams.FLAG_SECURE
//            )
//        } else {
//            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
//        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "enableSecure" -> {
                        window.setFlags(
                            WindowManager.LayoutParams.FLAG_SECURE,
                            WindowManager.LayoutParams.FLAG_SECURE
                        )
                        result.success(null)
                    }
                    "disableSecure" -> {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, receiptChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "printHtmlToPdf" -> {
                        val html = call.argument<String>("html") ?: ""
                        val fileName = call.argument<String>("fileName") ?: "receipt.pdf"
                        if (html.isBlank()) {
                            result.error("invalid_html", "HTML is empty", null)
                            return@setMethodCallHandler
                        }
                        printHtmlToPdf(html, fileName, result)
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, phoneHintChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getPhoneNumberHint" -> {
                        requestPhoneNumberHint(result)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun requestPhoneNumberHint(result: MethodChannel.Result) {
        if (pendingPhoneHintResult != null) {
            result.error("in_progress", "Phone hint request already in progress", null)
            return
        }
        pendingPhoneHintResult = result
        val request = GetPhoneNumberHintIntentRequest.builder().build()
        val client = Identity.getSignInClient(this)
        client.getPhoneNumberHintIntent(request)
            .addOnSuccessListener(OnSuccessListener { pendingIntent ->
                try {
                    val intentSenderRequest =
                        IntentSenderRequest.Builder(pendingIntent.intentSender).build()
                    phoneHintLauncher.launch(intentSenderRequest)
                } catch (e: Exception) {
                    pendingPhoneHintResult?.success(null)
                    pendingPhoneHintResult = null
                }
            })
            .addOnFailureListener(OnFailureListener { e ->
                pendingPhoneHintResult?.success(null)
                pendingPhoneHintResult = null
            })
    }

    private fun printHtmlToPdf(
        html: String,
        fileName: String,
        result: MethodChannel.Result
    ) {
        val completed = AtomicBoolean(false)
        val timeoutMs = 15000L
        val handler = Handler(Looper.getMainLooper())
        val timeoutRunnable = Runnable {
            if (completed.compareAndSet(false, true)) {
                result.error("timeout", "WebView did not finish loading", null)
            }
        }
        handler.postDelayed(timeoutRunnable, timeoutMs)
        runOnUiThread {
            val webView = WebView(this)
            webView.settings.javaScriptEnabled = true
            webView.settings.domStorageEnabled = true
            webView.settings.loadWithOverviewMode = true
            webView.settings.useWideViewPort = true
            webView.webViewClient = object : WebViewClient() {
                override fun onPageFinished(view: WebView, url: String) {
                    handler.removeCallbacks(timeoutRunnable)
                    createPdfFromWebView(view, fileName, result, completed)
                }
            }
            webView.loadDataWithBaseURL(null, html, "text/html", "UTF-8", null)
        }
    }

    private fun createPdfFromWebView(
        webView: WebView,
        fileName: String,
        result: MethodChannel.Result,
        completed: AtomicBoolean
    ) {
        val adapter = webView.createPrintDocumentAdapter("receipt")
        val file = File(cacheDir, fileName)
        val attributes = PrintAttributes.Builder()
            .setMediaSize(PrintAttributes.MediaSize.ISO_A4)
            .setResolution(PrintAttributes.Resolution("pdf", "pdf", 600, 600))
            .setMinMargins(PrintAttributes.Margins.NO_MARGINS)
            .build()

        adapter.onLayout(
            null,
            attributes,
            CancellationSignal(),
            LayoutResultCallbackProxy(
                onFinished = { _: PrintDocumentInfo?, _: Boolean ->
                    try {
                        val pfd = ParcelFileDescriptor.open(
                            file,
                            ParcelFileDescriptor.MODE_TRUNCATE or
                                ParcelFileDescriptor.MODE_READ_WRITE or
                                ParcelFileDescriptor.MODE_CREATE
                        )
                        adapter.onWrite(
                            arrayOf(PageRange.ALL_PAGES),
                            pfd,
                            CancellationSignal(),
                            WriteResultCallbackProxy(
                                onFinished = {
                                    pfd.close()
                                    webView.destroy()
                                    if (completed.compareAndSet(false, true)) {
                                        result.success(file.absolutePath)
                                    }
                                },
                                onFailed = { error ->
                                    pfd.close()
                                    webView.destroy()
                                    if (completed.compareAndSet(false, true)) {
                                        result.error(
                                            "write_failed",
                                            error?.toString() ?: "Write failed",
                                            null
                                        )
                                    }
                                },
                                onCancelled = {
                                    pfd.close()
                                    webView.destroy()
                                    if (completed.compareAndSet(false, true)) {
                                        result.error(
                                            "write_cancelled",
                                            "Write cancelled",
                                            null
                                        )
                                    }
                                }
                            )
                        )
                    } catch (e: Exception) {
                        webView.destroy()
                        if (completed.compareAndSet(false, true)) {
                            result.error("write_exception", e.toString(), null)
                        }
                    }
                },
                onFailed = { error ->
                    webView.destroy()
                    if (completed.compareAndSet(false, true)) {
                        result.error(
                            "layout_failed",
                            error?.toString() ?: "Layout failed",
                            null
                        )
                    }
                },
                onCancelled = {
                    webView.destroy()
                    if (completed.compareAndSet(false, true)) {
                        result.error("layout_cancelled", "Layout cancelled", null)
                    }
                }
            ),
            null
        )
    }
}
