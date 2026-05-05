import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:io';
import '../models/models.dart';

class FB {
  static final _auth = FirebaseAuth.instance;
  static final _db   = FirebaseFirestore.instance;
  static final _st   = FirebaseStorage.instance;
  static final _google = GoogleSignIn();

  /* ── AUTH ── */
  static Future<UserCredential> signIn(String email, String pass) =>
      _auth.signInWithEmailAndPassword(email: email, password: pass);

  static Future<UserCredential> register(String email, String pass) =>
      _auth.createUserWithEmailAndPassword(email: email, password: pass);

  static Future<UserCredential?> signInWithGoogle() async {
    try {
      final googleUser = await _google.signIn();
      if (googleUser == null) return null;
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final result = await _auth.signInWithCredential(credential);
      // Save profile if new user
      if (result.additionalUserInfo?.isNewUser == true) {
        final u = result.user!;
        await saveProfile(u.uid, {
          'fname': u.displayName?.split(' ').first ?? '',
          'lname': u.displayName?.split(' ').skip(1).join(' ') ?? '',
          'email': u.email ?? '',
          'phone': u.phoneNumber ?? '',
          'avatar': u.photoURL ?? '',
          'joined': DateTime.now().toIso8601String(),
          'provider': 'google',
        });
      }
      return result;
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> signOut() async {
    await _google.signOut();
    await _auth.signOut();
  }

  /* ── PROFILE ── */
  static Future<void> saveProfile(String uid, Map<String, dynamic> data) =>
      _db.collection('users').doc(uid).set(data, SetOptions(merge: true));

  static Future<Map<String, dynamic>> getProfile(String uid) async {
    final s = await _db.collection('users').doc(uid).get();
    return s.data() ?? {};
  }

  /* ── IMAGE UPLOAD ── */
  static Future<String> uploadImage(File file, String path) async {
    final ref = _st.ref().child(path);
    final task = await ref.putFile(file);
    return await task.ref.getDownloadURL();
  }

  /* ── STREAMS ── */
  static Stream<List<Category>> categoriesStream() =>
      _db.collection('categories').snapshots().map((s) =>
          s.docs.map((d) => Category(id: d.id, name: d['name'] ?? '', image: d['image'])).toList());

  static Stream<List<MenuItem>> itemsStream() =>
      _db.collection('items').snapshots().map((s) =>
          s.docs.map((d) => MenuItem(
            id: d.id,
            name: d['name'] ?? '',
            price: (d['price'] as num?)?.toDouble() ?? 0,
            salePrice: (d['salePrice'] as num?)?.toDouble(),
            description: d['description'],
            image: d['image'],
            categoryId: d['categoryId'] ?? '',
            available: d['available'] != false,
          )).toList());

  static Stream<List<Offer>> offersStream() =>
      _db.collection('offers').snapshots().map((s) =>
          s.docs.map((d) => Offer(
            id: d.id,
            title: d['title'] ?? '',
            description: d['description'],
            image: d['image'],
            discount: (d['discount'] as num?)?.toInt() ?? 0,
          )).toList());

  static Stream<Map<String, dynamic>> settingsStream() =>
      _db.collection('settings').doc('main').snapshots()
          .map((s) => s.data() ?? {});

  static Stream<List<RestaurantOrder>> userOrdersStream(String uid) =>
      _db.collection('orders')
          .where('userId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((s) => s.docs.map((d) => RestaurantOrder(
            id: d.id,
            status: d['status'] ?? 'pending',
            total: (d['total'] as num?)?.toDouble() ?? 0,
            items: d['items'] ?? [],
            address: d['address'],
            customerName: d['customerName'],
            paymentMethod: d['paymentMethod'],
            createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
          )).toList());

  static Stream<List<Review>> reviewsStream() =>
      _db.collection('reviews').orderBy('createdAt', descending: true).snapshots()
          .map((s) => s.docs.map((d) => Review(
            id: d.id,
            name: d['name'] ?? 'مجهول',
            stars: (d['stars'] as num?)?.toInt() ?? 5,
            comment: d['comment'],
          )).toList());

  /* ── ORDERS ── */
  static Future<void> placeOrder(Map<String, dynamic> data) =>
      _db.collection('orders').add({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
      });
}
