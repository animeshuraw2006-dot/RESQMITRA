import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:io';
import 'services/sos_repository.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:camera/camera.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';

bool firebaseReady = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    firebaseReady = true;
    FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }
    } on FirebaseAuthException {
      // Email-link authentication remains available even if anonymous auth is disabled.
    }
  } catch (_) {
    firebaseReady = false;
  }
  runApp(const ResqMitraApp());
}

const navy = Color(0xFF082A4D);
const saffron = Color(0xFFFF7900);
const green = Color(0xFF078442);
const red = Color(0xFFE52335);
const blue = Color(0xFF0876C9);
const pink = Color(0xFFD41472);
const yellow = Color(0xFFFFC928);
const pale = Color(0xFFF4F8FC);

class ResqMitraApp extends StatelessWidget {
  const ResqMitraApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'RESQ-MITRA',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: green, primary: green),
          scaffoldBackgroundColor: pale,
          appBarTheme: const AppBarTheme(
            backgroundColor: pale, foregroundColor: navy, centerTitle: false,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true, fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        home: firebaseReady ? const SplashPage() : const FirebaseSetupPage(),
      );
}


class FirebaseSetupPage extends StatelessWidget {
  const FirebaseSetupPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Icon(Icons.cloud_off, size: 72, color: red),
        SizedBox(height: 16),
        Text('Cloud service not configured', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: navy)),
        SizedBox(height: 12),
        Text('RESQ-MITRA needs a Firebase project configuration to authenticate users, submit SOS requests, and store voice recordings. Add the correct Android google-services.json and configure Firebase for this app, then rebuild.', textAlign: TextAlign.center),
      ],
    )))),
  );
}

class Emergency {
  final String name, icon, detail;
  final Color color;
  const Emergency(this.name, this.icon, this.detail, this.color);
}

const generalItems = <Emergency>[
  Emergency('Medical Emergency', '✚', 'Medical help needed', Color(0xFFFFE4E9)),
  Emergency('Accident', '🚗', 'Road or other accident', Color(0xFFDDF8E2)),
  Emergency('Fire', '🔥', 'Fire or smoke', Color(0xFFFFE9D7)),
  Emergency('Flood / Water', '🌊', 'Flooding or water rescue', Color(0xFFDDF4FF)),
  Emergency('Rescue', '🛟', 'Immediate rescue needed', Color(0xFFE9E3FF)),
  Emergency('Evacuation', '🏃', 'Urgent evacuation', Color(0xFFFFF3BF)),
  Emergency('Missing Person', '🔎', 'Person missing', Color(0xFFDDF9F5)),
  Emergency('Shelter', '⛺', 'Safe shelter needed', Color(0xFFFFE1EF)),
  Emergency('Food & Water', '🥣', 'Food or drinking water needed', Color(0xFFE1F9DF)),
  Emergency('Blood Needed', '🩸', 'Urgent blood donor request', Color(0xFFFFE0E4)),
  Emergency('Other Emergency', '•••', 'Other urgent help', Color(0xFFE4EDF5)),
];
const womenItems = <Emergency>[
  Emergency('Immediate Danger', '⚠️', 'Immediate threat to safety', Color(0xFFFFE1EA)),
  Emergency('Harassment / Threat', '🛡️', 'Harassment or threat', Color(0xFFECE4FF)),
  Emergency('Unsafe Situation', '🚶', 'Unsafe surroundings', Color(0xFFFFE8D7)),
  Emergency('Medical Emergency', '✚', 'Medical help needed', Color(0xFFDDF8EF)),
  Emergency('Safe Transport / Escort', '🚘', 'Trusted escort or transport', Color(0xFFE9E5FF)),
  Emergency('Missing / Lost', '❓', 'Help locating someone', Color(0xFFFFE1EF)),
  Emergency('Safe Shelter', '🏠', 'Safe place needed', Color(0xFFDDF8F5)),
  Emergency('Other Women’s Emergency', '•••', 'Other women’s safety need', Color(0xFFE4EDF5)),
];
const childItems = <Emergency>[
  Emergency('Lost / Missing Child', '📍', 'Child is lost or missing', Color(0xFFDDF4FF)),
  Emergency('Abuse / Unsafe Touch', '✋', 'Child safety concern', Color(0xFFDDF8E2)),
  Emergency('Stranger Danger', '🕵️', 'Potential stranger threat', Color(0xFFFFE8D7)),
  Emergency('Bullying', '🧒', 'Bullying or intimidation', Color(0xFFECE4FF)),
  Emergency('Medical Emergency', '✚', 'Medical help needed', Color(0xFFDDF8F5)),
  Emergency('Safe Pickup / Trusted Adult', '🤝', 'Trusted adult assistance', Color(0xFFFFF3BF)),
  Emergency('Child in Danger', '🛡️', 'Immediate child safety threat', Color(0xFFFFE1EA)),
  Emergency('Other Child Emergency', '•••', 'Other child emergency', Color(0xFFE4EDF5)),
];

class SosDraft {
  String category = 'General SOS';
  String emergency = 'Medical Emergency';
  String notes = '';
  String blood = 'Any blood group';
  bool doNotCall = false;
  bool recordingRequested = false;
  String? audioLocalPath;
  bool highAlert = false;
  bool videoRequested = false;
}

class AppState extends ChangeNotifier {
  bool signedIn = false;
  bool responderMode = false;
  SosDraft? active;
  String? activeRequestId;
  String databaseStatus = 'Not submitted';
  Future<void> createSos(SosDraft draft) async {
    active = draft;
    notifyListeners();
    double? lat, lng, accuracy;
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      var permission = await Geolocator.checkPermission();
      if (enabled && permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (enabled && permission != LocationPermission.denied &&
          permission != LocationPermission.deniedForever) {
        final pos = await Geolocator.getCurrentPosition();
        lat = pos.latitude; lng = pos.longitude; accuracy = pos.accuracy;
      }
    } catch (_) {}
    try {
      String? audioUrl;
      final localAudioPath = draft.audioLocalPath;
      if (localAudioPath != null && Firebase.apps.isNotEmpty) {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid == null) throw StateError('Sign in is required to upload emergency audio.');
        final audioRef = FirebaseStorage.instance.ref('sos-audio/$uid/${DateTime.now().millisecondsSinceEpoch}.m4a');
        await audioRef.putFile(File(localAudioPath), SettableMetadata(contentType: 'audio/mp4'));
        audioUrl = await audioRef.getDownloadURL();
      }
      final id = await SosRepository.instance.createRequest(
        category: draft.category,
        emergencyType: draft.emergency,
        instructions: draft.notes,
        doNotCall: draft.doNotCall,
        bloodGroup: draft.blood,
        audioRequested: draft.recordingRequested,
        audioUrl: audioUrl,
        highAlert: draft.highAlert,
        videoRequested: draft.videoRequested,
        latitude: lat,
        longitude: lng,
        accuracyMeters: accuracy,
        // Use the current Firebase Auth UID for request ownership.
        requesterId: FirebaseAuth.instance.currentUser?.uid ?? (throw StateError('Sign in to submit an SOS request.')),
      );
      activeRequestId = id;
      databaseStatus = id == null ? 'SOS could not be submitted: Firebase is not configured.' : 'SOS submitted successfully';
    } catch (_) {
      databaseStatus = 'SOS submission failed. Check your connection and try again.';
    }
    notifyListeners();
  }
  Future<void> cancelSos() async {
    final id = activeRequestId;
    if (id != null) {
      try {
        await SosRepository.instance.updateStatus(id, 'cancelled');
      } catch (_) {
        // Keep local cancellation responsive if the remote update fails.
      }
    }
    active = null; activeRequestId = null; notifyListeners();
  }
}
final appState = AppState();

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override State<SplashPage> createState() => _SplashPageState();
}
class _SplashPageState extends State<SplashPage> {
  @override void initState() { super.initState(); Future.delayed(const Duration(milliseconds: 1700), () {
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthPage()));
    }
  }); }
  @override Widget build(BuildContext context) => Scaffold(
    body: Container(width: double.infinity, decoration: const BoxDecoration(gradient: LinearGradient(
      colors: [Color(0xFFFFF8F0), Colors.white, Color(0xFFEFFAF3)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
      child: SafeArea(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 230, height: 230, padding: const EdgeInsets.all(8), decoration: BoxDecoration(
          shape: BoxShape.circle, border: Border.all(color: saffron, width: 4)),
          child: ClipOval(child: Image.asset('assets/resq_mitra_logo.jpeg', fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.health_and_safety_rounded, size: 132, color: green)))),
        const SizedBox(height: 18),
        const Text('RESQ-MITRA', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: 1.1, color: navy)),
        const SizedBox(height: 6),
        const Text('NO LIFE LEFT BEHIND', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 2, color: green)),
        const SizedBox(height: 20), const CircularProgressIndicator(color: saffron),
        const SizedBox(height: 15), const Text('HELP  |  SUPPORT  |  TOGETHER', style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1.1)),
      ]))),
  );
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final email = TextEditingController();
  final _auth = FirebaseAuth.instance;
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  bool busy = false;

  // Replace YOUR_FIREBASE_PROJECT_ID with the Firebase project's Hosting/auth domain.
  static const emailContinueUrl =
      'https://YOUR_FIREBASE_PROJECT_ID.firebaseapp.com/finishSignIn';
  static const androidPackageName = 'com.resqmitra.resq_mitra';

  @override
  void initState() {
    super.initState();
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) => _completeEmailLink(uri.toString()),
      onError: (_) {},
    );
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        _completeEmailLink(uri.toString());
      }
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    email.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _friendlyError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'That email address is invalid. Check it and try again.';
      case 'user-disabled':
        return 'This account has been disabled. Contact support.';
      case 'operation-not-allowed':
        return 'Email-link sign-in is not enabled in Firebase Authentication.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a while and try again.';
      case 'invalid-action-code':
      case 'expired-action-code':
        return 'This sign-in link is invalid or expired. Request a new link.';
      case 'network-request-failed':
        return 'Network connection failed. Check your internet and try again.';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }

  Future<void> _enterApp() async {
    if (!mounted) {
      return;
    }
    appState.signedIn = true;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const PermissionsPage()),
    );
  }

  Future<void> _sendEmailLink() async {
    final address = email.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(address)) {
      _showMessage('Enter a valid email address.');
      return;
    }
    if (emailContinueUrl.contains('YOUR_FIREBASE_PROJECT_ID')) {
      _showMessage('Set emailContinueUrl in lib/main.dart to your Firebase project URL first.');
      return;
    }
    setState(() => busy = true);
    try {
      await _auth.sendSignInLinkToEmail(
        email: address,
        actionCodeSettings: ActionCodeSettings(
          url: emailContinueUrl,
          handleCodeInApp: true,
          androidPackageName: androidPackageName,
          androidInstallApp: true,
          androidMinimumVersion: '21',
        ),
      );
      _showMessage('One-time sign-in link sent to $address. Open it on this device to finish signing in.');
    } on FirebaseAuthException catch (e) {
      _showMessage(_friendlyError(e));
    } catch (e) {
      _showMessage('Could not send email sign-in link: $e');
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  Future<void> _completeEmailLink(String link) async {
    if (!_auth.isSignInWithEmailLink(link)) {
      return;
    }
    final address = email.text.trim();
    if (address.isEmpty) {
      _showMessage('Enter the same email address you used to request the sign-in link, then open the link again.');
      return;
    }
    try {
      await _auth.signInWithEmailLink(email: address, emailLink: link);
      await _enterApp();
    } on FirebaseAuthException catch (e) {
      _showMessage(_friendlyError(e));
    } catch (e) {
      _showMessage('Could not complete email sign-in: $e');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.health_and_safety_rounded, color: green, size: 88),
                    const Text('RESQ-MITRA', textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: navy)),
                    const SizedBox(height: 8),
                    const Text('Secure one-time sign in', textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 22),
                      TextField(
                        controller: email,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        decoration: const InputDecoration(
                          labelText: 'Email address',
                          prefixIcon: Icon(Icons.email_outlined, size: 28),
                        ),
                      ),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: busy ? null : _sendEmailLink,
                        style: FilledButton.styleFrom(padding: const EdgeInsets.all(18)),
                        icon: busy
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.mark_email_read_outlined, size: 26),
                        label: Text(busy ? 'PLEASE WAIT…' : 'SEND ONE-TIME EMAIL LINK',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      ),
                      const SizedBox(height: 8),
                      const Text('Sign in securely using the email link sent to your inbox.',
                          textAlign: TextAlign.center, style: TextStyle(color: Colors.black54, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class PermissionsPage extends StatefulWidget {
  const PermissionsPage({super.key});
  @override State<PermissionsPage> createState() => _PermissionsPageState();
}
class _PermissionsPageState extends State<PermissionsPage> {
  final granted = <String, bool>{};
  Future<void> ask(String key) async {
    Permission p;
    switch (key) {
      case 'Location': p = Permission.locationWhenInUse; break;
      case 'Camera': p = Permission.camera; break;
      case 'Microphone': p = Permission.microphone; break;
      case 'Notifications': p = Permission.notification; break;
      case 'Vibration': granted[key] = true; setState(() {}); return;
      case 'Calling': granted[key] = true; setState(() {}); return;
      case 'Sound': granted[key] = true; setState(() {}); return;
      default: return;
    }
    final status = await p.request();
    if (key == 'Location' && status.isGranted) {
      try { await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium)); } catch (_) {}
    }
    if (mounted) {
      setState(() => granted[key] = status.isGranted);
    }
  }
  @override Widget build(BuildContext context) {
    final items = ['Location', 'Camera', 'Sound', 'Microphone', 'Vibration', 'Calling', 'Notifications'];
    return Scaffold(appBar: AppBar(title: const Text('Permissions & safety')), body: ListView(padding: const EdgeInsets.all(18), children: [
      const Text('Allow only what you are comfortable sharing. Location is needed to attach your position to an SOS.', style: TextStyle(fontSize: 15)),
      const SizedBox(height: 14),
      ...items.map((e) => Card(child: ListTile(leading: Icon(_permissionIcon(e), color: green), title: Text(e), subtitle: Text(granted[e] == true ? 'Enabled / acknowledged' : 'Tap to review permission'), trailing: Icon(granted[e] == true ? Icons.check_circle : Icons.chevron_right, color: granted[e] == true ? green : navy), onTap: () => ask(e)))),
      const SizedBox(height: 16), FilledButton(onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage())), child: const Text('CONTINUE')),
      const SizedBox(height: 8), const Text('Some Android permissions are not applicable as standalone permissions (sound, vibration, calling). The app requests them only when required.', style: TextStyle(fontSize: 12, color: Colors.black54)),
    ]));
  }
  IconData _permissionIcon(String s) => switch(s) { 'Location' => Icons.location_on, 'Camera' => Icons.camera_alt, 'Sound' => Icons.volume_up, 'Microphone' => Icons.mic, 'Vibration' => Icons.vibration, 'Calling' => Icons.call, _ => Icons.notifications };
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  final helplines = const [
    ['Pan-India Emergency', '112', Icons.emergency],
    ['Police', '100', Icons.local_police],
    ['Ambulance', '108', Icons.medical_services],
    ['Fire Brigade', '101', Icons.local_fire_department],
    ['Disaster Management', '1078', Icons.flood],
    ['Women Helpline', '181', Icons.woman],
    ['Child Helpline', '1098', Icons.child_care],
  ];
  Future<void> call(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (!await launchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open dialer for $number')));
      }
    }
  }
  @override Widget build(BuildContext context) => AnimatedBuilder(animation: appState, builder: (context, _) => Scaffold(
    appBar: AppBar(title: const Text('RESQ-MITRA'), actions: [IconButton(tooltip: 'Responder mode', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ResponderPage())), icon: const Icon(Icons.volunteer_activism))]),
    body: ListView(padding: const EdgeInsets.all(18), children: [
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: const LinearGradient(colors: [Color(0xFFFFF0E2), Color(0xFFE8F8EE)])), child: Column(children: [
        const Text('HELP IS ONE TAP AWAY', style: TextStyle(color: navy, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        const SizedBox(height: 20),
        InkWell(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SosTypesPage())), borderRadius: BorderRadius.circular(100), child: Container(width: 224, height: 224, decoration: BoxDecoration(shape: BoxShape.circle, color: red, boxShadow: [BoxShadow(color: red.withValues(alpha: .28), blurRadius: 28, spreadRadius: 5)]), child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.sos, color: Colors.white, size: 82), Text('SOS', style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900)), Text('GET HELP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]))),
        const SizedBox(height: 18),
        SizedBox(width: double.infinity, child: FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF8B0000), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 24), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          onPressed: () async {
            final draft = SosDraft()
              ..category = 'HIGH ALERT SOS'
              ..emergency = 'High Alert Emergency'
              ..notes = 'HIGH ALERT: immediate assistance required.'
              ..highAlert = true
              ..videoRequested = true;
            await appState.createSos(draft);
            if (context.mounted) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const HighAlertPage()));
            }
          },
          icon: const Icon(Icons.warning_rounded, size: 36),
          label: const Text('HIGH ALERT SOS', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        )),
        const SizedBox(height: 12), const Text('Use HIGH ALERT only when immediate, critical help is needed. It sends a critical-priority alert and opens a 10-second camera countdown.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF8B0000), fontWeight: FontWeight.w600)),
        const SizedBox(height: 16), const Text('Choose an emergency type. Share your location only with verified responders.', textAlign: TextAlign.center, style: TextStyle(color: navy)),
      ])),
      const SizedBox(height: 22), const Text('EMERGENCY HELPLINES', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: navy)),
      const SizedBox(height: 8),
      ...helplines.map((h) => Card(child: ListTile(leading: CircleAvatar(radius: 28, backgroundColor: const Color(0xFFE1F5E8), child: Icon(h[2] as IconData, color: green, size: 30)), title: Text(h[0] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)), subtitle: Text(h[1] as String), trailing: IconButton(iconSize: 30, icon: const Icon(Icons.call, color: green), onPressed: () => call(h[1] as String))))),
      const SizedBox(height: 8), OutlinedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ResponderPage())), icon: const Icon(Icons.volunteer_activism), label: const Text('Switch to AS RESPONDER')),
      const SizedBox(height: 8), const Text('Emergency numbers can vary by location. Verify local numbers before relying on them.', style: TextStyle(fontSize: 12, color: Colors.black54)),
    ]),
  ));
}

class HighAlertPage extends StatefulWidget {
  const HighAlertPage({super.key});
  @override State<HighAlertPage> createState() => _HighAlertPageState();
}

class _HighAlertPageState extends State<HighAlertPage> {
  Timer? _timer;
  int _seconds = 10;
  CameraController? _camera;
  bool _cameraStarting = false;
  String? _cameraMessage;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
      return;
    }
      if (_seconds <= 1) {
        timer.cancel();
        setState(() => _seconds = 0);
        _startCamera();
      } else {
        setState(() => _seconds--);
      }
    });
  }

  Future<void> _startCamera() async {
    if (_cameraStarting || _camera != null) {
      return;
    }
    _cameraStarting = true;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw StateError('No camera is available on this device.');
      }
      final selected = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(selected, ResolutionPreset.medium, enableAudio: false);
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _camera = controller;
        _cameraMessage = 'Camera preview is active on this device.';
      });
    } catch (e) {
      if (mounted) {
        setState(() => _cameraMessage = 'Camera unavailable: $e');
      }
    } finally {
      _cameraStarting = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _camera?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('HIGH ALERT SOS')),
    body: ListView(padding: const EdgeInsets.all(18), children: [
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFFFFE5E5), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF8B0000), width: 2)), child: Column(children: [
        const Icon(Icons.warning_rounded, size: 58, color: Color(0xFF8B0000)),
        const Text('CRITICAL EMERGENCY', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF8B0000))),
        const SizedBox(height: 8),
        if (_seconds > 0) Text('Camera starts in $_seconds seconds', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        if (_seconds == 0) const Text('Countdown complete', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(appState.databaseStatus, textAlign: TextAlign.center),
      ])),
      const SizedBox(height: 16),
      if (_camera != null && _camera!.value.isInitialized)
        ClipRRect(borderRadius: BorderRadius.circular(16), child: AspectRatio(aspectRatio: _camera!.value.aspectRatio, child: CameraPreview(_camera!)))
      else
        Container(height: 220, decoration: BoxDecoration(color: navy, borderRadius: BorderRadius.circular(16)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(_seconds > 0 ? Icons.timer : Icons.videocam_off, size: 56, color: Colors.white),
          const SizedBox(height: 8),
          Text(_seconds > 0 ? 'Camera will open automatically' : (_cameraMessage ?? 'Opening camera…'), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ])),
      const SizedBox(height: 12),
      const ListTile(leading: Icon(Icons.priority_high, color: Color(0xFF8B0000)), title: Text('Critical alert submitted'), subtitle: Text('Responders can see the high-priority request when Firebase and responder access are configured.')),
      const ListTile(leading: Icon(Icons.videocam, color: navy), title: Text('Video streaming status'), subtitle: Text('This screen provides a local camera preview. Remote live video requires a configured secure WebRTC media service.')),
      const ListTile(leading: Icon(Icons.volume_off, color: navy), title: Text('Silent mode'), subtitle: Text('Android does not allow an app to force silent mode without special Do Not Disturb access. Set Silent/Do Not Disturb manually in Quick Settings if safe to do so.')),
      const SizedBox(height: 8),
      FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: const Color(0xFF8B0000), padding: const EdgeInsets.all(15)), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ActiveSosPage())), icon: const Icon(Icons.sos), label: const Text('VIEW ACTIVE HIGH ALERT')),
      const SizedBox(height: 8),
      OutlinedButton.icon(onPressed: () async {
        await appState.cancelSos();
        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
            (route) => false,
          );
        }
      }, icon: const Icon(Icons.cancel_outlined), label: const Text('CANCEL ALERT')),
      const SizedBox(height: 8),
      const Text('If there is immediate danger, call the local emergency number as well. The app cannot guarantee responder arrival.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.black54)),
    ]),
  );
}

class SosTypesPage extends StatelessWidget {
  const SosTypesPage({super.key});
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Choose SOS type')), body: ListView(padding: const EdgeInsets.all(18), children: [
    _typeCard(context, 'General SOS', 'For everyone, anytime, anywhere', blue, Icons.groups, generalItems),
    _typeCard(context, 'Women SOS', 'Safety, support, always', pink, Icons.woman, womenItems),
    _typeCard(context, 'Child SOS', 'Safe children, brighter futures', const Color(0xFFF2BE00), Icons.child_care, childItems),
  ]));
  Widget _typeCard(BuildContext context, String title, String sub, Color color, IconData icon, List<Emergency> items) => Card(
    clipBehavior: Clip.antiAlias, child: InkWell(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EmergencyTypesPage(category: title, items: items, color: color))), child: Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(gradient: LinearGradient(colors: [color.withValues(alpha: .95), color.withValues(alpha: .72)])), child: Row(children: [
      Icon(icon, color: Colors.white, size: 58), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900)), Text(sub, style: const TextStyle(color: Colors.white))])), const Icon(Icons.chevron_right, color: Colors.white, size: 32),
    ]))));
}

class EmergencyTypesPage extends StatelessWidget {
  final String category; final List<Emergency> items; final Color color;
  const EmergencyTypesPage({super.key, required this.category, required this.items, required this.color});
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(category)), body: GridView.builder(padding: const EdgeInsets.all(14), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.92), itemCount: items.length, itemBuilder: (context, i) {
    final e = items[i];
    return Card(color: e.color, child: InkWell(borderRadius: BorderRadius.circular(16), onTap: () {
      final draft = SosDraft()..category = category..emergency = e.name;
      Navigator.push(context, MaterialPageRoute(builder: (_) => ConfirmSosPage(draft: draft)));
    }, child: Padding(padding: const EdgeInsets.all(14), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(e.icon, style: const TextStyle(fontSize: 46)), const SizedBox(height: 10), Text(e.name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: navy)), const SizedBox(height: 6), const Icon(Icons.arrow_forward_rounded, color: navy, size: 24),
    ]))));
  }));
}

class ConfirmSosPage extends StatefulWidget {
  final SosDraft draft;
  const ConfirmSosPage({super.key, required this.draft});
  @override State<ConfirmSosPage> createState() => _ConfirmSosPageState();
}
class _ConfirmSosPageState extends State<ConfirmSosPage> {
  final notes = TextEditingController();
  final AudioRecorder _recorder = AudioRecorder();
  bool recording = false;
  String? audioPath;
  String audioStatus = 'Optional voice recording';
  @override void dispose() { notes.dispose(); _recorder.dispose(); super.dispose(); }
  Future<void> _toggleRecording() async {
    try {
      if (recording) {
        audioPath = await _recorder.stop();
        setState(() { recording = false; audioStatus = audioPath == null ? 'Recording not saved' : 'Voice recording ready to upload with SOS'; });
      } else {
        if (!await _recorder.hasPermission()) { setState(() => audioStatus = 'Microphone permission is required'); return; }
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/resq_sos_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
        setState(() { recording = true; audioStatus = 'Recording in progress… tap stop when finished'; });
      }
    } catch (e) { setState(() => audioStatus = 'Recording error: $e'); }
  }
  @override Widget build(BuildContext context) {
    final d = widget.draft;
    final bloodNeeded = d.emergency == 'Blood Needed';
    final sensitive = d.category != 'General SOS';
    return Scaffold(appBar: AppBar(title: const Text('Confirm emergency')), body: ListView(padding: const EdgeInsets.all(18), children: [
      Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(d.category.toUpperCase(), style: TextStyle(color: d.category == 'General SOS' ? blue : d.category == 'Women SOS' ? pink : const Color(0xFFB18B00), fontWeight: FontWeight.w900)),
        const SizedBox(height: 6), Text(d.emergency, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: navy)),
        const SizedBox(height: 8), const Text('Your location and any voice recording will be attached to the SOS request when permissions and cloud services are configured.', style: TextStyle(color: Colors.black54)),
      ])),
      const SizedBox(height: 18),
      if (bloodNeeded) ...[
        const Text('Blood group needed', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(initialValue: d.blood, items: ['Any blood group', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setState(() => d.blood = v ?? d.blood)),
        const SizedBox(height: 16),
      ],
      const Text('Explain what happened', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      TextField(controller: notes, maxLines: 4, decoration: const InputDecoration(hintText: 'Describe the situation, exact landmark, injuries, or special instructions…')),
      const SizedBox(height: 14),
      Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: Column(children: [
        IconButton.filledTonal(onPressed: _toggleRecording, icon: Icon(recording ? Icons.stop_circle : Icons.mic), iconSize: 38),
        Text(recording ? 'Recording voice…' : audioStatus, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        const Text('The recording is uploaded to Firebase Storage with the SOS request when cloud configuration and permissions are valid.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.black54)),
      ])),
      if (sensitive) CheckboxListTile(value: d.doNotCall, onChanged: (v) => setState(() => d.doNotCall = v ?? false), contentPadding: EdgeInsets.zero, controlAffinity: ListTileControlAffinity.leading, title: const Text('DO NOT CALL', style: TextStyle(fontWeight: FontWeight.w900, color: pink)), subtitle: const Text('Please communicate by text / app only if it is safer.')),
      const SizedBox(height: 18),
      FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: red, padding: const EdgeInsets.all(16)), onPressed: () {
        d.notes = notes.text;
        d.recordingRequested = audioPath != null;
        d.audioLocalPath = audioPath;
        appState.createSos(d);
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const ActiveSosPage()), (route) => route.isFirst);
      }, icon: const Icon(Icons.sos), label: const Text('CONFIRM SOS')),
      const SizedBox(height: 10), OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Go back')),
    ]));
  }
}

class ActiveSosPage extends StatelessWidget {
  const ActiveSosPage({super.key});
  @override Widget build(BuildContext context) => AnimatedBuilder(animation: appState, builder: (context, _) {
    final d = appState.active;
    return Scaffold(appBar: AppBar(title: const Text('Active SOS')), body: ListView(padding: const EdgeInsets.all(18), children: [
      Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: const Color(0xFFFFE7E9), borderRadius: BorderRadius.circular(18)), child: Column(children: [
        const Icon(Icons.sos, color: red, size: 54), const Text('SOS ACTIVE', style: TextStyle(color: red, fontSize: 22, fontWeight: FontWeight.w900)),
        if (d != null) Text('${d.category} • ${d.emergency}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6), Text(appState.databaseStatus, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6), const Text('Live responder dispatch still requires verified accounts and server-side notification delivery. Call local emergency services if you need immediate help.', textAlign: TextAlign.center),
      ])),
      const SizedBox(height: 16),
      Container(height: 245, decoration: BoxDecoration(color: const Color(0xFFDDEFE7), borderRadius: BorderRadius.circular(18)), child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.map_outlined, size: 66, color: green), Text('MAP PREVIEW', style: TextStyle(fontWeight: FontWeight.w900, color: navy)), SizedBox(height: 6), Text('Live map and responder positions require map API + backend', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
      ])),
      const SizedBox(height: 12),
      if (d != null && d.doNotCall) const ListTile(leading: Icon(Icons.do_not_disturb_on, color: pink), title: Text('DO NOT CALL enabled'), subtitle: Text('Please communicate through the app if safer.')),
      if (d != null && d.notes.isNotEmpty) ListTile(leading: const Icon(Icons.notes), title: const Text('Your instructions'), subtitle: Text(d.notes)),
      const SizedBox(height: 14),
      FilledButton(style: FilledButton.styleFrom(backgroundColor: navy, padding: const EdgeInsets.all(15)), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ResponderPage())), child: const Text('VIEW RESPONDER QUEUE')),
      const SizedBox(height: 8), OutlinedButton(onPressed: () { appState.cancelSos(); Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomePage()), (r) => false); }, child: const Text('CANCEL SOS')),
      OutlinedButton.icon(onPressed: () { appState.cancelSos(); Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const SafePage()), (r) => false); }, icon: const Icon(Icons.check_circle, color: green), label: const Text('I AM SAFE')),
    ]));
  });
}

class SafePage extends StatelessWidget {
  const SafePage({super.key});
  @override Widget build(BuildContext context) => Scaffold(body: Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.verified_user, size: 90, color: green), const SizedBox(height: 16), const Text('Glad you are safe', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: navy)), const SizedBox(height: 8), const Text('Your safe status will be shared with the service when the SOS request is connected to the live backend.', textAlign: TextAlign.center), const SizedBox(height: 22), FilledButton(onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomePage()), (r) => false), child: const Text('BACK TO HOME')),
  ]))));
}

class ResponderPage extends StatefulWidget {
  const ResponderPage({super.key});
  @override State<ResponderPage> createState() => _ResponderPageState();
}
class _ResponderPageState extends State<ResponderPage> {
  final AudioPlayer _siren = AudioPlayer();
  final AudioPlayer _voicePlayer = AudioPlayer();
  final Set<String> _seenPendingIds = <String>{};
  bool _sirenReady = false;
  @override void initState() { super.initState(); _siren.setReleaseMode(ReleaseMode.stop); _sirenReady = true; }
  @override void dispose() { _siren.dispose(); _voicePlayer.dispose(); super.dispose(); }
  Future<void> _playVoice(String url) async { try { await _voicePlayer.stop(); await _voicePlayer.play(UrlSource(url)); } catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not play the attached voice recording.'))); } }
  Future<void> _playSiren() async { if (!_sirenReady) return; try { await _siren.stop(); await _siren.play(AssetSource('responder_siren.ogg')); } catch (_) {} }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('AS RESPONDER'), actions: [IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ResponderMapPage())), icon: const Icon(Icons.map))]), body: ListView(padding: const EdgeInsets.all(18), children: [
    Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF073B65), Color(0xFF078442)]), borderRadius: BorderRadius.circular(20)), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(Icons.volunteer_activism, color: Colors.white, size: 40), SizedBox(height: 10), Text('Be the help someone needs.', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)), Text('Accept nearby requests only if you are trained and can respond safely.', style: TextStyle(color: Colors.white)),
    ])),
    const SizedBox(height: 18), const Text('NEARBY ACTIVE REQUESTS', style: TextStyle(fontWeight: FontWeight.w900, color: navy)),
    const SizedBox(height: 8),
    if (SosRepository.instance.available)
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: SosRepository.instance.watchActiveRequests(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Could not load requests. Check Firestore rules and indexes.')));
          }
          if (!snapshot.hasData) {
            return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
          }
          final docs = snapshot.data!.docs;
          final newPending = docs.where((doc) => (doc.data()['status'] == 'pending') && !_seenPendingIds.contains(doc.id)).toList();
          for (final doc in docs) { _seenPendingIds.add(doc.id); }
          if (newPending.isNotEmpty) { WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) _playSiren(); }); }
          if (docs.isEmpty) {
            return const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('No active SOS requests.')));
          }
          return Column(children: docs.map((doc) {
            final data = doc.data();
            final loc = data['location'] as Map<String, dynamic>?;
            final distanceText = loc == null ? 'Location unavailable' : 'Location: ${loc['latitude']}, ${loc['longitude']}';
            final highAlert = data['highAlert'] == true || data['category'] == 'HIGH ALERT SOS';
            return Card(color: highAlert ? const Color(0xFFFFE5E5) : null, child: ListTile(
              leading: CircleAvatar(backgroundColor: highAlert ? const Color(0xFF8B0000) : const Color(0xFFFFE4E9), child: Icon(highAlert ? Icons.warning_rounded : Icons.sos, color: highAlert ? Colors.white : red)),
              title: Text(highAlert ? '🚨 HIGH ALERT — ${data['emergencyType'] ?? 'Emergency'}' : '${data['emergencyType'] ?? 'Emergency'}', style: TextStyle(fontWeight: highAlert ? FontWeight.w900 : FontWeight.normal, color: highAlert ? const Color(0xFF8B0000) : null)),
              subtitle: Text('${data['category'] ?? 'SOS'} • ${data['urgency'] ?? 'normal'}\n$distanceText\n${data['instructions'] ?? ''}'),
              isThreeLine: true,
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                if (data['audioUrl'] is String && (data['audioUrl'] as String).isNotEmpty)
                  IconButton(tooltip: 'Play attached voice recording', onPressed: () => _playVoice(data['audioUrl'] as String), icon: const Icon(Icons.play_circle_fill, color: green)),
                FilledButton(onPressed: () async {
                  try {
                    await SosRepository.instance.updateStatus(doc.id, 'accepted');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request accepted.')));
                    }
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not accept request. Check database rules.')));
                    }
                  }
                }, child: const Text('ACCEPT')),
              ]),
            ));
          }).toList());
        },
      )
    else
      AnimatedBuilder(animation: appState, builder: (context, _) {
        final active = appState.active;
        if (active == null) {
          return const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('No active SOS requests. Requests appear here when Firebase is configured and a request is received.')));
        }
        return Card(child: ListTile(leading: const CircleAvatar(backgroundColor: Color(0xFFFFE4E9), child: Icon(Icons.sos, color: red)), title: Text(active.emergency), subtitle: Text(active.category)));
      }),
    const SizedBox(height: 14), OutlinedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ResponderMapPage())), icon: const Icon(Icons.map_outlined), label: const Text('OPEN RESPONDER MAP')),
    const SizedBox(height: 8), const Text('Responder identity verification, proximity filtering, dispatch and acceptance locking must be implemented server-side.', style: TextStyle(fontSize: 12, color: Colors.black54)),
  ]));
}

class ResponderMapPage extends StatefulWidget {
  const ResponderMapPage({super.key});
  @override State<ResponderMapPage> createState() => _ResponderMapPageState();
}
class _ResponderMapPageState extends State<ResponderMapPage> {
  String status = 'Location not checked';
  Future<void> locate() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      final requested = await Geolocator.requestPermission();
      if (requested == LocationPermission.denied || requested == LocationPermission.deniedForever) {
        setState(() => status = 'Location permission not granted'); return;
      }
    }
    try {
      final p = await Geolocator.getCurrentPosition();
      setState(() => status = 'Current coordinates: ${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}');
    } catch (_) { setState(() => status = 'Could not determine current location'); }
  }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Responder map')), body: Padding(padding: const EdgeInsets.all(18), child: Column(children: [
    Expanded(child: Container(width: double.infinity, decoration: BoxDecoration(color: const Color(0xFFDDEFE7), borderRadius: BorderRadius.circular(20)), child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.map, size: 70, color: green), SizedBox(height: 10), Text('MAP SERVICE NOT CONFIGURED', style: TextStyle(fontWeight: FontWeight.w900, color: navy)), Padding(padding: EdgeInsets.all(18), child: Text('Connect Google Maps or OpenStreetMap tiles and a verified help-centre dataset to display real markers.', textAlign: TextAlign.center)),
    ]))),
    const SizedBox(height: 14), Text(status, textAlign: TextAlign.center), const SizedBox(height: 8), FilledButton.icon(onPressed: locate, icon: const Icon(Icons.my_location), label: const Text('GET MY LOCATION')),
  ])));
}
