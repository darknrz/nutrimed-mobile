import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
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
      backgroundColor: AppColors.background,
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
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              _tabItem(0, Icons.home_rounded, Icons.home_outlined, 'Inicio'),
              _tabItem(1, Icons.menu_book_rounded, Icons.menu_book_outlined, 'Recetas'),
              _tabItem(2, Icons.chat_bubble_rounded, Icons.chat_bubble_outline_rounded, 'Chat'),
              _tabItem(3, Icons.person_rounded, Icons.person_outline_rounded, 'Perfil'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isActive = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : inactiveIcon,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            if (isActive)
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
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
  List<Map<String, dynamic>> _recipes = [];
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
      final userId = await storage.getUserId() ?? '0';
      final name = await storage.getName() ?? '';
      if (mounted) setState(() => _userName = name);

      final results = await Future.wait([
        sl<DioClient>().get('${ApiConstants.recommended}/$userId'),
        sl<DioClient>().get('${ApiConstants.onboarding}/$userId/needed'),
      ]);

      final recipesRes = results[0];
      final diseasesRes = await sl<DioClient>().get('${ApiConstants.userDiseases}/$userId');

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
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              if (_userDiseases.isNotEmpty) _buildHealthCard(),
              _buildSectionHeader('Desayunos recomendados', onTap: () {}),
              _buildRecipeScroll(_breakfastRecipes),
              _buildSectionHeader('Almuerzos recomendados', onTap: () {}),
              _buildRecipeScroll(_lunchRecipes),
              _buildTipCard(),
              _buildSectionHeader('Cenas recomendadas', onTap: () {}),
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
              Text(
                _getGreeting(),
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              Text(
                _userName.isNotEmpty ? _userName : 'Bienvenido',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () async {
              await sl<SecureStorage>().clearTokens();
              if (context.mounted) context.go('/login');
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
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
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MIS CONDICIONES',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                  letterSpacing: 0.1,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_userDiseases.length} activas',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _userDiseases.map((d) => _ConditionPill(d['name'] ?? '')).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: Text(
              'Ver todas',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeScroll(List<Map<String, dynamic>> recipes) {
    if (recipes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          'Sin recetas disponibles',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      );
    }
    return SizedBox(
      height: 185,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: recipes.length,
        itemBuilder: (context, i) => _RecipeCard(recipe: recipes[i]),
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: AppColors.warning, width: 3),
          top: BorderSide(color: AppColors.border, width: 0.5),
          right: BorderSide(color: AppColors.border, width: 0.5),
          bottom: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CONSEJO DEL DÍA',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.warning,
              letterSpacing: 0.08,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            tip,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
          ),
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
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final Map<String, dynamic> recipe;
  const _RecipeCard({required this.recipe});

  @override
  Widget build(BuildContext context) {
    final totalMin = (recipe['prepMin'] as int? ?? 0) + (recipe['cookMin'] as int? ?? 0);

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
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Center(
                child: Text(
                  recipe['imageEmoji'] ?? '🍽️',
                  style: const TextStyle(fontSize: 38),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (recipe['mealType'] as String? ?? '').toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                      letterSpacing: 0.08,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    recipe['title'] ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$totalMin min · ${recipe['kcal']?.toInt() ?? 0} kcal',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
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
      backgroundColor: AppColors.background,
      body: Center(
        child: Text(
          name,
          style: TextStyle(color: AppColors.textPrimary, fontSize: 20),
        ),
      ),
    );
  }
}