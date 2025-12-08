import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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
  bool _isLoading = true;
  String? _errorMessage;
  Position? _currentPosition;
  String? _locationName;

  @override
  void initState() {
    super.initState();
    _initializeQibla();
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

      // Kaaba coordinates
      const double kaabaLat = 21.4225;  // Mecca latitude
      const double kaabaLon = 39.8262;  // Mecca longitude

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Qibla Direction'),
        backgroundColor: Colors.blue.shade600,
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
                        // Compass display
                        Container(
                          width: 280,
                          height: 280,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
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
                              // Qibla arrow
                              Transform.rotate(
                                angle: _qiblaDirection! * math.pi / 180,
                                child: Icon(
                                  Icons.navigation,
                                  size: 120,
                                  color: Colors.blue.shade600,
                                ),
                              ),
                              // Kaaba icon in center
                              const Icon(
                                Icons.home,
                                size: 40,
                                color: Colors.black87,
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Direction info
                        Card(
                          margin: const EdgeInsets.symmetric(horizontal: 32),
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
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
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
                            'Point your device in the direction of the arrow to face the Kaaba in Mecca',
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
}