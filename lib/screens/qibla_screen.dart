import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'dart:math' as math;

class QiblaScreen extends StatefulWidget {
  final Position? initialPosition;
  final String? initialLocationName;
  
  const QiblaScreen({
    super.key,
    this.initialPosition,
    this.initialLocationName,
  });

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  double? _qiblaDirection;
  double? _currentHeading;
  bool _isLoading = true;
  String? _errorMessage;
  Position? _currentPosition;
  String? _locationName;

  @override
  void initState() {
    super.initState();
    _initializeQibla();
    _initCompass();
  }

  Future<void> _initializeQibla() async {
    // Use provided position if available
    if (widget.initialPosition != null) {
      _calculateQiblaFromPosition(
        widget.initialPosition!,
        widget.initialLocationName ?? 'Current Location',
      );
    } else {
      _calculateQibla();
    }
  }

  void _initCompass() {
    FlutterCompass.events?.listen((CompassEvent event) {
      if (mounted) {
        setState(() {
          _currentHeading = event.heading;
        });
      }
    });
  }

  double get _qiblaAngle {
    if (_currentHeading == null || _qiblaDirection == null) return 0;
    return (_qiblaDirection! - _currentHeading!);
  }

  void _calculateQiblaFromPosition(Position position, String locationName) {
    const double kaabaLat = 21.4225;
    const double kaabaLon = 39.8262;

    final qibla = _calculateQiblaDirection(
      position.latitude,
      position.longitude,
      kaabaLat,
      kaabaLon,
    );

    setState(() {
      _currentPosition = position;
      _locationName = locationName;
      _qiblaDirection = qibla;
      _isLoading = false;
    });
  }

  Future<void> _calculateQibla() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get current location
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

      // Qibla coordinates
      const double kaabaLat = 21.4225;  // Makkah latitude
      const double kaabaLon = 39.8262;  // Makkah longitude

      // Calculate Qibla direction
      final qibla = _calculateQiblaDirection(
        position.latitude,
        position.longitude,
        kaabaLat,
        kaabaLon,
      );

      setState(() {
        _currentPosition = position;
        _qiblaDirection = qibla;
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  double _calculateQiblaDirection(
    double userLat,
    double userLon,
    double kaabaLat,
    double kaabaLon,
  ) {
    // Convert to radians
    final lat1 = userLat * math.pi / 180;
    final lon1 = userLon * math.pi / 180;
    final lat2 = kaabaLat * math.pi / 180;
    final lon2 = kaabaLon * math.pi / 180;

    // Calculate bearing
    final dLon = lon2 - lon1;
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    final bearing = math.atan2(y, x) * 180 / math.pi;

    // Normalize to 0-360
    return (bearing + 360) % 360;
  }

  String _getCardinalDirection(double bearing) {
    const directions = ['North', 'Northeast', 'East', 'Southeast', 'South', 'Southwest', 'West', 'Northwest'];
    final index = ((bearing + 22.5) % 360 / 45).floor();
    return directions[index];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: Text(
            'Qibla Direction',
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
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
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _calculateQibla,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Compass display with ROTATING ARROW
                        Container(
                          width: 280,
                          height: 280,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? Colors.grey[800] : Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Compass circle with degree marks
                              Container(
                                width: 260,
                                height: 260,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.blue.shade600,
                                    width: 3,
                                  ),
                                ),
                              ),
                              // ROTATING Qibla arrow based on device heading
                              if (_currentHeading != null)
                                Transform.rotate(
                                  angle: _qiblaAngle * math.pi / 180,
                                  child: Icon(
                                    Icons.navigation,
                                    size: 120,
                                    color: Colors.blue.shade600,
                                  ),
                                )
                              else
                                const CircularProgressIndicator(),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Direction info
                        Card(
                          margin: const EdgeInsets.symmetric(horizontal: 32),
                          color: isDark ? Colors.grey[850] : null,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                Text(
                                  '${_qiblaDirection!.toStringAsFixed(1)}°',
                                  style: TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _getCardinalDirection(_qiblaDirection!),
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Divider(),
                                const SizedBox(height: 16),
                                Text(
                                  'Your Location',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                if (_locationName != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    _locationName!,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                                if (_currentPosition != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Lat: ${_currentPosition!.latitude.toStringAsFixed(4)}, '
                                    'Lon: ${_currentPosition!.longitude.toStringAsFixed(4)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Refresh button
                        OutlinedButton.icon(
                          onPressed: _calculateQibla,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Recalculate'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Info text
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            'Point your device in the direction of the arrow to face the Qibla in Makkah',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}