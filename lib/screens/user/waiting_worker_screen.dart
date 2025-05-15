import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plugpro/providers/auth_provider.dart';
import 'package:plugpro/providers/booking_provider.dart';
import 'package:plugpro/providers/service_provider.dart';
import 'package:plugpro/models/booking_model.dart';
import 'package:plugpro/models/worker_model.dart';
import 'package:hive/hive.dart';
import 'dart:async';
import 'package:plugpro/screens/user/service_progress_screen.dart';
import 'package:plugpro/screens/user/user_home_screen.dart';

class WaitingWorkerScreen extends StatefulWidget {
  final String workerId;
  final String serviceId;

  const WaitingWorkerScreen({
    super.key,
    required this.workerId,
    required this.serviceId,
  });

  @override
  State<WaitingWorkerScreen> createState() => _WaitingWorkerScreenState();
}

class _WaitingWorkerScreenState extends State<WaitingWorkerScreen> {
  Worker? _worker;
  Booking? _booking;
  Timer? _timer;
  Timer? _timeoutTimer;
  int _remainingSeconds = 300; // 5 minutes timeout
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final workersBox = Hive.box<Worker>('workers');
    final worker = workersBox.get(widget.workerId);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);

    if (authProvider.currentUser != null) {
      final bookings = bookingProvider.getUserBookings(authProvider.currentUser!.id);
      
      // Find the most recent booking for this worker and service
      bookings.sort((a, b) => b.bookingTime.compareTo(a.bookingTime));
      
      final booking = bookings.firstWhere(
        (b) => b.workerId == widget.workerId && b.serviceId == widget.serviceId,
        orElse: () => throw Exception('Booking not found'),
      );

      setState(() {
        _worker = worker;
        _booking = booking;
        _isLoading = false;
      });

      // Start checking for booking status changes
      _startStatusCheck();
      
      // Start timeout timer
      _startTimeoutTimer();
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
          
          // If booking is accepted, navigate to progress screen
          if (updatedBooking.status == BookingStatus.accepted) {
            _timer?.cancel();
            _timeoutTimer?.cancel();
            
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => ServiceProgressScreen(bookingId: updatedBooking.id),
                ),
              );
            }
          }
          
          // If booking is rejected, show message and go back
          if (updatedBooking.status == BookingStatus.rejected) {
            _timer?.cancel();
            _timeoutTimer?.cancel();
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Your booking request was rejected by the worker'),
                  backgroundColor: Colors.red,
                ),
              );
              
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const UserHomeScreen()),
              );
            }
          }
        }
      }
    });
  }

  void _startTimeoutTimer() {
    // Update countdown every second
    _timeoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          // Time's up, auto-reject the booking
          _timeoutTimer?.cancel();
          _timer?.cancel();
          _autoRejectBooking();
        }
      });
    });
  }

  Future<void> _autoRejectBooking() async {
    if (_booking != null) {
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
      await bookingProvider.cancelBooking(_booking!.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Worker did not respond in time. Please try another worker.'),
            backgroundColor: Colors.red,
          ),
        );
        
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const UserHomeScreen()),
        );
      }
    }
  }

  Future<void> _cancelBooking() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_booking != null) {
        final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
        final success = await bookingProvider.cancelBooking(_booking!.id);
        
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking cancelled successfully'),
            ),
          );
          
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const UserHomeScreen()),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to cancel booking'),
              backgroundColor: Colors.red,
            ),
          );
        }
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

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Waiting for Worker'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_worker == null || _booking == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Waiting for Worker'),
        ),
        body: const Center(
          child: Text('Worker or booking not found'),
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
          title: const Text('Waiting for Worker'),
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 32),
                Text(
                  'Waiting for ${_worker!.name} to accept your request',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Service: ${service?.name ?? 'Unknown Service'}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Base Price: \$${_booking!.basePrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Request will expire in:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatTime(_remainingSeconds),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'You cannot leave this screen or book another service until the worker responds.',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _cancelBooking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Cancel Request',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
