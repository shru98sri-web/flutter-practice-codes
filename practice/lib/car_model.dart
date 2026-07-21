import 'package:flutter/material.dart';

void main() {
  runApp(const CarModelingApp());
}

class CarModelingApp extends StatelessWidget {
  const CarModelingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Car Configurator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true, // मॉडर्न UI डिझाईनसाठी
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: const CarConfiguratorScreen(),
    );
  }
}

class CarModel {
  final String id;
  final String name;
  final double basePrice;
  final Map<String, List<ColorOption>> paintOptions;
  final Map<String, List<WheelOption>> wheelOptions;

  CarModel({
    required this.id,
    required this.name,
    required this.basePrice,
    required this.paintOptions,
    required this.wheelOptions,
  });
}

class ColorOption {
  final String name;
  final Color hexColor;
  final double price;
  final String assetPath; // For 3D texturing or images

  ColorOption({
    required this.name,
    required this.hexColor,
    required this.price,
    required this.assetPath,
  });
}

class WheelOption {
  final String name;
  final int sizeInches;
  final double price;
  final String assetPath;

  WheelOption({
    required this.name,
    required this.sizeInches,
    required this.price,
    required this.assetPath,
  });
}

class CarConfiguratorScreen extends StatefulWidget {
  const CarConfiguratorScreen({super.key});

  @override
  State<CarConfiguratorScreen> createState() => _CarConfiguratorScreenState();
}

class _CarConfiguratorScreenState extends State<CarConfiguratorScreen> {
  // Mock Data Initialization
  late CarModel currentCar;
  late ColorOption selectedColor;
  late WheelOption selectedWheel;

  @override
  void initState() {
    super.initState();
    _loadMockData();
  }

  void _loadMockData() {
    currentCar = CarModel(
      id: 'sedan-01',
      name: 'Aero Sedan X',
      basePrice: 45000.00,
      paintOptions: {
        'Paint': [
          ColorOption(
            name: 'Obsidian Black',
            hexColor: Colors.black,
            price: 0.0,
            assetPath: 'assets/black_paint.png',
          ),
          ColorOption(
            name: 'Liquid Silver',
            hexColor: Colors.grey,
            price: 1200.0,
            assetPath: 'assets/silver_paint.png',
          ),
          ColorOption(
            name: 'Racing Red',
            hexColor: Colors.red,
            price: 2500.0,
            assetPath: 'assets/red_paint.png',
          ),
        ],
      },
      wheelOptions: {
        'Wheels': [
          WheelOption(
            name: 'Standard Sport',
            sizeInches: 18,
            price: 0.0,
            assetPath: 'assets/wheels_18.obj',
          ),
          WheelOption(
            name: 'Executive Alloy',
            sizeInches: 20,
            price: 1800.0,
            assetPath: 'assets/wheels_20.obj',
          ),
        ],
      },
    );

    selectedColor = currentCar.paintOptions['Paint']!.first;
    selectedWheel = currentCar.wheelOptions['Wheels']!.first;
  }

  // Cost calculation function
  double get _totalPrice {
    return currentCar.basePrice + selectedColor.price + selectedWheel.price;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          currentCar.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 3D Viewport Placeholder
          Expanded(
            flex: 5,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.directions_car,
                      size: 100,
                      color: selectedColor.hexColor,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Visualizer Engine [Active]',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    Text(
                      '${selectedColor.name} | ${selectedWheel.name} (${selectedWheel.sizeInches}")',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Selection and Pricing Panel
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section: Paint Color
                  const Text(
                    'Exterior Paint',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: currentCar.paintOptions['Paint']!.length,
                      itemBuilder: (context, index) {
                        final option = currentCar.paintOptions['Paint']![index];
                        final isSelected = selectedColor == option;
                        return GestureDetector(
                          onTap: () => setState(() => selectedColor = option),
                          child: Container(
                            margin: const EdgeInsets.only(right: 16),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.blue
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              backgroundColor: option.hexColor,
                              radius: 18,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section: Wheels
                  const Text(
                    'Wheel Blueprint',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: currentCar.wheelOptions['Wheels']!.map((option) {
                      final isSelected = selectedWheel == option;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: ChoiceChip(
                          label: Text('${option.name} (${option.sizeInches}")'),
                          selected: isSelected,
                          onSelected: (bool selected) {
                            if (selected)
                              setState(() => selectedWheel = option);
                          },
                        ),
                      );
                    }).toList(),
                  ),

                  const Spacer(),

                  // Checkout Summary Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ESTIMATED TOTAL',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            '\$${_totalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 24),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Save Model Layout'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
