import 'package:flutter/material.dart';
import 'package:pixelarticons/pixelarticons.dart';

import '../../app/petpal_controller.dart';
import '../../core/theme/petpal_theme.dart';
import '../../shared/models/chat_message.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/thinking_bubble.dart';

/// Opens the chat history window (spec 3.4): a semi-transparent panel that
/// slides up over the pet scene (the pet stays faintly visible behind the
/// dimmed barrier) and shows the complete conversation, grouped by date.
Future<void> showChatHistorySheet(
  BuildContext context,
  PetPalController controller,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    // A light barrier keeps the pet visible underneath, preserving the sense of
    // companionship instead of jumping to a separate full-page chat.
    barrierColor: PetPalColors.ink.withValues(alpha: 0.34),
    builder: (_) => ChatHistorySheet(controller: controller),
  );
}

class ChatHistorySheet extends StatefulWidget {
  const ChatHistorySheet({required this.controller, super.key});

  final PetPalController controller;

  @override
  State<ChatHistorySheet> createState() => _ChatHistorySheetState();
}

class _ChatHistorySheetState extends State<ChatHistorySheet> {
  static const _pageSize = 40;

  final ScrollController _scrollController = ScrollController();
  int _visibleCount = _pageSize;

  @override
  void initState() {
    super.initState();
    _visibleCount =
        widget.controller.messages.length.clamp(0, _pageSize).toInt();
    _scrollController.addListener(_onScroll);
    // Open at the latest message (spec 3.4 "回到最新一轮对话位置").
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToBottom());
  }

  void _jumpToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  /// Near the top, reveal an older page while compensating the scroll offset so
  /// the content under the user's finger does not jump.
  void _onScroll() {
    if (_scrollController.position.pixels > 48) return;
    final total = widget.controller.messages.length;
    if (_visibleCount >= total) return;
    final before = _scrollController.position.maxScrollExtent;
    setState(() {
      _visibleCount = (_visibleCount + _pageSize).clamp(0, total).toInt();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final after = _scrollController.position.maxScrollExtent;
      _scrollController.jumpTo(_scrollController.position.pixels + (after - before));
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(top: mediaQuery.padding.top + 56),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFBF3DE).withValues(alpha: 0.94),
            border: Border.all(color: PetPalColors.line, width: 2),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              _buildHandleAndHeader(context),
              const Divider(height: 1, color: PetPalColors.line),
              Expanded(child: _buildList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandleAndHeader(BuildContext context) {
    return GestureDetector(
      // Drag the header down to close (spec 3.4 "下滑").
      onVerticalDragEnd: (details) {
        if ((details.primaryVelocity ?? 0) > 160) Navigator.of(context).pop();
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: PetPalColors.line,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 10, 8),
            child: Row(
              children: [
                const Icon(Pixel.chat, size: 19, color: PetPalColors.bark),
                const SizedBox(width: 8),
                const Text(
                  'Chat history',
                  style: TextStyle(
                    color: PetPalColors.bark,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Pixel.close, color: PetPalColors.cocoa),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final pet = widget.controller.currentPet;
        final all = widget.controller.messages;
        if (pet == null || all.isEmpty) {
          return const _EmptyHistory();
        }

        final start = (all.length - _visibleCount).clamp(0, all.length).toInt();
        final visible = all.sublist(start);
        final items = _withDateHeaders(visible);

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
          itemCount: items.length + (widget.controller.petThinking ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= items.length) {
              return ThinkingBubble(
                role: pet.role,
                avatarUrl: pet.avatarUrl,
                avatarVariant: pet.avatarVariant,
              );
            }
            final item = items[index];
            if (item is _DateHeader) {
              return _DateHeaderTile(label: item.label);
            }
            final message = item as ChatMessage;
            return ChatBubble(
              message: message,
              role: pet.role,
              avatarUrl: pet.avatarUrl,
              avatarVariant: pet.avatarVariant,
              onRetry: () => widget.controller.retryMessage(message),
              onLongPressRemember: message.isPet
                  ? () => _remember(context, message)
                  : null,
            );
          },
        );
      },
    );
  }

  void _remember(BuildContext context, ChatMessage message) {
    final wasRemembered = message.remembered;
    widget.controller.rememberMessage(message);
    if (wasRemembered) return;
    final name = widget.controller.currentPet?.name ?? 'Your pet';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          backgroundColor: PetPalColors.ink,
          content: Text('$name will remember this 💭'),
        ),
      );
  }

  /// Inserts a date header before the first message of each calendar day.
  List<Object> _withDateHeaders(List<ChatMessage> source) {
    final items = <Object>[];
    DateTime? currentDay;
    for (final message in source) {
      final day = DateUtils.dateOnly(message.createdAt);
      if (currentDay == null || day != currentDay) {
        items.add(_DateHeader(_labelForDay(day)));
        currentDay = day;
      }
      items.add(message);
    }
    return items;
  }

  String _labelForDay(DateTime day) {
    final today = DateUtils.dateOnly(DateTime.now());
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
  }
}

class _DateHeader {
  const _DateHeader(this.label);
  final String label;
}

class _DateHeaderTile extends StatelessWidget {
  const _DateHeaderTile({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: PetPalColors.tan.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: PetPalColors.line, width: 1),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: PetPalColors.cocoa,
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Pixel.chat, size: 40, color: PetPalColors.line),
            SizedBox(height: 12),
            Text(
              'No messages yet.\nSay hello to start chatting!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: PetPalColors.cocoa,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.4,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
