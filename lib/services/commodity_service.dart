import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/commodity_data.dart';
import '../constants/app_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CommodityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String apiKey = dotenv.env['DATA_GOV_API_KEY'] ?? '';
  final String baseUrl = 'https://api.data.gov.in/resource';
  final String resourceId = '35985678-0d79-46b4-9ed6-6f13308a1d24';

  Future<List<String>> getStates() async {
    return AppData.states;
  }

  Future<List<String>> getDistricts(String state) async {
    return AppData.getDistricts(state);
  }

  Future<List<String>> getCommodities() async {
    return AppData.commodities;
  }

  Future<List<CommodityData>> getCommodityPrices({
    required String state,
    required String district,
    String? commodity,
  }) async {
    try {
      String url = '$baseUrl/$resourceId?api-key=$apiKey&format=json';
      
      // Add filters
      url += '&filters[State.keyword]=$state';
      url += '&filters[District.keyword]=$district';
      if (commodity != null && commodity.isNotEmpty) {
        url += '&filters[Commodity.keyword]=$commodity';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['records'] != null) {
          return (data['records'] as List)
              .map((record) => CommodityData.fromJson(record))
              .toList();
        }
        return [];
      } else {
        throw Exception('Failed to load commodity prices: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting commodity prices: $e');
      rethrow;
    }
  }

  Future<List<CommodityData>> getPriceHistory({
    required String commodity,
    required String state,
    required String district,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      String url = '$baseUrl/$resourceId?api-key=$apiKey&format=json';
      
      // Add filters
      url += '&filters[State.keyword]=$state';
      url += '&filters[District.keyword]=$district';
      url += '&filters[Commodity.keyword]=$commodity';
      
      // Add date range filters if API supports it
      // Note: Modify these parameters based on actual API documentation
      url += '&filters[Arrival_Date.gte]=${_formatDate(startDate)}';
      url += '&filters[Arrival_Date.lte]=${_formatDate(endDate)}';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['records'] != null) {
          return (data['records'] as List)
              .map((record) => CommodityData.fromJson(record))
              .toList();
        }
        return [];
      } else {
        throw Exception('Failed to load price history: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting price history: $e');
      rethrow;
    }
  }

  String _formatDate(DateTime date) {
    // Format date as required by the API (dd/MM/yyyy)
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<List<Map<String, dynamic>>> getLocalCommodities() async {
    try {
      final QuerySnapshot snapshot = await _firestore.collection('commodities')
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print('Error getting local commodities: $e');
      return [];
    }
  }

  Future<void> updateCommodity(String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('commodities').doc(id).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating commodity: $e');
      rethrow;
    }
  }

  Future<void> addCommodity(Map<String, dynamic> data) async {
    try {
      await _firestore.collection('commodities').add({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding commodity: $e');
      rethrow;
    }
  }

  Future<void> deleteCommodity(String id) async {
    try {
      await _firestore.collection('commodities').doc(id).delete();
    } catch (e) {
      print('Error deleting commodity: $e');
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getCommoditiesStream() {
    return _firestore.collection('commodities')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    });
  }

  Future<List<Map<String, dynamic>>> getAPICommodities() async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/$resourceId?api-key=$apiKey&format=json&limit=100',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final records = data['records'] as List;
        return records.map((record) => record as Map<String, dynamic>).toList();
      }
      
      throw 'Failed to load commodities';
    } catch (e) {
      print('Error getting API commodities: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> searchCommodities(String query) async {
    try {
      final QuerySnapshot snapshot = await _firestore.collection('commodities')
          .where('name', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('name', isLessThan: query.toLowerCase() + 'z')
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print('Error searching commodities: $e');
      return [];
    }
  }
} 