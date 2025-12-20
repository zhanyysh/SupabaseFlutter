import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<Map<String, dynamic>> _branches = [];
  bool _loading = true;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _loadAllBranches();
  }

  Future<void> _loadAllBranches() async {
    try {
      // Загружаем филиалы вместе с данными о компании (логотип, название, скидка)
      final data = await Supabase.instance.client
          .from('company_branches')
          .select('*, companies(name, logo_url, discount_percentage)');

      if (mounted) {
        setState(() {
          _branches = List<Map<String, dynamic>>.from(data);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        // Не показываем ошибку пользователю слишком навязчиво, если просто нет данных
        print('Ошибка загрузки карты: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Карта магазинов')),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : FlutterMap(
                mapController: _mapController,
                options: const MapOptions(
                  // Центр карты: Бишкек, Кыргызстан
                  initialCenter: LatLng(42.8746, 74.5698),
                  initialZoom: 12,
                ),
                children: [
                  TileLayer(
                    // Switch map style based on theme
                    urlTemplate:
                        Theme.of(context).brightness == Brightness.dark
                            ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
                            : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    userAgentPackageName: 'com.example.applearn',
                  ),
                  MarkerLayer(
                    markers:
                        _branches
                            .map((branch) {
                              final lat = branch['latitude'] as double?;
                              final lng = branch['longitude'] as double?;
                              final company =
                                  branch['companies'] as Map<String, dynamic>?;
                              final logoUrl = company?['logo_url'] as String?;
                              final name = company?['name'] as String? ?? '';
                              final isVip =
                                  branch['is_vip'] ==
                                  true; // Check the VIP flag

                              if (lat == null || lng == null) return null;

                              // Если есть логотип ИЛИ флаг VIP, считаем магазин "большим"
                              final isBigShop =
                                  isVip ||
                                  (logoUrl != null && logoUrl.isNotEmpty);

                              return Marker(
                                point: LatLng(lat, lng),
                                // Увеличиваем размер для магазинов с логотипом, чтобы вместить текст
                                width: isBigShop ? 120 : 40,
                                height: isBigShop ? 80 : 40,
                                child: GestureDetector(
                                  onTap: () => _showBranchDetails(branch),
                                  child: _buildMarkerIcon(
                                    logoUrl,
                                    name,
                                    isBigShop,
                                  ),
                                ),
                              );
                            })
                            .whereType<Marker>()
                            .toList(),
                  ),
                ],
              ),
    );
  }

  Widget _buildMarkerIcon(String? logoUrl, String name, bool isBigShop) {
    if (isBigShop) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF00A2FF),
                  width: 2,
                ), // Голубая обводка
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00A2FF).withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: CircleAvatar(
                backgroundImage: logoUrl != null ? NetworkImage(logoUrl) : null,
                backgroundColor: Colors.black,
                child:
                    logoUrl == null
                        ? const Icon(Icons.star, color: Colors.white)
                        : null,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }
    // Маленькие точки для обычных филиалов (без лого)
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black,
        border: Border.all(color: const Color(0xFF00A2FF), width: 2),
      ),
      child: const Center(
        child: Icon(Icons.circle, color: Color(0xFF00A2FF), size: 15),
      ),
    );
  }

  void _showBranchDetails(Map<String, dynamic> branch) {
    final company = branch['companies'] as Map<String, dynamic>?;
    final name = company?['name'] ?? 'Магазин';
    final address = branch['name'] ?? 'Адрес не указан';
    final discount = company?['discount_percentage'] ?? 0;
    final logoUrl = company?['logo_url'];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (ctx) => Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (logoUrl != null)
                  CircleAvatar(
                    radius: 35,
                    backgroundImage: NetworkImage(logoUrl),
                  )
                else
                  const Icon(Icons.store, size: 60, color: Colors.deepPurple),
                const SizedBox(height: 15),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  address,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    'Скидка $discount%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }
}
