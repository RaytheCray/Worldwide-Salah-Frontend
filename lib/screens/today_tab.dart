import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/prayer_calculator.dart';

class TodayTab extends StatefulWidget {
  const TodayTab({super.key});

  @override
  State<TodayTab> createState() => _TodayTabState();
}

class _TodayTabState extends State<TodayTab> {
  List<PrayerTime>? _prayerTimes;
  PrayerTime? _nextPrayer;
  bool _isLoading = false;
  String? _errorMessage;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _getCurrentLocation();
    if (_currentPosition != null) {
      await _loadTodayPrayerTimes();
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
        onTimeout: () => throw Exception('Location timeout'),
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

  Future<void> _loadTodayPrayerTimes() async {
    if (_currentPosition == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prayers = await PrayerCalculator.calculatePrayerTimes(
        DateTime.now(),
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        method: 'ISNA',
        asrMethod: 'standard',
      );

      final nextPrayer = await PrayerCalculator.getNextPrayer(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        method: 'ISNA',
        asrMethod: 'standard',
      );

      setState(() {
        _prayerTimes = prayers;
        _nextPrayer = nextPrayer;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Today - ${DateTime.now().toString().split(' ')[0]}'),
        actions: [
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

    if (_prayerTimes == null) {
      return const Center(child: Text('No prayer times available'));
    }

    return RefreshIndicator(
      onRefresh: _loadTodayPrayerTimes,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_nextPrayer != null)
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'NEXT PRAYER',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _nextPrayer!.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _nextPrayer!.formattedTime,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          ..._prayerTimes!.where((p) => p.name != 'Sunrise').map((prayer) {
            final isNext = _nextPrayer?.name == prayer.name;
            final now = TimeOfDay.now();
            final isPast = prayer.isPast(now);

            return Card(
              child: ListTile(
                leading: Icon(
                  _getPrayerIcon(prayer.name),
                  color: isNext ? Colors.blue : isPast ? Colors.grey : Colors.black87,
                ),
                title: Text(
                  prayer.name,
                  style: TextStyle(
                    fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
                    color: isPast ? Colors.grey : Colors.black87,
                  ),
                ),
                trailing: Text(
                  prayer.formattedTime,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isNext ? Colors.blue : isPast ? Colors.grey : Colors.black87,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  IconData _getPrayerIcon(String prayerName) {
    switch (prayerName.toLowerCase()) {
      case 'fajr':
        return Icons.brightness_2;
      case 'dhuhr':
        return Icons.wb_sunny_outlined;
      case 'asr':
        return Icons.wb_twilight;
      case 'maghrib':
        return Icons.brightness_3;
      case 'isha':
        return Icons.nightlight;
      default:
        return Icons.access_time;
    }
  }
}