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

  Future<Map<String, dynamic>> getFlightCrew(int id) async {
    return await get('/flights/$id/crew');
  }


  // Crews API
  Future<Map<String, dynamic>> getAllCrews({int page = 1, int limit = 10}) async {
    return await get('/crews?page=$page&limit=$limit');
  }

  Future<Map<String, dynamic>> getCrewById(int id) async {
    return await get('/crews/$id');
  }

  Future<Map<String, dynamic>> getCrewMembers(int crewId) async {
    return await get('/crews/$crewId/members');
  }

  Future<Map<String, dynamic>> createCrew(Map<String, dynamic> crewData) async {
    return await post('/crews', crewData);
  }

  Future<Map<String, dynamic>> updateCrew(int id, Map<String, dynamic> crewData) async {
    return await put('/crews/$id', crewData);
  }

  Future<Map<String, dynamic>> deleteCrew(int id) async {
    return await delete('/crews/$id');
  }

  Future<Map<String, dynamic>> assignCrewMember(int crewId, int crewMemberId) async {
    return await post('/crews/$crewId/members', {'crew_member_id': crewMemberId});
  }

  Future<Map<String, dynamic>> removeCrewMember(int crewId, int crewMemberId) async {
    return await delete('/crews/$crewId/members/$crewMemberId');
  }

  Future<Map<String, dynamic>> validateCrew(int crewId) async {
    return await get('/crews/$crewId/validate');
  }

  // Crew Members API
  Future<Map<String, dynamic>> getAllCrewMembers({int page = 1, int limit = 10, String? role}) async {
    String url = '/crew-members?page=$page&limit=$limit';
    if (role != null) {
      url += '&role=$role';
    }
    return await get(url);
  }

  Future<Map<String, dynamic>> getCrewMemberById(int id) async {
    return await get('/crew-members/$id');
  }

  Future<Map<String, dynamic>> createCrewMember(Map<String, dynamic> crewMemberData) async {
    return await post('/crew-members', crewMemberData);
  }

  Future<Map<String, dynamic>> updateCrewMember(int id, Map<String, dynamic> crewMemberData) async {
    return await put('/crew-members/$id', crewMemberData);
  }

  Future<Map<String, dynamic>> deleteCrewMember(int id) async {
    return await delete('/crew-members/$id');
  }

  Future<Map<String, dynamic>> searchCrewMembersByLastName(String lastName) async {
    // Debug print to see what's being sent
    print('Searching for last name: $lastName');

    // Make sure the URL is encoded properly
    final encodedName = Uri.encodeComponent(lastName);
    print('Encoded as: $encodedName');

    return await get('/crew-members/search/$encodedName');
  }

  Future<Map<String, dynamic>> getTicketsByFlightNumber(String flightNumber) async {
    return await get('/tickets/flight-number/$flightNumber');
  }

  Future<Map<String, dynamic>> getTicketsByPassportNumber(String passportNumber) async {
    return await get('/tickets/passport/$passportNumber');
  }

  // lib/services/api_service.dart

// Add these methods to your ApiService class

// Flight Seats API
  Future<Map<String, dynamic>> getFlightSeatMap(int flightId) async {
    return await get('/flight-seats/$flightId/seat-map');
  }

  Future<Map<String, dynamic>> getAvailableSeatsByClass(int flightId, String seatClass) async {
    return await get('/flight-seats/$flightId/available/$seatClass');
  }

  Future<Map<String, dynamic>> checkSeatAvailability(
      int flightId, String seatClass, String seatNumber) async {
    return await get('/flight-seats/$flightId/check/$seatClass/$seatNumber');
  }

  Future<Map<String, dynamic>> validateSeat(int flightId, Map<String, dynamic> seatData) async {
    return await post('/flight-seats/$flightId/validate', seatData);
  }

  Future<Map<String, dynamic>> initializeFlightSeats(int flightId) async {
    return await post('/flight-seats/$flightId/initialize', {});
  }

  Future<Map<String, dynamic>> reconfigureFlightSeats(
      int flightId, Map<String, dynamic> configuration) async {
    return await put('/flight-seats/$flightId/reconfigure', {'configuration': configuration});
  }

// Enhanced Ticket API methods
  Future<Map<String, dynamic>> validateSeatForBooking(Map<String, dynamic> seatData) async {
    return await post('/tickets/validate-seat', seatData);
  }

  Future<Map<String, dynamic>> getAvailableSeats(int flightId, {String? seatClass}) async {
    if (seatClass != null) {
      return await get('/tickets/flight/$flightId/available-seats/$seatClass');
    } else {
      return await get('/tickets/flight/$flightId/available-seats');
    }
  }
  // Passengers API (Users)
  Future<Map<String, dynamic>> createPassenger(Map<String, dynamic> passengerData) async {
    return await post('/passengers', passengerData);
  }

  Future<Map<String, dynamic>> getPassengerById(int id) async {
    return await get('/passengers/$id');
  }

  Future<Map<String, dynamic>> getPassengerTickets(int passengerId) async {
    return await get('/passengers/$passengerId/tickets');
  }


  Future<Map<String, dynamic>> getPassengerByPassport(String passportNumber) async {
    return await get('/passengers/passport/$passportNumber');
  }

// Flights API
  Future<Map<String, dynamic>> getFlightByNumber(String flightNumber) async {
    return await get('/flights/flight-number/$flightNumber');
  }
}
