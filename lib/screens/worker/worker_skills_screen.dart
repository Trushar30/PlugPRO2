import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plugpro/providers/auth_provider.dart';
import 'package:plugpro/providers/service_provider.dart';
import 'package:plugpro/models/service_model.dart';

class WorkerSkillsScreen extends StatefulWidget {
  const WorkerSkillsScreen({super.key});

  @override
  State<WorkerSkillsScreen> createState() => _WorkerSkillsScreenState();
}

class _WorkerSkillsScreenState extends State<WorkerSkillsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  List<String> _availableCategories = [];
  List<String> _selectedSkills = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);

    if (authProvider.currentWorker != null) {
      final worker = authProvider.currentWorker!;
      final categories = serviceProvider.getAllCategories();
      
      setState(() {
        _descriptionController.text = worker.description;
        _selectedSkills = List<String>.from(worker.skills);
        _availableCategories = categories;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateSkills() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      if (authProvider.currentWorker == null) {
        throw Exception('Worker not found');
      }
      
      final success = await authProvider.updateWorkerSkills(
        description: _descriptionController.text.trim(),
        skills: _selectedSkills,
      );
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Skills updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Update services with worker
        final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);
        final services = serviceProvider.getAllServices();
        
        for (final service in services) {
          final category = service.category;
          
          if (_selectedSkills.contains(category)) {
            await serviceProvider.addWorkerToService(
              serviceId: service.id,
              workerId: authProvider.currentWorker!.id,
            );
          } else {
            await serviceProvider.removeWorkerFromService(
              serviceId: service.id,
              workerId: authProvider.currentWorker!.id,
            );
          }
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update skills'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _toggleSkill(String skill) {
    setState(() {
      if (_selectedSkills.contains(skill)) {
        _selectedSkills.remove(skill);
      } else {
        _selectedSkills.add(skill);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Update Your Skills',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your skills and expertise to help customers find you for the right services.',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            
            // Professional Description
            const Text(
              'Professional Description',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                hintText: 'Describe your experience and expertise...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please provide a professional description';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 24),
            
            // Skills Selection
            const Text(
              'Select Your Skills',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose the categories you can provide services in:',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableCategories.map((category) {
                final isSelected = _selectedSkills.contains(category);
                return FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (_) => _toggleSkill(category),
                  backgroundColor: Colors.grey.shade200,
                  selectedColor: Colors.blue.shade100,
                  checkmarkColor: Colors.blue,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.blue.shade700 : Colors.black,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 24),
            
            // Additional Skills
            const Text(
              'Additional Skills',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add any specific skills or certifications you have:',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                hintText: 'e.g., Certified Plumber, HVAC Technician, etc.',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.add),
              ),
              onFieldSubmitted: (value) {
                if (value.isNotEmpty && !_selectedSkills.contains(value)) {
                  setState(() {
                    _selectedSkills.add(value);
                  });
                }
              },
            ),
            
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedSkills
                  .where((skill) => !_availableCategories.contains(skill))
                  .map((skill) {
                return Chip(
                  label: Text(skill),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () {
                    setState(() {
                      _selectedSkills.remove(skill);
                    });
                  },
                  backgroundColor: Colors.blue.shade100,
                  labelStyle: TextStyle(
                    color: Colors.blue.shade700,
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 32),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _updateSkills,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Update Skills',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
