import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plugpro/providers/booking_provider.dart';
import 'package:plugpro/providers/service_provider.dart';
import 'package:plugpro/models/booking_model.dart';
import 'package:plugpro/models/worker_model.dart';
import 'package:hive/hive.dart';
import 'dart:async';
import 'package:plugpro/screens/user/rate_service_screen.dart';

class ServiceProgressScreen extends StatefulWidget {
  final String bookingId;

  const ServiceProgressScreen({
    super.key,
    required this.bookingId,
  });

  @override
  State<ServiceProgressScreen> createState() => _ServiceProgressScreenState();
}

class _ServiceProgressScreenState extends State<ServiceProgressScreen> {
  Booking? _booking;
  Worker? _worker;
  Timer? _timer;
  bool _isLoading = true;
  double _progress = 0.0;
  String _statusText = 'Worker is on the way';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    final booking = bookingProvider.getBookingById(widget.bookingId);

    if (booking != null) {
      final workersBox = Hive.box<Worker>('workers');
      final worker = workersBox.get(booking.workerId);

      setState(() {
        _booking = booking;
        _worker = worker;
        _isLoading = false;
      });

      // Start checking for booking status changes
      _startStatusCheck();
      
      // Simulate progress
      _simulateProgress();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startStatusCheck() {
    // Check every 5 seconds
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (_booking != null) {
        final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
        final updatedBooking = bookingProvider.getBookingById(_booking!.id);
        
        if (updatedBooking != null) {
          setState(() {
            _booking = updatedBooking;
          });
          
          // If booking is completed, navigate to rating screen
          if (updatedBooking.status == BookingStatus.completed) {
            _timer?.cancel();
            
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => RateServiceScreen(bookingId: updatedBooking.id),
                ),
              );
            }
          }
        }
      }
    });
  }

  void _simulateProgress() {
    // Simulate worker progress
    Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_progress < 1.0) {
        setState(() {
          _progress += 0.1;
          if (_progress >= 1.0) {
            _progress = 1.0;
            _statusText = 'Worker has arrived';
            timer.cancel();
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _payAdditionalCharges() async {
    if (_booking == null || _booking!.additionalPrice <= 0) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
      final success = await bookingProvider.markPaymentComplete(_booking!.id);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment successful'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Refresh booking data
        final updatedBooking = bookingProvider.getBookingById(_booking!.id);
        if (updatedBooking != null) {
          setState(() {
            _booking = updatedBooking;
          });
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment failed'),
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
          title: const Text('Service Progress'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_booking == null || _worker == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Service Progress'),
        ),
        body: const Center(
          child: Text('Booking or worker not found'),
        ),
      );
    }

    final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);
    final service = serviceProvider.getServiceById(_booking!.serviceId);

    return WillPopScope(
      onWillPop: () async {
        // Prevent back button
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Service Progress'),
          automaticallyImplyLeading: false,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Service Info Card
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
                        service?.name ?? 'Unknown Service',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Category: ${service?.category ?? 'Unknown'}',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Base Price: \$${_booking!.basePrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      if (_booking!.additionalPrice > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Additional Charges: \$${_booking!.additionalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Total: \$${_booking!.totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
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
                                const SizedBox(height: 4),
                                Text(
                                  'Phone: ${_worker!.phone}',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              // Call worker
                            },
                            icon: const Icon(Icons.call),
                            color: Colors.green,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Progress Section
              if (_booking!.status == BookingStatus.accepted || _booking!.status == BookingStatus.inProgress) ...[
                const Text(
                  'Service Progress',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _statusText,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: _progress,
                        backgroundColor: Colors.blue.shade100,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Estimated arrival time: ${_progress < 1.0 ? '${(20 * (1 - _progress)).toInt()} minutes' : 'Arrived'}',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Status Updates
              const Text(
                'Status Updates',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildStatusTimeline(),
              
              const SizedBox(height: 24),
              
              // Payment Section (if service is completed and has additional charges)
              if (_booking!.status == BookingStatus.completed && 
                  _booking!.additionalPrice > 0 && 
                  !_booking!.isPaid && 
                  _booking!.paymentMethod == 'Online Payment') ...[
                const Text(
                  'Payment',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Additional Charges',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Base Price: \$${_booking!.basePrice.toStringAsFixed(2)}',
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Additional Charges: \$${_booking!.additionalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total: \$${_booking!.totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _payAdditionalCharges,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Pay Now'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusTimeline() {
    return Column(
      children: [
        _buildStatusItem(
          'Booking Requested',
          _formatDateTime(_booking!.bookingTime),
          true,
          isFirst: true,
        ),
        _buildStatusItem(
          'Booking Accepted',
          _booking!.serviceTime != null ? _formatDateTime(_booking!.serviceTime!) : 'Pending',
          _booking!.status != BookingStatus.pending,
        ),
        _buildStatusItem(
          'Service Started',
          _booking!.status == BookingStatus.inProgress || _booking!.status == BookingStatus.completed
              ? 'In Progress'
              : 'Pending',
          _booking!.status == BookingStatus.inProgress || _booking!.status == BookingStatus.completed,
        ),
        _buildStatusItem(
          'Service Completed',
          _booking!.completionTime != null ? _formatDateTime(_booking!.completionTime!) : 'Pending',
          _booking!.status == BookingStatus.completed,
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildStatusItem(String title, String time, bool isCompleted, {bool isFirst = false, bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? Colors.green : Colors.grey.shade300,
                border: Border.all(
                  color: isCompleted ? Colors.green : Colors.grey.shade300,
                  width: 3,
                ),
              ),
              child: isCompleted
                  ? const Icon(
                      Icons.check,
                      size: 12,
                      color: Colors.white,
                    )
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isCompleted ? Colors.green : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isCompleted ? Colors.black : Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: TextStyle(
                  fontSize: 12,
                  color: isCompleted ? Colors.grey.shade700 : Colors.grey,
                ),
              ),
              SizedBox(height: isLast ? 0 : 24),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
