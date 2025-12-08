import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'qibla_screen.dart';

class SettingsScreen extends StatefulWidget {
  final Position? currentPosition;
  final String locationName;
  final String calculationMethod;
  final String asrMethod;
  final Function(Position, String) onLocationChanged;
  final Function(String) onCalculationMethodChanged;
  final Function(String) onAsrMethodChanged;

  const SettingsScreen({
    super.key,
    required this.currentPosition,
    required this.locationName,
    required this.calculationMethod,
    required this.asrMethod,
    required this.onLocationChanged,
    required this.onCalculationMethodChanged,
    required this.onAsrMethodChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _cityController;
  late String _selectedCalculationMethod;
  late String _selectedAsrMethod;
  Position? _selectedPosition;
  String? _selectedLocationName;
  bool _isInitialized = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _cityController = TextEditingController(text: widget.locationName);
    _selectedCalculationMethod = widget.calculationMethod;
    _selectedAsrMethod = widget.asrMethod;
    _selectedPosition = widget.currentPosition;
    _selectedLocationName = widget.locationName;
    
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  void _handleSave() {
    FocusScope.of(context).unfocus();
    
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      
      Navigator.pop(context, {
        'position': _selectedPosition,
        'locationName': _selectedLocationName,
        'calculationMethod': _selectedCalculationMethod,
        'asrMethod': _selectedAsrMethod,
      });
    });
  }

  void _handleBack() {
    FocusScope.of(context).unfocus();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      Navigator.pop(context);
    });
  }

  Future<void> _searchCity() async {
    if (_cityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a city name')),
      );
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      List<Location> locations = await locationFromAddress(_cityController.text.trim());
      
      if (locations.isEmpty) {
        throw Exception('Location not found');
      }

      final location = locations.first;
      
      if (!mounted) return;

      setState(() {
        _selectedPosition = Position(
          latitude: location.latitude,
          longitude: location.longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
        _selectedLocationName = _cityController.text.trim();
        _isSearching = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Found: $_selectedLocationName'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isSearching = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location not found. Try: "City, State" or "City, Country"'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _handleLocationTap() async {
    if (!mounted) return;
    
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 16),
              Text('Getting your location...'),
            ],
          ),
          duration: Duration(seconds: 10),
        ),
      );

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

      if (!mounted) return;

      String cityName = 'Location Found';
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          cityName = place.locality ?? place.administrativeArea ?? 'Unknown Location';
          if (place.administrativeArea != null && place.locality != place.administrativeArea) {
            cityName += ', ${place.administrativeArea}';
          }
        }
      } catch (e) {
        debugPrint('Could not get city name: $e');
      }

      setState(() {
        _selectedPosition = position;
        _selectedLocationName = cityName;
        _cityController.text = cityName;
      });

      if (!mounted) return;  // Add mounted check before using context

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Location: $cityName'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.blue.shade600,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _handleBack,
        ),
        actions: [
          TextButton(
            onPressed: _handleSave,
            child: const Text(
              'Save',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: !_isInitialized
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Location Section
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Location',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _cityController,
                                    decoration: InputDecoration(
                                      hintText: 'Enter city (e.g., New York, NY)',
                                      filled: true,
                                      fillColor: Colors.grey.shade100,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
                                      ),
                                    ),
                                    onSubmitted: (_) => _searchCity(),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: _isSearching ? null : _searchCity,
                                  icon: _isSearching
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Icon(Icons.search),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.blue.shade600,
                                    foregroundColor: Colors.white,
                                  ),
                                  tooltip: 'Search location',
                                ),
                              ],
                            ),
                            if (_selectedPosition != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Lat: ${_selectedPosition!.latitude.toStringAsFixed(4)}, '
                                'Lon: ${_selectedPosition!.longitude.toStringAsFixed(4)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.grey.shade200),
                          ),
                        ),
                        child: ListTile(
                          leading: Icon(Icons.my_location, color: Colors.blue.shade600),
                          title: const Text('Use Current GPS Location'),
                          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                          onTap: _handleLocationTap,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Calculation Method
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Calculation Method',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCalculationMethod,
                            isExpanded: true,
                            items: ['ISNA', 'MWL', 'EGYPTIAN', 'KARACHI', 'MAKKAH', 'TEHRAN']
                                .map((method) => DropdownMenuItem(
                                      value: method,
                                      child: Text(method),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() => _selectedCalculationMethod = value!);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Asr Calculation
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Asr Calculation',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedAsrMethod,
                            isExpanded: true,
                            items: ['standard', 'hanafi']
                                .map((method) => DropdownMenuItem(
                                      value: method,
                                      child: Text(
                                        method == 'standard' ? 'Standard' : 'Hanafi',
                                      ),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() => _selectedAsrMethod = value!);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Qibla Direction
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Qibla Direction',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.explore,
                            color: Colors.blue.shade600,
                          ),
                        ),
                        title: const Text(
                          'Find Qibla',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: const Text('Compass pointing to Makkah'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => QiblaScreen(
                                initialPosition: _selectedPosition,
                                initialLocationName: _selectedLocationName,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}