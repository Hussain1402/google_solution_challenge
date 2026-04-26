import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/theme/colors.dart';
import '../../../core/models/sector_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../shared/widgets/app_drawer.dart';

// Provider to stream all 25 sectors for the map
final sectorsProvider = StreamProvider<List<SectorModel>>((ref) {
  return FirestoreService().streamSectors();
});

class GridMapScreen extends ConsumerStatefulWidget {
  const GridMapScreen({super.key});

  @override
  ConsumerState<GridMapScreen> createState() => _GridMapScreenState();
}

class _GridMapScreenState extends ConsumerState<GridMapScreen> {
  GoogleMapController? _mapController;

  // Center of the 5x5 grid (Pimpri-Chinchwad hub)
  static const LatLng _hubLocation = LatLng(18.6298, 73.8553);

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Color _getZoneColor(String zoneStatus) {
    switch (zoneStatus) {
      case 'SCARCITY':
        return kRed.withValues(alpha: 0.35);
      case 'NEUTRAL':
        return kGray.withValues(alpha: 0.25);
      case 'ABUNDANCE':
        return kGreen.withValues(alpha: 0.35);
      default:
        return Colors.transparent;
    }
  }

  Set<Polygon> _buildPolygons(List<SectorModel> sectors) {
    return sectors.map((sector) {
      final ne = LatLng(sector.boundingBox['ne']!['lat']!, sector.boundingBox['ne']!['lng']!);
      final sw = LatLng(sector.boundingBox['sw']!['lat']!, sector.boundingBox['sw']!['lng']!);

      // Define corners of the bounding box
      final points = [
        sw,
        LatLng(sw.latitude, ne.longitude),
        ne,
        LatLng(ne.latitude, sw.longitude),
      ];

      return Polygon(
        polygonId: PolygonId(sector.sectorId),
        points: points,
        fillColor: _getZoneColor(sector.zoneStatus),
        strokeColor: Colors.white,
        strokeWidth: 2,
        onTap: () {
          _showSectorDetails(sector);
        },
      );
    }).toSet();
  }

  void _showSectorDetails(SectorModel sector) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sector ${sector.sectorId} — ${sector.label}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kGray),
            ),
            const SizedBox(height: 12),
            Text('Zone Status: ${sector.zoneStatus}', 
                 style: TextStyle(fontSize: 16, color: _getStatusTextColor(sector.zoneStatus), fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Beneficiaries: ${sector.registeredBeneficiaries}'),
            Text('Donors: ${sector.registeredDonors}'),
            if (sector.activeDriveId != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                color: kLightAmb,
                child: Row(
                  children: [
                    const Icon(Icons.campaign, color: kAmber),
                    const SizedBox(width: 8),
                    Text('Active Drive: ${sector.activeDriveId}', style: const TextStyle(fontWeight: FontWeight.w600, color: kAmber)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Color _getStatusTextColor(String status) {
    if (status == 'SCARCITY') return kRed;
    if (status == 'ABUNDANCE') return kGreen;
    return kMidGray;
  }

  @override
  Widget build(BuildContext context) {
    final sectorsAsync = ref.watch(sectorsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('The Grid'),
      ),
      drawer: const AppDrawer(),
      body: sectorsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error loading grid: $e')),
        data: (sectors) {
          return GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: _hubLocation,
              zoom: 12.5,
            ),
            onMapCreated: (controller) => _mapController = controller,
            polygons: _buildPolygons(sectors),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          );
        },
      ),
    );
  }
}
