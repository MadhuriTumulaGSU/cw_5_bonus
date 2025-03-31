import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

//Madhuri- 002892521

void main() {
  runApp(MyApp());
}

class Fish {
  Color color;
  double speed;
  Offset position;

  Fish({
    required this.color,
    required this.speed,
    required this.position,
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Virtual Aquarium',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AquariumScreen(),
    );
  }
}

class AquariumScreen extends StatefulWidget {
  @override
  _AquariumScreenState createState() => _AquariumScreenState();
}

class _AquariumScreenState extends State<AquariumScreen> with TickerProviderStateMixin {
  List<Fish> fishList = [];
  Color selectedColor = Colors.blue;
  double selectedSpeed = 1.0;
  late Database db;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
    _controller = AnimationController(vsync: this, duration: Duration(seconds: 1))..repeat();
  }

  Future<void> _initializeDatabase() async {
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'aquarium_settings.db');
    db = await openDatabase(path, version: 1, onCreate: (Database database, int version) async {
      await database.execute('CREATE TABLE Settings (id INTEGER PRIMARY KEY, fishCount INTEGER, speed REAL, color TEXT)');
    });
    await _loadSettings();
  }

  Future<void> _loadSettings() async {
    List<Map> result = await db.query('Settings', limit: 1);
    if (result.isNotEmpty) {
      setState(() {
        selectedColor = Color(int.parse(result[0]['color'].toString()));
        selectedSpeed = result[0]['speed'];
      });
    }
  }

  Future<void> _saveSettings() async {
    await db.delete('Settings');
    await db.insert('Settings', {
      'fishCount': fishList.length,
      'speed': selectedSpeed,
      'color': selectedColor.value.toString(),
    });
  }

  void _addFish() {
    if (fishList.length < 10) {
      setState(() {
        fishList.add(Fish(
          color: selectedColor,
          speed: selectedSpeed,
          position: Offset(150.0, 150.0), // Initial position
        ));
      });
    }
  }

  void _toggleColorChange(bool value) {
    setState(() {
      // Enable or disable random color change logic
    });
  }

  void _animateFish() {
    for (int i = 0; i < fishList.length; i++) {
      setState(() {
        double dx = fishList[i].position.dx + (fishList[i].speed * 10);
        double dy = fishList[i].position.dy + (fishList[i].speed * 10);
        
        // If fish reaches container boundaries, change direction
        if (dx > 300 || dx < 0) {
          dx = fishList[i].position.dx - (fishList[i].speed * 10);
        }
        if (dy > 300 || dy < 0) {
          dy = fishList[i].position.dy - (fishList[i].speed * 10);
        }

        fishList[i].position = Offset(dx, dy);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _animateFish();
    return Scaffold(
      appBar: AppBar(
        title: Text('Virtual Aquarium'),
      ),
      body: Center(
        child: Column(
          children: [
            Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(),
                color: Colors.blue[50],
              ),
              child: Stack(
                children: fishList.map((fish) {
                  return AnimatedPositioned(
                    duration: Duration(seconds: fish.speed.toInt()),
                    left: fish.position.dx,
                    top: fish.position.dy,
                    child: GestureDetector(
                      onTap: () {
                        // Handle fish click for color change
                        setState(() {
                          fish.color = Random().nextBool() ? Colors.red : Colors.green;
                        });
                      },
                      child: CircleAvatar(
                        radius: 10,
                        backgroundColor: fish.color,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _addFish,
                  child: Text('Add Fish'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _saveSettings();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Settings Saved')));
                  },
                  child: Text('Save Settings'),
                ),
              ],
            ),
            Slider(
              value: selectedSpeed,
              min: 0.5,
              max: 5.0,
              divisions: 9,
              label: selectedSpeed.toStringAsFixed(1),
              onChanged: (value) {
                setState(() {
                  selectedSpeed = value;
                });
              },
            ),
            ColorPicker(onColorChanged: (color) {
              setState(() {
                selectedColor = color;
              });
            }),
            Row(
              children: [
                Text('Enable Collision Detection'),
                Switch(
                  value: false,
                  onChanged: _toggleColorChange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ColorPicker extends StatelessWidget {
  final Function(Color) onColorChanged;
  ColorPicker({required this.onColorChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ElevatedButton(
          onPressed: () {
            onColorChanged(Colors.blue);
          },
          child: Text('Blue'),
        ),
        ElevatedButton(
          onPressed: () {
            onColorChanged(Colors.red);
          },
          child: Text('Red'),
        ),
        ElevatedButton(
          onPressed: () {
            onColorChanged(Colors.green);
          },
          child: Text('Green'),
        ),
      ],
    );
  }
}