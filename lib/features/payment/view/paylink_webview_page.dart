import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:z_speed/features/payment/datasource/paylink_datasource.dart';

class PaylinkWebviewResult {
  final bool success;
  final int invoiceId;
  final String status;
  final String message;

  PaylinkWebviewResult({
    required this.success,
    required this.invoiceId,
    required this.status,
    required this.message,
  });
}

class PaylinkWebviewPage extends StatefulWidget {
  final String checkoutUrl;
  final int expectedInvoiceId;

  const PaylinkWebviewPage({
    super.key,
    required this.checkoutUrl,
    required this.expectedInvoiceId,
  });

  @override
  State<PaylinkWebviewPage> createState() => _PaylinkWebviewPageState();
}

class _PaylinkWebviewPageState extends State<PaylinkWebviewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasPopped = false;

  final PaylinkDatasource _datasource = PaylinkDatasource();
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController();
    _setupWebview();
  }

  void _setupWebview() {
    _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    _controller.setNavigationDelegate(
      NavigationDelegate(
        onPageStarted: (url) {
          setState(() => _isLoading = true);
          _checkReturnUrl(url);
        },
        onPageFinished: (url) async {
          if (!mounted) return;
          setState(() => _isLoading = false);

          // If navigated to receipt or confirmation page, auto-verify with PayLink
          final lower = url.toLowerCase();
          if (lower.contains('/receipt') ||
              lower.contains('success') ||
              lower.contains('completed') ||
              lower.contains('thankyou') ||
              lower.contains('payment-return')) {
            await _verifyAndPop(silent: true);
          }
        },
        onNavigationRequest: (request) {
          if (_checkReturnUrl(request.url)) {
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ),
    );

    _controller.loadRequest(Uri.parse(widget.checkoutUrl));
  }

  bool _checkReturnUrl(String url) {
    if (_hasPopped) return true;

    final uri = Uri.tryParse(url);
    if (uri == null) return false;

    // DO NOT intercept the gateway's checkout or processing pages!
    // The user MUST be allowed to stay on the page to choose Card/Wallet and enter credentials.
    final path = uri.path.toLowerCase();
    if (path.contains('/integration/checkout') ||
        path.contains('/cybersource/unifiedcheckout')) {
      return false;
    }

    // 1. Detect custom deep-link return scheme (e.g. zspeed://payment-return or paylink://)
    final isCustomScheme = (uri.scheme == 'zspeed' || uri.scheme == 'paylink') ||
        (uri.scheme.isNotEmpty &&
            uri.scheme != 'http' &&
            uri.scheme != 'https' &&
            uri.scheme != 'about');

    // 2. Detect gateway return redirect or success/failure page
    final isHttpReturn = path.contains('payment-return') ||
        path.contains('/payment/success') ||
        path.contains('/payment/failed') ||
        path.contains('/checkout/completed') ||
        path.contains('/checkout/return') ||
        path.contains('/receipt') ||
        (uri.queryParameters.containsKey('invoice_status') && !path.contains('/checkout')) ||
        (uri.queryParameters.containsKey('success') && !path.contains('/checkout'));

    if (isCustomScheme || isHttpReturn) {
      _hasPopped = true;

      final successParam = uri.queryParameters['success']?.toLowerCase();
      final invoiceStatus = (uri.queryParameters['invoice_status'] ??
          uri.queryParameters['status'] ??
          '').toUpperCase();
      final invoiceId = int.tryParse(uri.queryParameters['invoice_id'] ?? '') ??
          widget.expectedInvoiceId;
      final message = uri.queryParameters['message'] ?? 'Payment processed';
      final isSuccess = successParam == '1' ||
          successParam == 'true' ||
          invoiceStatus == 'PAID' ||
          invoiceStatus == 'COMPLETED';

      Navigator.of(context).pop(
        PaylinkWebviewResult(
          success: isSuccess,
          invoiceId: invoiceId,
          status: invoiceStatus.isNotEmpty ? invoiceStatus : (isSuccess ? 'PAID' : 'FAILED'),
          message: message,
        ),
      );
      return true;
    }

    return false;
  }

  Future<void> _verifyAndPop({bool silent = false}) async {
    if (_hasPopped) return;
    if (!silent) {
      setState(() => _isVerifying = true);
    }

    try {
      final res = await _datasource.checkPaymentStatus(widget.expectedInvoiceId);
      if (res['isPaid'] == true) {
        if (!_hasPopped && mounted) {
          _hasPopped = true;
          Navigator.of(context).pop(
            PaylinkWebviewResult(
              success: true,
              invoiceId: widget.expectedInvoiceId,
              status: 'PAID',
              message: 'Payment verified successfully',
            ),
          );
        }
        return;
      }

      if (!silent && mounted) {
        final isAr = Localizations.localeOf(context).languageCode == 'ar';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAr
                  ? 'لم يتم تأكيد السداد بعد من بوابة الدفع. يرجى إتمام الخطوات على الصفحة أولاً.'
                  : 'Payment is not marked as paid yet. Please complete checkout steps first.',
            ),
            backgroundColor: Colors.orange.shade800,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (_) {
      if (!silent && mounted) {
        final isAr = Localizations.localeOf(context).languageCode == 'ar';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAr ? 'تعذر التحقق من الدفع حالياً.' : 'Could not check payment status.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (!silent && mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || _hasPopped) return;
        // Verify one last time before exiting
        final res = await _datasource.checkPaymentStatus(widget.expectedInvoiceId);
        if (!_hasPopped && mounted) {
          _hasPopped = true;
          Navigator.of(context).pop(
            PaylinkWebviewResult(
              success: res['isPaid'] == true,
              invoiceId: widget.expectedInvoiceId,
              status: res['paidStatus']?.toString() ?? 'CANCELLED',
              message: res['isPaid'] == true ? 'Payment verified' : 'Payment cancelled',
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            isAr ? 'الدفع الإلكتروني الآمن' : 'Secure Payment',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              if (_hasPopped) return;
              final res = await _datasource.checkPaymentStatus(widget.expectedInvoiceId);
              if (!_hasPopped && mounted) {
                _hasPopped = true;
                Navigator.of(context).pop(
                  PaylinkWebviewResult(
                    success: res['isPaid'] == true,
                    invoiceId: widget.expectedInvoiceId,
                    status: res['paidStatus']?.toString() ?? 'CANCELLED',
                    message: res['isPaid'] == true ? 'Payment verified' : 'Payment cancelled',
                  ),
                );
              }
            },
          ),
          actions: [
            if (_isVerifying)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFF35535)),
                  ),
                ),
              )
            else
              TextButton.icon(
                onPressed: () => _verifyAndPop(silent: false),
                icon: const Icon(Icons.check_circle_outline, color: Color(0xFFF35535), size: 18),
                label: Text(
                  isAr ? 'تأكيد الدفع' : 'Verify',
                  style: const TextStyle(
                    color: Color(0xFFF35535),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: Colors.white.withValues(alpha: 0.8),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      color: Color(0xFFF35535),
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isAr ? 'جاري فتح بوابة الدفع الآمنة...' : 'Loading secure checkout...',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
