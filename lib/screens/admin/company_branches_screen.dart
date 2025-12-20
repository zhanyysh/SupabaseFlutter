import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/admin_logger.dart';

class CompanyBranchesScreen extends StatefulWidget {
  final String companyId;
  const CompanyBranchesScreen({super.key, required this.companyId});

  @override
  State<CompanyBranchesScreen> createState() => _CompanyBranchesScreenState();
}

class _CompanyBranchesScreenState extends State<CompanyBranchesScreen> {
  List<Map<String, dynamic>> branches = [];
  bool loading = true;
  final MapController _mapController = MapController();
  LatLng _selectedLocation = const LatLng(42.8746, 74.5698); // Default Bishkek
  final TextEditingController _addressCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadBranches();
  }

  Future<void> loadBranches() async {
    setState(() => loading = true);
    try {
      final data = await Supabase.instance.client
          .from('company_branches')
          .select()
          .eq('company_id', widget.companyId);
      setState(() {
        branches = List<Map<String, dynamic>>.from(data);
        loading = false;
      });
    } catch (e) {
      // If table doesn't exist or error
      setState(() => loading = false);
    }
  }

  Future<void> _addBranch() async {
    if (_addressCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите название/адрес филиала')),
      );
      return;
    }

    try {
      await Supabase.instance.client.from('company_branches').insert({
        'company_id': widget.companyId,
        'name': _addressCtrl.text,
        'latitude': _selectedLocation.latitude,
        'longitude': _selectedLocation.longitude,
      });
      _addressCtrl.clear();
      loadBranches();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  void _showAddDialog() {
    bool isVip = false;
    LatLng tempLocation = _selectedLocation;

    showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                contentPadding: EdgeInsets.zero,
                content: SizedBox(
                  width: double.maxFinite,
                  height: 500,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Text(
                              'Добавить филиал',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _addressCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Название / Адрес',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Text('Большой магазин (VIP):'),
                                const Spacer(),
                                Switch(
                                  value: isVip,
                                  onChanged: (val) {
                                    setState(() => isVip = val);
                                  },
                                  activeColor: const Color(0xFF00A2FF),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(20),
                          ),
                          child: Stack(
                            children: [
                              FlutterMap(
                                mapController: _mapController,
                                options: MapOptions(
                                  initialCenter: tempLocation,
                                  initialZoom: 13,
                                  onTap: (tapPosition, point) {
                                    setState(() {
                                      tempLocation = point;
                                      _selectedLocation =
                                          point; // Update parent state too if needed
                                    });
                                  },
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate:
                                        Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
                                            : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                                    subdomains: const ['a', 'b', 'c', 'd'],
                                    userAgentPackageName: 'com.example.app',
                                  ),
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: tempLocation,
                                        width: isVip ? 60 : 40,
                                        height: isVip ? 60 : 40,
                                        child:
                                            isVip
                                                ? Container(
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: const Color(
                                                        0xFF00A2FF,
                                                      ),
                                                      width: 2,
                                                    ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: const Color(
                                                          0xFF00A2FF,
                                                        ).withOpacity(0.5),
                                                        blurRadius: 8,
                                                        spreadRadius: 2,
                                                      ),
                                                    ],
                                                  ),
                                                  child: const CircleAvatar(
                                                    backgroundColor:
                                                        Colors.black,
                                                    child: Icon(
                                                      Icons.star,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                )
                                                : const Icon(
                                                  Icons.location_on,
                                                  color: Colors.red,
                                                  size: 40,
                                                ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Positioned(
                                top: 10,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'Нажмите на карту для выбора',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Отмена'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A2FF),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _addBranchWithVip(isVip),
                    child: const Text('Добавить'),
                  ),
                ],
              );
            },
          ),
    );
  }

  Future<void> _addBranchWithVip(bool isVip) async {
    if (_addressCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите название/адрес филиала')),
      );
      return;
    }

    try {
      await Supabase.instance.client.from('company_branches').insert({
        'company_id': widget.companyId,
        'name': _addressCtrl.text,
        'latitude': _selectedLocation.latitude,
        'longitude': _selectedLocation.longitude,
        'is_vip': isVip,
      });
      await AdminLogger.log(
        'add_branch',
        'Добавлен филиал: ${_addressCtrl.text}',
      );
      _addressCtrl.clear();
      loadBranches();
      Navigator.pop(context);
    } catch (e) {
      // Check for the specific error about missing column
      if (e.toString().contains("Could not find the 'is_vip' column")) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Ошибка: В базе данных нет колонки "is_vip". Выполните SQL скрипт.',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    }
  }

  Future<void> _deleteBranch(String id) async {
    try {
      await Supabase.instance.client
          .from('company_branches')
          .delete()
          .eq('id', id);

      await AdminLogger.log('delete_branch', 'Удален филиал ID: $id');

      loadBranches();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Филиалы магазина')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add_location),
      ),
      body:
          loading
              ? const Center(child: CircularProgressIndicator())
              : branches.isEmpty
              ? const Center(child: Text('Нет филиалов'))
              : ListView.builder(
                itemCount: branches.length,
                itemBuilder: (context, index) {
                  final b = branches[index];
                  return ListTile(
                    leading: const Icon(Icons.store),
                    title: Text(b['name'] ?? 'Филиал'),
                    subtitle: Text('${b['latitude']}, ${b['longitude']}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteBranch(b['id']),
                    ),
                  );
                },
              ),
    );
  }
}
