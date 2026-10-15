import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/sos_repository.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase is enabled after adding Android Firebase config (google-services.json).
  // The app remains navigable in demo mode if Firebase has not been configured.
  try {
    await Firebase.initializeApp();
    FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
  } catch (_) {
    // Missing Firebase platform configuration is expected until setup is completed.
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
        home: const SplashPage(),
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
}

class AppState extends ChangeNotifier {
  bool signedIn = false;
  bool responderMode = false;
  SosDraft? active;
  final List<Map<String, String>> demoRequests = [];
  String? activeRequestId;
  String databaseStatus = 'Local demo only';
  Future<void> createSos(SosDraft draft, {bool highAlert = false}) async {
    active = draft;
    demoRequests.insert(0, {'type': draft.category, 'emergency': draft.emergency, 'status': 'Pending', 'urgency': highAlert ? 'HIGH ALERT' : 'normal'});
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
      final id = await SosRepository.instance.createRequest(
        category: draft.category,
        emergencyType: draft.emergency,
        instructions: draft.notes,
        doNotCall: draft.doNotCall,
        bloodGroup: draft.blood,
        audioRequested: draft.recordingRequested,
        latitude: lat,
        longitude: lng,
        accuracyMeters: accuracy,
        // Replace with FirebaseAuth.instance.currentUser!.uid after Auth is connected.
        requesterId: FirebaseAuth.instance.currentUser?.uid ?? 'demo-anonymous-user',
        highAlert: highAlert,
      );
      activeRequestId = id;
      databaseStatus = id == null ? 'Local demo only — Firebase not configured' : 'Saved to live database';
    } catch (_) {
      databaseStatus = 'Database save failed — local demo only';
    }
    notifyListeners();
  }
  Future<void> cancelSos() async {
    final id = activeRequestId;
    if (id != null) {
      try { await SosRepository.instance.updateStatus(id, 'cancelled'); } catch (_) {}
    }
    active = null; activeRequestId = null; notifyListeners();
  }
}
final appState = AppState();
final highAlertSirenPlayer = AudioPlayer();
final Set<String> alertedHighAlertIds = <String>{};

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  VideoPlayerController? _controller;
  Timer? _fallbackTimer;
  bool _navigated = false;
  bool _videoReady = false;

  @override
  void initState() {
    super.initState();
    _fallbackTimer = Timer(const Duration(seconds: 8), _openAuth);
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    final controller = VideoPlayerController.asset('assets/resq_mitra_intro.mp4');
    _controller = controller;
    try {
      await controller.initialize();
      if (!mounted || _navigated) return;
      await controller.setLooping(false);
      setState(() => _videoReady = true);
      await controller.play();
      controller.addListener(() {
        if (controller.value.isInitialized && controller.value.isCompleted) {
          _openAuth();
        }
      });
    } catch (_) {
      // Keep the branded fallback screen and continue after the 8-second intro window.
    }
  }

  void _openAuth() {
    if (!mounted || _navigated) return;
    _navigated = true;
    _fallbackTimer?.cancel();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthPage()));
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: navy,
    body: Stack(
      fit: StackFit.expand,
      children: [
        if (_videoReady && _controller != null)
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _controller!.value.size.width,
              height: _controller!.value.size.height,
              child: VideoPlayer(_controller!),
            ),
          )
        else
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF082A4D), Color(0xFF075A50), Color(0xFF082A4D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Image.asset(
                'assets/resq_mitra_logo.jpeg',
                width: 180,
                height: 180,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.health_and_safety_rounded, size: 150, color: Colors.white),
              ),
            ),
          ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x55082A4D), Color(0x00082A4D), Color(0xDD082A4D)],
              stops: [0, .45, 1],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 30, 24, 28),
            child: Column(
              children: [
                const Spacer(),
                const Text('RESQ-MITRA', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: 2.2, shadows: [Shadow(color: Colors.black45, blurRadius: 12)])),
                const SizedBox(height: 10),
                const Text('NO LIFE LEFT BEHIND', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFFFC928), fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2.1)),
                const SizedBox(height: 9),
                const Text('HELP  |  SUPPORT  |  TOGETHER', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                const SizedBox(height: 22),
                const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFFFFC928))),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override State<AuthPage> createState() => _AuthPageState();
}
class _AuthPageState extends State<AuthPage> {
  final email = TextEditingController(), password = TextEditingController();
  bool create = true, obscure = true;
  @override void dispose() { email.dispose(); password.dispose(); super.dispose(); }
  void enter() {
    if (email.text.trim().isEmpty || password.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter an email/phone and password of at least 8 characters.')));
      return;
    }
    // Demo-only local sign-in; replace with Firebase Auth or another secure identity provider.
    appState.signedIn = true;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PermissionsPage()));
  }
  @override Widget build(BuildContext context) => Scaffold(body: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 480), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Icon(Icons.health_and_safety_rounded, color: green, size: 76),
      const Text('RESQ-MITRA', textAlign: TextAlign.center, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: navy)),
      const SizedBox(height: 8), Text(create ? 'Create your account' : 'Welcome back', textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 24),
      TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email or phone number', prefixIcon: Icon(Icons.person_outline))),
      const SizedBox(height: 14),
      TextField(controller: password, obscureText: obscure, decoration: InputDecoration(labelText: 'Password (8+ characters)', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(icon: Icon(obscure ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => obscure = !obscure)))),
      const SizedBox(height: 20), FilledButton(onPressed: enter, style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)), child: Text(create ? 'CREATE ACCOUNT' : 'LOGIN')),
      TextButton(onPressed: () => setState(() => create = !create), child: Text(create ? 'Already registered? Log in' : 'New here? Create account')),
      const SizedBox(height: 12), const Text('Prototype sign-in only. Use a secure authentication provider before deployment.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54, fontSize: 12)),
    ]))))));
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
    if (mounted) { setState(() => granted[key] = status.isGranted); }
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
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open dialer for $number'))); }
    }
  }
  @override Widget build(BuildContext context) => AnimatedBuilder(animation: appState, builder: (context, _) => Scaffold(
    appBar: AppBar(title: const Text('RESQ-MITRA'), actions: [IconButton(tooltip: 'Responder mode', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ResponderPage())), icon: const Icon(Icons.volunteer_activism))]),
    body: ListView(padding: const EdgeInsets.all(18), children: [
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: const LinearGradient(colors: [Color(0xFFFFF0E2), Color(0xFFE8F8EE)])), child: Column(children: [
        const Text('HELP IS ONE TAP AWAY', style: TextStyle(color: navy, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        const SizedBox(height: 20),
        InkWell(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SosTypesPage())), borderRadius: BorderRadius.circular(100), child: Container(width: 174, height: 174, decoration: BoxDecoration(shape: BoxShape.circle, color: red, boxShadow: [BoxShadow(color: red.withValues(alpha: .28), blurRadius: 28, spreadRadius: 5)]), child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.sos, color: Colors.white, size: 58), Text('SOS', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)), Text('GET HELP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]))),
        const SizedBox(height: 16),
        InkWell(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HighAlertPage())), borderRadius: BorderRadius.circular(22), child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14), decoration: BoxDecoration(color: const Color(0xFF69000B), borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFFFF5968), width: 2), boxShadow: const [BoxShadow(color: Color(0x55700000), blurRadius: 18, spreadRadius: 2)]), child: const Row(children: [Icon(Icons.warning_rounded, color: Colors.white, size: 46), SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('HIGH ALERT SOS', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: .6)), SizedBox(height: 4), Text('Immediate danger • 5-second countdown • no questions', style: TextStyle(color: Color(0xFFFFD8DC), fontWeight: FontWeight.w600))])), Icon(Icons.arrow_forward_ios, color: Colors.white)]))),
        const SizedBox(height: 16), const Text('Choose an emergency type for standard SOS. High Alert sends an immediate-danger request after its 5-second countdown.', textAlign: TextAlign.center, style: TextStyle(color: navy)),
      ])),
      const SizedBox(height: 22), const Text('EMERGENCY HELPLINES', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: navy)),
      const SizedBox(height: 8),
      ...helplines.map((h) => Card(child: ListTile(leading: CircleAvatar(backgroundColor: const Color(0xFFE1F5E8), child: Icon(h[2] as IconData, color: green)), title: Text(h[0] as String, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(h[1] as String), trailing: IconButton(icon: const Icon(Icons.call, color: green), onPressed: () => call(h[1] as String))))),
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
  int seconds = 5;
  Timer? timer;
  bool sending = false;
  @override void initState() { super.initState(); timer = Timer.periodic(const Duration(seconds: 1), (t) { if (!mounted) { t.cancel(); return; } if (seconds <= 1) { t.cancel(); setState(() => seconds = 0); _sendHighAlert(); } else { setState(() => seconds--); } }); }
  Future<void> _sendHighAlert() async {
    if (sending || !mounted) {
      return;
    }
    sending = true;
    final draft = SosDraft()..category = 'HIGH ALERT SOS'..emergency = 'Immediate Help Required'..notes = 'Automatic high-alert request after 5-second countdown. No further questions.';
    await appState.createSos(draft, highAlert: true);
    if (mounted) { Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HighAlertActivePage())); }
  }
  @override void dispose() { timer?.cancel(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF310006),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.emergency, color: Color(0xFFFF5968), size: 68),
                  const SizedBox(height: 8),
                  const Text('HIGH ALERT', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: 2)),
                  const SizedBox(height: 12),
                  const Text('IMMEDIATE DANGER', style: TextStyle(color: Color(0xFFFF9DA7), fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 28),
                  Container(
                    width: 270,
                    height: 270,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF79000D), border: Border.all(color: const Color(0xFFFF5968), width: 5), boxShadow: const [BoxShadow(color: Color(0xAAE00020), blurRadius: 35, spreadRadius: 8)]),
                    child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text('$seconds', style: const TextStyle(color: Colors.white, fontSize: 112, height: 1, fontWeight: FontWeight.w900)), const Text('SECONDS', style: TextStyle(color: Color(0xFFFFD8DC), fontWeight: FontWeight.bold, letterSpacing: 3))])),
                  ),
                  const SizedBox(height: 28),
                  const Text('When countdown ends, the app will submit an emergency request with your available location. No extra questions.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 16)),
                ],
              ),
            ),
            if (seconds > 0)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Color(0xFFFF9DA7), width: 1.5), padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 17), backgroundColor: const Color(0xFF69000B)),
                  onPressed: () { timer?.cancel(); Navigator.pop(context); },
                  icon: const Icon(Icons.close),
                  label: const Text('CANCEL SOS — I AM SAFE', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: .5)),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class HighAlertActivePage extends StatelessWidget {
  const HighAlertActivePage({super.key});
  @override Widget build(BuildContext context) => Scaffold(backgroundColor: const Color(0xFF310006), appBar: AppBar(backgroundColor: const Color(0xFF310006), foregroundColor: Colors.white, title: const Text('HIGH ALERT ACTIVE')), body: SafeArea(child: Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.campaign_rounded, color: Color(0xFFFF5968), size: 100), const Text('EMERGENCY SIGNAL SENT', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)), const SizedBox(height: 14), const Text('Your high-alert request has been submitted. Keep your phone available and move to safety if possible.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFFFD8DC), fontSize: 17)), const SizedBox(height: 18), Text(appState.databaseStatus, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)), const SizedBox(height: 24), FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB00018), padding: const EdgeInsets.all(16)), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ResponderPage())), icon: const Icon(Icons.volunteer_activism), label: const Text('OPEN RESPONDER QUEUE')), const SizedBox(height: 10), OutlinedButton(onPressed: () { appState.cancelSos(); Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomePage()), (r) => false); }, child: const Text('CANCEL ALERT', style: TextStyle(color: Colors.white))), const SizedBox(height: 16), const Text('If you are in immediate danger, call your local emergency number too. Background push notifications require a configured push-notification service.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 12)),
  ])))));
}

class SosTypesPage extends StatelessWidget {
  const SosTypesPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded, color: navy)),
                const Expanded(child: Text('CHOOSE YOUR SOS', textAlign: TextAlign.center, style: TextStyle(color: navy, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.1))),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Select the help you need', style: TextStyle(color: navy, fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            Expanded(
              child: Column(
                children: [
                  Expanded(child: _typeCard(context, 'GENERAL SOS', 'Emergency help for everyone', blue, Icons.health_and_safety_rounded, generalItems)),
                  const SizedBox(height: 12),
                  Expanded(child: _typeCard(context, 'WOMEN SOS', 'Safety, protection and support', pink, Icons.woman_rounded, womenItems)),
                  const SizedBox(height: 12),
                  Expanded(child: _typeCard(context, 'CHILD SOS', 'Protecting children, every moment', const Color(0xFFF2BE00), Icons.child_care_rounded, childItems)),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _typeCard(BuildContext context, String title, String sub, Color color, IconData icon, List<Emergency> items) => Card(
    margin: EdgeInsets.zero,
    elevation: 4,
    shadowColor: color.withValues(alpha: .28),
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    child: InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EmergencyTypesPage(category: title == 'GENERAL SOS' ? 'General SOS' : title == 'WOMEN SOS' ? 'Women SOS' : 'Child SOS', items: items, color: color))),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color.withValues(alpha: .96), color.withValues(alpha: .78)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: .22), borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.white.withValues(alpha: .65), width: 1.5)),
              child: Icon(icon, color: Colors.white, size: 48),
            ),
            const SizedBox(width: 18),
            Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: .6, shadows: [Shadow(color: Colors.black26, blurRadius: 5)])),
              const SizedBox(height: 6),
              Text(sub, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              const Text('TAP TO CONTINUE  →', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
            ])),
          ],
        ),
      ),
    ),
  );
}

class EmergencyTypesPage extends StatelessWidget {
  final String category; final List<Emergency> items; final Color color;
  const EmergencyTypesPage({super.key, required this.category, required this.items, required this.color});
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(category)), body: GridView.builder(padding: const EdgeInsets.all(14), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.08), itemCount: items.length, itemBuilder: (context, i) {
    final e = items[i];
    return Card(color: e.color, child: InkWell(borderRadius: BorderRadius.circular(16), onTap: () {
      final draft = SosDraft()..category = category..emergency = e.name;
      Navigator.push(context, MaterialPageRoute(builder: (_) => ConfirmSosPage(draft: draft)));
    }, child: Padding(padding: const EdgeInsets.all(10), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(e.icon, style: const TextStyle(fontSize: 34)), const SizedBox(height: 8), Text(e.name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, color: navy)), const SizedBox(height: 4), const Icon(Icons.arrow_forward_rounded, color: navy, size: 18),
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
  bool recording = false;
  @override void dispose() { notes.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    final d = widget.draft;
    final bloodNeeded = d.emergency == 'Blood Needed';
    final sensitive = d.category != 'General SOS';
    return Scaffold(appBar: AppBar(title: const Text('Confirm emergency')), body: ListView(padding: const EdgeInsets.all(18), children: [
      Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(d.category.toUpperCase(), style: TextStyle(color: d.category == 'General SOS' ? blue : d.category == 'Women SOS' ? pink : const Color(0xFFB18B00), fontWeight: FontWeight.w900)),
        const SizedBox(height: 6), Text(d.emergency, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: navy)),
        const SizedBox(height: 8), const Text('Your location will be attached when permission is available. In this starter app, alerts are not sent to real responders.', style: TextStyle(color: Colors.black54)),
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
        IconButton.filledTonal(onPressed: () => setState(() => recording = !recording), icon: Icon(recording ? Icons.stop_circle : Icons.mic), iconSize: 38),
        Text(recording ? 'Recording UI demo — audio is not being recorded' : 'Voice note (demo control)', style: const TextStyle(fontWeight: FontWeight.bold)),
        const Text('Real recording and secure upload require an audio-recorder plugin and backend.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.black54)),
      ])),
      if (sensitive) CheckboxListTile(value: d.doNotCall, onChanged: (v) => setState(() => d.doNotCall = v ?? false), contentPadding: EdgeInsets.zero, controlAffinity: ListTileControlAffinity.leading, title: const Text('DO NOT CALL', style: TextStyle(fontWeight: FontWeight.w900, color: pink)), subtitle: const Text('Please communicate by text / app only if it is safer.')),
      const SizedBox(height: 18),
      FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: red, padding: const EdgeInsets.all(16)), onPressed: () {
        d.notes = notes.text;
        d.recordingRequested = recording;
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
        const Icon(Icons.sos, color: red, size: 54), const Text('SOS ACTIVE — DEMO', style: TextStyle(color: red, fontSize: 22, fontWeight: FontWeight.w900)),
        if (d != null) Text('${d.category} • ${d.emergency}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6), Text(appState.databaseStatus, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6), const Text('Live responder dispatch still requires verified accounts and server-side notification delivery. Call local emergency services if you need immediate help.', textAlign: TextAlign.center),
      ])),
      const SizedBox(height: 16),
      Container(height: 245, decoration: BoxDecoration(color: const Color(0xFFDDEFE7), borderRadius: BorderRadius.circular(18)), child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.map_outlined, size: 66, color: green), Text('MAP PREVIEW', style: TextStyle(fontWeight: FontWeight.w900, color: navy)), SizedBox(height: 6), Text('Live map and responder positions require map API + backend', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
      ])),
      const SizedBox(height: 12),
      if (d != null && d.doNotCall) const ListTile(leading: Icon(Icons.do_not_disturb_on, color: pink), title: Text('DO NOT CALL enabled'), subtitle: Text('Preference retained in this local demo.')),
      if (d != null && d.notes.isNotEmpty) ListTile(leading: const Icon(Icons.notes), title: const Text('Your instructions'), subtitle: Text(d.notes)),
      const SizedBox(height: 14),
      FilledButton(style: FilledButton.styleFrom(backgroundColor: navy, padding: const EdgeInsets.all(15)), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ResponderPage())), child: const Text('VIEW RESPONDER QUEUE (DEMO)')),
      const SizedBox(height: 8), OutlinedButton(onPressed: () { appState.cancelSos(); Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomePage()), (r) => false); }, child: const Text('CANCEL SOS')),
      OutlinedButton.icon(onPressed: () { appState.cancelSos(); Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const SafePage()), (r) => false); }, icon: const Icon(Icons.check_circle, color: green), label: const Text('I AM SAFE')),
    ]));
  });
}

class SafePage extends StatelessWidget {
  const SafePage({super.key});
  @override Widget build(BuildContext context) => Scaffold(body: Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.verified_user, size: 90, color: green), const SizedBox(height: 16), const Text('Glad you are safe', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: navy)), const SizedBox(height: 8), const Text('This only closes the local demo SOS. In a production app, accepted responders and emergency contacts must receive the safe status update.', textAlign: TextAlign.center), const SizedBox(height: 22), FilledButton(onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomePage()), (r) => false), child: const Text('BACK TO HOME')),
  ]))));
}

class ResponderPage extends StatelessWidget {
  const ResponderPage({super.key});
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
          if (snapshot.hasError) { return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Could not load requests. Check Firestore rules and indexes.'))); }
          if (!snapshot.hasData) { return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())); }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) { return const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('No active SOS requests.'))); }
          for (final doc in docs) {
            final data = doc.data();
            final isHigh = data['highAlert'] == true || data['urgency'] == 'high_alert';
            if (isHigh && alertedHighAlertIds.add(doc.id)) {
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                if (!context.mounted) {
                  return;
                }
                try { await highAlertSirenPlayer.play(AssetSource('high_alert_siren.ogg')); } catch (_) {}
                if (!context.mounted) {
                  return;
                }
                showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(backgroundColor: const Color(0xFF69000B), title: const Text('🚨 HIGH ALERT SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)), content: Text('A person needs immediate assistance.\nLocation: ${(data['location'] as Map<String, dynamic>?)?['latitude'] ?? 'unavailable'}, ${(data['location'] as Map<String, dynamic>?)?['longitude'] ?? 'unavailable'}\n\nRespond only if you can do so safely.', style: const TextStyle(color: Colors.white)), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('CLOSE', style: TextStyle(color: Colors.white))), FilledButton(onPressed: () async { try { await SosRepository.instance.updateStatus(doc.id, 'accepted'); } catch (_) {} if (dialogContext.mounted) { Navigator.pop(dialogContext); } }, child: const Text('ACCEPT SOS'))]));
              });
            }
          }
          return Column(children: docs.map((doc) {
            final data = doc.data();
            final loc = data['location'] as Map<String, dynamic>?;
            final distanceText = loc == null ? 'Location unavailable' : 'Location: ${loc['latitude']}, ${loc['longitude']}';
            final isHighAlert = data['highAlert'] == true || data['urgency'] == 'high_alert';
            return Card(color: isHighAlert ? const Color(0xFF69000B) : null, child: ListTile(
              leading: CircleAvatar(backgroundColor: isHighAlert ? const Color(0xFFFF5968) : const Color(0xFFFFE4E9), child: Icon(isHighAlert ? Icons.warning_rounded : Icons.sos, color: isHighAlert ? Colors.white : red)),
              title: Text(isHighAlert ? '🚨 HIGH ALERT — ${data['emergencyType'] ?? 'Immediate Help'}' : '${data['emergencyType'] ?? 'Emergency'}', style: TextStyle(color: isHighAlert ? Colors.white : null, fontWeight: isHighAlert ? FontWeight.w900 : FontWeight.normal)),
              subtitle: Text('${data['category'] ?? 'SOS'} • ${data['urgency'] ?? 'normal'}\n$distanceText\n${data['instructions'] ?? ''}', style: TextStyle(color: isHighAlert ? Colors.white70 : null)),
              isThreeLine: true,
              onTap: isHighAlert ? () async {
                try { await highAlertSirenPlayer.play(AssetSource('high_alert_siren.ogg')); } catch (_) {}
                if (context.mounted) { showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(backgroundColor: const Color(0xFF69000B), title: const Text('🚨 HIGH ALERT SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)), content: Text('A person needs immediate assistance.\n\n$distanceText\n\nPlease accept only if you can respond safely.', style: const TextStyle(color: Colors.white)), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('CLOSE', style: TextStyle(color: Colors.white))), FilledButton(onPressed: () async { try { await SosRepository.instance.updateStatus(doc.id, 'accepted'); } catch (_) {} if (dialogContext.mounted) { Navigator.pop(dialogContext); } }, child: const Text('ACCEPT SOS'))])); }
              } : null,
              trailing: isHighAlert ? IconButton(tooltip: 'Play alert siren', color: Colors.white, onPressed: () async { try { await highAlertSirenPlayer.play(AssetSource('high_alert_siren.ogg')); } catch (_) {} }, icon: const Icon(Icons.volume_up_rounded)) : FilledButton(onPressed: () async {
                try {
                  await SosRepository.instance.updateStatus(doc.id, 'accepted');
                  if (context.mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request marked accepted in Firestore. Add verified responder authentication before production.'))); }
                } catch (_) {
                  if (context.mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not accept request. Check database rules.'))); }
                }
              }, child: const Text('ACCEPT')),
            ));
          }).toList());
        },
      )
    else
      AnimatedBuilder(animation: appState, builder: (context, _) {
        final active = appState.active;
        if (active == null) { return const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('No local demo requests. Configure Firebase to share SOS requests across devices.'))); }
        return Card(child: ListTile(leading: const CircleAvatar(backgroundColor: Color(0xFFFFE4E9), child: Icon(Icons.sos, color: red)), title: Text(active.emergency), subtitle: Text('${active.category} • local demo only'), trailing: const Text('DEMO')));
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
      Icon(Icons.map, size: 70, color: green), SizedBox(height: 10), Text('MAP PLACEHOLDER', style: TextStyle(fontWeight: FontWeight.w900, color: navy)), Padding(padding: EdgeInsets.all(18), child: Text('Connect Google Maps or OpenStreetMap tiles and a verified help-centre dataset to display real markers.', textAlign: TextAlign.center)),
    ]))),
    const SizedBox(height: 14), Text(status, textAlign: TextAlign.center), const SizedBox(height: 8), FilledButton.icon(onPressed: locate, icon: const Icon(Icons.my_location), label: const Text('GET MY LOCATION')),
  ])));
}
