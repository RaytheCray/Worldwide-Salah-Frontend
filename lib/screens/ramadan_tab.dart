import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/prayer_calculator.dart';
import '../services/time_format_service.dart';

class RamadanTab extends StatefulWidget {
  const RamadanTab({super.key});

  @override
  State<RamadanTab> createState() => _RamadanTabState();
}

class _RamadanTabState extends State<RamadanTab> {
  Map<String, dynamic>? _ramadanData;
  bool _isLoading = false;
  String? _errorMessage;
  Position? _currentPosition;
  int _selectedYear = DateTime.now().year;
  bool _use24HourFormat = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _initializeData();
  }

  Future<void> _loadPreferences() async {
    final use24Hour = await TimeFormatService.get24HourFormat();
    if (mounted) {
      setState(() {
        _use24HourFormat = use24Hour;
      });
    }
  }

  Future<void> _initializeData() async {
    await _getCurrentLocation();
    if (_currentPosition != null) {
      await _loadRamadanSchedule();
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 10));

      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRamadanSchedule() async {
    if (_currentPosition == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await PrayerCalculator.getRamadanSchedule(
        year: _selectedYear,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        method: 'ISNA',
      );

      setState(() {
        _ramadanData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _changeYear(int delta) async {
    setState(() {
      _selectedYear += delta;
    });
    await _loadRamadanSchedule();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ramadan $_selectedYear'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _changeYear(-1),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _changeYear(1),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initializeData,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
            ),
            ElevatedButton(
              onPressed: _initializeData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_ramadanData == null) {
      return const Center(child: Text('No Ramadan data available'));
    }

    final schedule = _ramadanData!['fasting_schedule'] as List;

    return RefreshIndicator(
      onRefresh: () async {
        await _loadPreferences(); // Reload preferences
        await _loadRamadanSchedule();
      },
      child: Column(
        children: [
          // Ramadan Info Card
          Card(
            margin: const EdgeInsets.all(16),
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.nightlight, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Ramadan $_selectedYear',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_ramadanData!['start_date']} - ${_ramadanData!['end_date']}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Fasting Schedule List
          Expanded(
            child: ListView.builder(
              itemCount: schedule.length,
              itemBuilder: (context, index) {
                final day = schedule[index];
                final suhoorEnd = TimeFormatService.formatTime(
                  day['suhoor_end'],
                  _use24HourFormat,
                );
                final iftarTime = TimeFormatService.formatTime(
                  day['iftar_time'],
                  _use24HourFormat,
                );
                
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ExpansionTile(
                    title: Text(
                      'Day ${day['day']} - ${day['date']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    children: [
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.restaurant, color: Colors.orange),
                        title: const Text('Suhoor Ends (Fajr)'),
                        trailing: Text(
                          suhoorEnd,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.wb_twilight, color: Colors.deepOrange),
                        title: const Text('Iftar Begins (Maghrib)'),
                        trailing: Text(
                          iftarTime,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}