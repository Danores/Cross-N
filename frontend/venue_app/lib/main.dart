import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 👇 BURAYA KENDİ PROJE BİLGİLERİNİ GİR
  await Supabase.initialize(
    url: '', 
    anonKey: '', 
  );

  runApp(const VenueOwnerApp());
}

class VenueOwnerApp extends StatelessWidget {
  const VenueOwnerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mekan Paneli',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange, brightness: Brightness.dark),
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

// -----------------------------------------------------------------------------
// 1. AUTH GATE
// -----------------------------------------------------------------------------
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session;
        if (session != null) {
          return const DashboardScreen(); 
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}

// -----------------------------------------------------------------------------
// 2. LOGIN SCREEN
// -----------------------------------------------------------------------------
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signIn() async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mekan Sahibi Girişi")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.store, size: 80, color: Colors.orange),
            const SizedBox(height: 20),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Şifre', border: OutlineInputBorder()), obscureText: true),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _signIn,
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.orange, foregroundColor: Colors.black),
                    child: const Text("Giriş Yap", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 3. DASHBOARD (TEK STREAM İLE ÇÖZÜM)
// -----------------------------------------------------------------------------
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // 👇 TEK VE DEV BİR YAYIN (Filtresiz)
  // Tüm istekleri dinliyoruz, ayrıştırmayı aşağıda Dart ile yapacağız.
  final _mainStream = Supabase.instance.client
      .from('requests')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false) // En yeniler
      .limit(100); // 👈 SADECE SON 100 İŞLEMİ GETİR 

  final Set<dynamic> _hiddenIds = {};

  Future<void> _acceptRequest(Map<String, dynamic> request) async {
    try {
      final user = Supabase.instance.client.auth.currentUser!;
      setState(() => _hiddenIds.add(request['id']));

      final venueData = await Supabase.instance.client
          .from('venues')
          .select()
          .eq('owner_id', user.id)
          .single();

      await Supabase.instance.client.from('offers').insert({
        'request_id': request['id'],
        'venue_id': venueData['id'],
        'status': 'pending',
      });
      // Not: Requests tablosunu güncellemiyoruz, müşteri güncelleyecek.
      
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Teklif Gönderildi!')));
    } catch (e) {
      setState(() => _hiddenIds.remove(request['id']));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }

  Future<void> _rejectRequest(String requestId) async {
    setState(() => _hiddenIds.add(requestId)); 
    try {
      await Supabase.instance.client
          .from('requests')
          .update({'status': 'rejected'}).eq('id', requestId);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Reddedildi.')));
    } catch (e) {
      setState(() => _hiddenIds.remove(requestId));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Mekan Paneli"),
          bottom: const TabBar(
            indicatorColor: Colors.orange,
            labelColor: Colors.orange,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(icon: Icon(Icons.notifications_active), text: "BEKLEYENLER"),
              Tab(icon: Icon(Icons.history), text: "GEÇMİŞ & DURUM"),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => Supabase.instance.client.auth.signOut(),
            )
          ],
        ),
        // StreamBuilder'ı EN TEPEYE koyduk.
        body: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _mainStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.orange));

            final allRequests = snapshot.data!;
            
            // 👇 SİHİRLİ KISIM: LİSTELERİ BURADA AYIRIYORUZ
            // 1. Bekleyenler: Status 'pending' olanlar
            final pendingList = allRequests
                .where((req) => req['status'] == 'pending' && !_hiddenIds.contains(req['id']))
                .toList();
            
            // 2. Geçmiş: Status 'pending' OLMAYANLAR (Matched, OnWay, Arrived, Rejected...)
            final historyList = allRequests
                .where((req) => req['status'] != 'pending')
                .toList();

            // Sıralamayı Düzeltelim:
            // Bekleyenler -> En Eski En Üste (İlk gelen ilk hizmet alır)
            pendingList.sort((a, b) => (a['created_at'] as String).compareTo(b['created_at']));
            
            // Geçmiş -> En Yeni En Üste (Son olay tepede)
            historyList.sort((a, b) => (b['created_at'] as String).compareTo(a['created_at']));

            return TabBarView(
              children: [
                // 1. SEKME: BEKLEYENLER
                _buildListContent(pendingList, isHistory: false),
                
                // 2. SEKME: GEÇMİŞ
                _buildListContent(historyList, isHistory: true),
              ],
            );
          },
        ),
      ),
    );
  }

  // Listeyi Çizen Widget
  Widget _buildListContent(List<Map<String, dynamic>> requests, {required bool isHistory}) {
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isHistory ? Icons.history_toggle_off : Icons.coffee, size: 60, color: Colors.grey),
            const SizedBox(height: 10),
            Text(isHistory ? "İşlem geçmişi boş." : "Bekleyen talep yok.", style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final req = requests[index];
        final status = req['status'];

        final bool isRejected = status == 'rejected';
        final bool isCanceled = status == 'canceled';
        final bool isOnWay = status == 'on_way';
        final bool isArrived = status == 'arrived';

        // Renkler
        Color cardColor = Colors.grey[900]!;
        Color statusColor = Colors.grey;
        String statusText = "BEKLEMEDE / EŞLEŞTİ";

        if (isOnWay) {
          cardColor = Colors.green[900]!;
          statusColor = Colors.greenAccent;
          statusText = "MÜŞTERİ GELİYOR 🚀";
        } else if (isArrived) {
          cardColor = Colors.blue[900]!;
          statusColor = Colors.cyanAccent;
          statusText = "MÜŞTERİ GELDİ 🎉";
        } else if (isRejected) {
          cardColor = Colors.red[900]!.withOpacity(0.3);
          statusColor = Colors.red;
          statusText = "REDDEDİLDİ";
        } else if (isCanceled) {
          cardColor = Colors.red[900]!.withOpacity(0.3);
          statusColor = Colors.orange;
          statusText = "MÜŞTERİ VAZGEÇTİ ❌";
        }

        return Card(
          margin: const EdgeInsets.all(10),
          color: cardColor,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(isOnWay ? Icons.directions_run : Icons.groups, color: Colors.orange),
                        const SizedBox(width: 10),
                        Text("${req['group_size']} Kişilik", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                    if (isHistory)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: statusColor.withOpacity(0.5))
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                Text("Tür: ${req['preferred_type'].toString().toUpperCase()}", style: const TextStyle(color: Colors.white70)),
                
                if (!isHistory) ...[
                  const Divider(color: Colors.white24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => _rejectRequest(req['id']),
                        child: const Text("Reddet", style: TextStyle(color: Colors.red)),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () => _acceptRequest(req),
                        icon: const Icon(Icons.check),
                        label: const Text("Teklif Ver"),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.black),
                      ),
                    ],
                  ),
                ]
              ],
            ),
          ),
        );
      },
    );
  }
}