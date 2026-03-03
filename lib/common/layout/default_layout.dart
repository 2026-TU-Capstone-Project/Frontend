import 'package:flutter/material.dart';

class DefaultLayout extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final Widget? title;
  final Widget? bottomNavigationBar;
  final List<Widget>? actions;
  const DefaultLayout({
    required this.child,
    this.title,
    this.bottomNavigationBar,
    this.backgroundColor,
    this.actions,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? Colors.white,
      appBar: renderAppbar(),
      body: child,
      bottomNavigationBar: bottomNavigationBar,
    );
  }

  AppBar? renderAppbar() {
    if (title == null) {
      return null;
    } else {
      return AppBar(
        backgroundColor: Colors.white,
        title: title,
        centerTitle: false,
        automaticallyImplyLeading: false,
        titleSpacing: 26.0,
        actions: actions,
      );
    }
  }
}
