import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../model/admin_panel_models.dart';

final areasProvider = AsyncNotifierProvider<AreasNotifier, List<Area>>(
  AreasNotifier.new,
);

final equipmentsProvider = AsyncNotifierProvider<EquipmentsNotifier, List<Equipment>>(
  EquipmentsNotifier.new,
);

class AreasNotifier extends AsyncNotifier<List<Area>> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  @override
  Future<List<Area>> build() async {
    return _fetchAreas();
  }

  Future<List<Area>> _fetchAreas() async {
    final snapshot = await _dbRef.child('Admin Panel/areas').get();
    if (snapshot.exists) {
      final Map<dynamic, dynamic> values = snapshot.value as Map<dynamic, dynamic>;
      return values.entries.map((entry) {
        return Area.fromMap({
          ...entry.value as Map<dynamic, dynamic>,
          'id': entry.key,
        });
      }).toList();
    }
    return [];
  }

  // ✅ Agregado este método
  Future<List<Area>> getAreas() async {
    return await _fetchAreas();
  }

  Future<String> addArea(Area area) async {
    final newAreaRef = _dbRef.child('Admin Panel/areas').push();
    await newAreaRef.set(area.toMap());
    ref.invalidateSelf(); // Refrescar la lista
    return newAreaRef.key!;
  }

  Future<void> updateArea(Area area) async {
    await _dbRef.child('Admin Panel/areas/${area.id}').update(area.toMap());
    ref.invalidateSelf();
  }

  Future<void> deleteArea(String id) async {
    await _dbRef.child('Admin Panel/areas/$id').remove();
    ref.invalidateSelf();
  }
}

class EquipmentsNotifier extends AsyncNotifier<List<Equipment>> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  @override
  Future<List<Equipment>> build() async {
    return _fetchEquipments();
  }

  Future<List<Equipment>> _fetchEquipments() async {
    final snapshot = await _dbRef.child('Admin Panel/equipments').get();
    if (snapshot.exists) {
      final Map<dynamic, dynamic> values = snapshot.value as Map<dynamic, dynamic>;
      return values.entries.map((entry) {
        return Equipment.fromMap({
          ...entry.value as Map<dynamic, dynamic>,
          'id': entry.key,
        });
      }).toList();
    }
    return [];
  }

  Future<String> addEquipment(Equipment equipment) async {
    final newEquipmentRef = _dbRef.child('Admin Panel/equipments').push();
    await newEquipmentRef.set(equipment.toMap());
    ref.invalidateSelf();
    return newEquipmentRef.key!;
  }

  Future<void> updateEquipment(Equipment equipment) async {
    await _dbRef.child('Admin Panel/equipments/${equipment.id}').update(equipment.toMap());
    ref.invalidateSelf();
  }

  Future<void> deleteEquipment(String id) async {
    await _dbRef.child('Admin Panel/equipments/$id').remove();
    ref.invalidateSelf();
  }
}