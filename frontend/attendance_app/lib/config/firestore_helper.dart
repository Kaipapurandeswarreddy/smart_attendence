import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Returns the Firestore instance pointing to the correct database.
///
/// This project uses a Firestore database named "default" (without
/// parentheses), NOT the standard "(default)".  Using
/// `FirebaseFirestore.instance` would connect to "(default)" which
/// does not exist, causing silent read failures.
FirebaseFirestore getFirestore() {
  return FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'default',
  );
}
