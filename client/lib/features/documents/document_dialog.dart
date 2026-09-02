import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/design_tokens.dart';
import '../../shared/glass_dropdown.dart';
import 'document_models.dart';
import 'documents_controller.dart';

Future<void> showDocumentDialog(
  BuildContext context, {
  TrackedDocument? document,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: isDark
        ? Colors.black.withValues(alpha: 0.60)
        : Colors.black.withValues(alpha: 0.30),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, anim1, anim2) =>
        Center(child: DocumentDialog(document: document)),
    transitionBuilder: (context, anim1, anim2, child) => FadeTransition(
      opacity: anim1,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.96, end: 1.0).animate(
          CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
        ),
        child: child,
      ),
    ),
  );
}

class DocumentDialog extends ConsumerStatefulWidget {
  const DocumentDialog({super.key, this.document});

  final TrackedDocument? document;

  @override
  ConsumerState<DocumentDialog> createState() => _DocumentDialogState();
}

class _DocumentDialogState extends ConsumerState<DocumentDialog> {
  final _formKey = GlobalKey<FormState>();
  late DocumentType _selectedType;
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  late final TextEditingController _providerController;
  late final TextEditingController _amountController;
  BillingCycle? _billingCycle;
  DateTime? _expiryDate;
  bool _isSaving = false;
  String? _errorMessage;
  Set<int> _reminderDays = {90, 30, 7, 1, 0};

  @override
  void initState() {
    super.initState();
    final doc = widget.document;
    _selectedType = doc?.type ?? DocumentType.nationalId;
    _titleController = TextEditingController(text: doc?.title ?? '');
    _notesController = TextEditingController(text: doc?.notes ?? '');
    _providerController = TextEditingController(text: doc?.providerName ?? '');
    _amountController = TextEditingController(
      text: doc?.renewalAmount != null ? doc!.renewalAmount.toString() : '',
    );
    _billingCycle = doc?.billingCycle ?? BillingCycle.monthly;
    _expiryDate =
        doc?.expiryDate ?? DateTime.now().add(const Duration(days: 365));

    if (doc != null) {
      _reminderDays = doc.reminderRules
          .where((r) => r.enabled)
          .map((r) => r.daysBeforeExpiry)
          .toSet();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _providerController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? now.add(const Duration(days: 365)),
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 50),
    );
    if (picked != null) setState(() => _expiryDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_expiryDate == null) {
      setState(() => _errorMessage = 'Select an expiry date.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final double? amount = double.tryParse(_amountController.text.trim());
      String title;
      if (_selectedType == DocumentType.other) {
        title = _titleController.text.trim();
      } else if (_selectedType == DocumentType.subscription) {
        final provider = _providerController.text.trim();
        title = provider.isNotEmpty ? provider : _selectedType.label;
      } else {
        title = _selectedType.label;
      }

      if (widget.document == null) {
        await ref.read(documentsControllerProvider.notifier).addDocument(
              type: _selectedType,
              title: title,
              expiryDate: _expiryDate!,
              notes: _notesController.text.trim(),
              providerName: _selectedType == DocumentType.subscription
                  ? _providerController.text.trim()
                  : null,
              renewalAmount:
                  _selectedType == DocumentType.subscription ? amount : null,
              billingCycle: _selectedType == DocumentType.subscription
                  ? _billingCycle
                  : null,
              reminderDays: _reminderDays.toList(),
            );
      } else {
        await ref.read(documentsControllerProvider.notifier).editDocument(
              widget.document!.id,
              type: _selectedType,
              title: title,
              expiryDate: _expiryDate!,
              notes: _notesController.text.trim(),
              providerName: _selectedType == DocumentType.subscription
                  ? _providerController.text.trim()
                  : null,
              renewalAmount:
                  _selectedType == DocumentType.subscription ? amount : null,
              billingCycle: _selectedType == DocumentType.subscription
                  ? _billingCycle
                  : null,
              reminderDays: _reminderDays.toList(),
            );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(
            () => _errorMessage = 'Failed to save document. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.document != null;

    final dateLabel = _expiryDate != null
        ? '${_expiryDate!.year}-${_expiryDate!.month.toString().padLeft(2, '0')}-${_expiryDate!.day.toString().padLeft(2, '0')}'
        : 'Select expiry date';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(
                        isEditing
                            ? Icons.edit_note_rounded
                            : Icons.add_circle_outline_rounded,
                        color: isDark ? AppColors.gray : AppColors.charcoal,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isEditing ? 'Edit item' : 'Track new item',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.4,
                          color: isDark ? AppColors.inkDark : AppColors.ink,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close_rounded,
                            color: isDark
                                ? AppColors.charcoal
                                : AppColors.charcoal,
                            size: 20),
                        tooltip: 'Close',
                        style: IconButton.styleFrom(
                          side: BorderSide.none,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Error box
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _ErrorBox(message: _errorMessage!),
                    ),

                  // Category
                  GlassDropdownField<DocumentType>(
                    initialValue: _selectedType,
                    labelText: 'Category',
                    prefixIcon: Icon(_selectedType.icon),
                    items: DocumentType.values
                        .map((t) => GlassDropdownItem(
                              value: t,
                              label: t.label,
                              icon: t.icon,
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedType = val);
                    },
                  ),

                  // Title — only for "Other"
                  if (_selectedType == DocumentType.other) ...[
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title / Document label',
                        hintText: 'e.g. Gym Membership, Insurance Policy',
                        prefixIcon: Icon(Icons.title_rounded),
                      ),
                      validator: (v) => _selectedType == DocumentType.other &&
                              (v == null || v.trim().isEmpty)
                          ? 'Enter a title.'
                          : null,
                    ),
                  ],
                  const SizedBox(height: 14),

                  // Expiry date picker
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Expiry date',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                        suffixIcon: Icon(Icons.arrow_drop_down_rounded),
                      ),
                      child: Text(
                        dateLabel,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? AppColors.inkDark : AppColors.ink,
                        ),
                      ),
                    ),
                  ),

                  // Subscription fields
                  if (_selectedType == DocumentType.subscription) ...[
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _providerController,
                      decoration: const InputDecoration(
                        labelText: 'Provider name',
                        hintText: 'e.g. Netflix, Spotify, AWS',
                        prefixIcon: Icon(Icons.business_outlined),
                      ),
                      validator: (v) =>
                          _selectedType == DocumentType.subscription &&
                                  (v == null || v.trim().isEmpty)
                              ? 'Enter a provider name.'
                              : null,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Renewal amount',
                              hintText: 'e.g. 14.99',
                              prefixIcon: Icon(Icons.receipt_long_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: GlassDropdownField<BillingCycle>(
                            initialValue: _billingCycle,
                            labelText: 'Cycle',
                            items: BillingCycle.values
                                .map((b) =>
                                    GlassDropdownItem(value: b, label: b.label))
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _billingCycle = val),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),

                  // Notes
                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      hintText: 'Any reminder details…',
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Reminders
                  Text(
                    'Email Reminders',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.gray : AppColors.charcoal,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [90, 30, 7, 1, 0].map((days) {
                      final isSelected = _reminderDays.contains(days);
                      final label = days == 0 ? 'On Due Date' : '$days Days';
                      return FilterChip(
                        label: Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? AppColors.inkDark : AppColors.ink),
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _reminderDays.add(days);
                            } else {
                              _reminderDays.remove(days);
                            }
                          });
                        },
                        backgroundColor:
                            isDark ? AppColors.surfaceDark : AppColors.fog,
                        selectedColor: AppColors.charcoal,
                        checkmarkColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isSelected
                                ? Colors.transparent
                                : (isDark
                                    ? AppColors.borderDark
                                    : AppColors.border),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        onPressed: _isSaving ? null : _save,
                        child: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(isEditing ? 'Save changes' : 'Add item'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Error box ────────────────────────────────────────────────────────────────

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFCEBEB),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded,
                color: Color(0xFF791F1F), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Color(0xFF791F1F),
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      );
}
