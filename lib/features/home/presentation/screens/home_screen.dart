import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../recipes/presentation/screens/recipes_screen.dart';
import '../../../recipe_detail/presentation/screens/recipe_detail_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../chatbot/presentation/screens/chatbot_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1412),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _HomeContent(),
          RecipesScreen(),
          ChatbotScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _buildTabBar(),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF161E1A),
        border: Border(
            top: BorderSide(color: Color(0xFF253028), width: 0.5)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              _tabItem(0, Icons.home_rounded,
                  Icons.home_outlined, 'Inicio'),
              _tabItem(1, Icons.menu_book_rounded,
                  Icons.menu_book_outlined, 'Recetas'),
              _tabItem(2, Icons.chat_bubble_rounded,
                  Icons.chat_bubble_outline_rounded, 'Chat'),
              _tabItem(3, Icons.person_rounded,
                  Icons.person_outline_rounded, 'Perfil'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabItem(int index, IconData activeIcon,
      IconData inactiveIcon, String label) {
    final isActive = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isActive ? activeIcon : inactiveIcon,
                color: isActive
                    ? const Color(0xFF3ECF7C)
                    : const Color(0xFF566860),
                size: 22),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive
                      ? FontWeight.w600 : FontWeight.w400,
                  color: isActive
                      ? const Color(0xFF3ECF7C)
                      : const Color(0xFF566860),
                )),
            const SizedBox(height: 2),
            if (isActive)
              Container(
                width: 4, height: 4,
                decoration: const BoxDecoration(
                    color: Color(0xFF3ECF7C),
                    shape: BoxShape.circle),
              )
            else
              const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

// ── CONTENIDO HOME ────────────────────────────────────────────
class _HomeContent extends StatefulWidget {
  const _HomeContent();
  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  String _userName = '';
  List<Map<String, dynamic>> _recipes      = [];
  List<Map<String, dynamic>> _userDiseases = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final storage = sl<SecureStorage>();
      final userId  = await storage.getUserId() ?? '0';
      final name    = await storage.getName() ?? '';
      if (mounted) setState(() => _userName = name);

      final results = await Future.wait([
        sl<DioClient>().get('${ApiConstants.recommended}/$userId'),
        sl<DioClient>().get('${ApiConstants.onboarding}/$userId/needed'),
      ]);

      final recipesRes  = results[0];
      final diseasesRes = await sl<DioClient>()
          .get('${ApiConstants.userDiseases}/$userId');

      if (mounted) {
        setState(() {
          _recipes = List<Map<String, dynamic>>.from(recipesRes.data);
          _userDiseases = List<Map<String, dynamic>>.from(
              diseasesRes.data is List ? diseasesRes.data : []);
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando home: $e');
      try {
        final res = await sl<DioClient>().get(ApiConstants.recipes);
        if (mounted) {
          setState(() {
            _recipes = List<Map<String, dynamic>>.from(res.data);
            _loading = false;
          });
        }
      } catch (e2) {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buenos días,';
    if (hour < 18) return 'Buenas tardes,';
    return 'Buenas noches,';
  }

  List<Map<String, dynamic>> get _breakfastRecipes =>
      _recipes.where((r) => r['mealType'] == 'desayuno').toList();
  List<Map<String, dynamic>> get _lunchRecipes =>
      _recipes.where((r) => r['mealType'] == 'almuerzo').toList();
  List<Map<String, dynamic>> get _dinnerRecipes =>
      _recipes.where((r) => r['mealType'] == 'cena').toList();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: _loading
          ? const Center(child: CircularProgressIndicator(
          color: Color(0xFF3ECF7C)))
          : RefreshIndicator(
        onRefresh: _loadData,
        color: const Color(0xFF3ECF7C),
        backgroundColor: const Color(0xFF1A2420),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              if (_userDiseases.isNotEmpty) _buildHealthCard(),
              _buildSectionHeader('Desayunos recomendados',
                  onTap: () {}),
              _buildRecipeScroll(_breakfastRecipes),
              _buildSectionHeader('Almuerzos recomendados',
                  onTap: () {}),
              _buildRecipeScroll(_lunchRecipes),
              _buildTipCard(),
              _buildSectionHeader('Cenas recomendadas',
                  onTap: () {}),
              _buildRecipeScroll(_dinnerRecipes),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_getGreeting(),
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF8FA899))),
              Text(
                _userName.isNotEmpty ? _userName : 'Bienvenido',
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFE8F0EC)),
              ),
            ],
          ),
          GestureDetector(
            onTap: () async {
              await sl<SecureStorage>().clearTokens();
              if (context.mounted) context.go('/login');
            },
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF1A2420),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                    color: const Color(0xFF2E3D36), width: 0.5),
              ),
              child: const Icon(Icons.notifications_none_rounded,
                  size: 18, color: Color(0xFF8FA899)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A4A30),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2DB868), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('MIS CONDICIONES',
                  style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w600,
                      color: Color(0xFFA8F0C6), letterSpacing: 0.1)),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF3ECF7C),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${_userDiseases.length} activas',
                    style: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w600,
                        color: Color(0xFF0F1412))),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: _userDiseases
                .map((d) => _ConditionPill(d['name'] ?? ''))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title,
      {required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w500,
                  color: Color(0xFFE8F0EC))),
          GestureDetector(
            onTap: onTap,
            child: const Text('Ver todas',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w500,
                    color: Color(0xFF3ECF7C))),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeScroll(List<Map<String, dynamic>> recipes) {
    if (recipes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Text('Sin recetas disponibles',
            style: TextStyle(fontSize: 13, color: Color(0xFF566860))),
      );
    }
    return SizedBox(
      height: 185,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: recipes.length,
        itemBuilder: (context, i) =>
            _RecipeCard(recipe: recipes[i]),
      ),
    );
  }

  Widget _buildTipCard() {
    final tips = [
      'Reducir el sodio a menos de 2g/día ayuda a controlar la presión arterial.',
      'Combina alimentos ricos en hierro con vitamina C para mejor absorción.',
      'La quinoa es proteína completa — ideal para reemplazar la carne.',
      'Beber agua antes de comer reduce el apetito y mejora la digestión.',
    ];
    final tip = tips[DateTime.now().day % tips.length];
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2420),
        borderRadius: BorderRadius.circular(12),
        border: const Border(
            left: BorderSide(color: Color(0xFFF0A830), width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CONSEJO DEL DÍA',
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w600,
                  color: Color(0xFFF0A830), letterSpacing: 0.08)),
          const SizedBox(height: 4),
          Text(tip,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF8FA899), height: 1.5)),
        ],
      ),
    );
  }
}

// ── WIDGETS ───────────────────────────────────────────────────
class _ConditionPill extends StatelessWidget {
  final String label;
  const _ConditionPill(this.label);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A3D28),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2A6040), width: 0.5),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w500,
              color: Color(0xFFA8F0C6))),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final Map<String, dynamic> recipe;
  const _RecipeCard({required this.recipe});

  @override
  Widget build(BuildContext context) {
    final totalMin = (recipe['prepMin'] as int? ?? 0) +
        (recipe['cookMin'] as int? ?? 0);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RecipeDetailScreen(
            id: recipe['id'].toString(),
            recipe: recipe,
          ),
        ),
      ),
      child: Container(
        width: 158,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2420),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: const Color(0xFF253028), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 90,
              decoration: const BoxDecoration(
                color: Color(0xFF212E28),
                borderRadius: BorderRadius.vertical(
                    top: Radius.circular(14)),
              ),
              child: Center(
                child: Text(recipe['imageEmoji'] ?? '🍽️',
                    style: const TextStyle(fontSize: 38)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (recipe['mealType'] as String? ?? '')
                        .toUpperCase(),
                    style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3ECF7C),
                        letterSpacing: 0.08),
                  ),
                  const SizedBox(height: 3),
                  Text(recipe['title'] ?? '',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFE8F0EC)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(
                    '$totalMin min · ${recipe['kcal']?.toInt() ?? 0} kcal',
                    style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF566860)),
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

class _PlaceholderScreen extends StatelessWidget {
  final String name;
  const _PlaceholderScreen(this.name);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1412),
      body: Center(
        child: Text(name,
            style: const TextStyle(
                color: Color(0xFFE8F0EC), fontSize: 20)),
      ),
    );
  }
}