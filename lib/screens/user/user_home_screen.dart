import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plugpro/providers/auth_provider.dart';
import 'package:plugpro/providers/service_provider.dart';
import 'package:plugpro/screens/user/user_services_screen.dart';
import 'package:plugpro/screens/user/user_history_screen.dart';
import 'package:plugpro/screens/user/user_subscription_screen.dart';
import 'package:plugpro/screens/user/service_detail_screen.dart';
import 'package:plugpro/screens/user/worker_detail_screen.dart';
import 'package:plugpro/screens/user/chat_bot_screen.dart';
import 'package:plugpro/models/service_model.dart';
import 'package:plugpro/models/worker_model.dart';
import 'package:hive/hive.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _currentIndex = 0;
  final _searchController = TextEditingController();
  final List<Widget> _screens = [
    const UserHomeContent(),
    const UserServicesScreen(),
    const UserHistoryScreen(),
    const UserSubscriptionScreen(),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: _currentIndex == 0
            ? Text('Welcome, ${user?.name.split(' ')[0] ?? 'User'}')
            : Text([
                'Home',
                'Services',
                'History',
                'Subscriptions',
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
            icon: Icon(Icons.miscellaneous_services),
            label: 'Services',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_membership),
            label: 'Subscription',
          ),
        ],
      ),
    );
  }
}

class UserHomeContent extends StatefulWidget {
  const UserHomeContent({super.key});

  @override
  State<UserHomeContent> createState() => _UserHomeContentState();
}

class _UserHomeContentState extends State<UserHomeContent> {
  final _searchController = TextEditingController();
  List<Service> _featuredServices = [];
  List<Worker> _topWorkers = [];
  int _currentBannerIndex = 0;
  final PageController _bannerController = PageController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _startBannerTimer();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bannerController.dispose();
    super.dispose();
  }

  void _startBannerTimer() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _currentBannerIndex = (_currentBannerIndex + 1) % 3;
          _bannerController.animateToPage(
            _currentBannerIndex,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        });
        _startBannerTimer();
      }
    });
  }

  Future<void> _loadData() async {
    final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);
    final services = serviceProvider.getAllServices();
    
    final workersBox = Hive.box<Worker>('workers');
    final workers = workersBox.values.toList();
    
    // Sort workers by rating
    workers.sort((a, b) => b.rating.compareTo(a.rating));
    
    setState(() {
      _featuredServices = services.take(6).toList();
      _topWorkers = workers.take(4).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for services...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onSubmitted: (value) {
                // Handle search
              },
            ),
          ),
          
          // Banner Ads
          SizedBox(
            height: 180,
            child: PageView(
              controller: _bannerController,
              onPageChanged: (index) {
                setState(() {
                  _currentBannerIndex = index;
                });
              },
              children: [
                _buildBanner(
                  'Special Offer!',
                  '20% off on all plumbing services',
                  Colors.blue.shade700,
                ),
                _buildBanner(
                  'New User?',
                  'Get your first service free with subscription',
                  Colors.green.shade700,
                ),
                _buildBanner(
                  'Weekend Special',
                  'Book any cleaning service at flat rates',
                  Colors.orange.shade700,
                ),
              ],
            ),
          ),
          
          // Banner Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentBannerIndex == index
                      ? Colors.blue
                      : Colors.grey.shade300,
                ),
              );
            }),
          ),
          
          // Categories Section
          _buildSectionHeader('Categories', () {
            setState(() {
              var _currentIndex = 1;
            });
          }),
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildCategoryItem('Plumbing', Icons.plumbing, Colors.blue),
                _buildCategoryItem('Electrical', Icons.electrical_services, Colors.orange),
                _buildCategoryItem('Cleaning', Icons.cleaning_services, Colors.green),
                _buildCategoryItem('Appliances', Icons.kitchen, Colors.red),
                _buildCategoryItem('Home Improvement', Icons.home_repair_service, Colors.purple),
                _buildCategoryItem('Outdoor', Icons.grass, Colors.teal),
              ],
            ),
          ),
          
          // Featured Services
          _buildSectionHeader('Featured Services', () {}),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _featuredServices.length,
              itemBuilder: (context, index) {
                final service = _featuredServices[index];
                return _buildServiceItem(service);
              },
            ),
          ),
          
          // Top Workers
          _buildSectionHeader('Top Workers', () {}),
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _topWorkers.length,
              itemBuilder: (context, index) {
                final worker = _topWorkers[index];
                return _buildWorkerItem(worker);
              },
            ),
          ),
          
          // App Reviews
          _buildSectionHeader('App Reviews', () {}),
          SizedBox(
            height: 150,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildReviewItem('John D.', 'Great service, highly recommended!', 5),
                _buildReviewItem('Sarah M.', 'Workers are professional and on time.', 4),
                _buildReviewItem('Mike T.', 'Solved my plumbing issue quickly.', 5),
                _buildReviewItem('Lisa R.', 'Good app, but could improve UI.', 4),
              ],
            ),
          ),
          
          // AI Chatbot Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ChatBotScreen()),
                );
              },
              icon: const Icon(Icons.chat),
              label: const Text('Ask our AI Assistant'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                minimumSize: const Size(double.infinity, 0),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildBanner(String title, String subtitle, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.handyman,
              size: 150,
              color: Colors.white.withOpacity(0.2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: color,
                  ),
                  child: const Text('Learn More'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onSeeAll) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextButton(
            onPressed: onSeeAll,
            child: const Text('See All'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(String name, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {
        // Navigate to category services
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 36,
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceItem(Service service) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ServiceDetailScreen(serviceId: service.id),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.asset(
                service.imageUrl,
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 100,
                    color: Colors.grey.shade300,
                    child: const Icon(
                      Icons.image_not_supported,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
          ],
        ),
      ),
    );
  }

  Widget _buildWorkerItem(Worker worker) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => WorkerDetailScreen(workerId: worker.id),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.blue.shade100,
              child: Text(
                worker.name.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              worker.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              worker.skills.isNotEmpty
                  ? worker.skills.join(', ')
                  : 'No skills listed',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.star,
                  color: Colors.amber,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  worker.rating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  ' (${worker.completedJobs})',
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
    );
  }

  Widget _buildReviewItem(String name, String review, int rating) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 16,
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
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
