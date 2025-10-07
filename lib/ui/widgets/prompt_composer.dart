import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'circle_icon_button.dart';

class PromptComposer extends StatefulWidget {
  final ValueChanged<String>? onPromptChanged;
  final Future<void> Function(Uint8List bytes, String filename)? onPickImage;
  final VoidCallback? onSend;
  final String initialPrompt;
  final TextEditingController? controller;

  const PromptComposer({
    super.key,
    this.onPromptChanged,
    this.onPickImage,
    this.onSend,
    this.initialPrompt = '',
    this.controller,
  });

  @override
  State<PromptComposer> createState() => _PromptComposerState();
}

class _PromptComposerState extends State<PromptComposer> {
  late TextEditingController _controller;
  VoidCallback? _ctrlListener;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ?? TextEditingController(text: widget.initialPrompt);
    _ctrlListener = () => setState(() {});
    _controller.addListener(_ctrlListener!);
  }

  @override
  void dispose() {
    _controller.removeListener(_ctrlListener!);
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PromptComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      // move listener to new controller
      oldWidget.controller?.removeListener(_ctrlListener!);
      if (widget.controller != null) {
        _controller = widget.controller!;
      } else if (oldWidget.controller != null) {
        // switched from external to internal; re-create internal controller
        _controller = TextEditingController(text: widget.initialPrompt);
      }
      _controller.addListener(_ctrlListener!);
      setState(() {});
    }
  }

  Future<void> _pick() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (res != null && res.files.single.bytes != null) {
      final bytes = res.files.single.bytes!;
      final name = res.files.single.name;
      await widget.onPickImage?.call(bytes, name);
      setState(() {}); // update send enabled if prompt present
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSend = _controller.text.trim().isNotEmpty;
    return Material(
      elevation: 0,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.black26, width: 1),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 12,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left circular + button without border
            CircleIconButton(
              icon: Icons.add,
              size: 36,
              backgroundColor: Colors.white,
              iconColor: Colors.black,
              tooltip: 'Upload image',
              onPressed: _pick,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Describe how you want to edit the image…',
                  border: InputBorder.none,
                ),
                onChanged: (v) {
                  widget.onPromptChanged?.call(v);
                  setState(() {}); // refresh send enabled
                },
              ),
            ),
            const SizedBox(width: 8),
            // Right circular send button without border
            CircleIconButton(
              icon: Icons.send,
              size: 36,
              backgroundColor: Colors.white,
              iconColor: Colors.black,
              tooltip: 'Generate',
              onPressed: canSend ? widget.onSend : null,
            ),
          ],
        ),
      ),
    );
  }
}
