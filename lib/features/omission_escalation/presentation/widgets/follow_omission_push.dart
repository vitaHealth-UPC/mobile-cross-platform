import 'package:flutter/widgets.dart';

/// Follows the omission notifications of the screen being shown: runs [follow] when the
/// screen appears and again whenever [followKey] changes (another person is followed).
///
/// A failure of [follow] never reaches the screen: following is best effort and the
/// notification permission and delivery are owned by the platform adapters.
class FollowOmissionPush extends StatefulWidget {
  const FollowOmissionPush({
    super.key,
    required this.followKey,
    required this.follow,
    required this.child,
  });

  final String followKey;
  final Future<void> Function() follow;
  final Widget child;

  @override
  State<FollowOmissionPush> createState() => _FollowOmissionPushState();
}

class _FollowOmissionPushState extends State<FollowOmissionPush> {
  @override
  void initState() {
    super.initState();
    _follow();
  }

  @override
  void didUpdateWidget(FollowOmissionPush oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.followKey != widget.followKey) _follow();
  }

  void _follow() {
    widget.follow().catchError((Object _) {});
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
