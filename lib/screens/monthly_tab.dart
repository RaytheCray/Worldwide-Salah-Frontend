import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/prayer_calculator.dart';
import '../services/time_format_service.dart';
import '../services/asr_method_service.dart';

class MonthlyTab extends StatefulWidget {
  const MonthlyTab({super.key});

  @override
  State<MonthlyTab> createState() => _MonthlyTabState();
}

class _MonthlyTabState extends State<MonthlyTab> {
  List<Map<String, dynamic>>? _monthlyPrayerTimes;
  bool _isLoading = false;
  String? _errorMessage;
  Position? _currentPosition;
  DateTime _selectedDate = DateTime.now();
  bool _use24HourFormat = true;
  String _asrMethod = 'standard';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _initializeData();
  }

  Future<void> _loadPreferences() async {
    final use24Hour = await TimeFormatService.get24HourFormat();
    final asrMethod = await AsrMethodService.getAsrMethod();
    if (mounted) {
      setState(() {
        _use24HourFormat = use24Hour;
        _asrMethod = asrMethod;
      });
    }
  }

  Future<void> _initializeData() async {
    await _getCurrentLocation();
    if (_currentPosition != null) {
      await _loadMonthlyData();
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

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permission permanently denied');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Location timeout');
        },
      );

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

  Future<void> _loadMonthlyData() async {
    if (_currentPosition == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final monthlyData = await PrayerCalculator.getMonthlyPrayerTimes(
        year: _selectedDate.year,
        month: _selectedDate.month,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        method: 'ISNA',
        asrMethod: _asrMethod,
      );

      setState(() {
        _monthlyPrayerTimes = monthlyData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _changeMonth(int delta) async {
    setState(() {
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month + delta,
        1,
      );
    });
    await _loadMonthlyData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${_getMonthName(_selectedDate.month)} ${_selectedDate.year}',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _changeMonth(-1),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _changeMonth(1),
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
                style: const TextStyle(fontSize: 16),
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

    if (_monthlyPrayerTimes == null || _monthlyPrayerTimes!.isEmpty) {
      return const Center(
        child: Text('No prayer times available'),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _loadPreferences(); // Reload preferences
        await _loadMonthlyData();
      },
      child: ListView.builder(
        itemCount: _monthlyPrayerTimes!.length,
        itemBuilder: (context, index) {
          final day = _monthlyPrayerTimes![index];
          final prayers = day['prayers'] as List<PrayerTime>;
          final date = day['date'] as String;
          final dayNum = day['day'] as int;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ExpansionTile(
              title: Text(
                'Day $dayNum - $date',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              children: prayers.map((prayer) {
                if (prayer.name == 'Sunrise') {
                  return const SizedBox.shrink();
                }
                
                // Format the time based on user preference
                final formattedTime = TimeFormatService.formatTime(
                  prayer.formattedTime,
                  _use24HourFormat,
                );
                
                return ListTile(
                  dense: true,
                  title: Text(prayer.name),
                  trailing: Text(
                    formattedTime,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}