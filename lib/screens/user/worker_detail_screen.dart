import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:plugpro/models/worker_model.dart';
import 'package:plugpro/models/service_model.dart';
import 'package:plugpro/models/booking_model.dart';
import 'package:plugpro/screens/user/book_service_screen.dart';

class WorkerDetailScreen extends StatefulWidget {
  final String workerId;

  const WorkerDetailScreen({
    super.key,
    required this.workerId,
  });

  @override
  State<WorkerDetailScreen> createState() => _WorkerDetailScreenState();
}

class _WorkerDetailScreenState extends State<WorkerDetailScreen> {
  Worker? _worker;
  List<Service> _services = [];
  List<String> _reviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final workersBox = Hive.box<Worker>('workers');
    final worker = workersBox.get(widget.workerId);

    if (worker != null) {
      final servicesBox = Hive.box<Service>('services');
      final services = servicesBox.values
          .where((service) => service.availableWorkers.contains(worker.id))
          .toList();

      // If no services are assigned, get all services
      if (services.isEmpty) {
        services.addAll(servicesBox.values.toList());
      }

      // Get reviews from bookings
      final bookingsBox = Hive.box<Booking>('bookings');
      final reviews = bookingsBox.values
          .where((booking) => 
              booking.workerId == worker.id && 
              booking.status == BookingStatus.completed &&
              booking.review != null)
          .map((booking) => booking.review!)
          .toList();

      setState(() {
        _worker = worker;
        _services = services;
        _reviews = reviews;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Worker Profile'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_worker == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Worker Profile'),
        ),
        body: const Center(
          child: Text('Worker not found'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_worker!.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Worker Profile Header
            Container(
              padding: const EdgeInsets.all(24),
              color: Colors.blue.shade50,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      _worker!.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _worker!.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _worker!.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        ' (${_worker!.completedJobs} jobs)',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: _worker!.skills.map((skill) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Text(
                          skill,
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            
            // About Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'About',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _worker!.description.isNotEmpty
                        ? _worker!.description
                        : 'No description available for this worker.',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  const Text(
                    'Services Offered',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _services.isEmpty
                      ? Text(
                          'No services available',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _services.length,
                          itemBuilder: (context, index) {
                            final service = _services[index];
                            return _buildServiceItem(service);
                          },
                        ),
                  
                  const SizedBox(height: 24),
                  
                  const Text(
                    'Reviews',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _reviews.isEmpty
                      ? Text(
                          'No reviews yet',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _reviews.length,
                          itemBuilder: (context, index) {
                            final review = _reviews[index];
                            return _buildReviewItem(review);
                          },
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ElevatedButton(
            onPressed: () {
              // Show service selection dialog
              _showServiceSelectionDialog();
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text(
              'Book This Worker',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceItem(Service service) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                service.imageUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey.shade300,
                    child: const Icon(
                      Icons.image_not_supported,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    service.category,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${service.basePrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BookServiceScreen(
                      serviceId: service.id,
                      workerId: _worker!.id,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: const Text('Book'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewItem(String review) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.format_quote,
                  color: Colors.blue,
                  size: 16,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Customer Review',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              review,
              style: TextStyle(
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showServiceSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select a Service'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _services.length,
            itemBuilder: (context, index) {
              final service = _services[index];
              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.asset(
                    service.imageUrl,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 40,
                        height: 40,
                        color: Colors.grey.shade300,
                        child: const Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                          size: 20,
                        ),
                      );
                    },
                  ),
                ),
                title: Text(service.name),
                subtitle: Text('\$${service.basePrice.toStringAsFixed(2)}'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BookServiceScreen(
                        serviceId: service.id,
                        workerId: _worker!.id,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
