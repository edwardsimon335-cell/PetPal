import 'package:flutter/material.dart';

/// Reveals [text] character by character to mimic a pet "speaking" its reply
/// (spec 3.3 "逐字 / 流式显示"). When [animate] is false the full text is shown
/// immediately — used for history and already-seen lines.
class TypewriterText extends StatefulWidget {
  const TypewriterText({
    required this.text,
    this.style,
    this.textAlign = TextAlign.start,
    this.animate = true,
    this.charDuration = const Duration(milliseconds: 28),
    this.onCompleted,
    this.maxLines,
    this.overflow,
    super.key,
  });

  final String text;
  final TextStyle? style;
  final TextAlign textAlign;
  final bool animate;
  final Duration charDuration;
  final VoidCallback? onCompleted;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<int> _charCount;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _start();
  }

  void _start() {
    if (!widget.animate || widget.text.isEmpty) {
      // Nothing to animate — report completion after layout so callers can
      // safely mutate controller state in response.
      WidgetsBinding.instance
          .addPostFrameCallback((_) => widget.onCompleted?.call());
      return;
    }
    _controller.duration = widget.charDuration * widget.text.length;
    _charCount =
        StepTween(begin: 0, end: widget.text.length).animate(_controller);
    _controller.forward(from: 0);
    _controller.addStatusListener(_onStatus);
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      widget.onCompleted?.call();
    }
  }

  @override
  void didUpdateWidget(covariant TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text || oldWidget.animate != widget.animate) {
      _controller.removeStatusListener(_onStatus);
      _controller.reset();
      _start();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate || widget.text.isEmpty) {
      return Text(
        widget.text,
        style: widget.style,
        textAlign: widget.textAlign,
        maxLines: widget.maxLines,
        overflow: widget.overflow,
      );
    }
    return AnimatedBuilder(
      animation: _charCount,
      builder: (context, _) {
        final shown = widget.text.substring(0, _charCount.value);
        return Text(
          shown,
          style: widget.style,
          textAlign: widget.textAlign,
          maxLines: widget.maxLines,
          overflow: widget.overflow,
        );
      },
    );
  }
}
