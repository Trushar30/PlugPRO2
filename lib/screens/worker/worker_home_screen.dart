import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plugpro/providers/auth_provider.dart';
import 'package:plugpro/providers/booking_provider.dart';
import 'package:plugpro/screens/worker/worker_requests_screen.dart';
import 'package:plugpro/screens/worker/worker_history_screen.dart';
import 'package:plugpro/screens/worker/worker_skills_screen.dart';
import 'package:plugpro/models/booking_model.dart';
import 'package:plugpro/models/service_model.dart';
import 'package:hive/hive.dart';
import 'package:fl_chart/fl_chart.dart';

class WorkerHomeScreen extends StatefulWidget {
  const WorkerHomeScreen({super.key});

  @override
  State<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const WorkerHomeContent(),
    const WorkerRequestsScreen(),
    const WorkerHistoryScreen(),
    const WorkerSkillsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final worker = authProvider.currentWorker;

    return Scaffold(
      appBar: AppBar(
        title: _currentIndex == 0
            ? Text('Welcome, ${worker?.name.split(' ')[0] ?? 'Worker'}')
            : Text([
                'Home',
                'Requests',
                'History',
                'Update Skills',
              ][_currentIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              // Navigate to profile screen
            },
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inbox),
            label: 'Requests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.build),
            label: 'Skills',
          ),
        ],
      ),
    );
  }
}

class WorkerHomeContent extends StatefulWidget {
  const WorkerHomeContent({super.key});

  @override
  State<WorkerHomeContent> createState() => _WorkerHomeContentState();
}

class _WorkerHomeContentState extends State<WorkerHomeContent> {
  int _pendingRequests = 0;
  int _completedJobs = 0;
  double _totalEarnings = 0;
  double _averageRating = 0;
  List<Booking> _recentBookings = [];
  List<String> _recentReviews = [];
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

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);

    if (authProvider.currentWorker != null) {
      final worker = authProvider.currentWorker!;
      final bookings = bookingProvider.getWorkerBookings(worker.id);
      
      // Calculate statistics
      final pendingRequests = bookings.where((b) => b.status == BookingStatus.pending).length;
      final completedJobs = bookings.where((b) => b.status == BookingStatus.completed).length;
      
      double totalEarnings = 0;
      for (var booking in bookings.where((b) => b.status == BookingStatus.completed)) {
        totalEarnings += booking.totalPrice;
      }
      
      // Get recent bookings (last 5 completed)
      final recentBookings = bookings
          .where((b) => b.status == BookingStatus.completed)
          .toList()
        ..sort((a, b) => b.completionTime!.compareTo(a.completionTime!));
      
      final recentBookingsList = recentBookings.take(5).toList();
      
      // Get recent reviews
      final recentReviews = recentBookings
          .where((b) => b.review != null && b.review!.isNotEmpty)
          .map((b) => b.review!)
          .take(3)
          .toList();
      
      setState(() {
        _pendingRequests = pendingRequests;
        _completedJobs = completedJobs;
        _totalEarnings = totalEarnings;
        _averageRating = worker.rating;
        _recentBookings = recentBookingsList;
        _recentReviews = recentReviews;
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
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final authProvider = Provider.of<AuthProvider>(context);
    final worker = authProvider.currentWorker;

    if (worker == null) {
      return const Center(
        child: Text('Worker information not found'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Worker Stats
          _buildStatsGrid(),
          
          const SizedBox(height: 24),
          
          // Earnings Chart
          const Text(
            'Earnings Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: _buildEarningsChart(),
          ),
          
          const SizedBox(height: 24),
          
          // Recent Reviews
          const Text(
            'Recent Reviews',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _recentReviews.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text('No reviews yet'),
                  ),
                )
              : Column(
                  children: _recentReviews.map((review) => _buildReviewCard(review)).toList(),
                ),
          
          const SizedBox(height: 24),
          
          // Recent Bookings
          const Text(
            'Recent Services',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _recentBookings.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text('No recent services'),
                  ),
                )
              : Column(
                  children: _recentBookings.map((booking) => _buildBookingCard(booking)).toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard(
          'Pending Requests',
          _pendingRequests.toString(),
          Icons.inbox,
          Colors.orange,
        ),
        _buildStatCard(
          'Completed Jobs',
          _completedJobs.toString(),
          Icons.check_circle,
          Colors.green,
        ),
        _buildStatCard(
          'Total Earnings',
          '\$${_totalEarnings.toStringAsFixed(2)}',
          Icons.attach_money,
          Colors.blue,
        ),
        _buildStatCard(
          'Rating',
          _averageRating.toStringAsFixed(1),
          Icons.star,
          Colors.amber,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsChart() {
    // Sample data for the chart
    final spots = [
      FlSpot(0, 100),
      FlSpot(1, 150),
      FlSpot(2, 120),
      FlSpot(3, 200),
      FlSpot(4, 180),
      FlSpot(5, 250),
      FlSpot(6, _totalEarnings > 0 ? _totalEarnings : 300),
    ];

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 50,
          verticalInterval: 1,
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                const style = TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                );
                String text;
                switch (value.toInt()) {
                  case 0:
                    text = 'Jan';
                    break;
                  case 1:
                    text = 'Feb';
                    break;
                  case 2:
                    text = 'Mar';
                    break;
                  case 3:
                    text = 'Apr';
                    break;
                  case 4:
                    text = 'May';
                    break;
                  case 5:
                    text = 'Jun';
                    break;
                  case 6:
                    text = 'Jul';
                    break;
                  default:
                    return Container();
                }
                return Text(text, style: style);
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 50,
              getTitlesWidget: (value, meta) {
                return Text(
                  '\$${value.toInt()}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              },
              reservedSize: 42,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade300),
        ),
        minX: 0,
        maxX: 6,
        minY: 0,
        maxY: 300,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(String review) {
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
                const Spacer(),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < 5 ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 14,
                    );
                  }),
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

  Widget _buildBookingCard(Booking booking) {
    final servicesBox = Hive.box<Service>('services');
    final service = servicesBox.get(booking.serviceId);

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
                service?.imageUrl ?? 'assets/images/placeholder.png',
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
                    service?.name ?? 'Unknown Service',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Date: ${_formatDate(booking.completionTime ?? booking.bookingTime)}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Earned: \$${booking.totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (booking.rating != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      booking.rating!.toStringAsFixed(1),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
