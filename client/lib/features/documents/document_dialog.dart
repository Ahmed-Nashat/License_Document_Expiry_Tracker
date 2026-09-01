import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/glass.dart';
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
        ? Colors.black.withValues(alpha: 0.65)
        : const Color(0xFF0F172A).withValues(alpha: 0.35),
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (context, anim1, anim2) => Center(
      child: DocumentDialog(document: document),
    ),
    transitionBuilder: (context, anim1, anim2, child) => FadeTransition(
      opacity: anim1,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.94, end: 1.0).animate(
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
    if (picked != null) {
      setState(() => _expiryDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_expiryDate == null) {
      setState(() => _errorMessage = 'Please select an expiry date.');
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
        ? "${_expiryDate!.year}-${_expiryDate!.month.toString().padLeft(2, '0')}-${_expiryDate!.day.toString().padLeft(2, '0')}"
        : 'Select expiry date';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: AdvancedGlassPanel(
          radius: 26,
          blurLevel: GlassBlurLevel.strong,
          primaryColor: const Color(0xFF2563EB),
          showBorder: false,
          padding: const EdgeInsets.all(28),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        isEditing
                            ? Icons.edit_note_rounded
                            : Icons.add_circle_outline_rounded,
                        color: const Color(0xFF3B82F6),
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isEditing ? 'Edit document' : 'Track new item',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF3F1212)
                              : const Color(0xFFFFF1F0),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFFFECACA)
                                : const Color(0xFFBA1A1A),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  GlassDropdownField<DocumentType>(
                    initialValue: _selectedType,
                    labelText: 'Category',
                    prefixIcon: Icon(_selectedType.icon),
                    items: DocumentType.values
                        .map(
                          (t) => GlassDropdownItem(
                            value: t,
                            label: t.label,
                            icon: t.icon,
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedType = val);
                    },
                  ),
                  if (_selectedType == DocumentType.other) ...[
                    const SizedBox(height: 16),
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
                  const SizedBox(height: 16),
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Expiry date',
                        prefixIcon: Icon(Icons.calendar_today_rounded),
                        suffixIcon: Icon(Icons.arrow_drop_down_rounded),
                      ),
                      child: Text(
                        dateLabel,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  ),
                  if (_selectedType == DocumentType.subscription) ...[
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 16),
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
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: GlassDropdownField<BillingCycle>(
                            initialValue: _billingCycle,
                            labelText: 'Cycle',
                            items: BillingCycle.values
                                .map(
                                  (b) => GlassDropdownItem(
                                    value: b,
                                    label: b.label,
                                  ),
                                )
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _billingCycle = val),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      hintText: 'Any reminder details...',
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          foregroundColor: isDark
                              ? const Color(0xFFE2E8F0)
                              : const Color(0xFF1E293B),
                          side: BorderSide(
                            color: isDark
                                ? const Color(0x4094A3B8)
                                : const Color(0xFFCBD5E1),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Cancel',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: _isSaving ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                isEditing ? 'Save changes' : 'Add document',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 15),
                              ),
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
