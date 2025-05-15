import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plugpro/providers/auth_provider.dart';
import 'package:plugpro/providers/booking_provider.dart';
import 'package:plugpro/providers/service_provider.dart';
import 'package:plugpro/models/booking_model.dart';
import 'package:plugpro/models/user_model.dart';
import 'package:hive/hive.dart';
import 'package:plugpro/screens/worker/request_detail_screen.dart';

class WorkerRequestsScreen extends StatefulWidget {
  const WorkerRequestsScreen({super.key});

  @override
  State<WorkerRequestsScreen> createState() => _WorkerRequestsScreenState();
}

class _WorkerRequestsScreenState extends State<WorkerRequestsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Booking> _pendingBookings = [];
  List<Booking> _acceptedBookings = [];
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
      
      final pendingBookings = bookingProvider.getWorkerBookings(workerId)
          .where((booking) => booking.status == BookingStatus.pending)
          .toList();
      
      final acceptedBookings = bookingProvider.getWorkerBookings(workerId)
          .where((booking) => 
              booking.status == BookingStatus.accepted || 
              booking.status == BookingStatus.inProgress)
          .toList();
      
      // Sort by booking time (newest first)
      pendingBookings.sort((a, b) => b.bookingTime.compareTo(a.bookingTime));
      acceptedBookings.sort((a, b) => b.bookingTime.compareTo(a.bookingTime));
      
      setState(() {
        _pendingBookings = pendingBookings;
        _acceptedBookings = acceptedBookings;
        _isLoading = false;
      });
    } else {
      setState(() {
        _pendingBookings = [];
        _acceptedBookings = [];
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
              text: 'Pending (${_pendingBookings.length})',
            ),
            Tab(
              text: 'Active (${_acceptedBookings.length})',
            ),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildBookingsList(_pendingBookings, isPending: true),
              _buildBookingsList(_acceptedBookings, isPending: false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBookingsList(List<Booking> bookings, {required bool isPending}) {
    if (bookings.isEmpty) {
      return Center(
        child: Text(
          isPending ? 'No pending requests' : 'No active services',
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
        return _buildRequestCard(booking, isPending);
      },
    );
  }

  Widget _buildRequestCard(Booking booking, bool isPending) {
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
          ).then((_) => _loadBookings());
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
              Text(
                'Problem: ${booking.problemDescription}',
                style: TextStyle(
                  color: Colors.grey.shade700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Price: \$${booking.basePrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isPending)
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () => _rejectBooking(booking.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          child: const Text('Reject'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _acceptBooking(booking.id),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          child: const Text('Accept'),
                        ),
                      ],
                    )
                  else
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => RequestDetailScreen(bookingId: booking.id),
                          ),
                        ).then((_) => _loadBookings());
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
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

  Future<void> _acceptBooking(String bookingId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
      final success = await bookingProvider.acceptBooking(bookingId);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking accepted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        _loadBookings();
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
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _rejectBooking(String bookingId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
      final success = await bookingProvider.rejectBooking(bookingId);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking rejected'),
          ),
        );
        
        _loadBookings();
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
          _isLoading = false;
        });
      }
    }
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
