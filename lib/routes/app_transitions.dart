import 'package:flutter/material.dart';

enum PageTransition { slideRight, slideUp, fade }

Route<dynamic> buildRoute(
  RouteSettings settings,
  Widget page, {
  PageTransition transition = PageTransition.slideRight,
}) {
  return PageRouteBuilder(
    settings: settings,
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      switch (transition) {
        case PageTransition.slideUp:
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.25),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        case PageTransition.fade:
          return FadeTransition(opacity: animation, child: child);
        case PageTransition.slideRight:
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.25, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
      }
    },
    transitionDuration: const Duration(milliseconds: 280),
  );
}
