import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

/// Page transitions that honour "Reducir movimiento" (and the platform's own
/// reduce-motion setting): both reach [MediaQuery.disableAnimationsOf], and
/// when it is set the platform transition is kept at rest, so the next page
/// simply appears. Defaults mirror Flutter's own per-platform builders.
final class MotionAwarePageTransitionsBuilder extends PageTransitionsBuilder {
  const MotionAwarePageTransitionsBuilder(this._animated);

  final PageTransitionsBuilder _animated;

  /// Platform defaults wrapped so every [MaterialPageRoute] respects the setting.
  static const theme = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: MotionAwarePageTransitionsBuilder(
        PredictiveBackPageTransitionsBuilder(),
      ),
      TargetPlatform.iOS: MotionAwarePageTransitionsBuilder(
        CupertinoPageTransitionsBuilder(),
      ),
      TargetPlatform.macOS: MotionAwarePageTransitionsBuilder(
        CupertinoPageTransitionsBuilder(),
      ),
      TargetPlatform.windows: MotionAwarePageTransitionsBuilder(
        ZoomPageTransitionsBuilder(),
      ),
      TargetPlatform.linux: MotionAwarePageTransitionsBuilder(
        ZoomPageTransitionsBuilder(),
      ),
    },
  );

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (!MediaQuery.disableAnimationsOf(context)) {
      return _animated.buildTransitions(
        route,
        context,
        animation,
        secondaryAnimation,
        child,
      );
    }
    // Same builder (keeps back gestures) frozen at rest; a page being popped
    // is hidden at once instead of sliding out.
    return AnimatedBuilder(
      animation: animation,
      builder: (context, page) => Opacity(
        opacity: animation.status == AnimationStatus.reverse ? 0 : 1,
        child: page,
      ),
      child: _animated.buildTransitions(
        route,
        context,
        kAlwaysCompleteAnimation,
        kAlwaysDismissedAnimation,
        child,
      ),
    );
  }
}

/// Route for a bottom-bar destination. Switching tabs is not forward
/// navigation, so it cross-fades briefly instead of sliding, and appears
/// instantly when motion is reduced. Open it with [replaceTab] so the previous
/// tab is removed without running its own exit animation at the same time.
final class TabPageRoute<T> extends PageRouteBuilder<T> {
  TabPageRoute({required WidgetBuilder builder, super.settings})
    : super(
        pageBuilder: (context, _, _) => builder(context),
        transitionDuration: const Duration(milliseconds: 180),
        reverseTransitionDuration: const Duration(milliseconds: 140),
        transitionsBuilder: (context, animation, _, child) =>
            MediaQuery.disableAnimationsOf(context)
            ? Opacity(
                opacity: animation.status == AnimationStatus.reverse ? 0 : 1,
                child: child,
              )
            : FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOut,
                ),
                child: child,
              ),
      );

  /// Shows [builder] as the only route above the home, discarding the other
  /// destinations without animating them out.
  static Future<T?> replaceTab<T>(
    BuildContext context,
    WidgetBuilder builder,
  ) => Navigator.of(context).pushAndRemoveUntil<T>(
    TabPageRoute<T>(builder: builder),
    (route) => route.isFirst,
  );
}
