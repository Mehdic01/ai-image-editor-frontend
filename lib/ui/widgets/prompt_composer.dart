import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'circle_icon_button.dart';

class PromptComposer extends StatefulWidget {
  final ValueChanged<String>? onPromptChanged;
  final Future<void> Function(Uint8List bytes, String filename)? onPickImage;
  final VoidCallback? onSend;
  final String initialPrompt;

  const PromptComposer({
    super.key,
    this.onPromptChanged,
    this.onPickImage,
    this.onSend,
    this.initialPrompt = '',
  });

  @override
  State<PromptComposer> createState() => _PromptComposerState();
}

class _PromptComposerState extends State<PromptComposer> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialPrompt);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
    final theme = Theme.of(context);
    final canSend = _controller.text.trim().isNotEmpty;
    return Material(
      elevation: 1,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          children: [
            CircleIconButton(
              icon: Icons.add,
              size: 36,
              backgroundColor: theme.colorScheme.secondaryContainer,
              iconColor: theme.colorScheme.onSecondaryContainer,
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
            CircleIconButton(
              icon: Icons.send,
              size: 36,
              tooltip: 'Generate',
              onPressed: canSend ? widget.onSend : null,
            ),
          ],
        ),
      ),
    );
  }
}
