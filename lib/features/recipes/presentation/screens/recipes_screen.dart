import 'package:flutter/material.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../recipe_detail/presentation/screens/recipe_detail_screen.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});
  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  List<Map<String, dynamic>> _allRecipes      = [];
  List<Map<String, dynamic>> _filteredRecipes = [];
  bool   _loading        = true;
  String _selectedFilter = 'todos';
  String _searchQuery    = '';

  final _searchCtrl = TextEditingController();

  final List<Map<String, String>> _filters = [
    {'value': 'todos',    'label': 'Todas',    'icon': '🍽️'},
    {'value': 'desayuno', 'label': 'Desayuno', 'icon': '🌅'},
    {'value': 'almuerzo', 'label': 'Almuerzo', 'icon': '☀️'},
    {'value': 'cena',     'label': 'Cena',     'icon': '🌙'},
    {'value': 'snack',    'label': 'Snack',    'icon': '🍎'},
    {'value': 'bebida',   'label': 'Bebidas',  'icon': '🥤'},
  ];

  @override
  void initState() { super.initState(); _loadRecipes(); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _loadRecipes() async {
    try {
      final storage = sl<SecureStorage>();
      final userId  = await storage.getUserId() ?? '0';
      final res     = await sl<DioClient>().get('${ApiConstants.recommended}/$userId');
      if (mounted) setState(() {
        _allRecipes = _filteredRecipes = List<Map<String, dynamic>>.from(res.data);
        _loading = false;
      });
    } catch (e) {
      try {
        final res = await sl<DioClient>().get(ApiConstants.recipes);
        if (mounted) setState(() {
          _allRecipes = _filteredRecipes = List<Map<String, dynamic>>.from(res.data);
          _loading = false;
        });
      } catch (_) {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredRecipes = _allRecipes.where((r) {
        final matchFilter = _selectedFilter == 'todos' || r['mealType'] == _selectedFilter;
        final matchSearch = _searchQuery.isEmpty ||
            (r['title'] as String).toLowerCase().contains(_searchQuery.toLowerCase());
        return matchFilter && matchSearch;
      }).toList();
    });
  }

  void _onFilterTap(String filter) { _selectedFilter = filter; _applyFilters(); }
  void _onSearch(String query)     { _searchQuery    = query;  _applyFilters(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildFilterChips(),
            _buildResultCount(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _filteredRecipes.isEmpty
                  ? _buildEmpty()
                  : _buildGrid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Text('Recetas',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: TextField(
          controller: _searchCtrl,
          onChanged: _onSearch,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Buscar recetas o ingredientes…',
            hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? GestureDetector(
              onTap: () { _searchCtrl.clear(); _onSearch(''); },
              child: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 18),
            )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
        itemCount: _filters.length,
        itemBuilder: (context, i) {
          final f        = _filters[i];
          final isActive = _selectedFilter == f['value'];
          return GestureDetector(
            onTap: () => _onFilterTap(f['value']!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFFFFEEF1) : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? AppColors.primary : AppColors.border,
                  width: isActive ? 1.5 : 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(f['icon']!, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 5),
                  Text(f['label']!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                        color: isActive ? AppColors.primary : AppColors.textSecondary,
                      )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultCount() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
      child: Row(
        children: [
          Text('${_filteredRecipes.length} recetas encontradas',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return RefreshIndicator(
      onRefresh: _loadRecipes,
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.78,
        ),
        itemCount: _filteredRecipes.length,
        itemBuilder: (context, i) => _RecipeGridCard(recipe: _filteredRecipes[i]),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🔍', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          const Text('No encontramos recetas',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Prueba con otro término de búsqueda'
                : 'No hay recetas para este filtro',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () { _searchCtrl.clear(); _onSearch(''); },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEEF1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary, width: 0.5),
                ),
                child: const Text('Limpiar búsqueda',
                    style: TextStyle(fontSize: 13, color: AppColors.primary,
                        fontWeight: FontWeight.w500)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── TARJETA GRID ──────────────────────────────────────────────
class _RecipeGridCard extends StatelessWidget {
  final Map<String, dynamic> recipe;
  const _RecipeGridCard({required this.recipe});

  String _getMealLabel(String type) {
    switch (type) {
      case 'desayuno': return 'Desayuno';
      case 'almuerzo': return 'Almuerzo';
      case 'cena':     return 'Cena';
      case 'snack':    return 'Snack';
      case 'bebida':   return 'Bebida';
      default:         return type;
    }
  }

  Color _getMealColor(String type) {
    switch (type) {
      case 'desayuno': return const Color(0xFFFE2C55);
      case 'almuerzo': return const Color(0xFF25F4EE);
      case 'cena':     return const Color(0xFF8B5CF6);
      case 'snack':    return const Color(0xFFF0A830);
      case 'bebida':   return const Color(0xFF4285F4);
      default:         return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mealType = recipe['mealType'] as String? ?? '';
    final totalMin = (recipe['prepMin'] as int? ?? 0) + (recipe['cookMin'] as int? ?? 0);
    final kcal     = recipe['kcal']?.toInt() ?? 0;
    final color    = _getMealColor(mealType);

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => RecipeDetailScreen(id: recipe['id'].toString(), recipe: recipe),
      )),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // imagen
            Container(
              height: 110,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Stack(
                children: [
                  Center(child: Text(recipe['imageEmoji'] ?? '🍽️',
                      style: const TextStyle(fontSize: 44))),
                  Positioned(
                    top: 8, right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F8EF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF3ECF7C), width: 0.5),
                      ),
                      child: const Text('✓ Apta',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600,
                              color: Color(0xFF1A7A45))),
                    ),
                  ),
                ],
              ),
            ),
            // info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(_getMealLabel(mealType),
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600,
                            color: color, letterSpacing: 0.06)),
                  ),
                  const SizedBox(height: 5),
                  Text(recipe['title'] ?? '',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary, height: 1.3),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        const Icon(Icons.timer_outlined, size: 11, color: AppColors.textSecondary),
                        const SizedBox(width: 3),
                        Text('$totalMin min',
                            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      ]),
                      Text('$kcal kcal',
                          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                    ],
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