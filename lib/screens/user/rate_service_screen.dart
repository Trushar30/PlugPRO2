import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plugpro/providers/booking_provider.dart';
import 'package:plugpro/providers/service_provider.dart';
import 'package:plugpro/models/booking_model.dart';
import 'package:plugpro/models/worker_model.dart';
import 'package:hive/hive.dart';
import 'package:plugpro/screens/user/user_home_screen.dart';

class RateServiceScreen extends StatefulWidget {
  final String bookingId;

  const RateServiceScreen({
    super.key,
    required this.bookingId,
  });

  @override
  State<RateServiceScreen> createState() => _RateServiceScreenState();
}

class _RateServiceScreenState extends State<RateServiceScreen> {
  final _reviewController = TextEditingController();
  Booking? _booking;
  Worker? _worker;
  double _rating = 5.0;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _reviewController.dispose();
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
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _submitRating() async {
    if (_booking == null) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
      
      final success = await bookingProvider.addRatingAndReview(
        bookingId: _booking!.id,
        rating: _rating,
        review: _reviewController.text.trim(),
      );
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you for your feedback!'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const UserHomeScreen()),
          (route) => false,
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit rating'),
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
          title: const Text('Rate Service'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_booking == null || _worker == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Rate Service'),
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
        // Allow back button only if rating is already submitted
        return _booking!.rating != null;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Rate Service'),
          automaticallyImplyLeading: _booking!.rating != null,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 80,
              ),
              const SizedBox(height: 24),
              const Text(
                'Service Completed!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'How was your experience with ${_worker!.name}?',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Service Info Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.blue.shade100,
                            child: Text(
                              _worker!.name.substring(0, 1).toUpperCase(),
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
                                  _worker!.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  service?.name ?? 'Unknown Service',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Base Price:'),
                          Text('\$${_booking!.basePrice.toStringAsFixed(2)}'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Additional:'),
                          Text('\$${_booking!.additionalPrice.toStringAsFixed(2)}'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '\$${_booking!.totalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Payment:'),
                          Text(
                            _booking!.isPaid ? 'Paid' : 'Pending',
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
              
              const SizedBox(height: 32),
              
              // Rating Section
              if (_booking!.rating == null) ...[
                const Text(
                  'Rate your experience',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < _rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 36,
                      ),
                      onPressed: () {
                        setState(() {
                          _rating = index + 1;
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _reviewController,
                  decoration: const InputDecoration(
                    labelText: 'Write a review',
                    hintText: 'Share your experience...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitRating,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Submit Rating',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
              ] else ...[
                const Text(
                  'Your Rating',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return Icon(
                      index < _booking!.rating! ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 36,
                    );
                  }),
                ),
                const SizedBox(height: 16),
                Text(
                  _booking!.review ?? 'No review provided',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontStyle: _booking!.review != null ? FontStyle.normal : FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Back to Home'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
