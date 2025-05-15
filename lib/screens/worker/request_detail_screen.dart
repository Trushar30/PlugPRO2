import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plugpro/providers/booking_provider.dart';
import 'package:plugpro/providers/service_provider.dart';
import 'package:plugpro/models/booking_model.dart';
import 'package:plugpro/models/user_model.dart';
import 'package:hive/hive.dart';
import 'dart:io';

class RequestDetailScreen extends StatefulWidget {
  final String bookingId;

  const RequestDetailScreen({
    super.key,
    required this.bookingId,
  });

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  final _additionalPriceController = TextEditingController();
  Booking? _booking;
  User? _user;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _additionalPriceController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    final booking = bookingProvider.getBookingById(widget.bookingId);

    if (booking != null) {
      final usersBox = Hive.box<User>('users');
      final user = usersBox.get(booking.userId);

      setState(() {
        _booking = booking;
        _user = user;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _acceptBooking() async {
    if (_booking == null || _booking!.status != BookingStatus.pending) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
      final success = await bookingProvider.acceptBooking(_booking!.id);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking accepted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        _loadData();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to accept booking'),
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

  Future<void> _rejectBooking() async {
    if (_booking == null || _booking!.status != BookingStatus.pending) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
      final success = await bookingProvider.rejectBooking(_booking!.id);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking rejected'),
          ),
        );
        
        Navigator.of(context).pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to reject booking'),
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

  Future<void> _startService() async {
    if (_booking == null || _booking!.status != BookingStatus.accepted) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
      final success = await bookingProvider.startService(_booking!.id);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Service started'),
            backgroundColor: Colors.green,
          ),
        );
        
        _loadData();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to start service'),
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

  Future<void> _completeService() async {
    if (_booking == null || _booking!.status != BookingStatus.inProgress) {
      return;
    }

    // Show dialog to enter additional price
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Service'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter any additional charges:'),
            const SizedBox(height: 16),
            TextField(
              controller: _additionalPriceController,
              decoration: const InputDecoration(
                labelText: 'Additional Price',
                prefixText: '\$',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _submitCompletion();
            },
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitCompletion() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
      
      double additionalPrice = 0.0;
      if (_additionalPriceController.text.isNotEmpty) {
        additionalPrice = double.tryParse(_additionalPriceController.text) ?? 0.0;
      }
      
      final success = await bookingProvider.completeService(
        bookingId: _booking!.id,
        additionalPrice: additionalPrice,
      );
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Service completed successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        _loadData();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to complete service'),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Request Details'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_booking == null || _user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Request Details'),
        ),
        body: const Center(
          child: Text('Booking or user not found'),
        ),
      );
    }

    final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);
    final service = serviceProvider.getServiceById(_booking!.serviceId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Request Status',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        _buildStatusBadge(_booking!.status),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Requested on: ${_formatDateTime(_booking!.bookingTime)}',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    if (_booking!.serviceTime != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Service started: ${_formatDateTime(_booking!.serviceTime!)}',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (_booking!.completionTime != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Completed on: ${_formatDateTime(_booking!.completionTime!)}',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Service Details Card
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
                    const Text(
                      'Service Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            service?.imageUrl ?? 'assets/images/placeholder.png',
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey.shade300,
                                child: const Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                service?.name ?? 'Unknown Service',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Category: ${service?.category ?? 'Unknown'}',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Base Price: \$${_booking!.basePrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.blue,
                                ),
                              ),
                              if (_booking!.additionalPrice > 0) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Additional: \$${_booking!.additionalPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                'Total: \$${_booking!.totalPrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
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
            
            const SizedBox(height: 16),
            
            // Customer Details Card
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
                    const Text(
                      'Customer Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.blue.shade100,
                          child: Text(
                            _user!.name.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _user!.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Phone: ${_booking!.alternatePhone}',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            // Call customer
                          },
                          icon: const Icon(Icons.call),
                          color: Colors.green,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Service Location: ${_booking!.location}',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.payment,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Payment Method: ${_booking!.paymentMethod}',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _booking!.isPaid ? Icons.check_circle : Icons.pending,
                          size: 16,
                          color: _booking!.isPaid ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Payment Status: ${_booking!.isPaid ? 'Paid' : 'Pending'}',
                          style: TextStyle(
                            color: _booking!.isPaid ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Problem Details Card
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
                    const Text(
                      'Problem Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _booking!.problemDescription,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                      ),
                    ),
                    if (_booking!.problemImages.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Problem Images:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _booking!.problemImages.length,
                          itemBuilder: (context, index) {
                            return Container(
                              width: 100,
                              height: 100,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: FileImage(
                                    // In a real app, you would use a network image or file from storage
                                    // This is just a placeholder for the demo
                                    File(_booking!.problemImages[index]),
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Action Buttons
            if (_booking!.status == BookingStatus.pending)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _rejectBooking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Reject',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _acceptBooking,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Accept',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                ],
              )
            else if (_booking!.status == BookingStatus.accepted)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _startService,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Start Service',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              )
            else if (_booking!.status == BookingStatus.inProgress)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _completeService,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Complete Service',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BookingStatus status) {
    Color color;
    String text;

    switch (status) {
      case BookingStatus.pending:
        color = Colors.orange;
        text = 'Pending';
        break;
      case BookingStatus.accepted:
        color = Colors.blue;
        text = 'Accepted';
        break;
      case BookingStatus.inProgress:
        color = Colors.purple;
        text = 'In Progress';
        break;
      case BookingStatus.completed:
        color = Colors.green;
        text = 'Completed';
        break;
      case BookingStatus.rejected:
        color = Colors.red;
        text = 'Rejected';
        break;
      case BookingStatus.cancelled:
        color = Colors.grey;
        text = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
