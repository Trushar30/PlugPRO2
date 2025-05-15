import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plugpro/providers/auth_provider.dart';
import 'package:plugpro/providers/booking_provider.dart';
import 'package:plugpro/providers/service_provider.dart';
import 'package:plugpro/models/booking_model.dart';
import 'package:plugpro/models/user_model.dart';
import 'package:hive/hive.dart';
import 'package:plugpro/screens/worker/request_detail_screen.dart';

class WorkerHistoryScreen extends StatefulWidget {
  const WorkerHistoryScreen({super.key});

  @override
  State<WorkerHistoryScreen> createState() => _WorkerHistoryScreenState();
}

class _WorkerHistoryScreenState extends State<WorkerHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Booking> _completedBookings = [];
  List<Booking> _cancelledBookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);

    if (authProvider.currentWorker != null) {
      final workerId = authProvider.currentWorker!.id;
      
      final completedBookings = bookingProvider.getWorkerBookings(workerId)
          .where((booking) => booking.status == BookingStatus.completed)
          .toList();
      
      final cancelledBookings = bookingProvider.getWorkerBookings(workerId)
          .where((booking) => 
              booking.status == BookingStatus.cancelled || 
              booking.status == BookingStatus.rejected)
          .toList();
      
      // Sort by booking time (newest first)
      completedBookings.sort((a, b) => b.bookingTime.compareTo(a.bookingTime));
      cancelledBookings.sort((a, b) => b.bookingTime.compareTo(a.bookingTime));
      
      setState(() {
        _completedBookings = completedBookings;
        _cancelledBookings = cancelledBookings;
        _isLoading = false;
      });
    } else {
      setState(() {
        _completedBookings = [];
        _cancelledBookings = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: [
            Tab(
              text: 'Completed (${_completedBookings.length})',
            ),
            Tab(
              text: 'Cancelled (${_cancelledBookings.length})',
            ),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildBookingsList(_completedBookings),
              _buildBookingsList(_cancelledBookings),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBookingsList(List<Booking> bookings) {
    if (bookings.isEmpty) {
      return Center(
        child: Text(
          'No bookings found',
          style: TextStyle(
            color: Colors.grey.shade600,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return _buildBookingCard(booking);
      },
    );
  }

  Widget _buildBookingCard(Booking booking) {
    final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);
    final service = serviceProvider.getServiceById(booking.serviceId);
    
    final usersBox = Hive.box<User>('users');
    final user = usersBox.get(booking.userId);

    if (service == null || user == null) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RequestDetailScreen(bookingId: booking.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      service.imageUrl,
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
                          service.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Customer: ${user.name}',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Location: ${booking.location}',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Date: ${_formatDate(booking.completionTime ?? booking.bookingTime)}',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildStatusBadge(booking.status),
                          ],
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Base Price: \$${booking.basePrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                        ),
                      ),
                      if (booking.additionalPrice > 0)
                        Text(
                          'Additional: \$${booking.additionalPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                          ),
                        ),
                      Text(
                        'Total: \$${booking.totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Payment: ${booking.isPaid ? 'Paid' : 'Pending'}',
                        style: TextStyle(
                          color: booking.isPaid ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (booking.rating != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: List.generate(5, (index) {
                              return Icon(
                                index < booking.rating! ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 16,
                              );
                            }),
                          ),
                          Text(
                            booking.rating!.toStringAsFixed(1),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
