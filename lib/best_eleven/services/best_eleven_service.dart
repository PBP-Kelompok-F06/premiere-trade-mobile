import 'dart:convert';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import '../models/best_eleven_models.dart';

class BestElevenService {
  final CookieRequest request;
  // To connect Android emulator with Django on localhost, use URL http://10.0.2.2:8000
  // If you using chrome, use URL http://localhost:8000
  final String baseUrl = "http://localhost:8000";

  BestElevenService(this.request);

  // Fetch initial data (clubs & history) - sesuai dengan api_builder_data
  Future<Map<String, dynamic>> fetchBuilderData() async {
    try {
      final url = '$baseUrl/best_eleven/api/builder-data/';
      print('Fetching builder data from: $url');
      final response = await request.get(url);
      
      if (response == null) {
        print('Response is null');
        return {'clubs': [], 'history': []};
      }
      
      // Validasi response bukan HTML/error page
      if (response is String && response.contains('<!DOCTYPE')) {
        print('Error: Received HTML instead of JSON. Endpoint may not exist or authentication failed.');
        return {'clubs': [], 'history': []};
      }
      
      // Debug: print response structure
      print('Response type: ${response.runtimeType}');
      if (response is Map) {
        print('Response keys: ${response.keys.toList()}');
      }
      
      List<BestElevenClub> clubs = [];
      if (response is Map) {
        // Cek berbagai kemungkinan key untuk clubs
        var clubsData = response['clubs'] ?? response['club'] ?? response['clubs_list'];
        if (clubsData != null && clubsData is List) {
          print('Found ${clubsData.length} clubs in response');
          for (var data in clubsData) {
            if (data != null) {
              try {
                print('Parsing club: $data');
                clubs.add(BestElevenClub.fromJson(data));
              } catch (e) {
                print('Error parsing club: $e');
                print('Club data: $data');
              }
            }
          }
        } else {
          print('No clubs found in response. Available keys: ${response.keys.toList()}');
        }
      }
      
      List<BestElevenFormation> history = [];
      if (response is Map) {
        // Cek berbagai kemungkinan key untuk history
        var historyData = response['history'] ?? response['formations'] ?? response['formation_list'];
        if (historyData != null && historyData is List) {
          print('Found ${historyData.length} formations in history');
          for (var data in historyData) {
            if (data != null) {
              try {
                history.add(BestElevenFormation.fromJson(data));
              } catch (e) {
                print('Error parsing formation: $e');
                print('Formation data: $data');
              }
            }
          }
        } else {
          print('No history found in response. Available keys: ${response.keys.toList()}');
        }
      }
      
      print('Successfully parsed ${clubs.length} clubs and ${history.length} formations');
      return {
        'clubs': clubs,
        'history': history,
      };
    } catch (e) {
      print('Error fetching builder data: $e');
      if (e.toString().contains('<!DOCTYPE') || e.toString().contains('Unexpected token')) {
        print('Error: API returned HTML instead of JSON. Please check:');
        print('1. Django server is running on $baseUrl');
        print('2. Endpoint /best_eleven/api/builder-data/ exists');
        print('3. User is authenticated');
      }
      return {
        'clubs': <BestElevenClub>[],
        'history': <BestElevenFormation>[],
      };
    }
  }

  // Fetch semua formasi milik user yang sedang login
  Future<List<BestElevenFormation>> fetchFormations() async {
    try {
      final url = '$baseUrl/best_eleven/json-flutter/';
      print('Fetching formations from: $url');
      final response = await request.get(url);
      
      if (response == null) {
        print('Response is null');
        return [];
      }
      
      // Validasi response bukan HTML/error page
      if (response is String && response.contains('<!DOCTYPE')) {
        print('Error: Received HTML instead of JSON. Endpoint may not exist or authentication failed.');
        return [];
      }
      
      List<BestElevenFormation> formations = [];
      if (response is List) {
        for (var data in response) {
          if (data != null) {
            try {
              formations.add(BestElevenFormation.fromJson(data));
            } catch (e) {
              print('Error parsing formation: $e');
            }
          }
        }
      }
      return formations;
    } catch (e) {
      print('Error fetching formations: $e');
      if (e.toString().contains('<!DOCTYPE') || e.toString().contains('Unexpected token')) {
        print('Error: API returned HTML instead of JSON. Please check:');
        print('1. Django server is running on $baseUrl');
        print('2. Endpoint /best_eleven/json-flutter/ exists');
        print('3. User is authenticated');
      }
      return [];
    }
  }

  // Fetch detail formasi berdasarkan ID - sesuai dengan api_get_formation_details
  Future<BestElevenFormation?> fetchFormationById(int formationId) async {
    try {
      final url = '$baseUrl/best_eleven/api/formation/$formationId/';
      print('Fetching formation detail from: $url');
      final response = await request.get(url);
      
      if (response == null) {
        print('Response is null');
        return null;
      }
      
      // Validasi response bukan HTML/error page
      if (response is String && response.contains('<!DOCTYPE')) {
        print('Error: Received HTML instead of JSON. Endpoint may not exist or authentication failed.');
        return null;
      }
      
      if (response is Map && response['error'] != null) {
        print('API returned error: ${response['error']}');
        return null;
      }
      
      return BestElevenFormation.fromJson(response);
    } catch (e) {
      print('Error fetching formation by id: $e');
      if (e.toString().contains('<!DOCTYPE') || e.toString().contains('Unexpected token')) {
        print('Error: API returned HTML instead of JSON. Please check endpoint and authentication.');
      }
      return null;
    }
  }

  // Save formasi (create atau update) - sesuai dengan api_save_formation
  Future<Map<String, dynamic>> saveFormation({
    required String name,
    required String layout,
    int? formationId,
    required List<Map<String, dynamic>> playerIds, // List of {slotId: String, playerId: int}
  }) async {
    try {
      final payload = {
        'name': name,
        'layout': layout,
        if (formationId != null) 'formation_id': formationId,
        'player_ids': playerIds,
      };
      
      final url = '$baseUrl/best_eleven/api/save-formation/';
      print('Saving formation to: $url');
      print('Payload: $payload');
      
      // Try to get CSRF token first if needed
      // CookieRequest.postJson should handle CSRF automatically, but let's try explicit approach
      try {
        final response = await request.postJson(
          url,
          jsonEncode(payload),
        );
        
        if (response == null) {
          print('Response is null - might be a 204 No Content or error');
          return {'error': 'No response from server. Please check if you are authenticated.'};
        }
        
        // Check if response is a string (HTML error page)
        if (response is String) {
          if (response.contains('<!DOCTYPE') || response.contains('<html')) {
            print('Error: Received HTML instead of JSON.');
            print('Response preview: ${response.substring(0, response.length > 200 ? 200 : response.length)}');
            
            // Try to extract error message from HTML
            String errorMsg = 'Server returned HTML instead of JSON. ';
            if (response.contains('403')) {
              errorMsg += '403 Forbidden - Please check authentication and CSRF token. ';
            } else if (response.contains('CSRF')) {
              errorMsg += 'CSRF verification failed. ';
            } else if (response.contains('login') || response.contains('Login')) {
              errorMsg += 'Please log in again. ';
            }
            errorMsg += 'Check Django endpoint configuration.';
            
            return {'error': errorMsg};
          }
          // If response is a string but not HTML, might be an error message
          return {'error': response};
        }
        
        // Validasi response bukan HTML/error page
        if (response is Map) {
          // Cast to Map<String, dynamic> for type safety
          final responseMap = Map<String, dynamic>.from(response);
          
          if (responseMap['error'] != null) {
            print('API returned error: ${responseMap['error']}');
            return {'error': responseMap['error']};
          }
          
          // Check for common error patterns
          if (responseMap['detail'] != null) {
            return {'error': responseMap['detail'].toString()};
          }
          
          if (responseMap['message'] != null && responseMap['message'].toString().toLowerCase().contains('error')) {
            return {'error': responseMap['message'].toString()};
          }
          
          // Success response
          return responseMap;
        }
        
        // If response is not a Map, try to cast it
        if (response != null) {
          return Map<String, dynamic>.from({'error': 'Unexpected response type: ${response.runtimeType}'});
        }
        
        return {'error': 'Null response from server'};
      } catch (postError) {
        print('PostJson error: $postError');
        
        // Check if it's a 403 or authentication error
        final errorStr = postError.toString().toLowerCase();
        if (errorStr.contains('403') || errorStr.contains('forbidden')) {
          return {
            'error': '403 Forbidden: Authentication failed or CSRF token invalid. Please ensure:\n'
                '1. You are logged in\n'
                '2. Django endpoint has @csrf_exempt or proper CSRF handling\n'
                '3. Session cookies are valid'
          };
        }
        
        if (errorStr.contains('401') || errorStr.contains('unauthorized')) {
          return {'error': '401 Unauthorized: Please log in again.'};
        }
        
        throw postError; // Re-throw to outer catch
      }
    } catch (e, stackTrace) {
      print('Error saving formation: $e');
      print('Stack trace: $stackTrace');
      
      String errorMessage = 'Error menyimpan formasi: $e';
      
      if (e.toString().contains('<!DOCTYPE') || e.toString().contains('Unexpected token')) {
        errorMessage = 'Server returned HTML instead of JSON. Please check:\n'
            '1. Django server is running on $baseUrl\n'
            '2. Endpoint /best_eleven/api/save-formation/ exists\n'
            '3. User is authenticated\n'
            '4. Endpoint uses @csrf_exempt or handles CSRF properly';
      } else if (e.toString().contains('403')) {
        errorMessage = '403 Forbidden: Access denied. Please check:\n'
            '1. You are logged in\n'
            '2. CSRF token is valid\n'
            '3. Django endpoint configuration allows this request';
      }
      
      return {'error': errorMessage};
    }
  }

  // Create formasi baru (legacy method)
  Future<Map<String, dynamic>> createFormation({
    required String name,
    required String layout,
    required Map<String, int?> players, // Map position -> player_id
  }) async {
    List<Map<String, dynamic>> playerIds = players.entries
        .where((e) => e.value != null)
        .map((e) => {'slotId': e.key, 'playerId': e.value!})
        .toList();
    
    return saveFormation(
      name: name,
      layout: layout,
      playerIds: playerIds,
    );
  }

  // Update formasi
  Future<Map<String, dynamic>> updateFormation({
    required int formationId,
    String? name,
    String? layout,
    Map<String, int?>? players,
  }) async {
    try {
      Map<String, dynamic> data = {};
      if (name != null) data['name'] = name;
      if (layout != null) data['layout'] = layout;
      if (players != null) data['players'] = players;

      final url = '$baseUrl/best_eleven/edit-flutter/$formationId/';
      print('Updating formation at: $url');
      final response = await request.postJson(
        url,
        jsonEncode(data),
      );
      
      if (response == null) {
        print('Response is null');
        return {'error': 'No response from server'};
      }
      
      // Validasi response bukan HTML/error page
      if (response is String && response.contains('<!DOCTYPE')) {
        print('Error: Received HTML instead of JSON. Endpoint may not exist or authentication failed.');
        return {'error': 'Server returned HTML instead of JSON. Please check endpoint and authentication.'};
      }
      
      return response;
    } catch (e) {
      print('Error updating formation: $e');
      if (e.toString().contains('<!DOCTYPE') || e.toString().contains('Unexpected token')) {
        print('Error: API returned HTML instead of JSON. Please check endpoint and authentication.');
      }
      return {'error': e.toString()};
    }
  }

  // Delete formasi - sesuai dengan DELETE endpoint
  // Django endpoint: /best_eleven/api/formation/<int:pk>/ dengan method DELETE
  // Django mengembalikan status 204 untuk success
  Future<bool> deleteFormation(int formationId) async {
    try {
      final url = '$baseUrl/best_eleven/api/formation/$formationId/';
      print('Deleting formation at: $url');
      
      // Karena pbp_django_auth mungkin tidak support DELETE method langsung,
      // kita gunakan workaround dengan postJson
      // Django dengan @csrf_exempt akan menerima request ini
      try {
        final response = await request.postJson(
          url,
          jsonEncode({'_method': 'DELETE'}),
        );
        
        // Django mengembalikan status 204 (No Content) untuk success
        // Jika response null, kemungkinan besar success (204 tidak punya body)
        if (response == null) {
          print('Formation deleted successfully (204 - No Content)');
          return true;
        }
        
        // Validasi response bukan HTML/error page
        if (response is String && response.contains('<!DOCTYPE')) {
          print('Error: Received HTML instead of JSON.');
          return false;
        }
        
        // Jika response adalah Map, cek apakah ada error
        if (response is Map) {
          if (response['error'] != null) {
            print('Delete failed: ${response['error']}');
            return false;
          }
          // Jika tidak ada error, anggap success
          return true;
        }
        
        // Jika response bukan null, bukan HTML, dan bukan Map dengan error, anggap success
        return true;
      } catch (e) {
        // Jika error terjadi, coba cek apakah itu karena 204 (No Content)
        // Beberapa HTTP client menganggap 204 sebagai error karena tidak ada body
        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('204') || errorStr.contains('no content')) {
          print('Formation deleted successfully (204 detected in error)');
          return true;
        }
        
        // Cek jika error karena format exception (bisa jadi 204 yang di-parse sebagai JSON)
        if (e.toString().contains('FormatException') || 
            e.toString().contains('Unexpected end of input')) {
          print('Formation deleted successfully (204 - empty response)');
          return true;
        }
        
        print('Error deleting formation: $e');
        if (errorStr.contains('<!doctype') || errorStr.contains('unexpected token')) {
          print('Error: API returned HTML instead of JSON. Please check endpoint and authentication.');
        }
        return false;
      }
    } catch (e) {
      print('Error deleting formation: $e');
      final errorStr = e.toString().toLowerCase();
      
      // Cek jika error karena format exception (bisa jadi 204 yang di-parse sebagai JSON)
      if (e.toString().contains('FormatException') || 
          e.toString().contains('Unexpected end of input')) {
        print('Formation deleted successfully (204 - empty response)');
        return true;
      }
      
      if (errorStr.contains('<!doctype') || errorStr.contains('unexpected token')) {
        print('Error: API returned HTML instead of JSON. Please check endpoint and authentication.');
      }
      return false;
    }
  }

  // Fetch daftar pemain yang tersedia - sesuai dengan api_get_players
  Future<List<BestElevenPlayer>> fetchPlayers({
    String? position,
    int? clubId,
  }) async {
    try {
      String url = '$baseUrl/best_eleven/api/get-players/';
      List<String> params = [];
      if (position != null) params.add('position=$position');
      if (clubId != null) params.add('club_id=$clubId');
      if (params.isNotEmpty) url += '?${params.join('&')}';

      print('Fetching players from: $url');
      final response = await request.get(url);
      
      if (response == null) {
        print('Response is null');
        return [];
      }
      
      // Validasi response bukan HTML/error page
      if (response is String && response.contains('<!DOCTYPE')) {
        print('Error: Received HTML instead of JSON. Endpoint may not exist or authentication failed.');
        return [];
      }
      
      if (response is Map && response['error'] != null) {
        print('API returned error: ${response['error']}');
        return [];
      }
      
      // Debug: print response structure
      print('Response type: ${response.runtimeType}');
      if (response is Map) {
        print('Response keys: ${response.keys.toList()}');
      }
      
      List<BestElevenPlayer> players = [];
      if (response is Map) {
        // Cek berbagai kemungkinan key untuk players
        var playersData = response['players'] ?? response['player'] ?? response['players_list'] ?? response['data'];
        if (playersData != null && playersData is List) {
          print('Found ${playersData.length} players in response');
          for (var data in playersData) {
            if (data != null) {
              try {
                print('Parsing player: ${data['name'] ?? data['id'] ?? 'unknown'}');
                players.add(BestElevenPlayer.fromJson(data));
              } catch (e) {
                print('Error parsing player: $e');
                print('Player data: $data');
              }
            }
          }
        } else {
          print('No players found in response. Available keys: ${response.keys.toList()}');
        }
      } else if (response is List) {
        // Fallback jika response langsung list
        print('Response is a list with ${response.length} items');
        for (var data in response) {
          if (data != null) {
            try {
              players.add(BestElevenPlayer.fromJson(data));
            } catch (e) {
              print('Error parsing player: $e');
              print('Player data: $data');
            }
          }
        }
      }
      print('Successfully fetched ${players.length} players');
      return players;
    } catch (e) {
      print('Error fetching players: $e');
      if (e.toString().contains('<!DOCTYPE') || e.toString().contains('Unexpected token')) {
        print('Error: API returned HTML instead of JSON. Please check:');
        print('1. Django server is running on $baseUrl');
        print('2. Endpoint /best_eleven/api/get-players/ exists');
        print('3. User is authenticated');
      }
      return [];
    }
  }
}

