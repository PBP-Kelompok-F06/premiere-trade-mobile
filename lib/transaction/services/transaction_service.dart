import 'dart:convert';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import '../models/transaction_model.dart';

class TransactionService {
  final CookieRequest request;
  static const String baseUrl = 'https://walyulahdi-maulana-premieretrade.pbp.cs.ui.ac.id/player_transaction';

  TransactionService(this.request);

  // Fetch players for sale
  Future<List<PlayerForSale>> fetchPlayersForSale() async {
    try {
      final response = await request.get('$baseUrl/api/list_pemain_dijual/');
      
      if (response == null) {
        throw Exception('No response from server');
      }

      // Check if response is HTML (error page)
      if (response is String && response.contains('<!DOCTYPE')) {
        throw Exception('Server returned HTML error page. Please check your authentication.');
      }

      if (response is List) {
        return (response as List)
            .map((json) => PlayerForSale.fromJson(Map<String, dynamic>.from(json)))
            .toList();
      }

      throw Exception('Unexpected response format');
    } catch (e) {
      throw Exception('Failed to fetch players: ${e.toString()}');
    }
  }

  // Fetch my players
  Future<List<MyPlayer>> fetchMyPlayers() async {
    try {
      final response = await request.get('$baseUrl/api/list_pemain_saya/');
      
      if (response == null) {
        throw Exception('No response from server');
      }

      // Check if response is HTML (error page)
      if (response is String && response.contains('<!DOCTYPE')) {
        throw Exception('Server returned HTML error page. Please check your authentication.');
      }

      if (response is Map && response.containsKey('error')) {
        throw Exception(response['error']);
      }

      if (response is List) {
        return (response as List)
            .map((json) => MyPlayer.fromJson(Map<String, dynamic>.from(json)))
            .toList();
      }

      throw Exception('Unexpected response format');
    } catch (e) {
      throw Exception('Failed to fetch my players: ${e.toString()}');
    }
  }

  // Sell player
  Future<Map<String, dynamic>> sellPlayer(String playerId) async {
    try {
      final response = await request.post(
        '$baseUrl/jual/$playerId/',
        {},
      );

      if (response == null) {
        throw Exception('No response from server');
      }

      // Check if response is HTML (error page)
      if (response is String && response.contains('<!DOCTYPE')) {
        throw Exception('Server returned HTML error page. Please check your authentication and club configuration.');
      }

      final decoded = Map<String, dynamic>.from(response);
      
      if (decoded['success'] == true) {
        return {
          'success': true,
          'message': decoded['message'] ?? 'Player listed for sale successfully',
        };
      } else {
        return {
          'success': false,
          'message': decoded['message'] ?? 'Failed to sell player',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  // Cancel sell player
  Future<Map<String, dynamic>> cancelSellPlayer(String playerId) async {
    try {
      final response = await request.post(
        '$baseUrl/batalkan-jual/$playerId/',
        {},
      );

      if (response == null) {
        throw Exception('No response from server');
      }

      // Check if response is HTML (error page)
      if (response is String && response.contains('<!DOCTYPE')) {
        throw Exception('Server returned HTML error page. Please check your authentication.');
      }

      final decoded = Map<String, dynamic>.from(response);
      
      if (decoded['success'] == true) {
        return {
          'success': true,
          'message': decoded['message'] ?? 'Sale cancelled successfully',
        };
      } else {
        return {
          'success': false,
          'message': decoded['message'] ?? 'Failed to cancel sale',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  // Buy player
  Future<Map<String, dynamic>> buyPlayer(String playerId) async {
    try {
      final response = await request.post(
        '$baseUrl/beli/$playerId/',
        {},
      );

      if (response == null) {
        throw Exception('No response from server');
      }

      // Check if response is HTML (error page)
      if (response is String && response.contains('<!DOCTYPE')) {
        throw Exception('Server returned HTML error page. Please check your authentication.');
      }

      final decoded = Map<String, dynamic>.from(response);
      
      if (decoded['success'] == true) {
        return {
          'success': true,
          'message': decoded['message'] ?? 'Player purchased successfully',
        };
      } else {
        return {
          'success': false,
          'message': decoded['message'] ?? 'Failed to buy player',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  // Fetch negotiation inbox
  Future<Map<String, List<Negotiation>>> fetchNegotiationInbox() async {
    try {
      final response = await request.get('$baseUrl/inbox/json');
      
      if (response == null) {
        throw Exception('No response from server');
      }

      // Check if response is HTML (error page)
      if (response is String && response.contains('<!DOCTYPE')) {
        throw Exception('Server returned HTML error page. Please check your authentication.');
      }

      final decoded = Map<String, dynamic>.from(response);
      
      final receivedOffers = (decoded['received_offers'] as List? ?? [])
          .map((json) => Negotiation.fromJson(Map<String, dynamic>.from(json)))
          .toList();

      final sentOffers = (decoded['sent_offers'] as List? ?? [])
          .map((json) => Negotiation.fromJson(Map<String, dynamic>.from(json)))
          .toList();

      return {
        'received': receivedOffers,
        'sent': sentOffers,
      };
    } catch (e) {
      throw Exception('Failed to fetch negotiation inbox: ${e.toString()}');
    }
  }

  // Send negotiation
  Future<Map<String, dynamic>> sendNegotiation(String playerId, double offeredPrice) async {
    try {
      // Ensure playerId is a string (handle UUID format)
      final cleanPlayerId = playerId.toString();
      
      // Use postJson with jsonEncode to ensure proper JSON serialization
      final response = await request.postJson(
        '$baseUrl/send-negotiation/$cleanPlayerId/',
        jsonEncode({
          'offered_price': offeredPrice,
        }),
      );

      if (response == null) {
        throw Exception('No response from server');
      }

      // Check if response is HTML (error page)
      if (response is String && response.contains('<!DOCTYPE')) {
        throw Exception('Server returned HTML error page. Please check your authentication.');
      }

      // Handle both Map and dynamic response
      Map<String, dynamic> decoded;
      if (response is Map) {
        // Convert all values to proper types
        decoded = {};
        response.forEach((key, value) {
          if (value is int || value is double || value is bool || value == null) {
            decoded[key.toString()] = value;
          } else {
            decoded[key.toString()] = value.toString();
          }
        });
      } else if (response is String) {
        // Try to parse as JSON string
        try {
          final jsonDecoded = json.decode(response);
          decoded = Map<String, dynamic>.from(jsonDecoded);
        } catch (e) {
          decoded = {'success': false, 'message': 'Failed to parse response: $response'};
        }
      } else {
        decoded = {'success': false, 'message': 'Unexpected response format: ${response.runtimeType}'};
      }
      
      // Safely extract success and message
      final success = decoded['success'] == true || decoded['success'] == 'true';
      final message = decoded['message']?.toString() ?? 
                     (success ? 'Negotiation sent successfully' : 'Failed to send negotiation');
      
      return {
        'success': success,
        'message': message,
      };
    } catch (e, stackTrace) {
      print('Error in sendNegotiation: $e');
      print('Stack trace: $stackTrace');
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  // Respond to negotiation
  Future<Map<String, dynamic>> respondNegotiation(int negotiationId, String action) async {
    try {
      final response = await request.post(
        '$baseUrl/negotiation/$negotiationId/$action/',
        {},
      );

      if (response == null) {
        throw Exception('No response from server');
      }

      // Check if response is HTML (error page)
      if (response is String && response.contains('<!DOCTYPE')) {
        throw Exception('Server returned HTML error page. Please check your authentication.');
      }

      final decoded = Map<String, dynamic>.from(response);
      
      if (decoded['success'] == true) {
        return {
          'success': true,
          'message': decoded['message'] ?? 'Negotiation responded successfully',
        };
      } else {
        return {
          'success': false,
          'message': decoded['message'] ?? 'Failed to respond to negotiation',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  // Fetch transaction history
  Future<List<Transaction>> fetchTransactionHistory() async {
    try {
      final response = await request.get('$baseUrl/api/transaction_history/');
      
      if (response == null) {
        throw Exception('No response from server');
      }

      // Check if response is HTML (error page)
      if (response is String && response.contains('<!DOCTYPE')) {
        throw Exception('Server returned HTML error page. Please check your authentication.');
      }

      if (response is List) {
        return (response as List)
            .map((json) => Transaction.fromJson(Map<String, dynamic>.from(json)))
            .toList();
      }

      throw Exception('Unexpected response format');
    } catch (e) {
      throw Exception('Failed to fetch transaction history: ${e.toString()}');
    }
  }
}

