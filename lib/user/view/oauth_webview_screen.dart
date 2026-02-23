import 'package:capstone_fe/common/const/colors.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// 소셜 로그인 OAuth를 앱 내 WebView에서 처리.
/// 외부 브라우저로 열면 Google/카카오 앱 또는 스토어로 넘어갈 수 있어,
/// WebView로만 진행하면 웹 로그인만 사용되어 앱 설치 불필요.
class OAuthWebViewScreen extends StatefulWidget {
  final String initialUrl;
  final String redirectScheme;
  final String redirectHost;

  const OAuthWebViewScreen({
    required this.initialUrl,
    this.redirectScheme = 'lookpick',
    this.redirectHost = 'auth',
    super.key,
  });

  @override
  State<OAuthWebViewScreen> createState() => _OAuthWebViewScreenState();
}

class _OAuthWebViewScreenState extends State<OAuthWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            final uri = Uri.tryParse(request.url);
            if (uri != null &&
                uri.scheme == widget.redirectScheme &&
                uri.host == widget.redirectHost) {
              if (!mounted) return NavigationDecision.prevent;
              Navigator.of(context).pop(uri);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
        ),
      );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.loadRequest(Uri.parse(widget.initialUrl));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.BLACK),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '소셜 로그인',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.BLACK,
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SizedBox.expand(
              child: WebViewWidget(controller: _controller),
            ),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(color: AppColors.PRIMARYCOLOR),
              ),
          ],
        ),
      ),
    );
  }
}
