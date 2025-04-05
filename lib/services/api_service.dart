import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../utils/constants.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.0.232:3000/api';
  final storage = const FlutterSecureStorage();

  // Authentication
  Future<User> login(String email, String password) async {
    if (kDebugMode) {
      print('ApiService: Attempting login with email: $email');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (kDebugMode) {
      print('ApiService: Login response status: ${response.statusCode}');
      print('ApiService: Login response body: ${response.body.substring(0, min(100, response.body.length))}...');
    }

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);

      if (responseData['success']) {
        // Store token
        final token = responseData['token'];
        await storage.write(key: 'token', value: token);

        if (kDebugMode) {
          print('ApiService: Token stored successfully');
          print('ApiService: User data received: ${responseData['data']}');
        }

        // Return user data
        return User.fromJson(responseData['data']);
      } else {
        final error = responseData['error'] ?? 'Login failed';
        if (kDebugMode) {
          print('ApiService: Login failed with error: $error');
        }
        throw Exception(error);
      }
    } else {
      if (kDebugMode) {
        print('ApiService: HTTP error during login');
      }
      throw Exception('Failed to login. Status code: ${response.statusCode}');
    }
  }

  Future<User> getCurrentUser() async {
    final token = await storage.read(key: 'token');

    if (kDebugMode) {
      print('ApiService: Getting current user, token exists: ${token != null}');
    }

    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (kDebugMode) {
      print('ApiService: getCurrentUser response status: ${response.statusCode}');
    }

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);

      if (responseData['success']) {
        if (kDebugMode) {
          print('ApiService: User data received: ${responseData['data']}');
        }
        return User.fromJson(responseData['data']);
      } else {
        throw Exception(responseData['error'] ?? 'Failed to get user data');
      }
    } else if (response.statusCode == 401) {
      // Token expired or invalid
      await storage.delete(key: 'token');
      throw Exception('Authentication expired');
    } else {
      throw Exception('Failed to get user data. Status code: ${response.statusCode}');
    }
  }

  Future<void> logout() async {
    if (kDebugMode) {
      print('ApiService: Logging out, deleting token');
    }
    await storage.delete(key: 'token');
  }

  // HTTP Helper Methods
  Future<Map<String, String>> _getAuthHeader() async {
    final token = await storage.read(key: 'token');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> get(String endpoint) async {
    final headers = await _getAuthHeader();

    if (kDebugMode) {
      print('ApiService: GET request to $baseUrl$endpoint');
    }

    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );

    return _handleResponse(response);
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    final headers = await _getAuthHeader();

    if (kDebugMode) {
      print('ApiService: POST request to $baseUrl$endpoint');
    }

    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(data),
    );

    return _handleResponse(response);
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    final headers = await _getAuthHeader();

    if (kDebugMode) {
      print('ApiService: PUT request to $baseUrl$endpoint');
    }

    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(data),
    );

    return _handleResponse(response);
  }

  Future<dynamic> patch(String endpoint, Map<String, dynamic> data) async {
    final headers = await _getAuthHeader();

    if (kDebugMode) {
      print('ApiService: PATCH request to $baseUrl$endpoint');
    }

    final response = await http.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(data),
    );

    return _handleResponse(response);
  }

  Future<dynamic> delete(String endpoint) async {
    final headers = await _getAuthHeader();

    if (kDebugMode) {
      print('ApiService: DELETE request to $baseUrl$endpoint');
    }

    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );

    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    if (kDebugMode) {
      print('ApiService: Response status: ${response.statusCode}');
    }

    final responseData = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return responseData;
    } else if (response.statusCode == 401) {
      // Token expired or invalid
      storage.delete(key: 'token');
      throw Exception('Authentication expired');
    } else {
      final error = responseData['error'] ?? 'Request failed with status: ${response.statusCode}';
      if (kDebugMode) {
        print('ApiService: Error in response: $error');
      }
      throw Exception(error);
    }
  }

  // Helper function to limit string length for logging
  int min(int a, int b) {
    return a < b ? a : b;
  }

  // Flights API
  Future<Map<String, dynamic>> getAllFlights({int page = 1, int limit = 10}) async {
    return await get('/flights?page=$page&limit=$limit');
  }

  Future<Map<String, dynamic>> getFlightById(int id) async {
    return await get('/flights/$id');
  }

  Future<Map<String, dynamic>> searchFlightsbyDate(String origin, String destination, String date) async {
    return await get('/flights/search/by-route-date?origin=$origin&destination=$destination&date=$date');
  }
  Future<Map<String, dynamic>> searchFlightsByRoute(String origin, String destination) async {
    return await get('/flights/search/by-route?origin=$origin&destination=$destination');
  }

  Future<Map<String, dynamic>> generateFlightSchedule(String startDate, String endDate) async {
    return await get('/flights/schedule/generate?startDate=$startDate&endDate=$endDate');
  }

  Future<Map<String, dynamic>> createFlight(Map<String, dynamic> flightData) async {
    return await post('/flights', flightData);
  }

  Future<Map<String, dynamic>> updateFlight(int id, Map<String, dynamic> flightData) async {
    return await put('/flights/$id', flightData);
  }

  Future<Map<String, dynamic>> deleteFlight(int id) async {
    return await delete('/flights/$id');
  }

  Future<Map<String, dynamic>> cancelFlight(int id) async {
    return await patch('/flights/$id/cancel', {});
  }

  // Tickets API
  Future<Map<String, dynamic>> getAllTickets({int page = 1, int limit = 10}) async {
    return await get('/tickets?page=$page&limit=$limit');
  }

  Future<Map<String, dynamic>> getTicketById(int id) async {
    return await get('/tickets/$id');
  }

  Future<Map<String, dynamic>> getTicketsByPassengerId(int passengerId) async {
    return await get('/tickets/passenger/$passengerId');
  }

  Future<Map<String, dynamic>> getTicketsByFlightId(int flightId) async {
    return await get('/tickets/flight/$flightId');
  }

  Future<Map<String, dynamic>> generateTicketSalesReport(String startDate, String endDate) async {
    return await get('/tickets/reports/sales?startDate=$startDate&endDate=$endDate');
  }

  Future<Map<String, dynamic>> bookTicket(Map<String, dynamic> ticketData) async {
    return await post('/tickets', ticketData);
  }

  Future<Map<String, dynamic>> updateTicket(int id, Map<String, dynamic> ticketData) async {
    return await put('/tickets/$id', ticketData);
  }

  Future<Map<String, dynamic>> deleteTicket(int id) async {
    return await delete('/tickets/$id');
  }

  Future<Map<String, dynamic>> updateTicketPaymentStatus(int id, String status) async {
    return await patch('/tickets/$id/payment', {'payment_status': status});
  }
}