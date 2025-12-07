// MEMORY-OPTIMIZED VERSION - lib/screens/home_screen.dart
// This version reduces memory usage by not auto-loading mosques

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:worldwide_salah/services/geocoding_service.dart';
import '../services/api_service.dart';
import '../models/prayer_times.dart' as prayer_model;
import '../models/mosque.dart' as mosque_model;
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  prayer_model.PrayerTimes? _prayerTimes;
  List<mosque_model.Mosque> _nearbyMosques = [];
  final ApiService _api = ApiService();
  bool _isLoading = false;
  String? _errorMessage;
  Position? _currentPosition;
  bool _mosquesLoading = false;
  String? _mosqueError;
  bool _mosquesLoaded = false;  // Track if mosques have been loaded
  String _locationName = 'Loading...';
  
  String _calculationMethod = 'ISNA';
  String _asrMethod = 'standard';

  @override
  void initState() {
    super.initState();
    debugPrint('🔄 HomeScreen: initState called');
    
    // Safety timeout
    Future.delayed(const Duration(seconds: 20), () {
      if (_isLoading && mounted) {
        debugPrint('⏰ HomeScreen: Loading timeout triggered');
        setState(() {
          _isLoading = false;
          _errorMessage ??= 'Loading timed out. Please try again.';
        });
      }
    });
    
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    debugPrint('📱 HomeScreen: Initializing app...');

    //Safety timeout
    Future.delayed(const Duration(seconds: 20), () {
      if (_isLoading && mounted) {
        debugPrint('⏰ HomeScreen: Loading timeout triggered');
        setState(() {
          _isLoading = false;
          _errorMessage ??= 'Loading timed out. Please try again.';
        });
      }
    });

    await _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    debugPrint('📍 HomeScreen: Getting current location...');
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

      debugPrint('✅ HomeScreen: Location obtained');
      
      setState(() {
        _currentPosition = position;
      });

      // Get readable location name
      _locationName = await GeocodingService.getLocationName(
        position.latitude,
        position.longitude,
      );
      
      setState(() {});  // Update UI with location name

      await _loadPrayerTimes();
    } catch (e) {
      debugPrint('❌ HomeScreen: Location error: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;  // STOP LOADING
      });
    }
  }

  Future<void> _loadPrayerTimes() async {
    if (_currentPosition == null) {
      debugPrint('⚠️ HomeScreen: Cannot load prayer times - no position');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final today = DateTime.now();
      final dateString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      debugPrint('🔄 HomeScreen: Requesting prayer times');
      
      final response = await _api.getPrayerTimes(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        date: dateString,
        method: _calculationMethod,
        asrMethod: _asrMethod,
      );

      if (response['success'] == true) {
        debugPrint('✅ HomeScreen: Prayer times loaded successfully');
        
        setState(() {
          _prayerTimes = prayer_model.PrayerTimes.fromJson(response);
          _isLoading = false;  // STOP LOADING
        });
      } else {
        throw Exception(response['error'] ?? 'Failed to load prayer times');
      }
    } catch (e) {
      debugPrint('❌ HomeScreen: Error: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;  // STOP LOADING
      });
    }
  }

  // ✅ MEMORY OPTIMIZATION: Load mosques only when user requests
  Future<void> _loadNearbyMosques() async {
    if (_currentPosition == null) {
      setState(() {
        _mosqueError = 'Location not available';
      });
      return;
    }

    setState(() {
      _mosquesLoading = true;
      _mosqueError = null;
    });

    try {
      debugPrint('🕌 Loading mosques for: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');
      
      final response = await _api.getNearbyMosques(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        radius: 10.0,
      ).timeout(
        const Duration(seconds: 15),  // Add timeout
        onTimeout: () {
          throw Exception('Request timed out. Check your internet connection.');
        },
      );

      if (response['success'] == true) {
        final mosquesList = response['mosques'] as List;
        setState(() {
          _nearbyMosques = mosquesList
              .map((json) => mosque_model.Mosque.fromJson(json))
              .toList();
          _mosquesLoaded = true;
          _mosquesLoading = false;
        });
        
        debugPrint('✅ Loaded ${_nearbyMosques.length} mosques');
        
        if (_nearbyMosques.isEmpty) {
          setState(() {
            _mosqueError = 'No mosques found within 10km';
          });
        }
      } else {
        throw Exception(response['error'] ?? 'Failed to load mosques');
      }
    } catch (e) {
      debugPrint('❌ Error loading mosques: $e');
      setState(() {
        _mosquesLoading = false;
        _mosquesLoaded = false;
        _mosqueError = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Widget _buildLocationDisplay() {
    if (_currentPosition == null) {
      return Container();
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Location',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  _locationName,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.blue.shade700),
            onPressed: _getCurrentLocation,
            tooltip: 'Refresh location',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Worldwide Salah'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              debugPrint('⚙️ Opening settings screen...');
              
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(
                    location: _currentPosition != null
                        ? 'Lat: ${_currentPosition!.latitude.toStringAsFixed(4)}, '
                          'Lng: ${_currentPosition!.longitude.toStringAsFixed(4)}'
                        : 'Location not available',
                    calculationMethod: _calculationMethod,
                    asrMethod: _asrMethod,
                    onLocationChanged: (newLocation) {
                      debugPrint('📍 Location changed: $newLocation');
                    },
                    onCalculationMethodChanged: (newMethod) {
                      setState(() {
                        _calculationMethod = newMethod;
                      });
                      _loadPrayerTimes();
                    },
                    onAsrMethodChanged: (newAsrMethod) {
                      setState(() {
                        _asrMethod = newAsrMethod;
                      });
                      _loadPrayerTimes();
                    },
                  ),
                ),
              );
              
              if (result != null) {
                debugPrint('✅ Settings updated: $result');
                setState(() {
                  _calculationMethod = result['calculationMethod'] ?? _calculationMethod;
                  _asrMethod = result['asrMethod'] ?? _asrMethod;
                });
                await _loadPrayerTimes();
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
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
                        onPressed: _getCurrentLocation,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _getCurrentLocation,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLocationDisplay(),
                        
                        if (_prayerTimes != null)
                          _buildPrayerTimesCard()
                        else
                          const Card(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('Loading prayer times...'),
                            ),
                          ),
                        
                        const SizedBox(height: 16),
                        
                        // Mosques section with manual load button
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Nearby Mosques',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_mosquesLoading)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Load mosques button (if not loaded yet)
                        if (!_mosquesLoaded && !_mosquesLoading)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: ElevatedButton.icon(
                              onPressed: _loadNearbyMosques,
                              icon: const Icon(Icons.mosque),
                              label: const Text('Load Nearby Mosques'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 48),
                              ),
                            ),
                          ),
                        
                        // Mosque error
                        if (_mosqueError != null)
                          Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Icon(Icons.warning, color: Colors.orange[700]),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(_mosqueError!),
                                  ),
                                ],
                              ),
                            ),
                          )
                        // Empty mosque list
                        else if (_nearbyMosques.isEmpty && _mosquesLoaded)
                          Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, color: Colors.grey[600]),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      'No mosques found within 20 km',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        // Mosque list
                        else if (_nearbyMosques.isNotEmpty)
                          _buildMosquesList(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildPrayerTimesCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Prayer Times',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            _buildPrayerTimeRow('Fajr', _prayerTimes!.fajr),
            _buildPrayerTimeRow('Sunrise', _prayerTimes!.sunrise),
            _buildPrayerTimeRow('Dhuhr', _prayerTimes!.dhuhr),
            _buildPrayerTimeRow('Asr', _prayerTimes!.asr),
            _buildPrayerTimeRow('Maghrib', _prayerTimes!.maghrib),
            _buildPrayerTimeRow('Isha', _prayerTimes!.isha),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Method: ${_prayerTimes!.method}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerTimeRow(String name, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            time,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMosquesList() {
    return Column(
      children: _nearbyMosques.map((mosque) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: const Icon(Icons.mosque),
            title: Text(mosque.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (mosque.address case final address?) Text(address),
                if (mosque.distance case final distance?)
                  Text(
                    '${distance.toStringAsFixed(1)} km away',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _showMosqueDetails(mosque);
            },
          ),
        );
      }).toList(),
    );
  }

  void _showMosqueDetails(mosque_model.Mosque mosque) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                mosque.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              if (mosque.address case final address?)
                Text(address),
              if (mosque.phone case final phone?)
                Text('Phone: $phone'),
              if (mosque.distance case final distance?)
                Text('Distance: ${distance.toStringAsFixed(1)} km'),
            ],
          ),
        );
      },
    );
  }
}