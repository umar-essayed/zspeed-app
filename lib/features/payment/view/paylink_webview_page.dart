import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
        onPageFinished: (url) {
          setState(() => _isLoading = false);
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

    // Detect return deep link or return redirect
    final isCustomScheme = uri.scheme == 'zspeed' && uri.host == 'payment-return';
    final isHttpReturn = uri.path.contains('payment-return') ||
        uri.queryParameters.containsKey('invoice_status') ||
        uri.queryParameters.containsKey('invoice_id');

    if (isCustomScheme || isHttpReturn) {
      _hasPopped = true;

      final successParam = uri.queryParameters['success'];
      final invoiceStatus = uri.queryParameters['invoice_status'] ??
          uri.queryParameters['status'] ??
          (successParam == '1' ? 'PAID' : 'FAILED');
      final invoiceId = int.tryParse(uri.queryParameters['invoice_id'] ?? '') ??
          widget.expectedInvoiceId;
      final message = uri.queryParameters['message'] ?? 'Payment processed';
      final isSuccess = successParam == '1' || invoiceStatus.toUpperCase() == 'PAID';

      Navigator.of(context).pop(
        PaylinkWebviewResult(
          success: isSuccess,
          invoiceId: invoiceId,
          status: invoiceStatus,
          message: message,
        ),
      );
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
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
          onPressed: () {
            if (!_hasPopped) {
              _hasPopped = true;
              Navigator.of(context).pop(null);
            }
          },
        ),
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
