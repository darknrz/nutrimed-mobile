import 'package:flutter/material.dart';

class RecipeDetailScreen extends StatefulWidget {
  final String id;
  final Map<String, dynamic>? recipe;

  const RecipeDetailScreen({
    super.key,
    required this.id,
    this.recipe,
  });

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  int _tabIndex  = 0;
  int _porciones = 1;

  final List<Map<String, dynamic>> _tabs = [
    {'label': 'Información', 'icon': '📋'},
    {'label': 'Ingredientes', 'icon': '🥦'},
    {'label': 'Preparación',  'icon': '👨‍🍳'},
    {'label': 'Apta para ti', 'icon': '🛡️'},
  ];

  @override
  void initState() {
    super.initState();
    // Inicializar porciones con el valor base de la receta
    final base = (widget.recipe?['servings'] as int?) ?? 1;
    _porciones = base;
  }

  Color _getMealColor(String type) {
    switch (type) {
      case 'desayuno': return const Color(0xFF3ECF7C);
      case 'almuerzo': return const Color(0xFF38B4A0);
      case 'cena':     return const Color(0xFF8B5CF6);
      case 'snack':    return const Color(0xFFF0A830);
      case 'bebida':   return const Color(0xFF4285F4);
      default:         return const Color(0xFF3ECF7C);
    }
  }

  String _getMealLabel(String type) {
    const labels = {
      'desayuno': 'Desayuno', 'almuerzo': 'Almuerzo',
      'cena': 'Cena', 'snack': 'Snack', 'bebida': 'Bebida',
    };
    return labels[type] ?? type;
  }

  int get _baseServings => (widget.recipe!['servings'] as int?) ?? 1;
  double get _factor    => _porciones / _baseServings;

  @override
  Widget build(BuildContext context) {
    if (widget.recipe == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F1412),
        body: Center(child: CircularProgressIndicator(
            color: Color(0xFF3ECF7C))),
      );
    }

    final mealType = widget.recipe!['mealType'] as String? ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF0F1412),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, mealType),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título y descripción
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.recipe!['title'] ?? '',
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFE8F0EC),
                              height: 1.2)),
                      const SizedBox(height: 6),
                      Text(widget.recipe!['description'] ?? '',
                          style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF8FA899),
                              height: 1.6)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Selector de porciones
                _buildPortionSelector(),
                const SizedBox(height: 20),

                // Tabs
                _buildTabs(),
                const SizedBox(height: 20),

                // Contenido del tab
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildTabContent(mealType),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── APP BAR ──────────────────────────────────────────────
  Widget _buildAppBar(BuildContext context, String mealType) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: const Color(0xFF0F1412),
      leading: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1412).withOpacity(0.85),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_ios_new,
              size: 16, color: Color(0xFFE8F0EC)),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1412).withOpacity(0.85),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.favorite_border_rounded,
                color: Color(0xFF3ECF7C), size: 20),
            onPressed: () {},
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: const Color(0xFF1A2420),
          child: Center(
            child: Text(widget.recipe!['imageEmoji'] ?? '🍽️',
                style: const TextStyle(fontSize: 80)),
          ),
        ),
      ),
    );
  }

  // ── SELECTOR DE PORCIONES ─────────────────────────────────
  Widget _buildPortionSelector() {
    final isModified = _porciones != _baseServings;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2420),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isModified
                ? const Color(0xFF3ECF7C)
                : const Color(0xFF253028),
            width: isModified ? 1.0 : 0.5,
          ),
        ),
        child: Row(
          children: [
            const Text('👥', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Porciones',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFE8F0EC))),
                  if (isModified)
                    Text(
                      'Base: $_baseServings — escala: ${_factor.toStringAsFixed(1)}x',
                      style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF3ECF7C)),
                    ),
                ],
              ),
            ),

            // Botón −
            GestureDetector(
              onTap: _porciones > 1
                  ? () => setState(() => _porciones--)
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: _porciones > 1
                      ? const Color(0xFF1A4A30)
                      : const Color(0xFF253028),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _porciones > 1
                        ? const Color(0xFF3ECF7C)
                        : const Color(0xFF3E5045),
                    width: 0.5,
                  ),
                ),
                child: Center(
                  child: Icon(Icons.remove,
                      size: 16,
                      color: _porciones > 1
                          ? const Color(0xFF3ECF7C)
                          : const Color(0xFF566860)),
                ),
              ),
            ),

            // Número
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('$_porciones',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF3ECF7C))),
            ),

            // Botón +
            GestureDetector(
              onTap: _porciones < 20
                  ? () => setState(() => _porciones++)
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A4A30),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: const Color(0xFF3ECF7C), width: 0.5),
                ),
                child: const Center(
                  child: Icon(Icons.add,
                      size: 16, color: Color(0xFF3ECF7C)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── TABS ──────────────────────────────────────────────────
  Widget _buildTabs() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _tabs.length,
        itemBuilder: (context, i) {
          final isActive = _tabIndex == i;
          return GestureDetector(
            onTap: () => setState(() => _tabIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF1A4A30)
                    : const Color(0xFF1A2420),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isActive
                      ? const Color(0xFF3ECF7C)
                      : const Color(0xFF253028),
                  width: isActive ? 1.5 : 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_tabs[i]['icon']!,
                      style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 6),
                  Text(_tabs[i]['label']!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isActive
                            ? FontWeight.w600 : FontWeight.w400,
                        color: isActive
                            ? const Color(0xFF3ECF7C)
                            : const Color(0xFF8FA899),
                      )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── CONTENIDO POR TAB ─────────────────────────────────────
  Widget _buildTabContent(String mealType) {
    switch (_tabIndex) {
      case 0: return _buildInfoTab(mealType);
      case 1: return _buildIngredientsTab();
      case 2: return _buildStepsTab();
      case 3: return _buildCompatTab();
      default: return const SizedBox();
    }
  }

  // ── TAB 1: INFORMACIÓN ───────────────────────────────────
  Widget _buildInfoTab(String mealType) {
    final prepMin = (widget.recipe!['prepMin'] as int?) ?? 0;
    final cookMin = (widget.recipe!['cookMin'] as int?) ?? 0;

    // Cocción escala con las porciones, prep no
    final cookScaled  = (cookMin * _factor).round();
    final totalScaled = prepMin + cookScaled;

    final mealColor = _getMealColor(mealType);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2420),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFF253028), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: mealColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(_getMealLabel(mealType),
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: mealColor)),
          ),
          const SizedBox(height: 14),

          _infoRow('⚡', 'Calorías',
              '${((widget.recipe!['kcal'] as double? ?? 0) * _factor).toStringAsFixed(0)} kcal'),
          _infoRow('💪', 'Proteína',
              '${((widget.recipe!['proteinG'] as double? ?? 0) * _factor).toStringAsFixed(1)}g'),
          _infoRow('🌾', 'Carbohidratos',
              '${((widget.recipe!['carbsG'] as double? ?? 0) * _factor).toStringAsFixed(1)}g'),
          _infoRow('🥑', 'Grasas',
              '${((widget.recipe!['fatG'] as double? ?? 0) * _factor).toStringAsFixed(1)}g'),
          _infoRow('🫀', 'Sodio',
              '${((widget.recipe!['sodiumMg'] as double? ?? 0) * _factor).toStringAsFixed(0)}mg'),
          _infoRow('🌿', 'Fibra',
              '${((widget.recipe!['fiberG'] as double? ?? 0) * _factor).toStringAsFixed(1)}g'),

          const Divider(color: Color(0xFF253028), height: 24),

          _infoRow('⏱️', 'Preparación', '$prepMin min'),
          _infoRow('🍳', 'Cocción',     '$cookScaled min'),
          _infoRow('⏰', 'Tiempo total', '$totalScaled min'),
          _infoRow('👨‍🍳', 'Dificultad',
              widget.recipe!['difficulty'] ?? 'fácil'),
          _infoRow('🍽️', 'Porciones', '$_porciones porción(es)'),
        ],
      ),
    );
  }

  Widget _infoRow(String emoji, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF8FA899))),
          ),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE8F0EC))),
        ],
      ),
    );
  }

  // ── TAB 2: INGREDIENTES ───────────────────────────────────
  Widget _buildIngredientsTab() {
    final ingredients =
        widget.recipe!['ingredients'] as List<dynamic>? ?? [];

    if (ingredients.isEmpty) {
      return _emptyState('🥦', 'Sin ingredientes registrados');
    }

    final isModified = _porciones != _baseServings;

    return Column(
      children: [
        // Banner de escala cuando hay cambio
        if (isModified)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A4A30),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: const Color(0xFF3ECF7C), width: 0.5),
            ),
            child: Row(
              children: [
                const Text('⚖️',
                    style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Text(
                  'Cantidades ajustadas para $_porciones porción(es)',
                  style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF3ECF7C),
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

        ...ingredients.map((ing) {
          final name = ing is Map
              ? (ing['name'] ??
              ing['ingredientName'] ??
              ing.toString())
              : ing.toString();
          final qty  = ing is Map ? ing['quantityG'] : null;
          final prep = ing is Map ? ing['preparation'] : null;

          final qtyScaled = qty != null
              ? (qty as num).toDouble() * _factor
              : null;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2420),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFF253028), width: 0.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A4A30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text('🥗',
                        style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name.toString(),
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFFE8F0EC))),
                      if (prep != null &&
                          prep.toString().isNotEmpty)
                        Text(prep.toString(),
                            style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF566860))),
                    ],
                  ),
                ),
                if (qtyScaled != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isModified
                          ? const Color(0xFF1A4A30)
                          : const Color(0xFF253028),
                      borderRadius: BorderRadius.circular(8),
                      border: isModified
                          ? Border.all(
                          color: const Color(0xFF3ECF7C),
                          width: 0.5)
                          : null,
                    ),
                    child: Text(
                      qtyScaled == qtyScaled.roundToDouble()
                          ? '${qtyScaled.toInt()}g'
                          : '${qtyScaled.toStringAsFixed(1)}g',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3ECF7C)),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ── TAB 3: PREPARACIÓN ───────────────────────────────────
  Widget _buildStepsTab() {
    final steps =
    List<String>.from(widget.recipe!['steps'] ?? []);

    if (steps.isEmpty) {
      return _emptyState(
          '👨‍🍳', 'Sin pasos de preparación registrados');
    }

    return Column(
      children: steps.asMap().entries.map((entry) {
        final index  = entry.key;
        final step   = entry.value;
        final isLast = index == steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A4A30),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: const Color(0xFF3ECF7C),
                        width: 1.5),
                  ),
                  child: Center(
                    child: Text('${index + 1}',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF3ECF7C))),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 1.5, height: 44,
                    color: const Color(0xFF253028),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                    bottom: isLast ? 0 : 28, top: 6),
                child: Text(step,
                    style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF8FA899),
                        height: 1.6)),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  // ── TAB 4: APTA PARA TI ───────────────────────────────────
  Widget _buildCompatTab() {
    // Valores escalados para el análisis
    final sodium  = ((widget.recipe!['sodiumMg']  as double?) ?? 0) * _factor;
    final kcal    = ((widget.recipe!['kcal']       as double?) ?? 0) * _factor;
    final fiber   = ((widget.recipe!['fiberG']     as double?) ?? 0) * _factor;
    final protein = ((widget.recipe!['proteinG']   as double?) ?? 0) * _factor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2420),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFF253028), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🛡️',
                  style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              const Text('Análisis nutricional',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE8F0EC))),
              const Spacer(),
              if (_porciones != _baseServings)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A4A30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$_porciones porciones',
                    style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF3ECF7C),
                        fontWeight: FontWeight.w500),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          _compatItem('✓', 'Receta saludable',
              'Ingredientes naturales sin ultra-procesados',
              const Color(0xFF3ECF7C)),

          _compatItem('✓', 'Sin ultraprocesados',
              'Preparación con ingredientes frescos',
              const Color(0xFF3ECF7C)),

          if (sodium < 300)
            _compatItem('✓', 'Bajo en sodio',
                '${sodium.toStringAsFixed(0)}mg — recomendado para hipertensión',
                const Color(0xFF3ECF7C))
          else
            _compatItem('!', 'Sodio moderado',
                '${sodium.toStringAsFixed(0)}mg — consumir con precaución',
                const Color(0xFFF0A830)),

          if (kcal < 300)
            _compatItem('✓', 'Bajo en calorías',
                '${kcal.toInt()} kcal — ideal para control de peso',
                const Color(0xFF3ECF7C))
          else if (kcal < 450)
            _compatItem('~', 'Calorías moderadas',
                '${kcal.toInt()} kcal — parte de dieta balanceada',
                const Color(0xFFF0A830))
          else
            _compatItem('!', 'Alta energía',
                '${kcal.toInt()} kcal — moderar la porción',
                const Color(0xFFE85D4A)),

          if (fiber >= 3)
            _compatItem('✓', 'Rico en fibra',
                '${fiber.toStringAsFixed(1)}g — bueno para glucosa y digestión',
                const Color(0xFF3ECF7C)),

          if (protein >= 15)
            _compatItem('✓', 'Alto en proteína',
                '${protein.toStringAsFixed(1)}g — apoya masa muscular',
                const Color(0xFF3ECF7C)),
        ],
      ),
    );
  }

  Widget _compatItem(String icon, String title,
      String subtitle, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: color.withOpacity(0.25), width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22, height: 22,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(icon,
                  style: TextStyle(
                      fontSize: 10,
                      color: color,
                      fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: color)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF8FA899),
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── ESTADO VACÍO ──────────────────────────────────────────
  Widget _emptyState(String emoji, String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Text(emoji,
                style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(text,
                style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF566860))),
          ],
        ),
      ),
    );
  }
}