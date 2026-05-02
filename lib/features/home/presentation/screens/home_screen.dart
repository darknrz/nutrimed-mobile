import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/storage/secure_storage.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    _HomeContent(),
    _PlaceholderScreen('Recetas'),
    _PlaceholderScreen('Chat'),
    _PlaceholderScreen('Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1412),
      body: _screens[_currentIndex],
      bottomNavigationBar: _buildTabBar(),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF161E1A),
        border: Border(
          top: BorderSide(color: Color(0xFF253028), width: 0.5),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              _tabItem(0, Icons.home_rounded, Icons.home_outlined, 'Inicio'),
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
            Icon(
              isActive ? activeIcon : inactiveIcon,
              color: isActive
                  ? const Color(0xFF3ECF7C)
                  : const Color(0xFF566860),
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight:
                isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive
                    ? const Color(0xFF3ECF7C)
                    : const Color(0xFF566860),
              ),
            ),
            const SizedBox(height: 2),
            if (isActive)
              Container(
                width: 4, height: 4,
                decoration: const BoxDecoration(
                  color: Color(0xFF3ECF7C),
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
class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            _buildHealthCard(),
            _buildSectionHeader('Recetas para hoy', onTap: () {}),
            _buildRecipeScroll(),
            _buildTipCard(),
            _buildSectionHeader('Más recomendadas', onTap: () {}),
            _buildRecipeGrid(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── HEADER ──
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Buenos días,',
                style: TextStyle(
                    fontSize: 12, color: Color(0xFF8FA899)),
              ),
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                      fontSize: 22, color: Color(0xFFE8F0EC)),
                  children: [
                    TextSpan(text: 'María '),
                    TextSpan(
                      text: 'López',
                      style: TextStyle(
                        color: Color(0xFF3ECF7C),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
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

  // ── TARJETA CONDICIONES ──
  Widget _buildHealthCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A4A30),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFF2DB868), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'MIS CONDICIONES',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFA8F0C6),
                  letterSpacing: 0.1,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF3ECF7C),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '3 activas',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F1412),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: const [
              _ConditionPill('Diabetes tipo 2'),
              _ConditionPill('Hipertensión'),
              _ConditionPill('Colesterol alto'),
            ],
          ),
        ],
      ),
    );
  }

  // ── SECTION HEADER ──
  Widget _buildSectionHeader(String title,
      {required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFE8F0EC))),
          GestureDetector(
            onTap: onTap,
            child: const Text('Ver todas',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF3ECF7C))),
          ),
        ],
      ),
    );
  }

  // ── SCROLL HORIZONTAL DE RECETAS ──
  Widget _buildRecipeScroll() {
    final recipes = [
      _RecipeData('🥗', 'Almuerzo', 'Ensalada mediterránea', '25 min', '320 kcal'),
      _RecipeData('🍲', 'Cena', 'Sopa de lentejas', '40 min', '280 kcal'),
      _RecipeData('🥑', 'Desayuno', 'Bowl de avena', '10 min', '240 kcal'),
      _RecipeData('🐟', 'Almuerzo', 'Salmón al limón', '30 min', '350 kcal'),
    ];

    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: recipes.length,
        itemBuilder: (context, i) => _RecipeCard(recipe: recipes[i]),
      ),
    );
  }

  // ── TARJETA CONSEJO ──
  Widget _buildTipCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2420),
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(color: Color(0xFFF0A830), width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'CONSEJO DEL DÍA',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFFF0A830),
              letterSpacing: 0.08,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Reducir el sodio a menos de 2g/día ayuda a controlar la presión arterial.',
            style: TextStyle(
                fontSize: 12,
                color: Color(0xFF8FA899),
                height: 1.5),
          ),
        ],
      ),
    );
  }

  // ── GRID DE RECETAS ──
  Widget _buildRecipeGrid() {
    final recipes = [
      _RecipeData('🥦', 'Cena', 'Wok de verduras', '20 min', '210 kcal'),
      _RecipeData('🫐', 'Snack', 'Smoothie antioxidante', '5 min', '180 kcal'),
      _RecipeData('🍳', 'Desayuno', 'Huevos revueltos', '15 min', '260 kcal'),
      _RecipeData('🫘', 'Almuerzo', 'Estofado de garbanzos', '45 min', '310 kcal'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.82,
        ),
        itemCount: recipes.length,
        itemBuilder: (context, i) =>
            _GridRecipeCard(recipe: recipes[i]),
      ),
    );
  }
}

// ── WIDGETS REUTILIZABLES ─────────────────────────────────────

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
      child: Text(
        label,
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Color(0xFFA8F0C6)),
      ),
    );
  }
}

class _RecipeData {
  final String emoji, tag, name, time, kcal;
  const _RecipeData(
      this.emoji, this.tag, this.name, this.time, this.kcal);
}

class _RecipeCard extends StatelessWidget {
  final _RecipeData recipe;
  const _RecipeCard({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 155,
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
              child: Text(recipe.emoji,
                  style: const TextStyle(fontSize: 36)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe.tag.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3ECF7C),
                    letterSpacing: 0.08,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  recipe.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFE8F0EC),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${recipe.time} · ${recipe.kcal}',
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF566860)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GridRecipeCard extends StatelessWidget {
  final _RecipeData recipe;
  const _GridRecipeCard({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            height: 100,
            decoration: const BoxDecoration(
              color: Color(0xFF212E28),
              borderRadius: BorderRadius.vertical(
                  top: Radius.circular(14)),
            ),
            child: Center(
              child: Text(recipe.emoji,
                  style: const TextStyle(fontSize: 40)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe.tag.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF38B4A0),
                    letterSpacing: 0.08,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  recipe.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFE8F0EC),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(recipe.time,
                        style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF566860))),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A3D28),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '✓ Apta',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFA8F0C6),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── PLACEHOLDER para las otras tabs ──────────────────────────
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