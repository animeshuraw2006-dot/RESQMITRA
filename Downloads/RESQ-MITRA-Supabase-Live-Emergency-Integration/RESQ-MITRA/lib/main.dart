import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/sos_repository.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty) {
    try {
      await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseKey);
    } catch (_) {
      // The UI remains available, but live backend operations will report unavailable.
    }
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
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF087F8C),
            primary: const Color(0xFF087F8C),
            secondary: const Color(0xFFFF7900),
            error: red,
            surface: Colors.white,
          ),
          scaffoldBackgroundColor: const Color(0xFFF3F6FA),
          visualDensity: VisualDensity.adaptivePlatformDensity,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFF3F6FA),
            foregroundColor: navy,
            centerTitle: false,
            elevation: 0,
            scrolledUnderElevation: 1,
            titleTextStyle: TextStyle(
              color: navy, fontSize: 20, fontWeight: FontWeight.w800,
              letterSpacing: -.25,
            ),
          ),
          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 1.5,
            shadowColor: const Color(0x14082A4D),
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: Color(0xFFE7EDF4)),
            ),
          ),
          dividerTheme: const DividerThemeData(color: Color(0xFFE4EAF1)),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              minimumSize: const Size(48, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              textStyle: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: .2),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(44, 48),
              side: const BorderSide(color: Color(0xFFCBD6E2)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFDCE5EE)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFDCE5EE)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF087F8C), width: 1.8),
            ),
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
  Uint8List? recordedAudio;
}


Future<String> notifyEmergencyContacts({required String sosType, required double? latitude, required double? longitude}) async {
  if (!Platform.isAndroid) return 'Automatic SMS is available only in the Android app.';
  final contacts = await EmergencyContactsStore.load();
  if (contacts.isEmpty) return 'No emergency contacts saved; SOS SMS was not sent.';
  var permission = await Permission.sms.status;
  if (!permission.isGranted) permission = await Permission.sms.request();
  if (!permission.isGranted) return 'SMS permission denied; emergency contacts were not texted.';
  final message = formatSosSms(
    userName: currentSosUserName(),
    sosType: sosType,
    time: DateTime.now(),
    latitude: latitude,
    longitude: longitude,
  );
  var accepted = 0;
  final failures = <String>[];
  for (final contact in contacts) {
    var sent = false;
    for (var attempt = 0; attempt < 2 && !sent; attempt++) {
      try {
        await sendNativeSms(contact.phone, message);
        sent = true;
        accepted++;
      } catch (e) {
        if (attempt == 0) await Future<void>.delayed(const Duration(seconds: 2));
      }
    }
    if (!sent) failures.add(contact.name);
  }
  if (failures.isEmpty) return 'SMS submitted to Android for $accepted/${contacts.length} contact(s). Carrier delivery is not guaranteed.';
  return 'SMS submitted for $accepted/${contacts.length} contact(s). Failed to submit: ${failures.join(', ')}.';
}

class AppState extends ChangeNotifier {
  bool signedIn = false;
  bool responderMode = false;
  SosDraft? active;
  final List<Map<String, String>> demoRequests = [];
  String? activeRequestId;
  String databaseStatus = 'Supabase not configured';

  Future<void> createSos(SosDraft draft, {bool highAlert = false}) async {
    active = draft;
    databaseStatus = 'Sending SOS to secure server…';
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
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        );
        lat = pos.latitude; lng = pos.longitude; accuracy = pos.accuracy;
      }
    } catch (_) {}

    // Send emergency SMS independently of the cloud request, so an unavailable
    // backend does not prevent local SMS dispatch.
    try {
      final smsStatus = await notifyEmergencyContacts(
        sosType: highAlert ? 'HIGH ALERT SOS' : draft.category,
        latitude: lat,
        longitude: lng,
      );
      databaseStatus = smsStatus;
    } catch (_) {
      databaseStatus = 'SOS initiated, but SMS status could not be confirmed.';
    }
    notifyListeners();

    try {
      final result = await SosRepository.instance.createRequest(
        category: draft.category,
        emergencyType: draft.emergency,
        instructions: draft.notes,
        doNotCall: draft.doNotCall,
        bloodGroup: draft.blood,
        audioRequested: draft.recordingRequested,
        latitude: lat,
        longitude: lng,
        accuracyMeters: accuracy,
        highAlert: highAlert,
      );
      activeRequestId = result['id'] as String?;
      if (activeRequestId != null && draft.recordedAudio != null && draft.recordedAudio!.isNotEmpty) {
        try {
          await SosRepository.instance.uploadEmergencyAudio(activeRequestId!, draft.recordedAudio!);
          databaseStatus = 'SOS and voice recording securely saved • ${result['status'] ?? 'pending'}. SMS: $databaseStatus';
        } catch (_) {
          databaseStatus = 'SOS saved, but audio upload failed. SMS: $databaseStatus';
        }
      } else {
        databaseStatus = 'SOS recorded by Supabase • ${result['status'] ?? 'pending'}. SMS: $databaseStatus';
      }
      demoRequests.insert(0, {'type': draft.category, 'emergency': draft.emergency, 'status': 'Pending', 'urgency': highAlert ? 'HIGH ALERT' : 'normal'});
    } on AuthException {
      databaseStatus = 'Please sign in again before sending an SOS.';
      active = null;
    } catch (e) {
      databaseStatus = 'SOS was NOT confirmed by server. Check connection and try again.';
      activeRequestId = null;
      active = null;
    }
    notifyListeners();
  }

  Future<void> cancelSos() async {
    final id = activeRequestId;
    if (id != null) {
      try {
        await SosRepository.instance.cancelRequest(id);
        databaseStatus = 'Cancellation recorded by Supabase';
      } catch (_) {
        databaseStatus = 'Could not confirm cancellation with server';
      }
    }
    active = null; activeRequestId = null; notifyListeners();
  }
}
final appState = AppState();
final highAlertSirenPlayer = AudioPlayer();
final emergencyAudioPlayer = AudioPlayer();
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
  final email = TextEditingController(), password = TextEditingController(), fullName = TextEditingController();
  bool create = true, obscure = true;
  @override void dispose() { email.dispose(); password.dispose(); fullName.dispose(); super.dispose(); }
  Future<void> enter() async {
    if (email.text.trim().isEmpty || password.text.length < 8 || (create && fullName.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(create ? 'Enter your name, email and a password of at least 8 characters.' : 'Enter an email/phone and password of at least 8 characters.')));
      return;
    }
    if (!SosRepository.instance.configured) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Supabase is not configured. Build with SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY.')));
      return;
    }
    try {
      if (create) {
        final result = await Supabase.instance.client.auth.signUp(email: email.text.trim(), password: password.text, data: {'full_name': fullName.text.trim()});
        if (result.session == null) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account created. Check your email to confirm it, then log in.')));
          setState(() => create = false);
          return;
        }
      } else {
        await Supabase.instance.client.auth.signInWithPassword(email: email.text.trim(), password: password.text);
      }
      if (!mounted) return;
      appState.signedIn = Supabase.instance.client.auth.currentSession != null;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PermissionsPage()));
    } on AuthException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sign-in failed. Check your Supabase configuration and internet connection.')));
    }
  }
  @override Widget build(BuildContext context) => Scaffold(body: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 480), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Icon(Icons.health_and_safety_rounded, color: green, size: 76),
      const Text('RESQ-MITRA', textAlign: TextAlign.center, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: navy)),
      const SizedBox(height: 8), Text(create ? 'Create your account' : 'Welcome back', textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 24),
      if (create) ...[
        TextField(controller: fullName, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.badge_outlined))),
        const SizedBox(height: 14),
      ],
      TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email or phone number', prefixIcon: Icon(Icons.person_outline))),
      const SizedBox(height: 14),
      TextField(controller: password, obscureText: obscure, decoration: InputDecoration(labelText: 'Password (8+ characters)', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(icon: Icon(obscure ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => obscure = !obscure)))),
      const SizedBox(height: 20), FilledButton(onPressed: enter, style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)), child: Text(create ? 'CREATE ACCOUNT' : 'LOGIN')),
      TextButton(onPressed: () => setState(() => create = !create), child: Text(create ? 'Already registered? Log in' : 'New here? Create account')),
      const SizedBox(height: 12), const Text('Secure account access powered by Supabase Auth.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54, fontSize: 12)),
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
      case 'SMS': p = Permission.sms; break;
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
    final items = ['Location', 'Camera', 'Sound', 'Microphone', 'Vibration', 'Calling', 'Notifications', 'SMS'];
    return Scaffold(appBar: AppBar(title: const Text('Permissions & safety')), body: ListView(padding: const EdgeInsets.all(18), children: [
      const Text('Allow only what you are comfortable sharing. Location is needed to attach your position to an SOS.', style: TextStyle(fontSize: 15)),
      const SizedBox(height: 14),
      ...items.map((e) => Card(child: ListTile(leading: Icon(_permissionIcon(e), color: green), title: Text(e), subtitle: Text(granted[e] == true ? 'Enabled / acknowledged' : 'Tap to review permission'), trailing: Icon(granted[e] == true ? Icons.check_circle : Icons.chevron_right, color: granted[e] == true ? green : navy), onTap: () => ask(e)))),
      const SizedBox(height: 16), FilledButton(onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage())), child: const Text('CONTINUE')),
      const SizedBox(height: 8), const Text('Some Android permissions are not applicable as standalone permissions (sound, vibration, calling). The app requests them only when required.', style: TextStyle(fontSize: 12, color: Colors.black54)),
    ]));
  }
  IconData _permissionIcon(String s) => switch(s) { 'Location' => Icons.location_on, 'Camera' => Icons.camera_alt, 'Sound' => Icons.volume_up, 'Microphone' => Icons.mic, 'Vibration' => Icons.vibration, 'Calling' => Icons.call, 'SMS' => Icons.sms, _ => Icons.notifications };
}


const MethodChannel _smsChannel = MethodChannel('resq_mitra/native_sms');

class EmergencyContact {
  final String name;
  final String relation;
  final String phone;
  const EmergencyContact({required this.name, required this.relation, required this.phone});
  Map<String, dynamic> toJson() => {'name': name, 'relation': relation, 'phone': phone};
  factory EmergencyContact.fromJson(Map<String, dynamic> json) => EmergencyContact(
    name: (json['name'] ?? '').toString(),
    relation: (json['relation'] ?? '').toString(),
    phone: (json['phone'] ?? '').toString(),
  );
}

class EmergencyContactsStore {
  static const _key = 'resq_mitra_emergency_contacts_v1';
  static Future<List<EmergencyContact>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? <String>[];
    final contacts = <EmergencyContact>[];
    for (final item in raw) {
      try {
        final decoded = jsonDecode(item);
        if (decoded is Map<String, dynamic>) contacts.add(EmergencyContact.fromJson(decoded));
      } catch (_) {}
    }
    return contacts;
  }
  static Future<void> save(List<EmergencyContact> contacts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, contacts.map((c) => jsonEncode(c.toJson())).toList());
  }
}

Future<String> sendNativeSms(String phone, String message) async {
  if (!Platform.isAndroid) {
    throw PlatformException(code: 'unsupported_platform', message: 'Automatic SMS sending is supported on Android only.');
  }
  final result = await _smsChannel.invokeMethod<String>('sendSms', {'phone': phone, 'message': message});
  return result ?? 'submitted';
}

String currentSosUserName() {
  try {
    final user = Supabase.instance.client.auth.currentUser;
    final metadata = user?.userMetadata ?? const <String, dynamic>{};
    final name = (metadata['full_name'] ?? metadata['name'] ?? metadata['display_name'] ?? '').toString().trim();
    if (name.isNotEmpty) return name;
    final email = user?.email;
    if (email != null && email.contains('@')) return email.split('@').first;
  } catch (_) {}
  return 'RESQ-MITRA User';
}

String formatSosSms({required String userName, required String sosType, required DateTime time, required double? latitude, required double? longitude}) {
  final date = '${time.day.toString().padLeft(2, '0')}-${time.month.toString().padLeft(2, '0')}-${time.year}';
  final clock = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  final location = latitude != null && longitude != null
      ? 'Location: ${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}\nMap: https://maps.google.com/?q=$latitude,$longitude'
      : 'Location: Currently unavailable (GPS fix not obtained)';
  return '🚨 RESQ-MITRA SOS ALERT 🚨\n\nName: $userName\nSOS Type: $sosType\nDate: $date\nTime: $clock\n$location\n\nThis person may need immediate assistance. Please contact them or send help.';
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
      const SizedBox(height: 16),
      InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyContactsPage())),
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF082A4D), Color(0xFF087F8C)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [BoxShadow(color: Color(0x22082A4D), blurRadius: 16, offset: Offset(0, 7))],
          ),
          child: Row(children: [
            Container(width: 54, height: 54, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .15), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.shield_outlined, color: Colors.white, size: 30)),
            const SizedBox(width: 14),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('EMERGENCY CONTACTS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: .4)),
              SizedBox(height: 4),
              Text('Manage trusted people for automatic SOS SMS', style: TextStyle(color: Color(0xFFD5F3F0), fontSize: 12, height: 1.35)),
            ])),
            Container(width: 40, height: 40, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.add, color: Color(0xFF087F8C), size: 26)),
          ]),
        ),
      ),
      const SizedBox(height: 22), const Text('EMERGENCY HELPLINES', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: navy)),
      const SizedBox(height: 8),
      ...helplines.map((h) => Card(child: ListTile(leading: CircleAvatar(backgroundColor: const Color(0xFFE1F5E8), child: Icon(h[2] as IconData, color: green)), title: Text(h[0] as String, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(h[1] as String), trailing: IconButton(icon: const Icon(Icons.call, color: green), onPressed: () => call(h[1] as String))))),
      const SizedBox(height: 8), OutlinedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ResponderPage())), icon: const Icon(Icons.volunteer_activism), label: const Text('Switch to AS RESPONDER')),
      const SizedBox(height: 8), const Text('Emergency numbers can vary by location. Verify local numbers before relying on them.', style: TextStyle(fontSize: 12, color: Colors.black54)),
    ]),
  ));
}


class EmergencyContactsPage extends StatefulWidget {
  const EmergencyContactsPage({super.key});
  @override State<EmergencyContactsPage> createState() => _EmergencyContactsPageState();
}

class _EmergencyContactsPageState extends State<EmergencyContactsPage> {
  List<EmergencyContact> contacts = [];
  bool loading = true;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final loaded = await EmergencyContactsStore.load();
    if (!mounted) return;
    setState(() { contacts = loaded; loading = false; });
  }
  Future<void> _save() async => EmergencyContactsStore.save(contacts);

  Future<void> _addContact({int? editIndex}) async {
    final existing = editIndex == null ? null : contacts[editIndex];
    final name = TextEditingController(text: existing?.name ?? '');
    final relation = TextEditingController(text: existing?.relation ?? '');
    final phone = TextEditingController(text: existing?.phone ?? '');
    final formKey = GlobalKey<FormState>();
    final result = await showModalBottomSheet<EmergencyContact>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: const Color(0xFFD8E0E8), borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 20),
              Row(children: [
                Container(width: 48, height: 48, decoration: BoxDecoration(color: const Color(0xFFE2F5F1), borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF087F8C), size: 26)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(existing == null ? 'Add emergency contact' : 'Edit emergency contact', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: navy)),
                  const SizedBox(height: 3),
                  const Text('Details are saved on this device', style: TextStyle(color: Colors.black54, fontSize: 12)),
                ])),
              ]),
              const SizedBox(height: 22),
              TextFormField(controller: name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline), border: OutlineInputBorder()), validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter the contact name' : null),
              const SizedBox(height: 14),
              TextFormField(controller: relation, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Relation', hintText: 'e.g. Mother, Friend, Spouse', prefixIcon: Icon(Icons.diversity_1_outlined), border: OutlineInputBorder()), validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter the relationship' : null),
              const SizedBox(height: 14),
              TextFormField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Contact number', hintText: '+91 98765 43210', prefixIcon: Icon(Icons.phone_outlined), border: OutlineInputBorder()), validator: (v) {
                final digits = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                return digits.length < 7 || digits.length > 15 ? 'Enter a valid phone number' : null;
              }),
              const SizedBox(height: 20),
              SizedBox(width: double.infinity, child: FilledButton.icon(
                onPressed: () {
                  if (!(formKey.currentState?.validate() ?? false)) return;
                  Navigator.pop(sheetContext, EmergencyContact(name: name.text.trim(), relation: relation.text.trim(), phone: phone.text.trim()));
                },
                icon: const Icon(Icons.save_rounded),
                label: Text(existing == null ? 'SAVE CONTACT' : 'UPDATE CONTACT'),
              )),
            ])),
          ),
        ),
      ),
    );
    name.dispose(); relation.dispose(); phone.dispose();
    if (result == null || !mounted) return;
    setState(() {
      if (editIndex == null) {
        final duplicate = contacts.any((c) => c.phone.replaceAll(RegExp(r'[^0-9]'), '') == result.phone.replaceAll(RegExp(r'[^0-9]'), ''));
        if (duplicate) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This phone number is already saved.')));
          return;
        }
        contacts.add(result);
      } else {
        contacts[editIndex] = result;
      }
    });
    await _save();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(editIndex == null ? 'Emergency contact saved on this device.' : 'Contact updated.')));
  }

  Future<void> _deleteContact(int index) async {
    final contact = contacts[index];
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Remove contact?'),
      content: Text('Remove ${contact.name} from your emergency contacts?'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('REMOVE'))],
    ));
    if (confirmed != true || !mounted) return;
    setState(() => contacts.removeAt(index));
    await _save();
  }

  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF3F6FA),
    appBar: AppBar(title: const Text('Emergency Contacts'), actions: [
      IconButton(tooltip: 'Add contact', onPressed: () => _addContact(), icon: const Icon(Icons.add_circle_rounded, color: Color(0xFF087F8C), size: 30)),
    ]),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => _addContact(),
      backgroundColor: const Color(0xFF087F8C),
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: const Text('Add Contact', style: TextStyle(fontWeight: FontWeight.w800)),
    ),
    body: loading ? const Center(child: CircularProgressIndicator()) : ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF082A4D), Color(0xFF087F8C)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(24), boxShadow: const [BoxShadow(color: Color(0x22082A4D), blurRadius: 16, offset: Offset(0, 7))]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 52, height: 52, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .14), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.shield_rounded, color: Colors.white, size: 30)),
              const SizedBox(width: 12),
              const Expanded(child: Text('YOUR SAFETY NETWORK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: .8, fontSize: 16))),
              Text('${contacts.length}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
            ]),
            const SizedBox(height: 16),
            const Text('Trusted people who can be notified when you trigger an SOS.', style: TextStyle(color: Color(0xFFD8F3F0), fontSize: 14, height: 1.4)),
            const SizedBox(height: 12),
            const Row(children: [
              Icon(Icons.sms_outlined, color: Color(0xFF9AF0D9), size: 18),
              SizedBox(width: 7),
              Expanded(child: Text('SOS SMS uses your Android phone and SIM', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))),
            ]),
          ]),
        ),
        const SizedBox(height: 22),
        Row(children: [
          const Expanded(child: Text('SAVED CONTACTS', style: TextStyle(color: navy, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: .8))),
          Text('${contacts.length} saved', style: const TextStyle(color: Colors.black54, fontSize: 12)),
        ]),
        const SizedBox(height: 10),
        if (contacts.isEmpty)
          Container(padding: const EdgeInsets.fromLTRB(24, 30, 24, 30), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFFE2EAF1))), child: Column(children: [
            Container(width: 76, height: 76, decoration: const BoxDecoration(color: Color(0xFFE2F5F1), shape: BoxShape.circle), child: const Icon(Icons.people_alt_outlined, color: Color(0xFF087F8C), size: 38)),
            const SizedBox(height: 14),
            const Text('Build your safety network', textAlign: TextAlign.center, style: TextStyle(color: navy, fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 7),
            const Text('Add a family member or trusted friend. Their number will be used for your formatted SOS SMS.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54, height: 1.45)),
            const SizedBox(height: 18),
            OutlinedButton.icon(onPressed: () => _addContact(), icon: const Icon(Icons.add), label: const Text('ADD YOUR FIRST CONTACT')),
          ]))
        else
          ...List.generate(contacts.length, (index) {
            final c = contacts[index];
            final colors = [const Color(0xFFE3F4F0), const Color(0xFFE5EDFF), const Color(0xFFFFE9DF), const Color(0xFFF4E5FF)];
            return Padding(padding: const EdgeInsets.only(bottom: 10), child: Card(
              child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
                CircleAvatar(radius: 26, backgroundColor: colors[index % colors.length], child: Text(c.name.trim().isNotEmpty ? c.name.trim()[0].toUpperCase() : '?', style: const TextStyle(color: navy, fontWeight: FontWeight.w900, fontSize: 20))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(c.name, style: const TextStyle(color: navy, fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(height: 3),
                  Text(c.relation, style: const TextStyle(color: Color(0xFF087F8C), fontWeight: FontWeight.w700, fontSize: 12)),
                  const SizedBox(height: 5),
                  Text(c.phone, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                ])),
                PopupMenuButton<String>(tooltip: 'Contact options', onSelected: (value) {
                  if (value == 'edit') _addContact(editIndex: index);
                  if (value == 'delete') _deleteContact(index);
                }, itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined), SizedBox(width: 10), Text('Edit')])),
                  PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, color: red), SizedBox(width: 10), Text('Remove')])),
                ]),
              ])),
            ));
          }),
        const SizedBox(height: 8),
        Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFFFF4E5), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFFFD9A8))), child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.info_outline, color: Color(0xFF9A5700)),
          SizedBox(width: 10),
          Expanded(child: Text('SMS delivery depends on Android permissions, SIM availability and carrier coverage. A “sent” result does not guarantee that the recipient received or read the message.', style: TextStyle(color: Color(0xFF744500), fontSize: 12, height: 1.4))),
        ])),
      ],
    ),
  );
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
    const Icon(Icons.campaign_rounded, color: Color(0xFFFF5968), size: 100), Text(appState.activeRequestId == null ? 'SOS NOT CONFIRMED' : 'EMERGENCY SIGNAL SENT', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)), const SizedBox(height: 14), Text(appState.activeRequestId == null ? 'The server did not confirm this SOS. Check your connection and retry, or call 112 directly.' : 'Your SOS was recorded by the server. Keep your phone available and move to safety if possible.', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFFFD8DC), fontSize: 17)), const SizedBox(height: 18), Text(appState.databaseStatus, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)), const SizedBox(height: 24), const SizedBox(height: 10), OutlinedButton(onPressed: () { appState.cancelSos(); Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomePage()), (r) => false); }, child: const Text('CANCEL ALERT', style: TextStyle(color: Colors.white))), const SizedBox(height: 16), const Text('If you are in immediate danger, call your local emergency number too. Background push notifications require a configured push-notification service.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 12)),
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
  final AudioRecorder _recorder = AudioRecorder();
  final BytesBuilder _audioBytes = BytesBuilder(copy: false);
  StreamSubscription<Uint8List>? _audioSubscription;
  bool recording = false;
  String audioStatus = 'Optional voice recording is uploaded securely with your SOS.';
  Future<void> _toggleRecording() async {
    if (recording) {
      try {
        await _recorder.stop();
        await _audioSubscription?.cancel();
        _audioSubscription = null;
        widget.draft.recordedAudio = _audioBytes.takeBytes();
        widget.draft.recordingRequested = widget.draft.recordedAudio!.isNotEmpty;
        if (mounted) setState(() { recording = false; audioStatus = widget.draft.recordingRequested ? 'Voice captured. It will upload after SOS is confirmed.' : 'No audio captured.'; });
      } catch (_) { if (mounted) setState(() { recording = false; audioStatus = 'Could not stop recording. Check microphone permission.'; }); }
    } else {
      try {
        if (!await _recorder.hasPermission()) { if (mounted) setState(() => audioStatus = 'Microphone permission is required to record audio.'); return; }
        _audioBytes.clear();
        final stream = await _recorder.startStream(const RecordConfig(encoder: AudioEncoder.aacLc, sampleRate: 16000, bitRate: 64000));
        _audioSubscription = stream.listen((chunk) => _audioBytes.add(chunk));
        if (mounted) setState(() { recording = true; audioStatus = 'Recording emergency audio… tap stop when finished.'; });
      } catch (_) { if (mounted) setState(() => audioStatus = 'Recording is not available on this device/browser.'); }
    }
  }
  @override void dispose() { _audioSubscription?.cancel(); _recorder.dispose(); notes.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    final d = widget.draft;
    final bloodNeeded = d.emergency == 'Blood Needed';
    final sensitive = d.category != 'General SOS';
    return Scaffold(appBar: AppBar(title: const Text('Confirm emergency')), body: ListView(padding: const EdgeInsets.all(18), children: [
      Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(d.category.toUpperCase(), style: TextStyle(color: d.category == 'General SOS' ? blue : d.category == 'Women SOS' ? pink : const Color(0xFFB18B00), fontWeight: FontWeight.w900)),
        const SizedBox(height: 6), Text(d.emergency, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: navy)),
        const SizedBox(height: 8), const Text('Your location and emergency details are sent to the configured RESQ-MITRA responder backend when available.', style: TextStyle(color: Colors.black54)),
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
        Text(recording ? 'Recording emergency audio' : 'Optional emergency voice recording', style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(audioStatus, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ])),
      if (sensitive) CheckboxListTile(value: d.doNotCall, onChanged: (v) => setState(() => d.doNotCall = v ?? false), contentPadding: EdgeInsets.zero, controlAffinity: ListTileControlAffinity.leading, title: const Text('DO NOT CALL', style: TextStyle(fontWeight: FontWeight.w900, color: pink)), subtitle: const Text('Please communicate by text / app only if it is safer.')),
      const SizedBox(height: 18),
      FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: red, padding: const EdgeInsets.all(16)), onPressed: () {
        d.notes = notes.text;
        if (recording) {
          _toggleRecording().then((_) { appState.createSos(d); });
        } else {
          appState.createSos(d);
        }
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
        const SizedBox(height: 6), const Text('This page shows the status returned by the configured backend. Background alerts require a push-notification service. If you need immediate help, call 112.', textAlign: TextAlign.center),
      ])),
      const SizedBox(height: 16),
      Container(height: 245, decoration: BoxDecoration(color: const Color(0xFFDDEFE7), borderRadius: BorderRadius.circular(18)), child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.map_outlined, size: 66, color: green), Text('MAP PREVIEW', style: TextStyle(fontWeight: FontWeight.w900, color: navy)), SizedBox(height: 6), Text('Live map and responder positions require map API + backend', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
      ])),
      const SizedBox(height: 12),
      if (d != null && d.doNotCall) const ListTile(leading: Icon(Icons.do_not_disturb_on, color: pink), title: Text('DO NOT CALL enabled'), subtitle: Text('Preference retained in this local demo.')),
      if (d != null && d.notes.isNotEmpty) ListTile(leading: const Icon(Icons.notes), title: const Text('Your instructions'), subtitle: Text(d.notes)),
      const SizedBox(height: 14),
      OutlinedButton(onPressed: () { appState.cancelSos(); Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomePage()), (r) => false); }, child: const Text('CANCEL SOS')),
      OutlinedButton.icon(onPressed: () { appState.cancelSos(); Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const SafePage()), (r) => false); }, icon: const Icon(Icons.check_circle, color: green), label: const Text('I AM SAFE')),
    ]));
  });
}

class SafePage extends StatelessWidget {
  const SafePage({super.key});
  @override Widget build(BuildContext context) => Scaffold(body: Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.verified_user, size: 90, color: green), const SizedBox(height: 16), const Text('Glad you are safe', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: navy)), const SizedBox(height: 8), const Text('This closes the active SOS through the configured backend when available.', textAlign: TextAlign.center), const SizedBox(height: 22), FilledButton(onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomePage()), (r) => false), child: const Text('BACK TO HOME')),
  ]))));
}

class ResponderPage extends StatefulWidget {
  const ResponderPage({super.key});
  @override
  State<ResponderPage> createState() => _ResponderPageState();
}

class _ResponderPageState extends State<ResponderPage> {
  StreamSubscription<List<Map<String, dynamic>>>? _sosSubscription;
  final Set<String> _seenAssignmentIds = <String>{};
  bool _sirenPlaying = false;
  bool _alertDialogShowing = false;
  String _latestAlertTitle = 'New SOS signal received';
  String _latestAlertDetail = 'A responder assignment has reached this device.';

  Future<void> _showSosAlert(Map<String, dynamic> request) async {
    if (!mounted || _alertDialogShowing) return;
    _alertDialogShowing = true;
    final category = (request['category'] ?? request['emergency_type'] ?? 'Emergency').toString();
    final highAlert = request['high_alert'] == true || request['urgency'] == 'high_alert' || request['priority'] == 'high_alert';
    _latestAlertTitle = highAlert ? 'HIGH ALERT SOS RECEIVED' : 'SOS SIGNAL RECEIVED';
    _latestAlertDetail = '$category\nA new emergency assignment has reached this responder device.';
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 82, height: 82,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE8EB),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.sos_rounded, color: red, size: 52),
                ),
                const SizedBox(height: 18),
                Text(_latestAlertTitle, textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF9D1020), fontSize: 21, fontWeight: FontWeight.w900, letterSpacing: .2)),
                const SizedBox(height: 10),
                Text(_latestAlertDetail, textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF455468), fontSize: 15, height: 1.45)),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(color: const Color(0xFFFFF3F4), borderRadius: BorderRadius.circular(12)),
                  child: const Row(children: [
                    Icon(Icons.volume_up_rounded, color: red), SizedBox(width: 8),
                    Expanded(child: Text('High-alert siren is playing', style: TextStyle(color: Color(0xFF9D1020), fontWeight: FontWeight.w700))),
                  ]),
                ),
                const SizedBox(height: 20),
                SizedBox(width: double.infinity, child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: red, foregroundColor: Colors.white),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  icon: const Icon(Icons.visibility_rounded), label: const Text('VIEW SOS REQUESTS'),
                )),
                SizedBox(width: double.infinity, child: TextButton.icon(
                  onPressed: () async {
                    await highAlertSirenPlayer.stop();
                    if (mounted) setState(() => _sirenPlaying = false);
                    if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                  },
                  icon: const Icon(Icons.volume_off_rounded), label: const Text('SILENCE SIREN'),
                )),
              ],
            ),
          ),
        ),
      );
    } finally {
      _alertDialogShowing = false;
    }
  }

  @override
  void initState() {
    super.initState();
    _sosSubscription = SosRepository.instance.watchActiveRequests().listen(
      (requests) async {
        // A new assignment is a newly received SOS. Sound the siren once per
        // assignment while this responder screen is active.
        Map<String, dynamic>? newlyReceived;
        for (final request in requests) {
          final id = request['id']?.toString() ?? request['emergency_id']?.toString();
          if (id != null && _seenAssignmentIds.add(id)) {
            newlyReceived ??= request;
          }
        }
        if (newlyReceived != null && mounted) {
          try {
            await highAlertSirenPlayer.stop();
            await highAlertSirenPlayer.setReleaseMode(ReleaseMode.loop);
            await highAlertSirenPlayer.play(AssetSource('high_alert_siren.ogg'));
            _sirenPlaying = true;
            if (mounted) setState(() {});
          } catch (_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('SOS received, but siren audio could not play. Check device volume.')),
              );
            }
          }
          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _showSosAlert(newlyReceived!);
            });
          }
        }
      },
      onError: (_) {},
    );
  }

  @override
  void dispose() {
    _sosSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AS RESPONDER'),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ResponderMapPage()),
            ),
            icon: const Icon(Icons.map),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF073B65), Color(0xFF078442)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.volunteer_activism, color: Colors.white, size: 40),
                SizedBox(height: 10),
                Text(
                  'Be the help someone needs.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Accept nearby requests only if you are trained and can respond safely.',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'LIVE SOS ALERTS',
            style: TextStyle(fontWeight: FontWeight.w900, color: navy, fontSize: 16, letterSpacing: .5),
          ),
          const SizedBox(height: 8),
          if (_sirenPlaying) ...[
            Card(color: const Color(0xFFFFE4E9), child: ListTile(leading: const Icon(Icons.volume_up, color: red), title: const Text('NEW SOS SIGNAL RECEIVED', style: TextStyle(fontWeight: FontWeight.w900)), trailing: TextButton(onPressed: () async { await highAlertSirenPlayer.stop(); if (mounted) setState(() => _sirenPlaying = false); }, child: const Text('SILENCE')))),
            const SizedBox(height: 8),
          ],
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: SosRepository.instance.watchActiveRequests(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Could not load authorized responder assignments. Ensure this account is verified and assigned by an administrator.',
                    ),
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              final requests = snapshot.data!;
              if (requests.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'No active assigned SOS requests. Only verified responder accounts can see assigned incidents.',
                    ),
                  ),
                );
              }
              return Column(
                children: requests.map<Widget>((data) {
                  final id = data['emergency_id'] as String;
                  final isHigh = data['high_alert'] == true ||
                      data['urgency'] == 'high_alert';
                  final lat = data['latitude'];
                  final lng = data['longitude'];
                  final locationText = lat == null || lng == null
                      ? 'Location unavailable'
                      : 'Location: $lat, $lng';
                  return Card(
                    color: isHigh ? const Color(0xFF69000B) : null,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isHigh
                            ? const Color(0xFFFF5968)
                            : const Color(0xFFFFE4E9),
                        child: Icon(
                          isHigh ? Icons.warning_rounded : Icons.sos,
                          color: isHigh ? Colors.white : red,
                        ),
                      ),
                      title: Text(
                        '${isHigh ? '🚨 HIGH ALERT — ' : ''}${data['emergency_type'] ?? 'Emergency'}',
                        style: TextStyle(
                          color: isHigh ? Colors.white : null,
                          fontWeight:
                              isHigh ? FontWeight.w900 : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        '${data['category'] ?? 'SOS'} • ${data['status'] ?? 'pending'}\n$locationText\n${data['instructions'] ?? ''}',
                        style: TextStyle(
                          color: isHigh ? Colors.white70 : null,
                        ),
                      ),
                      isThreeLine: true,
                      trailing: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FilledButton(
                            onPressed: () async {
                              try {
                                await SosRepository.instance.acceptRequest(id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Acceptance confirmed by server.')),
                                  );
                                }
                              } catch (_) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Could not accept. Verify responder status or check whether another responder already accepted.')),
                                  );
                                }
                              }
                            },
                            child: const Text('ACCEPT'),
                          ),
                          if ((data['status'] ?? '').toString() == 'accepted' || (data['status'] ?? '').toString() == 'responding')
                            TextButton.icon(
                              onPressed: () async {
                                try {
                                  final url = await SosRepository.instance.getAcceptedEmergencyAudioUrl(id);
                                  if (url == null) {
                                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No uploaded voice recording is available yet.')));
                                    return;
                                  }
                                  await emergencyAudioPlayer.play(UrlSource(url));
                                } catch (_) {
                                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Audio is not available or access was denied.')));
                                }
                              },
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('AUDIO'),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ResponderMapPage()),
            ),
            icon: const Icon(Icons.map_outlined),
            label: const Text('OPEN RESPONDER MAP'),
          ),
          const SizedBox(height: 8),
          const Text(
            'Only verified responders assigned by the backend should accept an SOS. Audio playback is available after acceptance when the requester has uploaded a voice recording.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }
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
