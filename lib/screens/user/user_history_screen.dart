import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plugpro/providers/auth_provider.dart';
import 'package:plugpro/providers/booking_provider.dart';
import 'package:plugpro/providers/service_provider.dart';
import 'package:plugpro/models/booking_model.dart';
import 'package:plugpro/models/service_model.dart';
import 'package:plugpro/models/worker_model.dart';
import 'package:hive/hive.dart';
import 'package:plugpro/screens/user/booking_detail_screen.dart';

class UserHistoryScreen extends StatefulWidget {
  const UserHistoryScreen({super.key});

  @override
  State<UserHistoryScreen> createState() => _UserHistoryScreenState();
}

class _UserHistoryScreenState extends State<UserHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Booking> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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

    if (authProvider.currentUser != null) {
      final bookings = bookingProvider.getUserBookings(authProvider.currentUser!.id);
      
      // Sort bookings by booking time (newest first)
      bookings.sort((a, b) => b.bookingTime.compareTo(a.bookingTime));
      
      setState(() {
        _bookings = bookings;
        _isLoading = false;
      });
    } else {
      setState(() {
        _bookings = [];
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

    if (_bookings.isEmpty) {
      return const Center(
        child: Text('No booking history found'),
      );
    }

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildBookingsList(_bookings),
              _buildBookingsList(_bookings.where((booking) => 
                booking.status == BookingStatus.pending || 
                booking.status == BookingStatus.accepted || 
                booking.status == BookingStatus.inProgress
              ).toList()),
              _buildBookingsList(_bookings.where((booking) => 
                booking.status == BookingStatus.completed
              ).toList()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBookingsList(List<Booking> bookings) {
    if (bookings.isEmpty) {
      return const Center(
        child: Text('No bookings found'),
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
    
    final workersBox = Hive.box<Worker>('workers');
    final worker = workersBox.get(booking.workerId);

    if (service == null || worker == null) {
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
              builder: (_) => BookingDetailScreen(bookingId: booking.id),
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
                          'Worker: ${worker.name}',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Date: ${_formatDate(booking.bookingTime)}',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildStatusBadge(booking.status),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total: \$${booking.totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (booking.status == BookingStatus.completed && booking.rating != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          booking.rating!.toStringAsFixed(1),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => BookingDetailScreen(bookingId: booking.id),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Text('View Details'),
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
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
