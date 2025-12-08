import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../theme/app_colors.dart';

/// 终端输出组件
/// 用于实时显示命令行输出
class TerminalOutput extends StatefulWidget {
  final Stream<String>? outputStream;
  final String title;
  final VoidCallback? onClose;
  final VoidCallback? onClear;
  final VoidCallback? onStop;
  final bool isRunning;

  const TerminalOutput({
    super.key,
    this.outputStream,
    this.title = 'Terminal',
    this.onClose,
    this.onClear,
    this.onStop,
    this.isRunning = false,
  });

  @override
  State<TerminalOutput> createState() => TerminalOutputState();
}

class TerminalOutputState extends State<TerminalOutput> {
  final List<String> _lines = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _listenToStream();
  }

  @override
  void didUpdateWidget(TerminalOutput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.outputStream != oldWidget.outputStream) {
      _listenToStream();
    }
  }

  void _listenToStream() {
    widget.outputStream?.listen((line) {
      if (mounted) {
        setState(() {
          _lines.add(line);
        });
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void clear() {
    setState(() {
      _lines.clear();
    });
  }

  void addLine(String line) {
    setState(() {
      _lines.add(line);
    });
    _scrollToBottom();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 标题栏
          _buildHeader(),
          
          // 分隔线
          Container(height: 1, color: AppColors.divider),
          
          // 输出内容区域
          Expanded(
            child: _buildOutputArea(),
          ),
          
          // 底部操作栏
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF252526),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.text_cursor,
            size: 16,
            color: Color(0xFF858585),
          ),
          const SizedBox(width: 8),
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFFCCCCCC),
            ),
          ),
          const Spacer(),
          if (widget.isRunning)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withAlpha(50),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Running',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF4EC9B0),
                    ),
                  ),
                ],
              ),
            ),
          if (widget.onClose != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: widget.onClose,
              child: const Icon(
                CupertinoIcons.xmark,
                size: 14,
                color: Color(0xFF858585),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOutputArea() {
    if (_lines.isEmpty) {
      return const Center(
        child: Text(
          'Waiting for output...',
          style: TextStyle(
            color: Color(0xFF858585),
            fontSize: 13,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      itemCount: _lines.length,
      itemBuilder: (context, index) {
        final line = _lines[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: SelectableText(
            line,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: _getLineColor(line),
              height: 1.4,
            ),
          ),
        );
      },
    );
  }

  Color _getLineColor(String line) {
    // 根据内容着色
    final lowerLine = line.toLowerCase();
    if (lowerLine.contains('error') || lowerLine.contains('failed')) {
      return const Color(0xFFF48771);
    } else if (lowerLine.contains('success') || lowerLine.contains('found')) {
      return const Color(0xFF4EC9B0);
    } else if (lowerLine.contains('warning')) {
      return const Color(0xFFCE9178);
    } else if (line.startsWith('>') || line.startsWith('\$')) {
      return const Color(0xFF569CD6);
    }
    return const Color(0xFFD4D4D4);
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF252526),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 行数统计
          Text(
            '${_lines.length} lines',
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF858585),
            ),
          ),
          const Spacer(),
          // 清空按钮
          if (widget.onClear != null)
            _buildActionButton(
              icon: CupertinoIcons.trash,
              label: 'Clear',
              onTap: () {
                clear();
                widget.onClear?.call();
              },
            ),
          // 停止按钮
          if (widget.onStop != null && widget.isRunning) ...[
            const SizedBox(width: 8),
            _buildActionButton(
              icon: CupertinoIcons.stop_fill,
              label: 'Stop',
              onTap: widget.onStop,
              color: AppColors.error,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF3C3C3C),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color ?? const Color(0xFFCCCCCC)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color ?? const Color(0xFFCCCCCC),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
