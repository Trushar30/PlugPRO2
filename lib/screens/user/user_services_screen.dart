import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plugpro/providers/service_provider.dart';
import 'package:plugpro/models/service_model.dart';
import 'package:plugpro/screens/user/service_detail_screen.dart';

class UserServicesScreen extends StatefulWidget {
  const UserServicesScreen({super.key});

  @override
  State<UserServicesScreen> createState() => _UserServicesScreenState();
}

class _UserServicesScreenState extends State<UserServicesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<String> _categories = [];
  Map<String, List<Service>> _servicesByCategory = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);
    final categories = serviceProvider.getAllCategories();
    final services = serviceProvider.getAllServices();

    final Map<String, List<Service>> servicesByCategory = {};
    for (final category in categories) {
      servicesByCategory[category] = services
          .where((service) => service.category == category)
          .toList();
    }

    setState(() {
      _categories = ['All', ...categories];
      _servicesByCategory = servicesByCategory;
      _servicesByCategory['All'] = services;
      _tabController = TabController(length: _categories.length, vsync: this);
      _isLoading = false;
    });
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
          isScrollable: true,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: _categories.map((category) => Tab(text: category)).toList(),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: _categories.map((category) {
              final services = _servicesByCategory[category] ?? [];
              return services.isEmpty
                  ? const Center(child: Text('No services available'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: services.length,
                      itemBuilder: (context, index) {
                        final service = services[index];
                        return _buildServiceCard(service);
                      },
                    );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildServiceCard(Service service) {
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
              builder: (_) => ServiceDetailScreen(serviceId: service.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.asset(
                service.imageUrl,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 150,
                    color: Colors.grey.shade300,
                    child: const Icon(
                      Icons.image_not_supported,
                      color: Colors.grey,
                      size: 50,
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          service.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          service.category,
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    service.description,
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
                        'Starting from \$${service.basePrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ServiceDetailScreen(serviceId: service.id),
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
          ],
        ),
      ),
    );
  }
}
