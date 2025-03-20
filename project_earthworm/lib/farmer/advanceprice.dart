import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class AdvancedPricePrediction extends StatefulWidget {
  const AdvancedPricePrediction({Key? key}) : super(key: key);

  @override
  _AdvancedPricePredictionState createState() => _AdvancedPricePredictionState();
}

class _AdvancedPricePredictionState extends State<AdvancedPricePrediction> {
  String? selectedState;
  List<CommodityData> commodities = [];
  CommodityData? selectedCommodity;
  PredictionData? prediction;
  bool isLoading = false;
  String? errorMessage;

  // List of available states
  final List<String> states = [
    'Maharashtra',
    'Karnataka',
    'Kerala',
    'Gujarat',
    'Madhya Pradesh'
  ];

  // API configuration - removed primary API, using only backup API
  final String apiBaseUrl = "https://market-api-m222.onrender.com/api/commodities";
  final String geminiApiUrl = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent?key=AIzaSyBHZH-qGsEjnyoKDcpCM-BzfLIr9YdUJkU";
  final String geminiApiKey = "AIzaSyBHZH-qGsEjnyoKDcpCM-BzfLIr9YdUJkU";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Market Price Prediction'),
        backgroundColor: Colors.green.shade700,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.shade50, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // State Selection
                Text(
                  'Select State',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: states.length,
                    itemBuilder: (context, index) {
                      final state = states[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 10.0),
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              selectedState = state;
                              selectedCommodity = null;
                              prediction = null;
                              errorMessage = null;
                            });
                            fetchCommodities(state);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selectedState == state 
                              ? Colors.green.shade700 
                              : Colors.white,
                            foregroundColor: selectedState == state 
                              ? Colors.white 
                              : Colors.green.shade700,
                            elevation: selectedState == state ? 3 : 1,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                              side: BorderSide(
                                color: Colors.green.shade700,
                                width: selectedState == state ? 0 : 1,
                              ),
                            ),
                          ),
                          child: Text(state),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                
                // Loading indicator for commodities
                if (isLoading && selectedCommodity == null)
                  Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(color: Colors.green.shade700),
                        const SizedBox(height: 16),
                        Text('Loading commodities...', 
                          style: TextStyle(color: Colors.green.shade700)),
                      ],
                    ),
                  ),
                
                // Error message
                if (errorMessage != null && selectedCommodity == null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade400),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            errorMessage!,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          color: Colors.red.shade400,
                          onPressed: () {
                            if (selectedState != null) {
                              fetchCommodities(selectedState!);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                
                // Commodities Display
                if (selectedState != null && commodities.isNotEmpty && selectedCommodity == null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Available Commodities',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800,
                            ),
                          ),
                          Text(
                            '${commodities.length} items',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.3,
                        ),
                        itemCount: commodities.length,
                        itemBuilder: (context, index) {
                          final commodity = commodities[index];
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedCommodity = commodity;
                                errorMessage = null;
                              });
                              fetchPrediction(commodity);
                            },
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [Colors.white, Colors.green.shade50],
                                  ),
                                ),
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      commodity.commodity,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold, 
                                        fontSize: 16,
                                        color: Colors.green,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Market: ${commodity.market}',
                                      style: TextStyle(color: Colors.grey.shade700),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Price: ₹${commodity.modalPrice}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Date: ${commodity.arrivalDate}',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
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
                
                // Prediction Details
                if (isLoading && selectedCommodity != null)
                  Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(color: Colors.green.shade700),
                        const SizedBox(height: 16),
                        Text(
                          'Generating price prediction...',
                          style: TextStyle(color: Colors.green.shade700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This may take a moment',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                
                if (selectedCommodity != null && prediction != null)
                  buildPredictionView(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildPredictionView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back button
        ElevatedButton.icon(
          onPressed: () {
            setState(() {
              selectedCommodity = null;
              prediction = null;
            });
          },
          icon: const Icon(Icons.arrow_back),
          label: const Text('Back to Commodities'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.green.shade700,
            elevation: 1,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
              side: BorderSide(color: Colors.green.shade700),
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        // Commodity header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.green.shade500, Colors.green.shade700],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.green.shade200.withOpacity(0.5),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                selectedCommodity!.commodity,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on, color: Colors.white.withOpacity(0.9), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${selectedCommodity!.market}, ${selectedCommodity!.district}',
                      style: TextStyle(color: Colors.white.withOpacity(0.9)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Divider(color: Colors.white.withOpacity(0.2)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  buildPriceColumn('Current Price', '₹${selectedCommodity!.modalPrice}'),
                  buildPriceColumn('Min Price', '₹${selectedCommodity!.minPrice}'),
                  buildPriceColumn('Max Price', '₹${selectedCommodity!.maxPrice}'),
                ],
              ),
              const SizedBox(height: 8),
              Divider(color: Colors.white.withOpacity(0.2)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.white.withOpacity(0.9), size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Last Updated: ${selectedCommodity!.arrivalDate}',
                    style: TextStyle(color: Colors.white.withOpacity(0.9)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        
        // Prediction summary
        Text(
          'Price Prediction Summary',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.green.shade800,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Text(
            prediction!.summary,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Colors.grey.shade800,
            ),
          ),
        ),
        const SizedBox(height: 32),
        
        // Price prediction chart
        Text(
          '30-Day Price Forecast',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.green.shade800,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 300,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: buildPriceChart(),
        ),
        const SizedBox(height: 32),
        
        // Key factors
        Text(
          'Key Factors Affecting Price',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.green.shade800,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: prediction!.factors.length,
            separatorBuilder: (context, index) => Divider(
              color: Colors.grey.shade200,
              height: 1,
            ),
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        prediction!.factors[index],
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 32),
        
        // Weather impact
        buildInfoSection('Weather Impact', prediction!.weatherImpact, Icons.cloud),
        
        // Demand and Supply
        buildInfoSection('Demand & Supply Analysis', prediction!.demandSupply, Icons.trending_up),
        
        const SizedBox(height: 32),
      ],
    );
  }

  Widget buildPriceColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget buildInfoSection(String title, String content, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.green.shade700, size: 24),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Text(
            content,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Colors.grey.shade800,
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget buildPriceChart() {
    final currentPrice = double.parse(selectedCommodity!.modalPrice);

    // Find min and max values for better scaling
    double minPrice = currentPrice;
    double maxPrice = currentPrice;
    
    for (var day in prediction!.dailyPredictions) {
      if (day.price < minPrice) minPrice = day.price;
      if (day.price > maxPrice) maxPrice = day.price;
    }
    
    // Add a small buffer
    minPrice = minPrice * 0.95;
    maxPrice = maxPrice * 1.05;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade200,
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.grey.shade200,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 46,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    '₹${value.toInt()}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value % 5 == 0 || value == 0 || value == 29) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      value == 0 ? 'Now' : 'Day ${value.toInt()}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
        minX: 0,
        maxX: 29,
        minY: minPrice,
        maxY: maxPrice,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((LineBarSpot spot) {
                final day = spot.x.toInt();
                final price = spot.y;
                return LineTooltipItem(
                  day == 0 ? 'Current\n₹$price' : 'Day $day\n₹$price',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
          handleBuiltInTouches: true,
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              FlSpot(0, currentPrice),
              ...prediction!.dailyPredictions.map(
                (day) => FlSpot(
                  day.day.toDouble(),
                  day.price.toDouble(),
                ),
              ),
            ],
            isCurved: true,
            color: Colors.green.shade600,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 3,
                  color: Colors.green.shade600,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Colors.green.shade400.withOpacity(0.3),
                  Colors.green.shade50.withOpacity(0.1),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> fetchCommodities(String state) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      commodities = [];
    });
    
    try {
      // Use only the backup API
      final url = Uri.parse('UrlstateEndpointapiBase$state');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data.isNotEmpty) {
          setState(() {
            commodities = List<CommodityData>.from(
              data.map((item) => CommodityData.fromJson(item))
            );
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = 'No commodities found for $state';
            isLoading = false;
          });
        }
      } else {
        throw Exception('API request failed with status code: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to fetch commodities. Please try again later.';
        isLoading = false;
      });
    }
  }

  Future<void> fetchPrediction(CommodityData commodity) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      prediction = null;
    });
    
    try {
      // Prepare prompt for Gemini API
      final prompt = '''
        Generate a detailed price prediction analysis for apple  in ${selectedState} for the next 30 days. 
        Include factors such as weather patterns, demand and supply dynamics, seasonal trends, and historical price patterns. 
        Current price is price per kg. 
        Format the response as JSON with the following structure: 
        {
          "summary": "text summary of the prediction", 
          "factors": ["factor1", "factor2", "factor3", "factor4", "factor5"], 
          "dailyPredictions": [{"day": 1, "price": value}, {"day": 2, "price": value}, ... for 30 days], 
          "weatherImpact": "detailed analysis of weather impact", 
          "demandSupply": "detailed analysis of demand and supply dynamics"
        }
      ''';
      
      // Make request to Gemini API
      final geminiResponse = await http.post(
        Uri.parse('$geminiApiUrl?key=$geminiApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'contents': [
            {
              'role': 'user',
              'parts': [{'text': prompt}]
            }
          ],
          'generationConfig': {
            'temperature': 0.2,
            'topP': 0.8,
            'topK': 40
          }
        }),
      );
      
      if (geminiResponse.statusCode == 200) {
        final data = json.decode(geminiResponse.body);
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final responseText = data['candidates'][0]['content']['parts'][0]['text'];
          
          // Extract JSON from response
          final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(responseText);
          if (jsonMatch != null) {
            final predictionJson = json.decode(jsonMatch.group(0)!);
            setState(() {
              prediction = PredictionData.fromJson(predictionJson);
              isLoading = false;
            });
          } else {
            throw Exception('Failed to parse prediction data');
          }
        } else {
          throw Exception('No prediction data received');
        }
      } else {
        throw Exception('Gemini API request failed with status code: ${geminiResponse.statusCode}');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to fetch prediction. Please try again later.';
        isLoading = false;
      });
    }
  }
}

// Model classes
class CommodityData {
  final String state;
  final String district;
  final String market;
  final String commodity;
  final String variety;
  final String grade;
  final String arrivalDate;
  final String minPrice;
  final String maxPrice;
  final String modalPrice;

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
  });

  factory CommodityData.fromJson(Map<String, dynamic> json) {
    return CommodityData(
      state: json['state'] ?? '',
      district: json['district'] ?? '',
      market: json['market'] ?? '',
      commodity: json['commodity'] ?? '',
      variety: json['variety'] ?? '',
      grade: json['grade'] ?? '',
      arrivalDate: json['arrival_date'] ?? '',
      minPrice: json['min_price'] ?? '0',
      maxPrice: json['max_price'] ?? '0',
      modalPrice: json['modal_price'] ?? '0',
    );
  }
}

class DailyPrediction {
  final int day;
  final double price;

  DailyPrediction({required this.day, required this.price});

  factory DailyPrediction.fromJson(Map<String, dynamic> json) {
    return DailyPrediction(
      day: json['day'],
      price: json['price'].toDouble(),
    );
  }
}

class PredictionData {
  final String summary;
  final List<String> factors;
  final List<DailyPrediction> dailyPredictions;
  final String weatherImpact;
  final String demandSupply;

  PredictionData({
    required this.summary,
    required this.factors,
    required this.dailyPredictions,
    required this.weatherImpact,
    required this.demandSupply,
  });

factory PredictionData.fromJson(Map<String, dynamic> json) {
  return PredictionData(
    summary: json['summary'] ?? 'No summary available',
    factors: List<String>.from(json['factors'] ?? []),
    dailyPredictions: List<DailyPrediction>.from(
      (json['dailyPredictions'] ?? []).map(
        (prediction) => DailyPrediction.fromJson(prediction),
      ),
    ),
    weatherImpact: json['weatherImpact'] ?? 'No weather impact analysis available',
    demandSupply: json['demandSupply'] ?? 'No demand and supply analysis available',
  );
}}