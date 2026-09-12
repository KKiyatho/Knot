import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_options.dart';

class KnotFirebaseService {
  KnotFirebaseService._();
  static final instance = KnotFirebaseService._();

  bool isReady = false;
  User? user;
  FirebaseAnalytics? analytics;
  bool get isGoogleLinked =>
      user?.providerData.any((p) => p.providerId == 'google.com') ?? false;

  Future<void> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: kIsWeb ? DefaultFirebaseOptions.web : null,
        );
      }
      user =
          FirebaseAuth.instance.currentUser ??
          (await FirebaseAuth.instance.signInAnonymously()).user;
      analytics = FirebaseAnalytics.instance;
      isReady = user != null;
    } on FirebaseException {
      isReady = false;
    } catch (_) {
      isReady = false;
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final UserCredential credential;
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        final currentUser = FirebaseAuth.instance.currentUser;
        credential = currentUser?.isAnonymous == true
            ? await currentUser!.linkWithPopup(provider)
            : await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        await GoogleSignIn.instance.initialize();
        final account = await GoogleSignIn.instance.authenticate();
        final googleAuth = account.authentication;
        final firebaseCredential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );
        final currentUser = FirebaseAuth.instance.currentUser;
        credential = currentUser?.isAnonymous == true
            ? await currentUser!.linkWithCredential(firebaseCredential)
            : await FirebaseAuth.instance.signInWithCredential(
                firebaseCredential,
              );
      }
      user = credential.user;
      isReady = user != null;
      await analytics?.logLogin(loginMethod: 'google');
      return credential;
    } on FirebaseAuthException catch (error) {
      if (error.code == 'credential-already-in-use' &&
          error.credential != null) {
        final result = await FirebaseAuth.instance.signInWithCredential(
          error.credential!,
        );
        user = result.user;
        isReady = user != null;
        return result;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> submitClaim({
    required String routineId,
    required String eventId,
    required String dateKey,
  }) async {
    final currentUser = user;
    if (!isReady || currentUser == null) return;

    final claim = FirebaseDatabase.instance.ref(
      'users/${currentUser.uid}/claims/$routineId/$dateKey',
    );
    try {
      await claim.set({'eventId': eventId, 'createdAt': ServerValue.timestamp});
      await analytics?.logEvent(
        name: 'routine_claimed',
        parameters: {'routine_id': routineId},
      );
    } on FirebaseException {
      // Local completion remains valid when the network is unavailable.
    }
  }

  Future<Set<String>> loadClaimKeys() async {
    final currentUser = user;
    if (!isReady || currentUser == null) return {};

    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('users/${currentUser.uid}/claims')
          .get();
      final keys = <String>{};
      for (final routine in snapshot.children) {
        for (final date in routine.children) {
          keys.add('${routine.key}|${date.key}');
        }
      }
      return keys;
    } on FirebaseException {
      return {};
    }
  }
}
