import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:maauts003/features/ticket/presentation/providers/ticket_provider.dart';
import 'package:maauts003/features/ticket/domain/ticket_model.dart';
import 'package:maauts003/core/theme/glassmorphism.dart';
import 'package:maauts003/features/auth/presentation/providers/auth_provider.dart';

class CreateTicketScreen extends ConsumerStatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  ConsumerState<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends ConsumerState<CreateTicketScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String? _fileName;
  bool _isUploading = false;

  Future<void> _pickFile() async {
    final ImagePicker picker = ImagePicker();
    // In actual app we can use file_picker for any file. Here we use image_picker to simulate
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      final bytes = await image.length();
      final mb = bytes / (1024 * 1024);
      
      if (mb > 5) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File exceeds 5MB limit!', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red),
          );
        }
        return;
      }
      
      setState(() {
        _fileName = image.name;
      });
    }
  }

  Future<void> _submitTicket() async {
    if (_titleController.text.isEmpty || _descController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() => _isUploading = true);

    final user = ref.read(authProvider).value;
    
    final newTicket = TicketModel(
      id: 'TCK-\${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      title: _titleController.text,
      description: _descController.text,
      status: TicketStatus.open,
      createdAt: DateTime.now(),
      createdBy: user?.name ?? 'User',
      attachedFilePath: _fileName,
      timeline: [
        TicketTimeline(
          id: 'tml_created',
          description: 'Ticket generated',
          timestamp: DateTime.now(),
          actorRole: 'User',
        )
      ]
    );

    await ref.read(ticketListProvider.notifier).addTicketLocally(newTicket);

    if (mounted) {
      setState(() => _isUploading = false);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Ticket'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
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
              GlassmorphismCard(
                child: Column(
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        hintText: 'Ticket Title',
                        prefixIcon: Icon(LucideIcons.edit2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _descController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Detailed Description',
                        prefixIcon: Icon(LucideIcons.alignLeft),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _pickFile,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.2), style: BorderStyle.solid),
                        ),
                        child: Column(
                          children: [
                            Icon(LucideIcons.uploadCloud, size: 40, color: Theme.of(context).primaryColor),
                            const SizedBox(height: 8),
                            Text(
                              _fileName != null ? 'File selected: \$_fileName' : 'Upload Screenshot (Max 5MB)',
                              style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isUploading ? null : _submitTicket,
                child: _isUploading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Submit Ticket', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
