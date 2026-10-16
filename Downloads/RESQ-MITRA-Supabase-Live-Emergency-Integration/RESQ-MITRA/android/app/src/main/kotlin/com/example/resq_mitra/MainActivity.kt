package com.example.resq_mitra

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.telephony.SmsManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "resq_mitra/native_sms"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                if (call.method != "sendSms") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }

                val phone = call.argument<String>("phone")?.trim()
                val message = call.argument<String>("message")
                if (phone.isNullOrBlank() || message.isNullOrBlank()) {
                    result.error("invalid_arguments", "Phone number and message are required.", null)
                    return@setMethodCallHandler
                }
                if (checkSelfPermission(Manifest.permission.SEND_SMS)
                    != PackageManager.PERMISSION_GRANTED) {
                    result.error("permission_denied", "SMS permission has not been granted.", null)
                    return@setMethodCallHandler
                }

                try {
                    val manager: SmsManager = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        getSystemService(SmsManager::class.java)
                    } else {
                        @Suppress("DEPRECATION")
                        SmsManager.getDefault()
                    }
                    val parts = manager.divideMessage(message)
                    if (parts.size > 1) {
                        manager.sendMultipartTextMessage(phone, null, parts, null, null)
                    } else {
                        manager.sendTextMessage(phone, null, message, null, null)
                    }
                    // This confirms Android accepted the send request, not carrier delivery.
                    result.success("submitted")
                } catch (e: Exception) {
                    result.error("sms_send_failed", e.message ?: "Android could not submit the SMS.", null)
                }
            }
    }
}
