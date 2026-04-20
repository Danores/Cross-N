import 'dart:ui'; // Cam efekti (Blur) için gerekli
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; // Harita
import 'package:latlong2/latlong.dart'; // Koordinat
import 'package:geolocator/geolocator.dart'; // Konum
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 👇 BURAYA KENDİ PROJE BİLGİLERİNİ GİR
  await Supabase.initialize(
    url: '', 
    anonKey: '', 
  );

  runApp(const CustomerApp());
}

class CustomerApp extends StatelessWidget {
  const CustomerApp({super.key});

  // 🔥 YENİ RENK PALETİ: NEON GECE
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PartyFinder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0E21), // Çok derin lacivert/siyah
        primaryColor: const Color(0xFF6C63FF), // Ana Mor
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6C63FF), // Mor
          secondary: Color(0xFF00E5FF), // Elektrik Mavisi (Vurgular için)
          tertiary: Color(0xFFFF2E63), // Neon Pembe (İptal/Dikkat için)
          surface: Color(0xFF1D1E33), // Kartlar için koyu zemin
        ),
        useMaterial3: true,
        // Fontları daha modern yapabiliriz (Varsayılanı kullanıyorum şimdilik)
        textTheme: Typography.whiteMountainView.apply(fontFamily: 'Roboto'), 
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
        if (snapshot.hasData && snapshot.data?.session != null) {
          return const MainLayout();
        } else {
          return const WelcomeScreen();
        }
      },
    );
  }
}

// -----------------------------------------------------------------------------
// 2. WELCOME SCREEN (Giriş Ekranı - Daha Havalı Arka Plan)
// -----------------------------------------------------------------------------
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isLoading = false;

  Future<void> _signInAnonymously() async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInAnonymously();
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Daha agresif bir gradyan arka plan
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2E0249), Color(0xFF570A57), Color(0xFFA91079)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Hafif bir doku (isteğe bağlı)
          Container(color: Colors.black.withOpacity(0.3)),

          Center(
            child: NeonGlassBox(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.nightlife, size: 80, color: Theme.of(context).colorScheme.secondary),
                  const SizedBox(height: 20),
                  Text("GECEYİ YAKALA", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2, shadows: [Shadow(color: Theme.of(context).colorScheme.secondary, blurRadius: 10)])),
                  const SizedBox(height: 10),
                  const Text("Sana en uygun mekanı bulalım.", style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 40),
                  _isLoading 
                    ? CircularProgressIndicator(color: Theme.of(context).colorScheme.secondary)
                    : SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _signInAnonymously,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.secondary, // Elektrik mavisi
                            foregroundColor: Colors.black,
                            elevation: 10,
                            shadowColor: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: const Text("BAŞLA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        ),
                      )
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
// 3. MAIN LAYOUT (Alt Menü)
// -----------------------------------------------------------------------------
class MainLayout extends StatefulWidget {
  const MainLayout({super.key});
  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  final List<Widget> _screens = [const FindVenueScreen(), const ProfileScreen()];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      extendBody: true,
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              // Daha koyu ve morumsu alt menü
              color: Color(0xFF1A1A2E).withOpacity(0.8),
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(Icons.map_outlined, Icons.map, "Mekan Bul", 0, colorScheme.secondary),
                  _buildNavItem(Icons.person_outline, Icons.person, "Profilim", 1, colorScheme.primary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData iconOutlined, IconData iconFilled, String label, int index, Color activeColor) {
    final bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: isSelected 
          ? BoxDecoration(color: activeColor.withOpacity(0.2), borderRadius: BorderRadius.circular(20))
          : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isSelected ? iconFilled : iconOutlined, color: isSelected ? activeColor : Colors.white54, size: 26),
             if (isSelected) ...[
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: activeColor, fontWeight: FontWeight.bold, fontSize: 14))
             ]
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 4. MEKAN BULMA EKRANI (Ana Operasyon)
// -----------------------------------------------------------------------------
class FindVenueScreen extends StatefulWidget {
  const FindVenueScreen({super.key});
  @override
  State<FindVenueScreen> createState() => _FindVenueScreenState();
}

class _FindVenueScreenState extends State<FindVenueScreen> {
  LatLng? _currentLocation;
  final MapController _mapController = MapController();
  double _groupSize = 2;
  String _venueType = 'pub';
  bool _isRequesting = false;
  
  List<Map<String, dynamic>> _offers = [];
  String? _currentRequestId;

  // Rota Çizgisi İçin Değişkenler
  List<LatLng> _routePoints = []; 
  bool _showRoute = false;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
    });
  }

  Future<void> _sendRequest() async {
    if (_currentLocation == null) return;
    setState(() {
      _isRequesting = true;
      _offers = []; 
      _showRoute = false;
      _routePoints = [];
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      final response = await Supabase.instance.client.from('requests').insert({
        'user_id': user!.id,
        'group_size': _groupSize.toInt(),
        'preferred_type': _venueType,
        'user_location': 'SRID=4326;POINT(${_currentLocation!.longitude} ${_currentLocation!.latitude})',
        'status': 'pending'
      }).select().single();

      if (mounted) {
        _currentRequestId = response['id'];
        _listenForOffers(response['id']);     
        _listenRequestStatus(response['id']); 
      }
    } catch (e) {
      setState(() => _isRequesting = false);
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
    }
  }

  void _listenForOffers(String requestId) {
    Supabase.instance.client
        .from('offers')
        .stream(primaryKey: ['id'])
        .eq('request_id', requestId)
        .listen((data) async {
      
      final List<Map<String, dynamic>> enrichedOffers = [];
      for (var offer in data) {
        final venue = await Supabase.instance.client
            .from('venues')
            .select('name, rating, location')
            .eq('id', offer['venue_id'])
            .single();
        final newOffer = Map<String, dynamic>.from(offer);
        newOffer['venue_details'] = venue;
        enrichedOffers.add(newOffer);
      }

      if (mounted) setState(() => _offers = enrichedOffers);
    });
  }

  void _listenRequestStatus(String requestId) {
    Supabase.instance.client
        .from('requests')
        .stream(primaryKey: ['id'])
        .eq('id', requestId)
        .listen((data) {
      if (data.isNotEmpty && mounted) {
        if (data.first['status'] == 'rejected') {
          setState(() => _isRequesting = false);
          _showErrorDialog("İsteğin reddedildi veya zaman aşımına uğradı.");
        }
      }
    });
  }

  Future<void> _selectVenue(Map<String, dynamic> offer) async {
    try {
      await Supabase.instance.client
          .from('requests')
          .update({'status': 'on_way'}).eq('id', _currentRequestId!); // on_way

      await Supabase.instance.client
          .from('offers')
          .update({'status': 'accepted'}).eq('id', offer['id']);

      setState(() => _isRequesting = false); 

      // Rota Çizme (Dummy)
      final venueLat = _currentLocation!.latitude + 0.005;
      final venueLng = _currentLocation!.longitude + 0.005;

      setState(() {
        _showRoute = true;
        _routePoints = [
          _currentLocation!,
          LatLng(venueLat, venueLng),
        ];
        _mapController.move(
            LatLng((_currentLocation!.latitude + venueLat) / 2, 
                   (_currentLocation!.longitude + venueLng) / 2), 
            14
        );
      });

      if(mounted) {
        showDialog(
          context: context,
          builder: (c) => NeonAlertDialog(
            title: "🎉 YOLA ÇIK!",
            content: "${offer['venue_details']['name']} seni bekliyor.\nRotan oluşturuldu!",
            buttonText: "TAMAM",
            onPressed: () => Navigator.pop(c),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
    }
  }

    // --- MÜŞTERİ "GELDİM" DERSE ---
  Future<void> _markAsArrived() async {
    try {
      await Supabase.instance.client
          .from('requests')
          .update({'status': 'arrived'})
          .eq('id', _currentRequestId!);

      setState(() {
        _isRequesting = false;
        _showRoute = false; // Rotayı kaldır
        _offers = [];
      });

      if(mounted) {
        showDialog(
          context: context,
          builder: (c) => NeonAlertDialog(
            title: "Hoş Geldiniz! 🍻",
            content: "Mekana vardınız. İyi eğlenceler!",
            buttonText: "Teşekkürler",
            onPressed: () => Navigator.pop(c),
             isSuccess: true,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
    }
  }

  // --- MÜŞTERİ "VAZGEÇTİM" DERSE ---
  Future<void> _cancelTrip() async {
    try {
      await Supabase.instance.client
          .from('requests')
          .update({'status': 'canceled'})
          .eq('id', _currentRequestId!);

      setState(() {
        _isRequesting = false;
        _showRoute = false; // Rotayı kaldır
        _offers = [];
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Yolculuk iptal edildi.")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
    }
  }


  void _showErrorDialog(String msg) {
    showDialog(
      context: context,
      builder: (c) => NeonAlertDialog(title: "Üzgünüz", content: msg, buttonText: "Tamam", onPressed: () => Navigator.pop(c), isError: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (_currentLocation == null) return Center(child: CircularProgressIndicator(color: colorScheme.secondary));

    return Stack(
      children: [
        // 1. HARİTA (KARANLIK MOD)
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(initialCenter: _currentLocation!, initialZoom: 15),
          children: [
            // 👇 İŞTE SİHİRLİ DOKUNUŞ: KARANLIK HARİTA KATMANI
            TileLayer(
              urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.partyfinder.app', // Kendi paket adın
            ),
            
            if (_showRoute)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePoints,
                    strokeWidth: 5.0,
                    // isDotted satırını sildik, hata ondan kaynaklanıyordu.
                    color: colorScheme.secondary.withOpacity(0.8),
                  ),
                ],
              ),

            MarkerLayer(markers: [
              // Müşteri (Sen) - Daha parlak ikon
              Marker(
                point: _currentLocation!, width: 80, height: 80, 
                child: Icon(Icons.person_pin_circle, color: colorScheme.secondary, size: 50, shadows: [Shadow(color: colorScheme.secondary, blurRadius: 20)])
              ),
              
              // Mekan İkonu
              if (_showRoute && _routePoints.isNotEmpty)
                Marker(
                  point: _routePoints.last, width: 80, height: 80, 
                  child: Icon(Icons.location_on, color: colorScheme.tertiary, size: 50, shadows: [Shadow(color: colorScheme.tertiary, blurRadius: 20)])
                ),
            ]),
          ],
        ),

        // 2. ARAYÜZ KATMANLARI
        if (_isRequesting)
          // --- DURUM A: MEKAN ARANIYOR VEYA TEKLİFLER GELİYOR ---
          Positioned(
            bottom: 120, left: 20, right: 20,
            child: Column(
              children: [
                NeonGlassBox(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 3, color: colorScheme.secondary)),
                      const SizedBox(width: 15),
                      Text(_offers.isEmpty ? "Mekanlar Aranıyor..." : "Teklifler Geliyor!", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 15),

                if (_offers.isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 250),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _offers.length,
                      itemBuilder: (context, index) {
                        final offer = _offers[index];
                        final details = offer['venue_details'];
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: NeonGlassBox(
                            padding: const EdgeInsets.all(15),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(15)),
                                  child: Icon(Icons.store, color: colorScheme.primary, size: 30)
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(details['name'] ?? "Bilinmeyen Mekan", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                      Row(children: [Icon(Icons.star, color: Colors.amber, size: 16), Text(" ${details['rating']}", style: const TextStyle(color: Colors.white70))]),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () => _selectVenue(offer),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colorScheme.secondary, 
                                    foregroundColor: Colors.black,
                                    shadowColor: colorScheme.secondary.withOpacity(0.5),
                                    elevation: 8,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                                  ),
                                  child: const Text("Git", style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          )
         // 👇 YENİ: YOLCULUK MODU
        else if (_showRoute)
          Positioned(
            bottom: 120, left: 20, right: 20,
            child: NeonGlassBox(
              child: Column(
                children: [
                  Text("YOLDASINIZ 🚀", style: TextStyle(color: colorScheme.secondary, fontSize: 22, fontWeight: FontWeight.bold, shadows: [Shadow(color: colorScheme.secondary, blurRadius: 10)])),
                  const SizedBox(height: 5),
                  const Text("Rotayı takip edin...", style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 25),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _cancelTrip,
                          icon: const Icon(Icons.close),
                          label: const Text("Vazgeç"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colorScheme.tertiary,
                            side: BorderSide(color: colorScheme.tertiary),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _markAsArrived,
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text("Ben Geldim!"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            elevation: 10,
                            shadowColor: Colors.green.withOpacity(0.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          )
          else
          // --- DURUM B: İSTEK FORMU (Slim Fit Tasarım) ---
          Positioned(
            top: 60, left: 30, right: 30, // Sağdan soldan biraz daha pay verdik (daha dar dursun)
            child: NeonGlassBox(
              // 👇 1. PADDING AZALTILDI (Eskisi 25'ti, 15 yaptık)
              padding: const EdgeInsets.all(15), 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // İçeriği kadar yer kaplasın
                children: [
                  const Text("KAÇ KİŞİYİZ?", style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                  
                  // Slider Kısmı (Biraz sıkıştırdık)
                  SizedBox(
                    height: 40, // Slider'ın kapladığı alanı kısıtladık
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("1", style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                        Expanded(
                          child: SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: Theme.of(context).colorScheme.secondary,
                              inactiveTrackColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                              thumbColor: Theme.of(context).colorScheme.secondary,
                              overlayColor: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                              trackHeight: 2, // Çubuğu incelttik
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8), // Topu küçülttük
                            ),
                            child: Slider(
                              value: _groupSize, min: 1, max: 15, divisions: 14,
                              label: _groupSize.toInt().toString(),
                              onChanged: (val) => setState(() => _groupSize = val),
                            ),
                          ),
                        ),
                        Text("15", style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                      ],
                    ),
                  ),
                  Center(child: Text("${_groupSize.toInt()} Kişi", style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold, fontSize: 16))),
                  
                  // 👇 2. BOŞLUK AZALTILDI (Eskisi 25'ti)
                  const SizedBox(height: 15),
                  
                  const Text("NE İÇİYORUZ?", style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5), // Başlık ile kutu arasını azalttık
                  
                  Container(
                    height: 45, // Dropdown kutusunu incelttik
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12), // Köşeleri biraz daha az yuvarladık
                      border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3))
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _venueType,
                        dropdownColor: const Color(0xFF1A1A2E),
                        isExpanded: true,
                        icon: Icon(Icons.keyboard_arrow_down, color: Theme.of(context).colorScheme.secondary),
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        items: ['pub', 'bar', 'cafe', 'restoran']
                            .map((v) => DropdownMenuItem(value: v, child: Text(v.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: v == _venueType ? Theme.of(context).colorScheme.secondary : Colors.white))))
                            .toList(),
                        onChanged: (val) => setState(() => _venueType = val!),
                      ),
                    ),
                  ),
                  
                  // 👇 3. BUTON ÜSTÜ BOŞLUK AZALTILDI (Eskisi 30'du)
                  const SizedBox(height: 20),
                  
                  // Buton
                  SizedBox(
                    width: double.infinity, 
                    height: 45, // 👇 4. BUTON BOYU KISALTILDI (Eskisi 60'tı)
                    child: ElevatedButton(
                      onPressed: _sendRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                        elevation: 8,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: const Text("MEKAN BUL", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2)),
                    ),
                  )
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// 5. PROFİL EKRANI (Gelişmiş)
// -----------------------------------------------------------------------------
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      body: Stack(
        children: [
           Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0A0E21), Color(0xFF1A1A2E)],
                begin: Alignment.topCenter, end: Alignment.bottomCenter
              ),
            ),
          ),
          Center(
            child: NeonGlassBox(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: colorScheme.secondary, width: 2)),
                    child: CircleAvatar(radius: 50, backgroundColor: colorScheme.primary.withOpacity(0.2), child: Icon(Icons.person, size: 50, color: colorScheme.secondary)),
                  ),
                  const SizedBox(height: 20),
                  const Text("Misafir Kullanıcı", style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)),
                    child: Text("ID: ${user?.id.substring(0, 8) ?? '...'}...", style: TextStyle(color: Colors.white54, fontFamily: 'monospace')),
                  ),
                  const SizedBox(height: 40),
                  OutlinedButton.icon(
                    onPressed: () => Supabase.instance.client.auth.signOut(),
                    icon: const Icon(Icons.logout),
                    label: const Text("Çıkış Yap"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.tertiary,
                      side: BorderSide(color: colorScheme.tertiary),
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 💎 YENİ YARDIMCI WIDGET'LAR: NEON GLASS BOX & ALERT
// -----------------------------------------------------------------------------
class NeonGlassBox extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const NeonGlassBox({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding ?? const EdgeInsets.all(25),
          decoration: BoxDecoration(
            // Hafif mor/mavi gradyanlı cam
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.15),
                Theme.of(context).colorScheme.secondary.withOpacity(0.05),
              ]
            ),
            borderRadius: BorderRadius.circular(25),
            // Parlayan ince kenarlık
            border: Border.all(color: Theme.of(context).colorScheme.secondary.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, spreadRadius: 5)
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class NeonAlertDialog extends StatelessWidget {
  final String title;
  final String content;
  final String buttonText;
  final VoidCallback onPressed;
  final bool isError;
  final bool isSuccess;

  const NeonAlertDialog({
    super.key, required this.title, required this.content, required this.buttonText, required this.onPressed, this.isError = false, this.isSuccess = false,
  });

  @override
  Widget build(BuildContext context) {
    Color headerColor = Theme.of(context).colorScheme.secondary;
    if (isError) headerColor = Theme.of(context).colorScheme.tertiary;
    if (isSuccess) headerColor = Colors.greenAccent;

    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: headerColor.withOpacity(0.5))),
      title: Text(title, style: TextStyle(color: headerColor, fontWeight: FontWeight.bold)),
      content: Text(content, style: const TextStyle(color: Colors.white70)),
      actions: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(backgroundColor: headerColor, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.bold)),
        )
      ],
    );
  }
}