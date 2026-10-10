import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// NELY Collection
/// Sebelum dijalankan:
/// 1. Sesuaikan SUPABASE_URL dan SUPABASE_PUBLISHABLE_KEY.
/// 2. Jalankan SQL skema yang disediakan terpisah.
/// 3. Ganti nomor WhatsApp di whatsappNumber.
const String supabaseUrl = 'https://kbxcqfjhycwajuderddo.supabase.co';
const String supabasePublishableKey =
    'sb_publishable_-oq3SNz_r6Ea-QZRr-jSFg_V-FMlY-k';
const String whatsappNumber = '628816715599'; // GANTI dengan nomor toko.
const String storeName = 'NELY Collection';

final SupabaseClient supabase = Supabase.instance.client;

const Color burgundy = Color(0xFF641D32);
const Color deepBurgundy = Color(0xFF3D1020);
const Color gold = Color(0xFFC7A15A);
const Color cream = Color(0xFFFFF8EF);
const Color ink = Color(0xFF2E2526);
const Color muted = Color(0xFF827578);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );

  runApp(const NelyCollectionApp());
}

class NelyCollectionApp extends StatelessWidget {
  const NelyCollectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: storeName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: cream,
        colorScheme: ColorScheme.fromSeed(
          seedColor: burgundy,
          primary: burgundy,
          secondary: gold,
          surface: cream,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: cream,
          foregroundColor: deepBurgundy,
          elevation: 0,
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          hintStyle: const TextStyle(color: muted),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE8DCD6)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE8DCD6)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: burgundy, width: 1.5),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: burgundy,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

// -----------------------------------------------------------------------------
// AUTHENTICATION / SESSION
// -----------------------------------------------------------------------------

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session ?? supabase.auth.currentSession;
        if (session == null) return const WelcomePage();
        return const ProfileRouter();
      },
    );
  }
}

class ProfileRouter extends StatefulWidget {
  const ProfileRouter({super.key});

  @override
  State<ProfileRouter> createState() => _ProfileRouterState();
}

class _ProfileRouterState extends State<ProfileRouter> {
  late Future<Map<String, dynamic>?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
  }

  Future<Map<String, dynamic>?> _loadProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final row = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      if (row != null) return Map<String, dynamic>.from(row);

      final metadataName =
          user.userMetadata?['nama']?.toString() ??
          user.email?.split('@').first ??
          'Pelanggan NELY';
      final created = await supabase
          .from('profiles')
          .insert({
            'id': user.id,
            'nama': metadataName,
            'role': 'customer',
            'no_hp': '',
          })
          .select()
          .single();
      return Map<String, dynamic>.from(created);
    } catch (_) {
      // Jika tabel/policy profil belum disiapkan, jangan mengunci aplikasi.
      return {
        'id': user.id,
        'nama':
            user.userMetadata?['nama']?.toString() ??
            user.email?.split('@').first ??
            'Pelanggan NELY',
        'role': 'customer',
        'no_hp': '',
      };
    }
  }

  void _retry() {
    setState(() => _profileFuture = _loadProfile());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const LoadingPage();
        }
        final profile = snapshot.data;
        if (profile == null) return const WelcomePage();
        if (profile['role'] == 'admin') {
          return AdminDashboardPage(profile: profile);
        }
        return CustomerShell(profile: profile, onProfileChanged: _retry);
      },
    );
  }
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [deepBurgundy, burgundy, Color(0xFF8B4557)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                Container(
                  height: 86,
                  width: 86,
                  decoration: BoxDecoration(
                    color: gold.withValues(alpha: .16),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: gold, width: 1.3),
                  ),
                  child: const Icon(
                    Icons.design_services_rounded,
                    color: gold,
                    size: 42,
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'NELY\nCollection',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    height: 1.05,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.8,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Jahit dengan sentuhan tradisi,\ntampil dengan elegansi.',
                  style: TextStyle(
                    color: Color(0xFFF5E5D4),
                    fontSize: 16,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 24),
                const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: gold, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Jasa jahit  •  Sewa kebaya  •  Galeri',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: gold,
                    foregroundColor: deepBurgundy,
                  ),
                  child: const Text('Masuk ke akun'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterPage()),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                    side: const BorderSide(color: Colors.white54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Buat akun baru'),
                ),
                const SizedBox(height: 18),
                const Center(
                  child: Text(
                    'BUSANA • KETELITIAN • KEANGGUNAN',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _hidePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await supabase.auth.signInWithPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
      if (!mounted) return;
      // AuthGate akan berpindah otomatis saat sesi berubah.
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on AuthException catch (e) {
      _showMessage(e.message);
    } catch (_) {
      _showMessage(
        'Login belum berhasil. Periksa internet dan konfigurasi Supabase.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: burgundy));
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      eyebrow: 'SELAMAT DATANG KEMBALI',
      title: 'Masuk akun',
      subtitle: 'Masuk untuk melihat layanan dan pesananmu.',
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Belum punya akun? '),
          TextButton(
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const RegisterPage()),
            ),
            child: const Text('Daftar', style: TextStyle(color: burgundy)),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'nama@email.com',
                prefixIcon: Icon(Icons.mail_outline),
              ),
              validator: (value) {
                final v = value?.trim() ?? '';
                if (v.isEmpty) return 'Email wajib diisi.';
                if (!v.contains('@')) return 'Masukkan email yang valid.';
                return null;
              },
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _password,
              obscureText: _hidePassword,
              decoration: InputDecoration(
                labelText: 'Kata sandi',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => _hidePassword = !_hidePassword),
                  icon: Icon(
                    _hidePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) {
                if ((value ?? '').isEmpty) return 'Kata sandi wajib diisi.';
                return null;
              },
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
                ),
                child: const Text(
                  'Lupa kata sandi?',
                  style: TextStyle(color: burgundy),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _busy ? null : _login,
              child: _busy
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Masuk'),
            ),
          ],
        ),
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  bool _hidePassword = true;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final response = await supabase.auth.signUp(
        email: _email.text.trim(),
        password: _password.text,
        data: {'nama': _name.text.trim(), 'no_hp': _phone.text.trim()},
      );

      final user = response.user;
      if (user != null) {
        try {
          await supabase.from('profiles').upsert({
            'id': user.id,
            'nama': _name.text.trim(),
            'no_hp': _phone.text.trim(),
            'role': 'customer',
          });
        } catch (_) {
          // Profil bisa dibuat oleh trigger database; lihat SQL pendamping.
        }
      }
      if (!mounted) return;
      if (response.session == null) {
        _showMessage(
          'Akun berhasil dibuat. Periksa email untuk verifikasi, lalu masuk.',
        );
        Navigator.pop(context);
      } else {
        _showMessage(
          'Pendaftaran berhasil. Selamat datang di NELY Collection!',
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on AuthException catch (e) {
      _showMessage(e.message);
    } catch (_) {
      _showMessage(
        'Pendaftaran gagal. Periksa koneksi dan pengaturan Supabase.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: burgundy));
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      eyebrow: 'MULAI PERJALANAN GAYAMU',
      title: 'Buat akun',
      subtitle: 'Daftar supaya pesananmu tersimpan dan mudah dipantau.',
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Sudah punya akun? '),
          TextButton(
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
            ),
            child: const Text('Masuk', style: TextStyle(color: burgundy)),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nama lengkap',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) =>
                  (v?.trim().isEmpty ?? true) ? 'Nama wajib diisi.' : null,
            ),
            const SizedBox(height: 13),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Nomor WhatsApp',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: (v) => (v?.trim().isEmpty ?? true)
                  ? 'Nomor WhatsApp wajib diisi.'
                  : null,
            ),
            const SizedBox(height: 13),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email aktif',
                prefixIcon: Icon(Icons.mail_outline),
              ),
              validator: (v) {
                final value = v?.trim() ?? '';
                if (value.isEmpty || !value.contains('@')) {
                  return 'Masukkan email yang valid.';
                }
                return null;
              },
            ),
            const SizedBox(height: 13),
            TextFormField(
              controller: _password,
              obscureText: _hidePassword,
              decoration: InputDecoration(
                labelText: 'Kata sandi (minimal 6 karakter)',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => _hidePassword = !_hidePassword),
                  icon: Icon(
                    _hidePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (v) {
                if ((v ?? '').length < 6) {
                  return 'Kata sandi minimal 6 karakter.';
                }
                return null;
              },
            ),
            const SizedBox(height: 13),
            TextFormField(
              controller: _confirm,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Ulangi kata sandi',
                prefixIcon: Icon(Icons.verified_user_outlined),
              ),
              validator: (v) => v != _password.text
                  ? 'Konfirmasi kata sandi belum sama.'
                  : null,
            ),
            const SizedBox(height: 22),
            ElevatedButton(
              onPressed: _busy ? null : _register,
              child: _busy
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Daftar sekarang'),
            ),
          ],
        ),
      ),
    );
  }
}

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _email = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    if (!_email.text.trim().contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan email yang valid.')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await supabase.auth.resetPasswordForEmail(_email.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jika email terdaftar, tautan pemulihan akan dikirim.'),
        ),
      );
      Navigator.pop(context);
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      eyebrow: 'PEMULIHAN AKUN',
      title: 'Lupa kata sandi?',
      subtitle: 'Kami akan mengirim tautan pemulihan ke email akunmu.',
      child: Column(
        children: [
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email akun',
              prefixIcon: Icon(Icons.mail_outline),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _busy ? null : _sendReset,
            child: Text(_busy ? 'Mengirim...' : 'Kirim tautan pemulihan'),
          ),
        ],
      ),
    );
  }
}

class AuthScaffold extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? footer;

  const AuthScaffold({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.child,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 18),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 58,
                    width: 58,
                    decoration: BoxDecoration(
                      color: burgundy,
                      borderRadius: BorderRadius.circular(19),
                    ),
                    child: const Icon(
                      Icons.design_services_rounded,
                      color: gold,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    eyebrow,
                    style: const TextStyle(
                      color: gold,
                      fontSize: 11,
                      letterSpacing: 1.8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: deepBurgundy,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.7,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: const TextStyle(color: muted, height: 1.5),
                  ),
                  const SizedBox(height: 28),
                  child,
                  if (footer != null) ...[const SizedBox(height: 16), footer!],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// CUSTOMER AREA
// -----------------------------------------------------------------------------

class CustomerShell extends StatefulWidget {
  final Map<String, dynamic> profile;
  final VoidCallback onProfileChanged;

  const CustomerShell({
    super.key,
    required this.profile,
    required this.onProfileChanged,
  });

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final name = widget.profile['nama']?.toString() ?? 'Pelanggan NELY';
    final pages = [
      HomeTab(name: name),
      const ServiceTab(),
      const RentalTab(),
      const GalleryTab(),
      ProfileTab(
        profile: widget.profile,
        onProfileChanged: widget.onProfileChanged,
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        backgroundColor: Colors.white,
        indicatorColor: gold.withValues(alpha: .22),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.content_cut_outlined),
            label: 'Jasa Jahit',
          ),
          NavigationDestination(
            icon: Icon(Icons.checkroom_outlined),
            label: 'Sewa Kebaya',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_library_outlined),
            label: 'Galeri',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Akun',
          ),
        ],
      ),
    );
  }
}

class HomeTab extends StatelessWidget {
  final String name;
  const HomeTab({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: burgundy,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.design_services_rounded,
                  color: gold,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      storeName,
                      style: TextStyle(
                        color: deepBurgundy,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Busana dengan sentuhan tradisi',
                      style: TextStyle(color: muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyOrdersPage()),
                ),
                icon: const Icon(Icons.receipt_long_outlined, color: burgundy),
                tooltip: 'Pesanan saya',
              ),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [deepBurgundy, burgundy, Color(0xFF8B4557)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -10,
                  bottom: -18,
                  child: Icon(
                    Icons.local_florist_outlined,
                    size: 120,
                    color: gold.withValues(alpha: .16),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ASSALAMUALAIKUM,',
                      style: TextStyle(
                        color: gold,
                        fontSize: 10,
                        letterSpacing: 1.8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Temukan busana yang dirancang dengan detail, tradisi, dan keanggunan.',
                      style: TextStyle(color: Colors.white70, height: 1.5),
                    ),
                    const SizedBox(height: 18),
                    OutlinedButton.icon(
                      onPressed: () => openWhatsApp(
                        'Halo NELY Collection, saya ingin bertanya tentang layanan.',
                      ),
                      icon: const Icon(Icons.chat_outlined, size: 18),
                      label: const Text('Konsultasi sekarang'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: gold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
          const SectionHeading(
            title: 'Layanan kami',
            subtitle: 'Pilih layanan sesuai kebutuhanmu',
          ),
          const SizedBox(height: 13),
          Row(
            children: const [
              Expanded(
                child: ServiceShortcut(
                  icon: Icons.content_cut_rounded,
                  title: 'Jasa Jahit',
                  detail: 'Jahit sesuai kebutuhan',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ServiceShortcut(
                  icon: Icons.checkroom_rounded,
                  title: 'Sewa Kebaya',
                  detail: 'Untuk hari istimewa',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const ServiceShortcut(
            icon: Icons.photo_library_outlined,
            title: 'Galeri Koleksi',
            detail: 'Lihat inspirasi busana NELY Collection',
            horizontal: true,
          ),
          const SizedBox(height: 25),
          const SectionHeading(
            title: 'Cara memesan',
            subtitle: 'Mudah, jelas, dan bisa dikonsultasikan',
          ),
          const SizedBox(height: 13),
          const StepTile(
            number: '01',
            title: 'Pilih layanan',
            detail: 'Jelajahi jasa jahit atau koleksi kebaya.',
          ),
          const StepTile(
            number: '02',
            title: 'Kirim permintaan',
            detail: 'Isi kebutuhanmu dan tunggu konfirmasi toko.',
          ),
          const StepTile(
            number: '03',
            title: 'Pantau pesanan',
            detail: 'Status pesanan tersimpan di halaman Pesanan Saya.',
          ),
          const SizedBox(height: 18),
          const Text(
            'Jahit dengan sentuhan tradisi, tampil dengan elegansi.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: burgundy,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class ServiceShortcut extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;
  final bool horizontal;

  const ServiceShortcut({
    super.key,
    required this.icon,
    required this.title,
    required this.detail,
    this.horizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0E3DA)),
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: burgundy.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: burgundy),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: deepBurgundy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SectionHeading extends StatelessWidget {
  final String title;
  final String subtitle;
  const SectionHeading({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: deepBurgundy,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: muted, fontSize: 12)),
      ],
    );
  }
}

class StepTile extends StatelessWidget {
  final String number;
  final String title;
  final String detail;
  const StepTile({
    super.key,
    required this.number,
    required this.title,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: gold.withValues(alpha: .22),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: burgundy,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: deepBurgundy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    detail,
                    style: const TextStyle(
                      color: muted,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SERVICE, RENTAL, GALLERY
// -----------------------------------------------------------------------------

class ServiceTab extends StatelessWidget {
  const ServiceTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const CatalogTab(
      title: 'Jasa Jahit',
      subtitle: 'Layanan jahit yang dapat disesuaikan dengan kebutuhanmu.',
      table: 'jasa_jahit',
      emptyTitle: 'Layanan sedang disiapkan',
      emptyText: 'Hubungi NELY Collection untuk informasi layanan jahit.',
    );
  }
}

class RentalTab extends StatelessWidget {
  const RentalTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const CatalogTab(
      title: 'Sewa Kebaya',
      subtitle: 'Koleksi kebaya untuk acara dan momen istimewa.',
      table: 'kebaya',
      emptyTitle: 'Koleksi segera hadir',
      emptyText: 'Hubungi kami untuk bertanya tentang koleksi kebaya.',
    );
  }
}

class CatalogTab extends StatefulWidget {
  final String title;
  final String subtitle;
  final String table;
  final String emptyTitle;
  final String emptyText;

  const CatalogTab({
    super.key,
    required this.title,
    required this.subtitle,
    required this.table,
    required this.emptyTitle,
    required this.emptyText,
  });

  @override
  State<CatalogTab> createState() => _CatalogTabState();
}

class _CatalogTabState extends State<CatalogTab> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final rows = await supabase
        .from(widget.table)
        .select()
        .eq('aktif', true)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  void _refresh() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                color: deepBurgundy,
                fontSize: 29,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              widget.subtitle,
              style: const TextStyle(color: muted, height: 1.5),
            ),
            const SizedBox(height: 20),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return ErrorPanel(
                    message:
                        'Data belum dapat dimuat. Pastikan tabel "${widget.table}" dan izin Supabase sudah dibuat.',
                    onRetry: _refresh,
                  );
                }
                final rows = snapshot.data ?? [];
                if (rows.isEmpty) {
                  return EmptyPanel(
                    icon: widget.table == 'kebaya'
                        ? Icons.checkroom_outlined
                        : Icons.content_cut_outlined,
                    title: widget.emptyTitle,
                    message: widget.emptyText,
                    onContact: () => openWhatsApp(
                      'Halo NELY Collection, saya ingin bertanya tentang ${widget.title.toLowerCase()}.',
                    ),
                  );
                }
                return Column(
                  children: rows
                      .map(
                        (row) => CatalogCard(
                          row: row,
                          isRental: widget.table == 'kebaya',
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class CatalogCard extends StatelessWidget {
  final Map<String, dynamic> row;
  final bool isRental;
  const CatalogCard({super.key, required this.row, required this.isRental});

  @override
  Widget build(BuildContext context) {
    final title = (row['nama'] ?? row['judul'] ?? 'Layanan NELY').toString();
    final description =
        (row['deskripsi'] ?? 'Detail layanan dapat ditanyakan kepada toko.')
            .toString();
    final image = row['gambar_url']?.toString();
    final price = row['harga'];
    final available = row['tersedia'] != false;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF0E3DA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (image != null && image.startsWith('http'))
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
              child: Image.network(
                image,
                height: 190,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const CatalogImagePlaceholder(),
              ),
            )
          else
            const CatalogImagePlaceholder(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: deepBurgundy,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (price != null)
                      Text(
                        formatRupiah(price),
                        style: const TextStyle(
                          color: burgundy,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  description,
                  style: const TextStyle(color: muted, height: 1.5),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      available ? Icons.check_circle_outline : Icons.schedule,
                      size: 17,
                      color: available ? const Color(0xFF2E7D50) : gold,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        isRental
                            ? (available
                                  ? 'Tanyakan ketersediaan ukuran dan koleksi'
                                  : 'Perlu konfirmasi ketersediaan')
                            : (available
                                  ? 'Penerimaan permintaan dapat dikonfirmasi'
                                  : 'Konfirmasi penerimaan pesanan terlebih dahulu'),
                        style: const TextStyle(color: muted, fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderFormPage(
                        serviceName: title,
                        isRental: isRental,
                        price: price,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.edit_calendar_outlined, size: 19),
                  label: Text(isRental ? 'Ajukan sewa' : 'Pesan layanan'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CatalogImagePlaceholder extends StatelessWidget {
  const CatalogImagePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF4E5D9), Color(0xFFE8D2C2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.checkroom_outlined, color: burgundy, size: 42),
          SizedBox(height: 8),
          Text(
            'NELY COLLECTION',
            style: TextStyle(
              color: burgundy,
              fontSize: 10,
              letterSpacing: 2,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class GalleryTab extends StatefulWidget {
  const GalleryTab({super.key});

  @override
  State<GalleryTab> createState() => _GalleryTabState();
}

class _GalleryTabState extends State<GalleryTab> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final rows = await supabase
        .from('galeri')
        .select()
        .eq('aktif', true)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Galeri Koleksi',
            style: TextStyle(
              color: deepBurgundy,
              fontSize: 29,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Inspirasi detail jahitan dan koleksi NELY Collection.',
            style: TextStyle(color: muted, height: 1.5),
          ),
          const SizedBox(height: 20),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(35),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              if (snapshot.hasError) {
                return ErrorPanel(
                  message: 'Galeri belum dapat dimuat. Periksa tabel galeri dan izin akses Supabase.',
                  onRetry: () => setState(() => _future = _load()),
                );
              }
              final rows = snapshot.data ?? [];
              if (rows.isEmpty) {
                return EmptyPanel(
                  icon: Icons.photo_library_outlined,
                  title: 'Galeri sedang disiapkan',
                  message: 'Koleksi akan ditampilkan di sini setelah admin menambahkan foto.',
                  onContact: () => openWhatsApp(
                    'Halo NELY Collection, boleh minta informasi koleksi terbaru?',
                  ),
                );
              }
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: rows.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: .72,
                ),
                itemBuilder: (context, index) {
                  final row = rows[index];
                  final image = row['gambar_url']?.toString() ?? '';
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      color: const Color(0xFFF0E2D8),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (image.startsWith('http'))
                            Image.network(image, fit: BoxFit.cover)
                          else
                            const CatalogImagePlaceholder(),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              color: deepBurgundy.withValues(alpha: .85),
                              child: Text(
                                (row['judul'] ?? row['nama'] ?? 'Koleksi')
                                    .toString(),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// ORDER FORM / CUSTOMER ORDERS
// -----------------------------------------------------------------------------

class OrderFormPage extends StatefulWidget {
  final String serviceName;
  final bool isRental;
  final dynamic price;

  const OrderFormPage({
    super.key,
    required this.serviceName,
    required this.isRental,
    this.price,
  });

  @override
  State<OrderFormPage> createState() => _OrderFormPageState();
}

class _OrderFormPageState extends State<OrderFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _notes = TextEditingController();
  final _size = TextEditingController();
  final _date = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _notes.dispose();
    _size.dispose();
    _date.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan masuk terlebih dahulu.')),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      await supabase.from('pesanan').insert({
        'user_id': user.id,
        'nama_layanan': widget.serviceName,
        'jenis': widget.isRental ? 'sewa_kebaya' : 'jasa_jahit',
        'catatan': _notes.text.trim(),
        'ukuran': _size.text.trim(),
        'tanggal_acara': _date.text.trim().isEmpty ? null : _date.text.trim(),
        'status': 'menunggu',
        'harga': widget.price is num ? widget.price : null,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permintaan terkirim. Pantau status di Pesanan Saya.'),
          backgroundColor: burgundy,
        ),
      );
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pesanan belum tersimpan. Pastikan tabel pesanan dan policy Supabase sudah dibuat.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajukan pesanan')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: burgundy,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.isRental ? 'PERMINTAAN SEWA' : 'PERMINTAAN JAHIT',
                    style: const TextStyle(
                      color: gold,
                      fontSize: 10,
                      letterSpacing: 1.6,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    widget.serviceName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (widget.price != null) ...[
                    const SizedBox(height: 5),
                    Text(
                      formatRupiah(widget.price),
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 22),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  if (widget.isRental) ...[
                    TextFormField(
                      controller: _size,
                      decoration: const InputDecoration(
                        labelText: 'Ukuran / detail kebaya',
                        hintText: 'Contoh: ukuran M, warna marun',
                        prefixIcon: Icon(Icons.checkroom_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _date,
                      decoration: const InputDecoration(
                        labelText: 'Tanggal acara (opsional)',
                        hintText: 'YYYY-MM-DD',
                        prefixIcon: Icon(Icons.calendar_month_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ] else ...[
                    TextFormField(
                      controller: _size,
                      decoration: const InputDecoration(
                        labelText: 'Ukuran / kebutuhan jahit',
                        hintText: 'Contoh: atasan, bawahan, ukuran',
                        prefixIcon: Icon(Icons.straighten_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  TextFormField(
                    controller: _notes,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Catatan kebutuhan',
                      hintText:
                          'Ceritakan model, bahan, warna, atau detail lain.',
                      alignLabelWithHint: true,
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                    validator: (v) => (v?.trim().isEmpty ?? true)
                        ? 'Tulis sedikit detail kebutuhanmu.'
                        : null,
                  ),
                  const SizedBox(height: 22),
                  ElevatedButton(
                    onPressed: _busy ? null : _submit,
                    child: Text(_busy ? 'Mengirim...' : 'Kirim permintaan'),
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: () => openWhatsApp(
                      'Halo NELY Collection, saya ingin memesan ${widget.serviceName}. '
                      'Catatan: ${_notes.text.trim()}',
                    ),
                    icon: const Icon(Icons.chat_outlined),
                    label: const Text('Tanya lewat WhatsApp'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];
    final rows = await supabase
        .from('pesanan')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pesanan saya')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorPanel(
              message: 'Pesanan belum dapat dimuat. Periksa tabel dan policy Supabase.',
              onRetry: () => setState(() => _future = _load()),
            );
          }
          final rows = snapshot.data ?? [];
          if (rows.isEmpty) {
            return const EmptyPanel(
              icon: Icons.receipt_long_outlined,
              title: 'Belum ada pesanan',
              message:
                  'Pesanan yang kamu ajukan nanti akan muncul di halaman ini.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: rows.length,
            itemBuilder: (context, index) {
              final row = rows[index];
              final status = (row['status'] ?? 'menunggu').toString();
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFF0E3DA)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            (row['nama_layanan'] ?? 'Pesanan').toString(),
                            style: const TextStyle(
                              color: deepBurgundy,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        StatusPill(status: status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      (row['catatan'] ?? 'Tanpa catatan').toString(),
                      style: const TextStyle(color: muted, height: 1.4),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Diajukan: ${formatDate(row['created_at'])}',
                      style: const TextStyle(color: muted, fontSize: 11),
                    ),
                    if (row['catatan_admin'] != null &&
                        row['catatan_admin'].toString().isNotEmpty) ...[
                      const Divider(height: 20),
                      Text('Catatan toko: ${row['catatan_admin']}'),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  final String status;
  const StatusPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toLowerCase()) {
      case 'diterima':
      case 'selesai':
        color = const Color(0xFF2E7D50);
        break;
      case 'ditolak':
      case 'dibatalkan':
        color = const Color(0xFFB3261E);
        break;
      case 'diproses':
        color = const Color(0xFF89651E);
        break;
      default:
        color = burgundy;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// PROFILE / SIGN OUT
// -----------------------------------------------------------------------------

class ProfileTab extends StatefulWidget {
  final Map<String, dynamic> profile;
  final VoidCallback onProfileChanged;

  const ProfileTab({
    super.key,
    required this.profile,
    required this.onProfileChanged,
  });

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(
      text: widget.profile['nama']?.toString() ?? '',
    );
    _phone = TextEditingController(
      text: widget.profile['no_hp']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    setState(() => _saving = true);
    try {
      await supabase.from('profiles').upsert({
        'id': user.id,
        'nama': _name.text.trim(),
        'no_hp': _phone.text.trim(),
        'role': 'customer',
      });
      widget.onProfileChanged();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil gagal disimpan. Periksa izin Supabase.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _signOut() async {
    try {
      await supabase.auth.signOut();
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = supabase.auth.currentUser?.email ?? '-';
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Akun saya',
            style: TextStyle(
              color: deepBurgundy,
              fontSize: 29,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Kelola informasi akun dan akses pesananmu.',
            style: TextStyle(color: muted),
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: burgundy,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: gold,
                  child: Icon(
                    Icons.person_rounded,
                    color: deepBurgundy,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _name.text.isEmpty ? 'Pelanggan NELY' : _name.text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Nama lengkap',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Nomor WhatsApp',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Menyimpan...' : 'Simpan perubahan'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyOrdersPage()),
            ),
            icon: const Icon(Icons.receipt_long_outlined),
            label: const Text('Lihat pesanan saya'),
            style: OutlinedButton.styleFrom(
              foregroundColor: burgundy,
              minimumSize: const Size.fromHeight(50),
              side: const BorderSide(color: gold),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _signOut,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Keluar dari akun'),
            style: OutlinedButton.styleFrom(
              foregroundColor: burgundy,
              minimumSize: const Size.fromHeight(50),
              side: const BorderSide(color: Color(0xFFE8DCD6)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Center(
            child: Text(
              'NELY Collection • Tradisi dalam setiap detail',
              style: TextStyle(color: muted, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// ADMIN AREA
// -----------------------------------------------------------------------------

class AdminDashboardPage extends StatefulWidget {
  final Map<String, dynamic> profile;
  const AdminDashboardPage({super.key, required this.profile});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  late Future<List<Map<String, dynamic>>> _orders;

  @override
  void initState() {
    super.initState();
    _orders = _loadOrders();
  }

  Future<List<Map<String, dynamic>>> _loadOrders() async {
    final rows = await supabase
        .from('pesanan')
        .select('*, profiles(nama, no_hp)')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> _setStatus(Map<String, dynamic> order, String status) async {
    try {
      await supabase
          .from('pesanan')
          .update({
            'status': status,
            'catatan_admin': 'Status diperbarui oleh admin.',
          })
          .eq('id', order['id']);
      if (!mounted) return;
      setState(() => _orders = _loadOrders());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status pesanan menjadi $status.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Status gagal diperbarui. Periksa policy admin.'),
        ),
      );
    }
  }

  Future<void> _signOut() async {
    await supabase.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final adminName =
        widget.profile['nama']?.toString().trim().isNotEmpty == true
        ? widget.profile['nama'].toString()
        : 'Admin NELY';
    return Scaffold(
      appBar: AppBar(
        title: const Text('NELY • Admin'),
        actions: [
          IconButton(
            onPressed: () => setState(() => _orders = _loadOrders()),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Muat ulang',
          ),
          IconButton(
            onPressed: _signOut,
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Keluar',
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [deepBurgundy, burgundy],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DASHBOARD PENGELOLA',
                    style: TextStyle(
                      color: gold,
                      letterSpacing: 1.5,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    'Halo, $adminName',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Pantau permintaan dan kelola status pesanan.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const SectionHeading(
              title: 'Daftar pesanan',
              subtitle: 'Permintaan terbaru dari pelanggan',
            ),
            const SizedBox(height: 14),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _orders,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(30),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return ErrorPanel(
                    message: 'Data pesanan belum bisa dibuka. Pastikan profil admin memiliki role admin dan policy database sudah benar.',
                    onRetry: () => setState(() => _orders = _loadOrders()),
                  );
                }
                final orders = snapshot.data ?? [];
                if (orders.isEmpty) {
                  return const EmptyPanel(
                    icon: Icons.inbox_outlined,
                    title: 'Belum ada permintaan',
                    message: 'Pesanan pelanggan akan muncul di bagian ini.',
                  );
                }
                return Column(
                  children: orders.map((order) {
                    final customer = order['profiles'];
                    final customerName = customer is Map
                        ? (customer['nama'] ?? 'Pelanggan').toString()
                        : 'Pelanggan';
                    final status = (order['status'] ?? 'menunggu').toString();
                    return Container(
                      margin: const EdgeInsets.only(bottom: 13),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFF0E3DA)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  (order['nama_layanan'] ?? 'Pesanan')
                                      .toString(),
                                  style: const TextStyle(
                                    color: deepBurgundy,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              StatusPill(status: status),
                            ],
                          ),
                          const SizedBox(height: 7),
                          Text(
                            'Pelanggan: $customerName',
                            style: const TextStyle(color: muted, fontSize: 12),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            (order['catatan'] ?? 'Tanpa catatan').toString(),
                            style: const TextStyle(height: 1.4),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            'Tanggal: ${formatDate(order['created_at'])}',
                            style: const TextStyle(color: muted, fontSize: 11),
                          ),
                          const SizedBox(height: 13),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _statusButton(order, 'menunggu'),
                              _statusButton(order, 'diproses'),
                              _statusButton(order, 'diterima'),
                              _statusButton(order, 'selesai'),
                              _statusButton(order, 'ditolak'),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 20),
            const Divider(),
            const Text(
              'Catatan: pengelolaan katalog dan unggah foto perlu dibuat melalui tabel/storage Supabase atau halaman admin tambahan.',
              style: TextStyle(color: muted, fontSize: 12, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusButton(Map<String, dynamic> order, String status) {
    final selected = order['status'] == status;
    return OutlinedButton(
      onPressed: selected ? null : () => _setStatus(order, status),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        foregroundColor: burgundy,
        side: BorderSide(color: selected ? gold : const Color(0xFFE3D5CD)),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(status, style: const TextStyle(fontSize: 11)),
    );
  }
}

// -----------------------------------------------------------------------------
// SHARED UI / HELPERS
// -----------------------------------------------------------------------------

class LoadingPage extends StatelessWidget {
  const LoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.design_services_rounded, color: burgundy, size: 44),
            SizedBox(height: 16),
            CircularProgressIndicator(color: burgundy),
            SizedBox(height: 14),
            Text(
              'Menyiapkan NELY Collection...',
              style: TextStyle(color: muted),
            ),
          ],
        ),
      ),
    );
  }
}

class ErrorPanel extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ErrorPanel({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0E3DA)),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined, color: burgundy, size: 34),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: muted, height: 1.5),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Coba lagi'),
          ),
        ],
      ),
    );
  }
}

class EmptyPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onContact;

  const EmptyPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.onContact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0E3DA)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 38, color: gold),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: deepBurgundy,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: muted, height: 1.5),
          ),
          if (onContact != null) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onContact,
              icon: const Icon(Icons.chat_outlined),
              label: const Text('Hubungi toko'),
            ),
          ],
        ],
      ),
    );
  }
}

String formatRupiah(dynamic value) {
  if (value == null) return '';
  final number = value is num
      ? value.round()
      : int.tryParse(value.toString()) ?? 0;
  final digits = number.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    buffer.write(digits[i]);
    final remaining = digits.length - i - 1;
    if (remaining > 0 && remaining % 3 == 0) buffer.write('.');
  }
  return 'Rp${buffer.toString()}';
}

String formatDate(dynamic value) {
  if (value == null) return '-';
  final parsed = DateTime.tryParse(value.toString());
  if (parsed == null) return value.toString();
  final local = parsed.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  return '$day-$month-${local.year}';
}

Future<void> openWhatsApp(String message) async {
  final uri = Uri.parse(
    'https://wa.me/$whatsappNumber?text=${Uri.encodeComponent(message)}',
  );
  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) throw Exception('WhatsApp tidak dapat dibuka');
  } catch (_) {
    // Tidak memunculkan error global jika aplikasi WhatsApp tidak tersedia.
  }
}
