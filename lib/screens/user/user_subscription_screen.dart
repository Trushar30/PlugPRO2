import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plugpro/providers/service_provider.dart';
import 'package:plugpro/models/subscription_model.dart';

class UserSubscriptionScreen extends StatefulWidget {
  const UserSubscriptionScreen({super.key});

  @override
  State<UserSubscriptionScreen> createState() => _UserSubscriptionScreenState();
}

class _UserSubscriptionScreenState extends State<UserSubscriptionScreen> {
  List<Subscription> _subscriptions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  Future<void> _loadSubscriptions() async {
    setState(() {
      _isLoading = true;
    });

    final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);
    final subscriptions = serviceProvider.getAllSubscriptions();

    setState(() {
      _subscriptions = subscriptions;
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Subscription Plans',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose a subscription plan to get regular services at discounted rates.',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _subscriptions.length,
            itemBuilder: (context, index) {
              final subscription = _subscriptions[index];
              return _buildSubscriptionCard(subscription);
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Your Active Subscriptions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Placeholder for active subscriptions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Center(
              child: Text(
                'You don\'t have any active subscriptions',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(Subscription subscription) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  subscription.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '\$${subscription.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              subscription.description,
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),
            _buildFeatureItem(
              '${subscription.servicesPerMonth} service(s) per month',
              Icons.check_circle,
            ),
            _buildFeatureItem(
              '${subscription.durationMonths} month(s) duration',
              Icons.check_circle,
            ),
            _buildFeatureItem(
              'Includes: ${subscription.includedServiceCategories.join(', ')}',
              Icons.check_circle,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Handle subscription purchase
                  _showSubscriptionDialog(subscription);
                },
                child: const Text('Subscribe Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.green,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text),
          ),
        ],
      ),
    );
  }

  void _showSubscriptionDialog(Subscription subscription) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Subscription'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You are about to subscribe to ${subscription.name}.'),
            const SizedBox(height: 8),
            Text('Price: \$${subscription.price.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            Text('Duration: ${subscription.durationMonths} month(s)'),
            const SizedBox(height: 8),
            Text('Services per month: ${subscription.servicesPerMonth}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Handle subscription purchase
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Subscription purchased successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Subscribe'),
          ),
        ],
      ),
    );
  }
}
