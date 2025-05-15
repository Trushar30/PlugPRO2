import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:plugpro/models/user_model.dart';
import 'package:plugpro/models/worker_model.dart';

enum UserRole { user, worker, none }

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  Worker? _currentWorker;
  UserRole _currentRole = UserRole.none;
  bool _isAuthenticated = false;

  User? get currentUser => _currentUser;
  Worker? get currentWorker => _currentWorker;
  UserRole get currentRole => _currentRole;
  bool get isAuthenticated => _isAuthenticated;

  // Register a new user
  Future<bool> registerUser({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String address,
    required UserRole role,
  }) async {
    try {
      final uuid = const Uuid();
      
      if (role == UserRole.user) {
        final usersBox = Hive.box<User>('users');
        
        // Check if email already exists
        final existingUser = usersBox.values.any((user) => user.email == email);
        if (existingUser) {
          return false;
        }
        
        final newUser = User(
          id: uuid.v4(),
          name: name,
          email: email,
          password: password,
          phone: phone,
          address: address,
        );
        
        await usersBox.put(newUser.id, newUser);
        
        _currentUser = newUser;
        _currentRole = UserRole.user;
        _isAuthenticated = true;
        
        notifyListeners();
        return true;
      } else if (role == UserRole.worker) {
        final workersBox = Hive.box<Worker>('workers');
        
        // Check if email already exists
        final existingWorker = workersBox.values.any((worker) => worker.email == email);
        if (existingWorker) {
          return false;
        }
        
        final newWorker = Worker(
          id: uuid.v4(),
          name: name,
          email: email,
          password: password,
          phone: phone,
          address: address,
          description: '',
          skills: [],
        );
        
        await workersBox.put(newWorker.id, newWorker);
        
        _currentWorker = newWorker;
        _currentRole = UserRole.worker;
        _isAuthenticated = true;
        
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error registering user: $e');
      return false;
    }
  }

  // Login user
  Future<bool> login({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    try {
      if (role == UserRole.user) {
        final usersBox = Hive.box<User>('users');
        
        final user = usersBox.values.firstWhere(
          (user) => user.email == email && user.password == password,
          orElse: () => throw Exception('Invalid credentials'),
        );
        
        _currentUser = user;
        _currentRole = UserRole.user;
        _isAuthenticated = true;
        
        notifyListeners();
        return true;
      } else if (role == UserRole.worker) {
        final workersBox = Hive.box<Worker>('workers');
        
        final worker = workersBox.values.firstWhere(
          (worker) => worker.email == email && worker.password == password,
          orElse: () => throw Exception('Invalid credentials'),
        );
        
        _currentWorker = worker;
        _currentRole = UserRole.worker;
        _isAuthenticated = true;
        
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error logging in: $e');
      return false;
    }
  }

  // Logout
  void logout() {
    _currentUser = null;
    _currentWorker = null;
    _currentRole = UserRole.none;
    _isAuthenticated = false;
    notifyListeners();
  }

  // Update user profile
  Future<bool> updateUserProfile({
    required String name,
    required String phone,
    required String address,
  }) async {
    try {
      if (_currentRole == UserRole.user && _currentUser != null) {
        final usersBox = Hive.box<User>('users');
        
        final updatedUser = _currentUser!.copyWith(
          name: name,
          phone: phone,
          address: address,
        );
        
        await usersBox.put(updatedUser.id, updatedUser);
        
        _currentUser = updatedUser;
        notifyListeners();
        return true;
      } else if (_currentRole == UserRole.worker && _currentWorker != null) {
        final workersBox = Hive.box<Worker>('workers');
        
        final updatedWorker = _currentWorker!.copyWith(
          name: name,
          phone: phone,
          address: address,
        );
        
        await workersBox.put(updatedWorker.id, updatedWorker);
        
        _currentWorker = updatedWorker;
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }

  // Update worker skills
  Future<bool> updateWorkerSkills({
    required String description,
    required List<String> skills,
  }) async {
    try {
      if (_currentRole == UserRole.worker && _currentWorker != null) {
        final workersBox = Hive.box<Worker>('workers');
        
        final updatedWorker = _currentWorker!.copyWith(
          description: description,
          skills: skills,
        );
        
        await workersBox.put(updatedWorker.id, updatedWorker);
        
        _currentWorker = updatedWorker;
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error updating worker skills: $e');
      return false;
    }
  }
}
