import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/entities.dart';
import 'quote.dart';

/// To/Cc/Bcc input: address chips plus a text field with autocomplete.
class RecipientField extends StatefulWidget {
  const RecipientField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.suggestions,
    this.autofocus = false,
  });
  final String label;
  final List<MailAddress> value;
  final ValueChanged<List<MailAddress>> onChanged;
  final List<MailAddress> suggestions;
  final bool autofocus;

  @override
  State<RecipientField> createState() => _RecipientFieldState();
}

class _RecipientFieldState extends State<RecipientField> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) _commit(_controller.text);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _commit(String raw) {
    if (raw.trim().isEmpty) return;
    final parts = raw.split(RegExp(r'[,;]'));
    final added = <MailAddress>[];
    for (final p in parts) {
      final a = Quote.parseAddress(p);
      if (a != null && !widget.value.any((v) => v.email.toLowerCase() == a.email.toLowerCase())) added.add(a);
    }
    if (added.isNotEmpty) widget.onChanged([...widget.value, ...added]);
    _controller.clear();
  }

  void _add(MailAddress a) {
    if (!widget.value.any((v) => v.email.toLowerCase() == a.email.toLowerCase())) {
      widget.onChanged([...widget.value, a]);
    }
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 44,
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(widget.label, style: TextStyle(color: cs.onSurfaceVariant)),
          ),
        ),
        Expanded(
          child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 6, runSpacing: 4, children: [
            for (final a in widget.value)
              InputChip(
                label: Text(a.name?.isNotEmpty == true ? '${a.name} <${a.email}>' : a.email),
                tooltip: a.email,
                onDeleted: () => widget.onChanged(widget.value.where((v) => v != a).toList()),
              ),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 180),
              child: RawAutocomplete<MailAddress>(
                textEditingController: _controller,
                focusNode: _focus,
                displayStringForOption: (a) => a.toString(),
                optionsBuilder: (t) {
                  final q = t.text.trim().toLowerCase();
                  if (q.isEmpty) return const Iterable<MailAddress>.empty();
                  return widget.suggestions
                      .where((a) => !widget.value.contains(a))
                      .where((a) => a.email.toLowerCase().contains(q) || (a.name?.toLowerCase().contains(q) ?? false))
                      .take(8);
                },
                onSelected: _add,
                fieldViewBuilder: (context, controller, focus, onSubmit) => KeyboardListener(
                  focusNode: FocusNode(skipTraversal: true),
                  onKeyEvent: (e) {
                    if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.backspace && controller.text.isEmpty && widget.value.isNotEmpty) {
                      widget.onChanged(widget.value.sublist(0, widget.value.length - 1));
                    }
                  },
                  child: TextField(
                    controller: controller,
                    focusNode: focus,
                    autofocus: widget.autofocus,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(border: InputBorder.none, isDense: true, hintText: 'name@example.com'),
                    onChanged: (v) {
                      if (v.endsWith(',') || v.endsWith(';') || (v.endsWith(' ') && Quote.isEmail(v.trim()))) _commit(v);
                    },
                    onSubmitted: (v) {
                      _commit(v);
                      onSubmit();
                    },
                  ),
                ),
                optionsViewBuilder: (context, onSelected, options) => Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(8),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 240, maxWidth: 420),
                      child: ListView(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        children: [
                          for (final a in options)
                            ListTile(
                              dense: true,
                              title: Text(a.name ?? a.email),
                              subtitle: a.name == null ? null : Text(a.email),
                              onTap: () => onSelected(a),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
