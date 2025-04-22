import 'package:flutter/material.dart';
import '../services/commodity_service.dart';
import '../models/commodity_data.dart';

class CommodityScreen extends StatefulWidget {
  const CommodityScreen({super.key});

  @override
  State<CommodityScreen> createState() => _CommodityScreenState();
}

class _CommodityScreenState extends State<CommodityScreen> {
  final CommodityService _commodityService = CommodityService();
  bool _isLoading = false;
  
  List<String> _states = [];
  List<String> _districts = [];
  List<String> _commodities = [];
  List<CommodityData>? _prices;
  
  String? _selectedState;
  String? _selectedDistrict;
  String? _selectedCommodity;
  
  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }
  
  Future<void> _loadInitialData() async {
    try {
      final states = await _commodityService.getStates();
      final commodities = await _commodityService.getCommodities();
      
      setState(() {
        _states = states;
        _commodities = commodities;
      });
    } catch (e) {
      _showError('Error loading initial data');
    }
  }
  
  Future<void> _loadDistricts(String state) async {
    try {
      final districts = await _commodityService.getDistricts(state);
      setState(() {
        _districts = districts;
        _selectedDistrict = null;
      });
    } catch (e) {
      _showError('Error loading districts');
    }
  }
  
  Future<void> _searchPrices() async {
    if (_selectedState == null || _selectedDistrict == null) {
      _showError('Please select both state and district');
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final prices = await _commodityService.getCommodityPrices(
        state: _selectedState!,
        district: _selectedDistrict!,
        commodity: _selectedCommodity,
      );
      
      setState(() {
        _prices = prices;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error loading prices');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showCommodityDetails(CommodityData commodity) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  commodity.commodity,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _buildDetailCard(
                  title: 'Price Information',
                  content: Column(
                    children: [
                      _buildDetailRow('Modal Price', '₹${commodity.modalPrice}/quintal'),
                      const Divider(),
                      _buildDetailRow('Minimum Price', '₹${commodity.minPrice}/quintal'),
                      const Divider(),
                      _buildDetailRow('Maximum Price', '₹${commodity.maxPrice}/quintal'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildDetailCard(
                  title: 'Market Information',
                  content: Column(
                    children: [
                      _buildDetailRow('Market', commodity.market),
                      const Divider(),
                      _buildDetailRow('State', _selectedState ?? 'N/A'),
                      const Divider(),
                      _buildDetailRow('District', _selectedDistrict ?? 'N/A'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildDetailCard(
                  title: 'Additional Details',
                  content: Column(
                    children: [
                      _buildDetailRow('Variety', commodity.variety),
                      const Divider(),
                      _buildDetailRow('Grade', commodity.grade),
                      const Divider(),
                      _buildDetailRow('Arrival Date', commodity.arrivalDate),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard({required String title, required Widget content}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Market Prices'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedState,
                      decoration: const InputDecoration(
                        labelText: 'Select State',
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      items: _states.map((state) {
                        return DropdownMenuItem(
                          value: state,
                          child: Text(state),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedState = value;
                          _selectedDistrict = null;
                          _prices = null;
                        });
                        if (value != null) {
                          _loadDistricts(value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedDistrict,
                      decoration: const InputDecoration(
                        labelText: 'Select District',
                        prefixIcon: Icon(Icons.location_city),
                      ),
                      items: _districts.map((district) {
                        return DropdownMenuItem(
                          value: district,
                          child: Text(district),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedDistrict = value;
                          _prices = null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedCommodity,
                      decoration: const InputDecoration(
                        labelText: 'Select Commodity (Optional)',
                        prefixIcon: Icon(Icons.shopping_basket),
                      ),
                      items: _commodities.map((commodity) {
                        return DropdownMenuItem(
                          value: commodity,
                          child: Text(commodity),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCommodity = value;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _searchPrices,
                      icon: _isLoading 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.search),
                      label: Text(_isLoading ? 'Searching...' : 'Search Prices'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_prices != null && _prices!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0, bottom: 16.0),
                    child: Text(
                      'Current Market Prices',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _prices!.length,
                    itemBuilder: (context, index) {
                      final price = _prices![index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () => _showCommodityDetails(price),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        price.commodity,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.store, size: 16),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: Text(
                                              'Market: ${price.market}',
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.calendar_today, size: 16),
                                          const SizedBox(width: 8),
                                          Text('Date: ${price.arrivalDate}'),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '₹${price.modalPrice}',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'per quintal',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            if (_prices != null && _prices!.isEmpty)
              const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 48,
                          color: Colors.orange,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No price data available',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Try selecting different criteria',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
} 