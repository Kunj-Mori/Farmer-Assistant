class CommodityData {
  final String state;
  final String district;
  final String market;
  final String commodity;
  final String variety;
  final String grade;
  final String arrivalDate;
  final double minPrice;
  final double maxPrice;
  final double modalPrice;
  final String commodityCode;

  CommodityData({
    required this.state,
    required this.district,
    required this.market,
    required this.commodity,
    required this.variety,
    required this.grade,
    required this.arrivalDate,
    required this.minPrice,
    required this.maxPrice,
    required this.modalPrice,
    required this.commodityCode,
  });

  factory CommodityData.fromJson(Map<String, dynamic> json) {
    return CommodityData(
      state: json['State'] ?? '',
      district: json['District'] ?? '',
      market: json['Market'] ?? '',
      commodity: json['Commodity'] ?? '',
      variety: json['Variety'] ?? '',
      grade: json['Grade'] ?? '',
      arrivalDate: json['Arrival_Date'] ?? '',
      minPrice: double.tryParse(json['Min_Price']?.toString() ?? '0') ?? 0.0,
      maxPrice: double.tryParse(json['Max_Price']?.toString() ?? '0') ?? 0.0,
      modalPrice: double.tryParse(json['Modal_Price']?.toString() ?? '0') ?? 0.0,
      commodityCode: json['Commodity_Code'] ?? '',
    );
  }
} 