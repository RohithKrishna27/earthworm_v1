import 'package:flutter/material.dart';
import 'calculator_screen/crop_yield.dart';
import 'calculator_screen/input_cost.dart';
import 'calculator_screen/irrigation.dart';
import 'calculator_screen/profit-loss.dart';
import 'calculator_screen/soil-fertile.dart';
import 'calculator_screen/pest.dart';
import 'calculator_screen/market.dart';
import 'calculator_screen/loan.dart';
import 'calculator_screen/planting.dart';
import 'calculator_screen/livestock.dart';

class CalculatorHomeScreen extends StatelessWidget {
  final List<Map<String, dynamic>> calculatorOptions = [
    {
      'title': 'Crop Yield',
      'screen': CropYieldScreen(),
      'icon': Icons.agriculture,
      'description': 'Estimate crop production',
      'gradient': [Color(0xFFFF6B6B), Color(0xFFFFA06B)]
    },
    {
      'title': 'Input Cost',
      'screen': InputCostManagementScreen(),
      'icon': Icons.attach_money,
      'description': 'Manage input expenses',
      'gradient': [Color(0xFF4ECDC4), Color(0xFF45B7D1)]
    },
    {
      'title': 'Irrigation',
      'screen': IrrigationRequirementsScreen(),
      'icon': Icons.water_drop,
      'description': 'Water management',
      'gradient': [Color(0xFF5D3FD3), Color(0xFF7B68EE)]
    },
    {
      'title': 'Profit Analysis',
      'screen': ProfitLossCalculatorScreen(),
      'icon': Icons.analytics,
      'description': 'Financial performance',
      'gradient': [Color(0xFFFFD700), Color(0xFFFFA500)]
    },
    {
      'title': 'Soil Fertility',
      'screen': SoilFertilityScreen(),
      'icon': Icons.grass,
      'description': 'Soil nutrient analysis',
      'gradient': [Color(0xFF2E8B57), Color(0xFF3CB371)]
    },
    {
      'title': 'Pest Management',
      'screen': PestDiseaseManagementScreen(),
      'icon': Icons.bug_report,
      'description': 'Pest control strategy',
      'gradient': [Color(0xFFFF4500), Color(0xFFFF6347)]
    },
    {
      'title': 'Market Price',
      'screen': MarketPriceScreen(),
      'icon': Icons.trending_up,
      'description': 'Price trend analysis',
      'gradient': [Color(0xFF1E90FF), Color(0xFF4169E1)]
    },
    {
      'title': 'Loan Calculator',
      'screen': LoanSubsidyCalculatorScreen(),
      'icon': Icons.account_balance,
      'description': 'Financial planning',
      'gradient': [Color(0xFF9370DB), Color(0xFFBA55D3)]
    },
    {
      'title': 'Planting Schedule',
      'screen': PlantingHarvestingScheduleScreen(),
      'icon': Icons.calendar_month,
      'description': 'Crop timeline planning',
      'gradient': [Color(0xFF20B2AA), Color(0xFF00CED1)]
    },
    {
      'title': 'Livestock Feed',
      'screen': LivestockFeedCalculatorScreen(),
      'icon': Icons.pets,
      'description': 'Animal nutrition',
      'gradient': [Color(0xFFCD5C5C), Color(0xFFF08080)]
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Smart Farming Calculators',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: Color.fromARGB(255, 37, 155, 131),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.green[50]!, Colors.green[100]!],
          ),
        ),
        child: SafeArea(
          child: GridView.builder(
            padding: EdgeInsets.all(12),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: calculatorOptions.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => calculatorOptions[index]['screen'],
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: calculatorOptions[index]['gradient'],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        offset: Offset(0, 4),
                        blurRadius: 5.0,
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        calculatorOptions[index]['icon'],
                        size: 48,
                        color: Colors.white,
                      ),
                      SizedBox(height: 12),
                      Text(
                        calculatorOptions[index]['title'],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.1,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        calculatorOptions[index]['description'],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
