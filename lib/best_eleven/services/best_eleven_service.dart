import 'dart:convert';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:http/http.dart' as http;
import '../models/best_eleven_models.dart';

class BestElevenService {
  // TODO: Replace the URL with your app's URL and don't forget to add a trailing slash (/)!
  // To connect Android emulator with Django on localhost, use URL http://10.0.2.2:8000
  // If you using chrome, use URL http://localhost:8000
  static const String baseUrl = "http://localhost:8000";

  Future<Map<String, dynamic>> fetchBuilderData(CookieRequest request) async {
    try {
      // Check if user is logged in
      if (!request.loggedIn) {
        throw Exception('User belum login. Silakan login terlebih dahulu.');
      }
      
      // TODO: Replace the URL with your app's URL and don't forget to add a trailing slash (/)!
      // To connect Android emulator with Django on localhost, use URL http://10.0.2.2:8000
      // If you using chrome, use URL http://localhost:8000
      final url = '$baseUrl/best_eleven/api/builder-data/';
      print('Fetching builder data from: $url');
      print('User logged in: ${request.loggedIn}');
      
      final response = await request.get(url);
      
      print('Builder data response type: ${response.runtimeType}');
      print('Builder data response: $response');
      
      if (response == null) {
        throw Exception('Response is null - mungkin tidak terautentikasi atau server error');
      }
      
      // Handle if response is a Map
      if (response is Map<String, dynamic>) {
        // Check if response has error
        if (response.containsKey('error') && response['error'] != null) {
          throw Exception(response['error']);
        }
        
        // Ensure clubs and history exist (even if empty)
        final result = <String, dynamic>{
          'clubs': response['clubs'] ?? [],
          'history': response['history'] ?? [],
        };
        
        print('Parsed builder data - clubs: ${(result['clubs'] as List).length}, history: ${(result['history'] as List).length}');
        return result;
      } 
      // Handle if response is a List (shouldn't happen but just in case)
      else if (response is List) {
        print('Response is a List, not Map. This is unexpected.');
        return {
          'clubs': [],
          'history': [],
        };
      } 
      else {
        print('Response is not a Map or List: ${response.runtimeType}');
        throw Exception('Invalid response format from server: ${response.runtimeType}');
      }
    } catch (e) {
      print('Error in fetchBuilderData: $e');
      print('Stack trace: ${StackTrace.current}');
      
      // Provide more helpful error messages
      String errorMessage = 'Gagal memuat data';
      if (e.toString().contains('Failed host lookup') || e.toString().contains('Connection refused')) {
        errorMessage = 'Tidak dapat terhubung ke server. Pastikan server Django berjalan di $baseUrl';
      } else if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        errorMessage = 'Sesi telah berakhir. Silakan login ulang.';
      } else if (e.toString().contains('404')) {
        errorMessage = 'Endpoint tidak ditemukan. Periksa konfigurasi URL.';
      } else if (e.toString().contains('500')) {
        errorMessage = 'Server error. Periksa log server Django.';
      } else {
        errorMessage = 'Gagal memuat data: $e';
      }
      
      throw Exception(errorMessage);
    }
  }

  Future<List<BestElevenPlayer>> fetchPlayers(CookieRequest request, {int? clubId}) async {
    // TODO: Replace the URL with your app's URL and don't forget to add a trailing slash (/)!
    // To connect Android emulator with Django on localhost, use URL http://10.0.2.2:8000
    // If you using chrome, use URL http://localhost:8000
    String url = '$baseUrl/best_eleven/api/get-players/';
    if (clubId != null) {
      url += '?club_id=$clubId';
    }
    
    try {
      print('Fetching players from: $url');
      final response = await request.get(url);
      
      // Debug: print response to see what we're getting
      print('Fetch Players Response type: ${response.runtimeType}');
      print('Fetch Players Response: $response');
      
      if (response == null) {
        throw Exception('Response is null - mungkin tidak terautentikasi');
      }
      
      // Handle if response is a Map
      if (response is Map<String, dynamic>) {
        // Check if response has error
        if (response['error'] != null) {
          throw Exception(response['error']);
        }
        
        if (response['players'] != null) {
          final playersList = response['players'];
          
          if (playersList is List) {
            print('Found ${playersList.length} players');
            
            if (playersList.isEmpty) {
              print('Players list is empty');
              return [];
            }
            
            return playersList
                .map((p) {
                  try {
                    if (p is Map<String, dynamic>) {
                      return BestElevenPlayer.fromJson(p);
                    } else {
                      print('Player is not a Map: ${p.runtimeType}');
                      throw Exception('Invalid player data format');
                    }
                  } catch (e) {
                    print('Error parsing player: $p, Error: $e');
                    rethrow;
                  }
                })
                .toList();
          } else {
            print('Players is not a List: ${playersList.runtimeType}');
            return [];
          }
        } else {
          print('No players key in response. Keys: ${response.keys}');
          return [];
        }
      } else {
        print('Response is not a Map: ${response.runtimeType}');
        throw Exception('Invalid response format from server');
      }
    } catch (e) {
      print('Error in fetchPlayers: $e');
      print('Stack trace: ${StackTrace.current}');
      throw Exception('Gagal memuat daftar pemain: $e');
    }
  }

  Future<Map<String, dynamic>> saveFormation(CookieRequest request, {
    required String name,
    required String layout,
    required List<Map<String, String>> playerIds, // [{'playerId': 'uuid', 'slotId': 'GK'}, ...]
    int? formationId,
  }) async {
    // Format data sesuai dengan Django API
    final data = {
      'name': name,
      'layout': layout,
      'player_ids': playerIds, // Format: [{'playerId': 'uuid', 'slotId': 'GK'}]
      if (formationId != null) 'formation_id': formationId,
    };

    try {
      // TODO: Replace the URL with your app's URL and don't forget to add a trailing slash (/)!
      // To connect Android emulator with Django on localhost, use URL http://10.0.2.2:8000
      // If you using chrome, use URL http://localhost:8000
      print('Saving formation to: $baseUrl/best_eleven/api/save-formation/');
      print('Formation data: $data');
      print('Player IDs count: ${playerIds.length}');
      
      final response = await request.postJson(
        '$baseUrl/best_eleven/api/save-formation/',
        jsonEncode(data),
      );
      
      print('Save formation response: $response');
      
      if (response != null && response is Map<String, dynamic>) {
        if (response.containsKey('error')) {
          throw Exception(response['error']);
        }
        return response;
      }
      
      throw Exception('Invalid response format');
    } catch (e) {
      print('Error saving formation: $e');
      print('Stack trace: ${StackTrace.current}');
      throw Exception('Gagal menyimpan formasi: $e');
    }
  }

  Future<BestElevenFormation> fetchFormationDetails(CookieRequest request, int id) async {
    try {
      // TODO: Replace the URL with your app's URL and don't forget to add a trailing slash (/)!
      // To connect Android emulator with Django on localhost, use URL http://10.0.2.2:8000
      // If you using chrome, use URL http://localhost:8000
      final url = '$baseUrl/best_eleven/api/formation/$id/';
      print('Fetching formation details from: $url');
      
      final response = await request.get(url);
      
      print('Formation details response type: ${response.runtimeType}');
      print('Formation details response: $response');
      
      if (response == null) {
        throw Exception('Response is null - formasi tidak ditemukan atau tidak terautentikasi');
      }
      
      if (response is Map<String, dynamic>) {
        // Check for error
        if (response.containsKey('error') && response['error'] != null) {
          throw Exception(response['error']);
        }
        
        return BestElevenFormation.fromJson(response);
      } else {
        throw Exception('Invalid response format: ${response.runtimeType}');
      }
    } catch (e) {
      print('Error fetching formation details: $e');
      print('Stack trace: ${StackTrace.current}');
      throw Exception('Gagal memuat detail formasi: $e');
    }
  }

  Future<bool> deleteFormation(CookieRequest request, int id) async {
    try {
      // TODO: Replace the URL with your app's URL and don't forget to add a trailing slash (/)!
      // To connect Android emulator with Django on localhost, use URL http://10.0.2.2:8000
      // If you using chrome, use URL http://localhost:8000
      // CookieRequest doesn't have delete method, so we use http package directly
      // Since Django endpoint uses @csrf_exempt, we don't need CSRF token
      // But we need session cookie for @login_required
      
      final url = Uri.parse('$baseUrl/best_eleven/api/formation/$id/');
      
      // Make a request using CookieRequest first to ensure session is active
      // This ensures cookies are set in the browser/app
      await request.get('$baseUrl/best_eleven/api/builder-data/');
      
      // Use http client
      final client = http.Client();
      
      try {
        // Make DELETE request
        // Note: Cookies should be automatically included by the browser/app
        // For web, cookies are managed by the browser
        // For mobile, we might need to handle cookies differently
        final response = await client.delete(
          url,
          headers: {
            'Content-Type': 'application/json',
          },
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception('Request timeout');
          },
        );

        if (response.statusCode == 204 || response.statusCode == 200) {
          return true;
        } else {
          final errorBody = response.body.isNotEmpty 
              ? response.body 
              : 'Unknown error';
          throw Exception('Failed to delete: ${response.statusCode} - $errorBody');
        }
      } finally {
        client.close();
      }
    } catch (e) {
      throw Exception('Gagal menghapus formasi: $e');
    }
  }
}
