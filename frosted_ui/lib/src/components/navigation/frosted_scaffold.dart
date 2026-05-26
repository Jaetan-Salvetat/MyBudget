import 'package:flutter/material.dart';

/// A thin [Scaffold] wrapper that turns on `extendBody` and
/// `extendBodyBehindAppBar` by default — every Frosted UI chrome floats
/// above content, so the body should always flow underneath.
///
/// Mirrors [Scaffold]'s most common API surface. Reach for the underlying
/// [Scaffold] directly when you need a setting not exposed here.
class FrostedScaffold extends StatelessWidget {
  const FrostedScaffold({
    super.key,
    this.appBar,
    this.body,
    this.bottomNavigationBar,
    this.drawer,
    this.endDrawer,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.backgroundColor,
    this.extendBody = true,
    this.extendBodyBehindAppBar = true,
    this.resizeToAvoidBottomInset = true,
    this.drawerScrimColor,
  });

  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final Widget? endDrawer;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Color? backgroundColor;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final bool resizeToAvoidBottomInset;
  final Color? drawerScrimColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: body,
      bottomNavigationBar: bottomNavigationBar,
      drawer: drawer,
      endDrawer: endDrawer,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      backgroundColor: backgroundColor,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      drawerScrimColor: drawerScrimColor,
    );
  }
}
