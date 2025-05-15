import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:plugpro/models/service_model.dart';
import 'package:plugpro/models/subscription_model.dart';

class ServiceProvider with ChangeNotifier {
  // Get all services
  List<Service> getAllServices() {
    try {
      final servicesBox = Hive.box<Service>('services');
      return servicesBox.values.toList();
    } catch (e) {
      print('Error getting services: $e');
      return [];
    }
  }

  // Get services by category
  List<Service> getServicesByCategory(String category) {
    try {
      final servicesBox = Hive.box<Service>('services');
      return servicesBox.values.where((service) => service.category == category).toList();
    } catch (e) {
      print('Error getting services by category: $e');
      return [];
    }
  }

  // Get service by ID
  Service? getServiceById(String id) {
    try {
      final servicesBox = Hive.box<Service>('services');
      return servicesBox.get(id);
    } catch (e) {
      print('Error getting service by ID: $e');
      return null;
    }
  }

  // Get all categories
  List<String> getAllCategories() {
    try {
      final servicesBox = Hive.box<Service>('services');
      return servicesBox.values.map((service) => service.category).toSet().toList();
    } catch (e) {
      print('Error getting categories: $e');
      return [];
    }
  }

  // Add a new service
  Future<bool> addService({
    required String name,
    required String description,
    required String category,
    required double basePrice,
    required String imageUrl,
  }) async {
    try {
      final servicesBox = Hive.box<Service>('services');
      final uuid = const Uuid();
      
      final newService = Service(
        id: uuid.v4(),
        name: name,
        description: description,
        category: category,
        basePrice: basePrice,
        imageUrl: imageUrl,
      );
      
      await servicesBox.put(newService.id, newService);
      notifyListeners();
      return true;
    } catch (e) {
      print('Error adding service: $e');
      return false;
    }
  }

  // Update a service
  Future<bool> updateService({
    required String id,
    required String name,
    required String description,
    required String category,
    required double basePrice,
    required String imageUrl,
  }) async {
    try {
      final servicesBox = Hive.box<Service>('services');
      final existingService = servicesBox.get(id);
      
      if (existingService == null) {
        return false;
      }
      
      final updatedService = existingService.copyWith(
        name: name,
        description: description,
        category: category,
        basePrice: basePrice,
        imageUrl: imageUrl,
      );
      
      await servicesBox.put(id, updatedService);
      notifyListeners();
      return true;
    } catch (e) {
      print('Error updating service: $e');
      return false;
    }
  }

  // Delete a service
  Future<bool> deleteService(String id) async {
    try {
      final servicesBox = Hive.box<Service>('services');
      await servicesBox.delete(id);
      notifyListeners();
      return true;
    } catch (e) {
      print('Error deleting service: $e');
      return false;
    }
  }

  // Add worker to service
  Future<bool> addWorkerToService({
    required String serviceId,
    required String workerId,
  }) async {
    try {
      final servicesBox = Hive.box<Service>('services');
      final service = servicesBox.get(serviceId);
      
      if (service == null) {
        return false;
      }
      
      final updatedWorkers = List<String>.from(service.availableWorkers);
      if (!updatedWorkers.contains(workerId)) {
        updatedWorkers.add(workerId);
      }
      
      final updatedService = service.copyWith(
        availableWorkers: updatedWorkers,
      );
      
      await servicesBox.put(serviceId, updatedService);
      notifyListeners();
      return true;
    } catch (e) {
      print('Error adding worker to service: $e');
      return false;
    }
  }

  // Remove worker from service
  Future<bool> removeWorkerFromService({
    required String serviceId,
    required String workerId,
  }) async {
    try {
      final servicesBox = Hive.box<Service>('services');
      final service = servicesBox.get(serviceId);
      
      if (service == null) {
        return false;
      }
      
      final updatedWorkers = List<String>.from(service.availableWorkers);
      updatedWorkers.remove(workerId);
      
      final updatedService = service.copyWith(
        availableWorkers: updatedWorkers,
      );
      
      await servicesBox.put(serviceId, updatedService);
      notifyListeners();
      return true;
    } catch (e) {
      print('Error removing worker from service: $e');
      return false;
    }
  }

  // Get all subscriptions
  List<Subscription> getAllSubscriptions() {
    try {
      final subscriptionsBox = Hive.box<Subscription>('subscriptions');
      return subscriptionsBox.values.toList();
    } catch (e) {
      print('Error getting subscriptions: $e');
      return [];
    }
  }

  // Get subscription by ID
  Subscription? getSubscriptionById(String id) {
    try {
      final subscriptionsBox = Hive.box<Subscription>('subscriptions');
      return subscriptionsBox.get(id);
    } catch (e) {
      print('Error getting subscription by ID: $e');
      return null;
    }
  }

  // Add a new subscription
  Future<bool> addSubscription({
    required String name,
    required String description,
    required double price,
    required int durationMonths,
    required int servicesPerMonth,
    required List<String> includedServiceCategories,
  }) async {
    try {
      final subscriptionsBox = Hive.box<Subscription>('subscriptions');
      final uuid = const Uuid();
      
      final newSubscription = Subscription(
        id: uuid.v4(),
        name: name,
        description: description,
        price: price,
        durationMonths: durationMonths,
        servicesPerMonth: servicesPerMonth,
        includedServiceCategories: includedServiceCategories,
      );
      
      await subscriptionsBox.put(newSubscription.id, newSubscription);
      notifyListeners();
      return true;
    } catch (e) {
      print('Error adding subscription: $e');
      return false;
    }
  }

  // Initialize demo data
  Future<void> initializeDemoData() async {
    try {
      final servicesBox = Hive.box<Service>('services');
      final subscriptionsBox = Hive.box<Subscription>('subscriptions');
      
      // Only initialize if boxes are empty
      if (servicesBox.isEmpty) {
        final uuid = const Uuid();
        
        // Add demo services
        final services = [
          Service(
            id: uuid.v4(),
            name: 'Plumbing Repair',
            description: 'Fix leaks, clogs, and other plumbing issues',
            category: 'Plumbing',
            basePrice: 49.99,
            imageUrl: 'assets/images/plumbing.png',
          ),
          Service(
            id: uuid.v4(),
            name: 'Electrical Repair',
            description: 'Fix electrical issues, install fixtures, and more',
            category: 'Electrical',
            basePrice: 59.99,
            imageUrl: 'assets/images/electrical.png',
          ),
          Service(
            id: uuid.v4(),
            name: 'House Cleaning',
            description: 'Professional house cleaning services',
            category: 'Cleaning',
            basePrice: 79.99,
            imageUrl: 'assets/images/cleaning.png',
          ),
          Service(
            id: uuid.v4(),
            name: 'Appliance Repair',
            description: 'Fix refrigerators, washers, dryers, and more',
            category: 'Appliances',
            basePrice: 69.99,
            imageUrl: 'assets/images/appliance.png',
          ),
          Service(
            id: uuid.v4(),
            name: 'Painting',
            description: 'Interior and exterior painting services',
            category: 'Home Improvement',
            basePrice: 199.99,
            imageUrl: 'assets/images/painting.png',
          ),
          Service(
            id: uuid.v4(),
            name: 'Lawn Care',
            description: 'Lawn mowing, trimming, and maintenance',
            category: 'Outdoor',
            basePrice: 49.99,
            imageUrl: 'assets/images/lawn.png',
          ),
        ];
        
        for (var service in services) {
          await servicesBox.put(service.id, service);
        }
      }
      
      if (subscriptionsBox.isEmpty) {
        final uuid = const Uuid();
        
        // Add demo subscriptions
        final subscriptions = [
          Subscription(
            id: uuid.v4(),
            name: 'Basic Plan',
            description: 'One service per month for 3 months',
            price: 129.99,
            durationMonths: 3,
            servicesPerMonth: 1,
            includedServiceCategories: ['Plumbing', 'Electrical', 'Cleaning'],
          ),
          Subscription(
            id: uuid.v4(),
            name: 'Standard Plan',
            description: 'Two services per month for 6 months',
            price: 299.99,
            durationMonths: 6,
            servicesPerMonth: 2,
            includedServiceCategories: ['Plumbing', 'Electrical', 'Cleaning', 'Appliances'],
          ),
          Subscription(
            id: uuid.v4(),
            name: 'Premium Plan',
            description: 'Three services per month for 12 months',
            price: 599.99,
            durationMonths: 12,
            servicesPerMonth: 3,
            includedServiceCategories: ['Plumbing', 'Electrical', 'Cleaning', 'Appliances', 'Home Improvement', 'Outdoor'],
          ),
        ];
        
        for (var subscription in subscriptions) {
          await subscriptionsBox.put(subscription.id, subscription);
        }
      }
      
      notifyListeners();
    } catch (e) {
      print('Error initializing demo data: $e');
    }
  }
}
