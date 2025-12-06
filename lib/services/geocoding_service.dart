import 'package:geocoding/geocoding.dart';
import 'package:flutter/material.dart';

class GeocodingService {
  /// Get readable location from coordinates
  static Future<String> getLocationName(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );
      
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        
        // Build location string: "City, State" or "City, Country"
        List<String> parts = [];
        
        if (place.locality != null && place.locality!.isNotEmpty) {
          parts.add(place.locality!);
        } else if (place.subAdministrativeArea != null) {
          parts.add(place.subAdministrativeArea!);
        }
        
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
          parts.add(place.administrativeArea!);
        } else if (place.country != null) {
          parts.add(place.country!);
        }
        
        return parts.isNotEmpty ? parts.join(', ') : 'Unknown Location';
      }
      
      return 'Unknown Location';
    } catch (e) {
      debugPrint('❌ Geocoding error: $e');
      return 'Lat: ${latitude.toStringAsFixed(4)}, Lng: ${longitude.toStringAsFixed(4)}';
    }
  }
}