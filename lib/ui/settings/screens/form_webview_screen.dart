import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart' as android_webview;

class FormWebviewScreen extends StatefulWidget {
  final String title;
  final String url;
  final String allowedHost;

  const FormWebviewScreen({
    super.key,
    required this.title,
    required this.url,
    required this.allowedHost,
  });

  @override
  State<FormWebviewScreen> createState() => _FormWebviewScreenState();
}

class _FormWebviewScreenState extends State<FormWebviewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final uri = Uri.parse(request.url);
            if (uri.host == widget.allowedHost || uri.host.endsWith('.${widget.allowedHost}')) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));

    if (Platform.isAndroid) {
      final androidController =
          _controller.platform as android_webview.AndroidWebViewController;
      androidController.setOnShowFileSelector(_handleFilePicker);
    }
  }

  Future<List<String>> _handleFilePicker(
    android_webview.FileSelectorParams params,
  ) async {
    try {
      final allowMultiple =
          params.mode == android_webview.FileSelectorMode.openMultiple;
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: allowMultiple,
      );
      if (result == null) return [];
      return result.files
          .where((file) => file.path != null)
          .map((file) => File(file.path!).uri.toString())
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FrostedScaffold(
      appBar: FrostedAppBar(
        title: widget.title,
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 100),
            child: WebViewWidget(controller: _controller),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 100),
              child: FrostedLinearProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
