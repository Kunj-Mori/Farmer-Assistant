import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/commodity_data.dart';
import '../constants/app_data.dart';

class CommodityService {
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
} 