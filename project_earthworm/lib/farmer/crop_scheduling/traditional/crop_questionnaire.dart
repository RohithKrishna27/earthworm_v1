// crop_questionnaire_screen.dart
import 'package:flutter/material.dart';
import 'crop_schedule.dart';

class CropQuestionnaireScreen extends StatefulWidget {
  final String cropName;

  const CropQuestionnaireScreen({Key? key, required this.cropName})
      : super(key: key);

  @override
  State<CropQuestionnaireScreen> createState() =>
      _CropQuestionnaireScreenState();
}

class _CropQuestionnaireScreenState extends State<CropQuestionnaireScreen> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();

  // Form values
  String? fieldSize;
  DateTime? plantingDate;
  String? soilType;
  String? irrigationType;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.cropName} Details'),
        backgroundColor: Colors.green[700],
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < 3) {
              setState(() => _currentStep++);
            } else {
              // Navigate to schedule screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FarmingScheduleScreen(
                    cropName: widget.cropName,
                    fieldSize: fieldSize ?? '',
                    plantingDate: plantingDate ?? DateTime.now(),
                    soilType: soilType ?? '',
                    irrigationType: irrigationType ?? '',
                  ),
                ),
              );
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            }
          },
          steps: [
            Step(
              title: const Text('Field Size'),
              content: TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Enter field size in acres',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => fieldSize = value,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter field size' : null,
              ),
              isActive: _currentStep >= 0,
            ),
            Step(
              title: const Text('Planting Date'),
              content: InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() => plantingDate = date);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Select planting date',
                  ),
                  child: Text(
                    plantingDate != null
                        ? '${plantingDate!.day}/${plantingDate!.month}/${plantingDate!.year}'
                        : 'Tap to select date',
                  ),
                ),
              ),
              isActive: _currentStep >= 1,
            ),
            Step(
              title: const Text('Soil Type'),
              content: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Select soil type',
                ),
                items: ['Clay', 'Loamy', 'Sandy', 'Silt', 'Peaty']
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => soilType = value),
              ),
              isActive: _currentStep >= 2,
            ),
            Step(
              title: const Text('Irrigation Type'),
              content: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Select irrigation type',
                ),
                items: ['Drip', 'Sprinkler', 'Flood', 'Furrow', 'Rain-fed']
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => irrigationType = value),
              ),
              isActive: _currentStep >= 3,
            ),
          ],
        ),
      ),
    );
  }
}
