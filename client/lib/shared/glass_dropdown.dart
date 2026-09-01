import 'package:flutter/material.dart';
import 'glass.dart';

class GlassDropdownItem<T> {
  const GlassDropdownItem({
    required this.value,
    required this.label,
    this.icon,
  });

  final T value;
  final String label;
  final IconData? icon;
}

class GlassDropdownField<T> extends FormField<T> {
  GlassDropdownField({
    super.key,
    super.initialValue,
    required List<GlassDropdownItem<T>> items,
    required ValueChanged<T?> onChanged,
    String? labelText,
    String? hintText,
    Widget? prefixIcon,
    super.validator,
  }) : super(
          builder: (FormFieldState<T> state) => _GlassDropdownTrigger<T>(
            state: state,
            items: items,
            onChanged: onChanged,
            labelText: labelText,
            hintText: hintText,
            prefixIcon: prefixIcon,
          ),
        );
}

class _GlassDropdownTrigger<T> extends StatefulWidget {
  const _GlassDropdownTrigger({
    required this.state,
    required this.items,
    required this.onChanged,
    this.labelText,
    this.hintText,
    this.prefixIcon,
  });

  final FormFieldState<T> state;
  final List<GlassDropdownItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? labelText;
  final String? hintText;
  final Widget? prefixIcon;

  @override
  State<_GlassDropdownTrigger<T>> createState() =>
      _GlassDropdownTriggerState<T>();
}

class _GlassDropdownTriggerState<T> extends State<_GlassDropdownTrigger<T>> {
  final _fieldKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry?.dispose();
    _overlayEntry = null;
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry?.dispose();
    _overlayEntry = null;
    if (mounted) setState(() => _isOpen = false);
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _removeOverlay();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    final renderBox =
        _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final overlay = Overlay.of(context);
    final fieldOffset = renderBox.localToGlobal(Offset.zero);
    final fieldSize = renderBox.size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _removeOverlay,
            ),
          ),
          Positioned(
            left: fieldOffset.dx,
            top: fieldOffset.dy + fieldSize.height + 6,
            width: fieldSize.width,
            child: Material(
              color: Colors.transparent,
              child: AdvancedGlassPanel(
                radius: 18,
                blurLevel: GlassBlurLevel.strong,
                primaryColor: const Color(0xFF3B82F6),
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: widget.items.length,
                    itemBuilder: (context, index) {
                      final item = widget.items[index];
                      final isSelected = widget.state.value == item.value;

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            widget.state.didChange(item.value);
                            widget.onChanged(item.value);
                            _removeOverlay();
                          },
                          hoverColor: isDark
                              ? const Color(0x333B82F6)
                              : const Color(0x1A2563EB),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (isDark
                                      ? const Color(0x283B82F6)
                                      : const Color(0x202563EB))
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                if (item.icon != null) ...[
                                  Icon(item.icon,
                                      size: 18,
                                      color: isSelected
                                          ? const Color(0xFF60A5FA)
                                          : (isDark
                                              ? const Color(0xFF94A3B8)
                                              : const Color(0xFF6B7280))),
                                  const SizedBox(width: 10),
                                ],
                                Expanded(
                                  child: Text(
                                    item.label,
                                    style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? (isDark
                                              ? const Color(0xFF93C5FD)
                                              : const Color(0xFF1D4ED8))
                                          : (isDark
                                              ? const Color(0xFFE2E8F0)
                                              : const Color(0xFF1E293B)),
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_rounded,
                                    size: 18,
                                    color: Color(0xFF3B82F6),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    overlay.insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedItem = widget.items
        .where((item) => item.value == widget.state.value)
        .firstOrNull;

    final hasError = widget.state.hasError;

    return Column(
      key: _fieldKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _toggleDropdown,
          child: InputDecorator(
            isEmpty: selectedItem == null,
            decoration: InputDecoration(
              labelText: widget.labelText,
              hintText: widget.hintText,
              prefixIcon: widget.prefixIcon,
              suffixIcon: AnimatedRotation(
                turns: _isOpen ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.keyboard_arrow_down_rounded),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: hasError
                      ? Colors.red
                      : (isDark
                          ? const Color(0x33FFFFFF)
                          : const Color(0xFFCBD5E1)),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: hasError ? Colors.red : const Color(0xFF2864DC),
                  width: 2,
                ),
              ),
            ),
            child: Text(
              selectedItem?.label ?? widget.hintText ?? '',
              style: TextStyle(
                color: selectedItem == null
                    ? (isDark
                        ? const Color(0xFF64748B)
                        : const Color(0xFF94A3B8))
                    : (isDark
                        ? const Color(0xFFF3F6FF)
                        : const Color(0xFF111827)),
                fontSize: 15,
              ),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(left: 14, top: 6),
            child: Text(
              widget.state.errorText!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
