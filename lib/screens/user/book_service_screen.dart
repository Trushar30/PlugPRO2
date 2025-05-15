import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plugpro/providers/auth_provider.dart';
import 'package:plugpro/providers/service_provider.dart';
import 'package:plugpro/providers/booking_provider.dart';
import 'package:plugpro/models/service_model.dart';
import 'package:plugpro/models/worker_model.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:plugpro/screens/user/waiting_worker_screen.dart';
import 'dart:io';

class BookServiceScreen extends StatefulWidget {
  final String serviceId;
  final String workerId;

  const BookServiceScreen({
    super.key,
    required this.serviceId,
    required this.workerId,
  });

  @override
  State<BookServiceScreen> createState() => _BookServiceScreenState();
}

class _BookServiceScreenState extends State<BookServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _problemController = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();
  
  Service? _service;
  Worker? _worker;
  List<File> _problemImages = [];
  String _paymentMethod = 'Cash on Delivery';
  bool _isLoading = true;
  bool _acceptTerms = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _problemController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);
    final service = serviceProvider.getServiceById(widget.serviceId);

    final workersBox = Hive.box<Worker>('workers');
    final worker = workersBox.get(widget.workerId);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser != null) {
      _locationController.text = authProvider.currentUser!.address;
      _phoneController.text = authProvider.currentUser!.phone;
    }

    setState(() {
      _service = service;
      _worker = worker;
      _isLoading = false;
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _problemImages.add(File(pickedFile.path));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _problemImages.removeAt(index);
    });
  }

  Future<void> _bookService() async {
    if (!_formKey.currentState!.validate() || !_acceptTerms) {
      if (!_acceptTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please accept the terms and conditions'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);

      if (authProvider.currentUser == null || _service == null || _worker == null) {
        throw Exception('Missing required data');
      }

      // Convert images to paths (in a real app, you would upload these to storage)
      final imagePaths = _problemImages.map((file) => file.path).toList();

      final success = await bookingProvider.createBooking(
        userId: authProvider.currentUser!.id,
        workerId: _worker!.id,
        serviceId: _service!.id,
        problemDescription: _problemController.text.trim(),
        problemImages: imagePaths,
        location: _locationController.text.trim(),
        alternatePhone: _phoneController.text.trim(),
        basePrice: _service!.basePrice,
        paymentMethod: _paymentMethod,
      );

      if (success && mounted) {
        // Navigate to waiting screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => WaitingWorkerScreen(
              workerId: _worker!.id,
              serviceId: _service!.id,
            ),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to book service'),
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
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Book Service'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_service == null || _worker == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Book Service'),
        ),
        body: const Center(
          child: Text('Service or worker not found'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Service'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Service and Worker Info
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _service!.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Category: ${_service!.category}',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Base Price: \$${_service!.basePrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const Divider(height: 24),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.blue.shade100,
                            child: Text(
                              _worker!.name.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Worker: ${_worker!.name}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _worker!.rating.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      ' (${_worker!.completedJobs} jobs)',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              const Text(
                'Describe Your Problem',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _problemController,
                decoration: const InputDecoration(
                  hintText: 'Describe your problem in detail...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please describe your problem';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add Problem Photos',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.add_photo_alternate),
                    label: const Text('Add Photo'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _problemImages.isEmpty
                  ? Container(
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'No photos added',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    )
                  : SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _problemImages.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: FileImage(_problemImages[index]),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 12,
                                child: GestureDetector(
                                  onTap: () => _removeImage(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
              
              const SizedBox(height: 24),
              const Text(
                'Your Location',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  hintText: 'Enter your address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your location';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              const Text(
                'Alternate Phone Number',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  hintText: 'Enter alternate phone number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a phone number';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              const Text(
                'Payment Method',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    RadioListTile<String>(
                      title: const Text('Cash on Delivery'),
                      value: 'Cash on Delivery',
                      groupValue: _paymentMethod,
                      onChanged: (value) {
                        setState(() {
                          _paymentMethod = value!;
                        });
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text('Online Payment'),
                      value: 'Online Payment',
                      groupValue: _paymentMethod,
                      onChanged: (value) {
                        setState(() {
                          _paymentMethod = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              Row(
                children: [
                  Checkbox(
                    value: _acceptTerms,
                    onChanged: (value) {
                      setState(() {
                        _acceptTerms = value!;
                      });
                    },
                  ),
                  Expanded(
                    child: Text(
                      'I understand that this is only a visiting charge. Additional charges for equipment and components will be added after service.',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _bookService,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Book Service',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
