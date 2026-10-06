package com.zspeed.app

import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.nexgo.oaf.apiv3.APIProxy
import com.nexgo.oaf.apiv3.device.printer.AlignEnum
import com.nexgo.oaf.apiv3.device.printer.OnPrintListener

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.zspeed.app/printer"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "printReceipt") {
                val lines = call.argument<List<Map<String, Any>>>("lines")
                if (lines != null) {
                    printReceipt(lines, result)
                } else {
                    result.error("INVALID_ARGUMENT", "Lines parameter is missing", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun printReceipt(lines: List<Map<String, Any>>, result: MethodChannel.Result) {
        try {
            val deviceEngine = try {
                APIProxy.getDeviceEngine(applicationContext)
            } catch (e: Throwable) {
                null
            }

            if (deviceEngine == null) {
                result.error("PRINTER_UNSUPPORTED", "NEXGO printer service unavailable on this device.", null)
                return
            }

            val printer = deviceEngine.printer
            if (printer == null) {
                result.error("PRINTER_NULL", "Printer object is null.", null)
                return
            }

            val initRet = printer.initPrinter()
            if (initRet != 0) {
                // If init returns non-zero, retry once
                printer.initPrinter()
            }

            for (line in lines) {
                when (line["type"] as? String ?: "text") {
                    "text" -> {
                        val text = line["text"] as? String ?: ""
                        val rawSize = (line["size"] as? Number)?.toInt() ?: 24
                        val alignStr = (line["align"] as? String)?.uppercase() ?: "LEFT"
                        val isBold = line["bold"] as? Boolean ?: false

                        val align = when (alignStr) {
                            "CENTER" -> AlignEnum.CENTER
                            "RIGHT" -> AlignEnum.RIGHT
                            else -> AlignEnum.LEFT
                        }

                        // Normalize size to NEXGO supported font sizes: 16 (small), 24 (normal), 32 (large), 48 (xlarge)
                        val fontSize = when {
                            rawSize <= 18 -> 16
                            rawSize <= 26 -> 24
                            rawSize <= 36 -> 32
                            else -> 48
                        }

                        printer.appendPrnStr(text, fontSize, align, isBold)
                    }
                    "qrcode" -> {
                        val text = line["text"] as? String ?: ""
                        val rawSize = (line["size"] as? Number)?.toInt() ?: 200
                        val alignStr = (line["align"] as? String)?.uppercase() ?: "CENTER"

                        val align = when (alignStr) {
                            "LEFT" -> AlignEnum.LEFT
                            "RIGHT" -> AlignEnum.RIGHT
                            else -> AlignEnum.CENTER
                        }

                        printer.appendQRcode(text, rawSize, align)
                    }
                    "feed" -> {
                        val feedLines = (line["lines"] as? Number)?.toInt() ?: 1
                        printer.feedPaper(feedLines)
                    }
                }
            }

            printer.startPrint(true, OnPrintListener { retCode ->
                Handler(Looper.getMainLooper()).post {
                    if (retCode == 0) {
                        result.success(true)
                    } else {
                        val errorMsg = when (retCode) {
                            1, -1002 -> "Printer out of paper / لا يوجد ورق في الطابعة"
                            -1005, -1006 -> "Printer overheated / ارتفاع حرارة الطابعة"
                            -1004 -> "Low battery / البطارية ضعيفة"
                            -1001 -> "Printer busy / الطابعة مشغولة"
                            else -> "NEXGO printer error code: $retCode"
                        }
                        result.error("PRINT_FAILED", errorMsg, null)
                    }
                }
            })

        } catch (e: Throwable) {
            val rootCause = getRootCause(e)
            result.error("PRINTER_ERROR", rootCause.message ?: rootCause.toString(), rootCause.stackTraceToString())
        }
    }

    private fun getRootCause(throwable: Throwable): Throwable {
        var cause: Throwable? = throwable
        while (cause?.cause != null && cause.cause != cause) {
            cause = cause.cause
        }
        return cause ?: throwable
    }
}
