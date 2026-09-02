import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'design_tokens.dart';
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
            top: fieldOffset.dy + fieldSize.height + 4,
            width: fieldSize.width,
            child: Material(
              color: Colors.transparent,
              child: AdvancedGlassPanel(
                radius: 10,
                blurLevel: GlassBlurLevel.strong,
                padding: const EdgeInsets.symmetric(vertical: 4),
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
                            horizontal: 4, vertical: 2),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            widget.state.didChange(item.value);
                            widget.onChanged(item.value);
                            _removeOverlay();
                          },
                          hoverColor: isDark
                              ? const Color(0x1AFFFFFF)
                              : const Color(0x12111111),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (isDark
                                      ? AppColors.selectedDark
                                      : AppColors.fog)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                if (item.icon != null) ...[
                                  Icon(
                                    item.icon,
                                    size: 17,
                                    color: isSelected
                                        ? (isDark
                                            ? AppColors.inkDark
                                            : AppColors.ink)
                                        : AppColors.gray,
                                  ),
                                  const SizedBox(width: 10),
                                ],
                                Expanded(
                                  child: Text(
                                    item.label,
                                    style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: isDark
                                          ? AppColors.inkDark
                                          : AppColors.ink,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check_rounded,
                                    size: 16,
                                    color: isDark
                                        ? AppColors.inkDark
                                        : AppColors.ink,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ).animate().fadeIn(duration: 150.ms).slideY(begin: -0.05, end: 0, duration: 150.ms, curve: Curves.easeOutCubic),
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
    final activeBorderColor =
        hasError ? const Color(0xFF791F1F) : AppColors.ink;
    final activeBorderColorDark =
        hasError ? const Color(0xFFFCA5A5) : AppColors.inkDark;

    return Column(
      key: _fieldKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: _toggleDropdown,
          child: InputDecorator(
            isEmpty: selectedItem == null,
            decoration: InputDecoration(
              labelText: widget.labelText,
              hintText: widget.hintText,
              prefixIcon: widget.prefixIcon != null
                  ? IconTheme(
                      data: IconThemeData(color: AppColors.gray, size: 20),
                      child: widget.prefixIcon!,
                    )
                  : null,
              suffixIcon: AnimatedRotation(
                turns: _isOpen ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 180),
                child: Icon(Icons.keyboard_arrow_down_rounded,
                    color: AppColors.gray, size: 20),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: hasError
                      ? const Color(0xFF791F1F)
                      : (isDark ? AppColors.borderDark : AppColors.border),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isDark ? activeBorderColorDark : activeBorderColor,
                  width: 1.5,
                ),
              ),
            ),
            child: Text(
              selectedItem?.label ?? widget.hintText ?? '',
              style: TextStyle(
                color: selectedItem == null
                    ? AppColors.gray
                    : (isDark ? AppColors.inkDark : AppColors.ink),
                fontSize: 14,
                fontWeight:
                    selectedItem != null ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(left: 14, top: 5),
            child: Text(
              widget.state.errorText!,
              style: const TextStyle(color: Color(0xFF791F1F), fontSize: 12),
            ),
          ),
      ],
    );
  }
}
