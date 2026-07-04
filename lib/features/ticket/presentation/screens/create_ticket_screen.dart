import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:arvi_b3_uts/features/ticket/presentation/providers/ticket_provider.dart';
import 'package:arvi_b3_uts/features/ticket/domain/ticket_model.dart';
import 'package:arvi_b3_uts/features/auth/presentation/providers/auth_provider.dart';
import 'package:uuid/uuid.dart';

class CreateTicketScreen extends ConsumerStatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  ConsumerState<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends ConsumerState<CreateTicketScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  File? _selectedFile;
  String? _fileName;
  bool _isPdf = false;
  bool _isUploading = false;

  // =========================================================================
  // FILE PICKER — Kamera, Galeri, atau PDF
  // =========================================================================

  Future<void> _pickFile() async {
    final colorScheme = Theme.of(context).colorScheme;

    // Dialog pilihan sumber file — sekarang dengan 3 opsi
    final source = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Pilih Sumber File',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _SourceOption(
                  icon: LucideIcons.camera,
                  iconColor: colorScheme.primary,
                  title: 'Kamera',
                  subtitle: 'Ambil foto langsung',
                  onTap: () => Navigator.pop(context, 'camera'),
                ),
                const SizedBox(height: 8),
                _SourceOption(
                  icon: LucideIcons.image,
                  iconColor: colorScheme.tertiary,
                  title: 'Galeri',
                  subtitle: 'Pilih dari foto yang ada',
                  onTap: () => Navigator.pop(context, 'gallery'),
                ),
                const SizedBox(height: 8),
                _SourceOption(
                  icon: LucideIcons.fileText,
                  iconColor: colorScheme.error,
                  title: 'Dokumen (PDF)',
                  subtitle: 'Pilih file PDF dari penyimpanan',
                  onTap: () => Navigator.pop(context, 'pdf'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (source == null) return;

    try {
      if (source == 'pdf') {
        // === PDF Picker ===
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );

        if (result != null && result.files.single.path != null) {
          final file = File(result.files.single.path!);
          final bytes = await file.length();
          final mb = bytes / (1024 * 1024);

          if (mb > 5) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('File exceeds 5MB limit!'),
                  backgroundColor: colorScheme.error,
                ),
              );
            }
            return;
          }

          setState(() {
            _selectedFile = file;
            _fileName = result.files.single.name;
            _isPdf = true;
          });
        }
      } else {
        // === Image Picker (kamera/galeri) ===
        final ImagePicker picker = ImagePicker();
        final imageSource = source == 'camera' ? ImageSource.camera : ImageSource.gallery;
        final XFile? image = await picker.pickImage(source: imageSource);

        if (image != null) {
          final bytes = await image.length();
          final mb = bytes / (1024 * 1024);

          if (mb > 5) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('File exceeds 5MB limit!'),
                  backgroundColor: colorScheme.error,
                ),
              );
            }
            return;
          }

          setState(() {
            _selectedFile = File(image.path);
            _fileName = image.name;
            _isPdf = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengakses file: $e')),
        );
      }
    }
  }

  // =========================================================================
  // SUBMIT TICKET
  // =========================================================================

  Future<void> _submitTicket() async {
    if (_titleController.text.isEmpty || _descController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() => _isUploading = true);

    final user = ref.read(authProvider).value;
    
    final newTicket = TicketModel(
      id: const Uuid().v4(),
      title: _titleController.text,
      description: _descController.text,
      status: TicketStatus.open,
      createdAt: DateTime.now(),
      createdBy: user?.id ?? '', 
      attachedFilePath: _fileName,
      timeline: [
        TicketTimeline(
          id: const Uuid().v4(),
          description: 'Ticket generated',
          timestamp: DateTime.now(),
          actorRole: user?.role.toString() ?? 'User',
        )
      ]
    );

    try {
      await ref.read(ticketListProvider.notifier).createTicket(newTicket, _selectedFile);
      if (mounted) {
        setState(() => _isUploading = false);
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Ticket created successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Failed to create ticket: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // =========================================================================
  // BUILD
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Ticket', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Describe your issue',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: colorScheme.outlineVariant.withOpacity(0.5),
                    width: 0.5,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Ticket Details',
                        style: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          hintText: 'Ticket Title',
                          filled: true,
                          fillColor: colorScheme.surfaceContainerLow,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colorScheme.outlineVariant),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colorScheme.primary, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _descController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Detailed Description',
                          filled: true,
                          fillColor: colorScheme.surfaceContainerLow,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colorScheme.outlineVariant),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colorScheme.primary, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Attachment',
                        style: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant, fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _pickFile,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: colorScheme.primary.withOpacity(0.3),
                              style: BorderStyle.solid,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                _selectedFile != null
                                    ? (_isPdf ? LucideIcons.fileText : LucideIcons.image)
                                    : LucideIcons.upload,
                                size: 40,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _fileName != null ? 'Change Attachment' : 'Upload File',
                                style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'JPG, PNG or PDF (Max 5MB)',
                                style: TextStyle(color: colorScheme.outline, fontSize: 12),
                              ),
                              // Preview area
                              if (_selectedFile != null) ...[
                                const SizedBox(height: 20),
                                if (_isPdf)
                                  // PDF: ikon + nama file
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: colorScheme.errorContainer.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(LucideIcons.fileText, size: 28, color: colorScheme.error),
                                        const SizedBox(width: 12),
                                        Flexible(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _fileName ?? 'document.pdf',
                                                style: TextStyle(
                                                  color: colorScheme.onSurface,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'PDF Document',
                                                style: TextStyle(color: colorScheme.outline, fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  // Image: preview gambar
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(_selectedFile!, height: 160, width: double.infinity, fit: BoxFit.cover),
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _submitTicket,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isUploading 
                    ? SizedBox(
                        height: 24, 
                        width: 24, 
                        child: CircularProgressIndicator(color: colorScheme.onPrimary, strokeWidth: 2.5)
                      )
                    : const Text('Submit Ticket', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// SOURCE OPTION TILE — Untuk BottomSheet pilih sumber file
// =============================================================================

class _SourceOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SourceOption({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outlineVariant.withOpacity(0.4),
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 22, color: iconColor),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  Text(subtitle, style: TextStyle(color: colorScheme.outline, fontSize: 12)),
                ],
              ),
              const Spacer(),
              Icon(LucideIcons.chevronRight, size: 20, color: colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}
