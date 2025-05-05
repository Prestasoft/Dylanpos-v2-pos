import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:salespro_admin/model/ServicePackageModel.dart';

class ServicePackageRepository {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  // Obtener todos los paquetes de servicio
  Future<List<ServicePackageModel>> getAllPackages() async {
    try {
      final querySnapshot =
          await _firebaseFirestore.collection('services').get();

      return querySnapshot.docs
          .map((doc) => ServicePackageModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error al cargar los paquetes: $e');
      return [];
    }
  }

  // Agregar un paquete de servicio
  Future<bool> addPackage(ServicePackageModel newPackage) async {
    try {
      await _firebaseFirestore.collection('services').add({
        'name': newPackage.name,
        'category': newPackage.category,
        'subcategory': newPackage.subcategory,
        'price': newPackage.price,
        'duration': newPackage.duration,
        'components': newPackage.components,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error al agregar el paquete: $e');
      return false;
    }
  }

  // Actualizar un paquete de servicio
  Future<bool> updatePackage(ServicePackageModel updatedPackage) async {
    try {
      await _firebaseFirestore
          .collection('services')
          .doc(updatedPackage.id)
          .update({
        'name': updatedPackage.name,
        'category': updatedPackage.category,
        'subcategory': updatedPackage.subcategory,
        'price': updatedPackage.price,
        'duration': updatedPackage.duration,
        'components': updatedPackage.components,
        'updated_at': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error al actualizar el paquete: $e');
      return false;
    }
  }

  // Eliminar un paquete de servicio
  Future<bool> deletePackage(String packageId) async {
    try {
      await _firebaseFirestore.collection('services').doc(packageId).delete();
      return true;
    } catch (e) {
      print('Error al eliminar el paquete: $e');
      return false;
    }
  }
}
