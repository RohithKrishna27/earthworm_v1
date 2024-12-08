// farming_schedule_screen.dart
import 'package:flutter/material.dart';
import 'todo_screen.dart';

class FarmingScheduleScreen extends StatelessWidget {
  final String cropName;
  final String fieldSize;
  final DateTime plantingDate;
  final String soilType;
  final String irrigationType;

  const FarmingScheduleScreen({
    Key? key,
    required this.cropName,
    required this.fieldSize,
    required this.plantingDate,
    required this.soilType,
    required this.irrigationType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Farming Schedule'),
        backgroundColor: Colors.green[700],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Schedule for $cropName',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildScheduleTimeline(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailedTaskScreen(
                    crop: cropName,
                    date: plantingDate,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_turned_in, size: 24),
                SizedBox(width: 12),
                Text(
                  'View Detailed Tasks',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      // Rest of the code remains the same...
    );
  }

  Widget _buildScheduleTimeline() {
    // This would be customized based on the crop type
    final scheduleItems = _getScheduleForCrop();

    return Column(
      children: scheduleItems.map((item) => _buildTimelineItem(item)).toList(),
    );
  }

  Widget _buildTimelineItem(Map<String, String> item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.green[700],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['date']!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(item['task']!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, String>> _getScheduleForCrop() {
    // This would be customized based on the crop type
    return [
      {
        'date':
            'Day 1 - ${plantingDate.day}/${plantingDate.month}/${plantingDate.year}',
        'task': 'Land preparation and soil testing'
      },
      {'date': 'Week 1', 'task': 'Sowing/Planting'},
      {'date': 'Week 2-3', 'task': 'Initial irrigation and fertilization'},
      {'date': 'Week 4-6', 'task': 'Weed control and pest monitoring'},
      {'date': 'Week 7-8', 'task': 'Growth monitoring and disease prevention'},
      {
        'date': 'Week 9-12',
        'task': 'Regular irrigation and nutrient management'
      },
      {'date': 'Week 13-16', 'task': 'Pre-harvest preparation'},
      {'date': 'Final Week', 'task': 'Harvest and post-harvest handling'},
    ];
  }
}

// crop_schedule_helper.dart
class CropScheduleHelper {
  static List<Map<String, String>> getScheduleForCrop(
    String cropName,
    DateTime plantingDate,
    String soilType,
  ) {
    switch (cropName.toLowerCase()) {
      case 'rice':
        return [
          {
            'date': 'Day 1 - ${_formatDate(plantingDate)}',
            'task': 'Land preparation: Plow and level the field'
          },
          {
            'date':
                'Week 1 - ${_formatDate(plantingDate.add(const Duration(days: 7)))}',
            'task': 'Seed soaking and sowing in nursery'
          },
          {
            'date':
                'Week 3-4 - ${_formatDate(plantingDate.add(const Duration(days: 21)))}',
            'task': 'Transplanting seedlings'
          },
          {
            'date': 'Week 5-6',
            'task': 'First fertilizer application and weeding'
          },
          {'date': 'Week 8-9', 'task': 'Second fertilizer application'},
          {
            'date': 'Week 12-14',
            'task': 'Panicle initiation and flowering stage'
          },
          {'date': 'Week 16-18', 'task': 'Grain filling stage'},
          {
            'date': 'Week 20-22',
            'task': 'Harvest when 80% of grains are mature'
          },
        ];

      case 'maize':
        return [
          {
            'date': 'Day 1 - ${_formatDate(plantingDate)}',
            'task': 'Field preparation and soil testing'
          },
          {
            'date':
                'Week 1 - ${_formatDate(plantingDate.add(const Duration(days: 7)))}',
            'task': 'Direct seed sowing'
          },
          {
            'date': 'Week 2-3',
            'task': 'Monitor germination and thin seedlings'
          },
          {'date': 'Week 4-5', 'task': 'First fertilizer application'},
          {'date': 'Week 6-7', 'task': 'Weeding and pest monitoring'},
          {'date': 'Week 8-9', 'task': 'Second fertilizer application'},
          {'date': 'Week 10-12', 'task': 'Tasseling and silking stage'},
          {'date': 'Week 16-18', 'task': 'Harvest when kernels are firm'},
        ];

      case 'cotton':
        return [
          {
            'date': 'Day 1 - ${_formatDate(plantingDate)}',
            'task': 'Deep plowing and field preparation'
          },
          {
            'date':
                'Week 1 - ${_formatDate(plantingDate.add(const Duration(days: 7)))}',
            'task': 'Seed sowing'
          },
          {'date': 'Week 2-3', 'task': 'Monitor emergence and gap filling'},
          {
            'date': 'Week 4-5',
            'task': 'First fertilizer application and thinning'
          },
          {'date': 'Week 6-8', 'task': 'Weeding and inter-cultivation'},
          {
            'date': 'Week 10-12',
            'task': 'Square formation and flowering stage'
          },
          {'date': 'Week 16-20', 'task': 'Boll development stage'},
          {'date': 'Week 22-24', 'task': 'First picking of mature bolls'},
        ];

      case 'tomatoes':
        return [
          {
            'date': 'Day 1 - ${_formatDate(plantingDate)}',
            'task': 'Seedbed preparation and sowing'
          },
          {'date': 'Week 3-4', 'task': 'Transplant seedlings to main field'},
          {
            'date': 'Week 5-6',
            'task': 'Staking and first fertilizer application'
          },
          {'date': 'Week 7-8', 'task': 'Pruning and pest monitoring'},
          {'date': 'Week 9-10', 'task': 'Flowering stage and fruit set'},
          {'date': 'Week 12-14', 'task': 'First harvest of mature fruits'},
          {'date': 'Week 15-20', 'task': 'Continue harvesting periodically'},
        ];

      default:
        return [
          {
            'date': 'Day 1 - ${_formatDate(plantingDate)}',
            'task': 'Land preparation and soil testing'
          },
          {'date': 'Week 1', 'task': 'Sowing/Planting'},
          {'date': 'Week 2-3', 'task': 'Initial irrigation and fertilization'},
          {'date': 'Week 4-6', 'task': 'Weed control and pest monitoring'},
          {
            'date': 'Week 7-8',
            'task': 'Growth monitoring and disease prevention'
          },
          {
            'date': 'Week 9-12',
            'task': 'Regular irrigation and nutrient management'
          },
          {'date': 'Week 13-16', 'task': 'Pre-harvest preparation'},
          {'date': 'Final Week', 'task': 'Harvest and post-harvest handling'},
        ];
    }
  }

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  static String getIrrigationAdvice(String cropName, String irrigationType) {
    switch (cropName.toLowerCase()) {
      case 'rice':
        return 'Maintain 5-7 cm water level during vegetative stage. Drain field 10 days before harvest.';
      case 'maize':
        return 'Critical irrigation periods: knee-high stage, tasseling, and grain filling.';
      case 'cotton':
        return 'Regular irrigation during square formation and boll development.';
      case 'tomatoes':
        return 'Consistent moisture needed. Avoid wetting leaves to prevent disease.';
      default:
        return 'Maintain consistent soil moisture throughout growing season.';
    }
  }

  static String getSoilPreparationAdvice(String cropName, String soilType) {
    switch (cropName.toLowerCase()) {
      case 'rice':
        return 'Puddle soil for better water retention. Add organic matter.';
      case 'maize':
        return 'Deep plowing recommended. Ensure good drainage.';
      case 'cotton':
        return 'Deep plowing and ridge formation required.';
      case 'tomatoes':
        return 'Well-drained soil with organic matter. Raised beds recommended.';
      default:
        return 'Prepare soil to 6-8 inches depth. Ensure good drainage.';
    }
  }
}
