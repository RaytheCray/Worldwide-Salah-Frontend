import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'qibla_screen.dart';

class SettingsScreen extends StatefulWidget {
  final String location;
  final String calculationMethod;
  final String asrMethod;
  final Function(String) onLocationChanged;
  final Function(String) onCalculationMethodChanged;
  final Function(String) onAsrMethodChanged;

  const SettingsScreen({
    super.key,
    required this.location,
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
  late TextEditingController _locationController;
  late String _selectedCalculationMethod;
  late String _selectedAsrMethod;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _locationController = TextEditingController(text: widget.location);
    _selectedCalculationMethod = widget.calculationMethod;
    _selectedAsrMethod = widget.asrMethod;
    
    // Delay initialization to avoid vsync timing conflicts with page transition
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
    _locationController.dispose();
    super.dispose();
  }

  void _handleSave() {
    // Unfocus any text fields to stop animations before navigating
    FocusScope.of(context).unfocus();
    
    // Small delay to let animations stop
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      
      // Pop first, then update parent state
      Navigator.pop(context, {
        'location': _locationController.text,
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

  // ✅ UPDATED: GPS Location Implementation
  Future<void> _handleLocationTap() async {
    if (!mounted) return;
    
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              const Text('Getting your location...'),
            ],
          ),
          duration: const Duration(seconds: 10),
        ),
      );

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled. Please enable them in settings.');
      }

      // Check and request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied. Please grant permission in settings.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permission permanently denied. Please enable in settings.');
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      // Update location text field
      setState(() {
        _locationController.text = 
            'Lat: ${position.latitude.toStringAsFixed(4)}, '
            'Lng: ${position.longitude.toStringAsFixed(4)}';
      });

      // Show success message
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Location updated successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

    } catch (e) {
      if (!mounted) return;
      
      // Show error message
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
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
          ? const Center(
              child: CircularProgressIndicator(),
            )
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
                            TextField(
                              controller: _locationController,
                              decoration: InputDecoration(
                                hintText: 'Enter city or address',
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
                            ),
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
                          title: const Text('Use Current Location'),
                          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                          onTap: _handleLocationTap,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Calculation Method Section
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
                                      child: Text(
                                        method,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
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
                
                // ✅ FIXED: Asr Calculation - Changed to lowercase values
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
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
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
                
                // ✅ NEW: Qibla Direction Section
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
                        subtitle: const Text('Compass pointing to Mecca'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const QiblaScreen(),
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