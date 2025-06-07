// import 'package:firebase_database/firebase_database.dart';

// class DatabaseCleanupUtils {
//   static Future<bool> cleanupReservationsCollection() async {
//     try {
//       // Get a reference to the reservations collection
//       final ref = FirebaseDatabase.instance.ref('Admin Panel/reservations');

//       // Read the current data
//       final snapshot = await ref.get();

//       if (snapshot.exists && snapshot.value is Map) {
//         // Create a map of updates to clean up the data
//         Map<String, dynamic> updates = {};

//         // Mark empty string fields for removal
//         updates["branch_id"] = null;
//         updates["client_id"] = null;
//         updates["created_at"] = null;
//         updates["dress_id"] = null;
//         updates["reservation_date"] = null;
//         updates["reservation_time"] = null;
//         updates["service_id"] = null;
//         updates["updated_at"] = null;

//         // Apply the updates
//         await ref.update(updates);

//         print("Database cleanup completed successfully");
//         return true;
//       }

//       return false;
//     } catch (e) {
//       print("Error cleaning up database: $e");
//       return false;
//     }
//   }
// }
