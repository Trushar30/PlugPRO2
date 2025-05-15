import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:plugpro/models/booking_model.dart';
import 'package:plugpro/models/user_model.dart';
import 'package:plugpro/models/worker_model.dart';

class BookingProvider with ChangeNotifier {
  // Create a new booking
  Future<bool> createBooking({
    required String userId,
    required String workerId,
    required String serviceId,
    required String problemDescription,
    required List<String> problemImages,
    required String location,
    required String alternatePhone,
    required double basePrice,
    required String paymentMethod,
  }) async {
    try {
      final bookingsBox = Hive.box<Booking>('bookings');
      final usersBox = Hive.box<User>('users');
      final workersBox = Hive.box<Worker>('workers');
      
      final uuid = const Uuid();
      final bookingId = uuid.v4();
      
      final newBooking = Booking(
        id: bookingId,
        userId: userId,
        workerId: workerId,
        serviceId: serviceId,
        problemDescription: problemDescription,
        problemImages: problemImages,
        location: location,
        alternatePhone: alternatePhone,
        basePrice: basePrice,
        totalPrice: basePrice,
        paymentMethod: paymentMethod,
        bookingTime: DateTime.now(),
      );
      
      await bookingsBox.put(bookingId, newBooking);
      
      // Update user's booking history
      final user = usersBox.get(userId);
      if (user != null) {
        final updatedBookingHistory = List<String>.from(user.bookingHistory);
        updatedBookingHistory.add(bookingId);
        
        final updatedUser = user.copyWith(
          bookingHistory: updatedBookingHistory,
        );
        
        await usersBox.put(userId, updatedUser);
      }
      
      // Update worker's pending requests
      final worker = workersBox.get(workerId);
      if (worker != null) {
        final updatedPendingRequests = List<String>.from(worker.pendingRequests);
        updatedPendingRequests.add(bookingId);
        
        final updatedWorker = worker.copyWith(
          pendingRequests: updatedPendingRequests,
        );
        
        await workersBox.put(workerId, updatedWorker);
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      print('Error creating booking: $e');
      return false;
    }
  }

  // Get booking by ID
  Booking? getBookingById(String id) {
    try {
      final bookingsBox = Hive.box<Booking>('bookings');
      return bookingsBox.get(id);
    } catch (e) {
      print('Error getting booking by ID: $e');
      return null;
    }
  }

  // Get bookings for user
  List<Booking> getUserBookings(String userId) {
    try {
      final bookingsBox = Hive.box<Booking>('bookings');
      return bookingsBox.values.where((booking) => booking.userId == userId).toList();
    } catch (e) {
      print('Error getting user bookings: $e');
      return [];
    }
  }

  // Get bookings for worker
  List<Booking> getWorkerBookings(String workerId) {
    try {
      final bookingsBox = Hive.box<Booking>('bookings');
      return bookingsBox.values.where((booking) => booking.workerId == workerId).toList();
    } catch (e) {
      print('Error getting worker bookings: $e');
      return [];
    }
  }

  // Get pending bookings for worker
  List<Booking> getWorkerPendingBookings(String workerId) {
    try {
      final bookingsBox = Hive.box<Booking>('bookings');
      return bookingsBox.values.where(
        (booking) => booking.workerId == workerId && booking.status == BookingStatus.pending
      ).toList();
    } catch (e) {
      print('Error getting worker pending bookings: $e');
      return [];
    }
  }

  // Accept booking
  Future<bool> acceptBooking(String bookingId) async {
    try {
      final bookingsBox = Hive.box<Booking>('bookings');
      final booking = bookingsBox.get(bookingId);
      
      if (booking == null) {
        return false;
      }
      
      final updatedBooking = booking.copyWith(
        status: BookingStatus.accepted,
        serviceTime: DateTime.now(),
      );
      
      await bookingsBox.put(bookingId, updatedBooking);
      
      // Update worker's pending requests
      final workersBox = Hive.box<Worker>('workers');
      final worker = workersBox.get(booking.workerId);
      
      if (worker != null) {
        final updatedPendingRequests = List<String>.from(worker.pendingRequests);
        updatedPendingRequests.remove(bookingId);
        
        final updatedWorker = worker.copyWith(
          pendingRequests: updatedPendingRequests,
        );
        
        await workersBox.put(booking.workerId, updatedWorker);
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      print('Error accepting booking: $e');
      return false;
    }
  }

  // Reject booking
  Future<bool> rejectBooking(String bookingId) async {
    try {
      final bookingsBox = Hive.box<Booking>('bookings');
      final booking = bookingsBox.get(bookingId);
      
      if (booking == null) {
        return false;
      }
      
      final updatedBooking = booking.copyWith(
        status: BookingStatus.rejected,
      );
      
      await bookingsBox.put(bookingId, updatedBooking);
      
      // Update worker's pending requests
      final workersBox = Hive.box<Worker>('workers');
      final worker = workersBox.get(booking.workerId);
      
      if (worker != null) {
        final updatedPendingRequests = List<String>.from(worker.pendingRequests);
        updatedPendingRequests.remove(bookingId);
        
        final updatedWorker = worker.copyWith(
          pendingRequests: updatedPendingRequests,
        );
        
        await workersBox.put(booking.workerId, updatedWorker);
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      print('Error rejecting booking: $e');
      return false;
    }
  }

  // Start service
  Future<bool> startService(String bookingId) async {
    try {
      final bookingsBox = Hive.box<Booking>('bookings');
      final booking = bookingsBox.get(bookingId);
      
      if (booking == null) {
        return false;
      }
      
      final updatedBooking = booking.copyWith(
        status: BookingStatus.inProgress,
      );
      
      await bookingsBox.put(bookingId, updatedBooking);
      notifyListeners();
      return true;
    } catch (e) {
      print('Error starting service: $e');
      return false;
    }
  }

  // Complete service
  Future<bool> completeService({
    required String bookingId,
    required double additionalPrice,
  }) async {
    try {
      final bookingsBox = Hive.box<Booking>('bookings');
      final booking = bookingsBox.get(bookingId);
      
      if (booking == null) {
        return false;
      }
      
      final totalPrice = booking.basePrice + additionalPrice;
      
      final updatedBooking = booking.copyWith(
        status: BookingStatus.completed,
        additionalPrice: additionalPrice,
        totalPrice: totalPrice,
        completionTime: DateTime.now(),
      );
      
      await bookingsBox.put(bookingId, updatedBooking);
      
      // Update worker's service history and completed jobs
      final workersBox = Hive.box<Worker>('workers');
      final worker = workersBox.get(booking.workerId);
      
      if (worker != null) {
        final updatedServiceHistory = List<String>.from(worker.serviceHistory);
        updatedServiceHistory.add(bookingId);
        
        final updatedWorker = worker.copyWith(
          serviceHistory: updatedServiceHistory,
          completedJobs: worker.completedJobs + 1,
        );
        
        await workersBox.put(booking.workerId, updatedWorker);
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      print('Error completing service: $e');
      return false;
    }
  }

  // Mark payment as complete
  Future<bool> markPaymentComplete(String bookingId) async {
    try {
      final bookingsBox = Hive.box<Booking>('bookings');
      final booking = bookingsBox.get(bookingId);
      
      if (booking == null) {
        return false;
      }
      
      final updatedBooking = booking.copyWith(
        isPaid: true,
      );
      
      await bookingsBox.put(bookingId, updatedBooking);
      notifyListeners();
      return true;
    } catch (e) {
      print('Error marking payment as complete: $e');
      return false;
    }
  }

  // Add rating and review
  Future<bool> addRatingAndReview({
    required String bookingId,
    required double rating,
    required String review,
  }) async {
    try {
      final bookingsBox = Hive.box<Booking>('bookings');
      final booking = bookingsBox.get(bookingId);
      
      if (booking == null) {
        return false;
      }
      
      final updatedBooking = booking.copyWith(
        rating: rating,
        review: review,
      );
      
      await bookingsBox.put(bookingId, updatedBooking);
      
      // Update worker's rating and reviews
      final workersBox = Hive.box<Worker>('workers');
      final worker = workersBox.get(booking.workerId);
      
      if (worker != null) {
        final updatedReviews = List<String>.from(worker.reviews);
        updatedReviews.add(review);
        
        // Calculate new average rating
        final allWorkerBookings = bookingsBox.values.where(
          (b) => b.workerId == worker.id && b.rating != null
        ).toList();
        
        double totalRating = 0;
        for (var b in allWorkerBookings) {
          totalRating += b.rating!;
        }
        
        final newRating = totalRating / allWorkerBookings.length;
        
        final updatedWorker = worker.copyWith(
          reviews: updatedReviews,
          rating: newRating,
        );
        
        await workersBox.put(booking.workerId, updatedWorker);
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      print('Error adding rating and review: $e');
      return false;
    }
  }

  // Cancel booking
  Future<bool> cancelBooking(String bookingId) async {
    try {
      final bookingsBox = Hive.box<Booking>('bookings');
      final booking = bookingsBox.get(bookingId);
      
      if (booking == null) {
        return false;
      }
      
      final updatedBooking = booking.copyWith(
        status: BookingStatus.cancelled,
      );
      
      await bookingsBox.put(bookingId, updatedBooking);
      
      // Update worker's pending requests if it was pending
      if (booking.status == BookingStatus.pending) {
        final workersBox = Hive.box<Worker>('workers');
        final worker = workersBox.get(booking.workerId);
        
        if (worker != null) {
          final updatedPendingRequests = List<String>.from(worker.pendingRequests);
          updatedPendingRequests.remove(bookingId);
          
          final updatedWorker = worker.copyWith(
            pendingRequests: updatedPendingRequests,
          );
          
          await workersBox.put(booking.workerId, updatedWorker);
        }
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      print('Error cancelling booking: $e');
      return false;
    }
  }
}
