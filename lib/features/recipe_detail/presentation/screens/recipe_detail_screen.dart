import 'package:flutter/material.dart';

class RecipeDetailScreen extends StatelessWidget {
  final String id;
  final Map<String, dynamic>? recipe;

  const RecipeDetailScreen({
    super.key,
    required this.id,
    this.recipe,
  });

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
      case 'desayuno': return const Color(0xFF3ECF7C);
      case 'almuerzo': return const Color(0xFF38B4A0);
      case 'cena':     return const Color(0xFF8B5CF6);
      case 'snack':    return const Color(0xFFF0A830);
      case 'bebida':   return const Color(0xFF4285F4);
      default:         return const Color(0xFF3ECF7C);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (recipe == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F1412),
        body: Center(
          child: CircularProgressIndicator(
              color: Color(0xFF3ECF7C)),
        ),
      );
    }

    final mealType = recipe!['mealType'] as String? ?? '';
    final totalMin = (recipe!['prepMin'] as int? ?? 0) +
        (recipe!['cookMin'] as int? ?? 0);
    final kcal     = recipe!['kcal']?.toInt() ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1412),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, mealType),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTags(mealType),
                  const SizedBox(height: 12),
                  _buildTitle(),
                  const SizedBox(height: 8),
                  _buildDescription(),
                  const SizedBox(height: 20),
                  _buildMacros(kcal, totalMin),
                  const SizedBox(height: 20),
                  _buildCompatibility(),
                  const SizedBox(height: 20),
                  _buildNutritionDetail(),
                  const SizedBox(height: 20),
                  _buildTips(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, String mealType) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: const Color(0xFF0F1412),
      leading: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1412).withOpacity(0.8),
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
            color: const Color(0xFF0F1412).withOpacity(0.8),
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
            child: Text(
              recipe!['imageEmoji'] ?? '🍽️',
              style: const TextStyle(fontSize: 80),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTags(String mealType) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF1A4A30),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: const Color(0xFF3ECF7C), width: 0.5),
          ),
          child: const Text('✓ Apta para ti',
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600,
                  color: Color(0xFF3ECF7C))),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _getMealColor(mealType).withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(_getMealLabel(mealType),
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600,
                  color: _getMealColor(mealType))),
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return Text(
      recipe!['title'] ?? '',
      style: const TextStyle(
          fontSize: 22, fontWeight: FontWeight.w600,
          color: Color(0xFFE8F0EC), height: 1.2),
    );
  }

  Widget _buildDescription() {
    return Text(
      recipe!['description'] ?? '',
      style: const TextStyle(
          fontSize: 13, color: Color(0xFF8FA899), height: 1.6),
    );
  }

  Widget _buildMacros(int kcal, int totalMin) {
    return Row(
      children: [
        _macroCard('${kcal}', 'kcal', const Color(0xFFF0A830)),
        const SizedBox(width: 10),
        _macroCard('${recipe!['proteinG']?.toInt() ?? 0}g',
            'proteína', const Color(0xFF3ECF7C)),
        const SizedBox(width: 10),
        _macroCard('${recipe!['carbsG']?.toInt() ?? 0}g',
            'carbos', const Color(0xFF4285F4)),
        const SizedBox(width: 10),
        _macroCard('$totalMin', 'min', const Color(0xFF38B4A0)),
      ],
    );
  }

  Widget _macroCard(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2420),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: const Color(0xFF253028), width: 0.5),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600,
                    color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: Color(0xFF566860))),
          ],
        ),
      ),
    );
  }

  Widget _buildCompatibility() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Compatibilidad con tu perfil',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w500,
                color: Color(0xFFE8F0EC))),
        const SizedBox(height: 12),
        _compatRow('✓', 'Apta para tu perfil de salud',
            const Color(0xFF3ECF7C), const Color(0xFF1A4A30)),
        const SizedBox(height: 8),
        _compatRow('⚡', 'Rica en nutrientes esenciales',
            const Color(0xFF3ECF7C), const Color(0xFF1A4A30)),
        const SizedBox(height: 8),
        if ((recipe!['sodiumMg'] as double? ?? 0) < 300)
          _compatRow('✓', 'Bajo en sodio — buena para hipertensión',
              const Color(0xFF3ECF7C), const Color(0xFF1A4A30))
        else
          _compatRow('!', 'Moderado en sodio — controlar porción',
              const Color(0xFFF0A830), const Color(0xFF3D2A10)),
      ],
    );
  }

  Widget _compatRow(String icon, String text,
      Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(icon,
                  style: TextStyle(
                      fontSize: 11, color: color,
                      fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF8FA899))),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionDetail() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Información nutricional',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w500,
                color: Color(0xFFE8F0EC))),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2420),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: const Color(0xFF253028), width: 0.5),
          ),
          child: Column(
            children: [
              _nutritionRow('Calorías',
                  '${recipe!['kcal']?.toInt() ?? 0} kcal'),
              _nutritionDivider(),
              _nutritionRow('Proteínas',
                  '${recipe!['proteinG']?.toStringAsFixed(1) ?? 0} g'),
              _nutritionDivider(),
              _nutritionRow('Carbohidratos',
                  '${recipe!['carbsG']?.toStringAsFixed(1) ?? 0} g'),
              _nutritionDivider(),
              _nutritionRow('Grasas',
                  '${recipe!['fatG']?.toStringAsFixed(1) ?? 0} g'),
              _nutritionDivider(),
              _nutritionRow('Sodio',
                  '${recipe!['sodiumMg']?.toStringAsFixed(0) ?? 0} mg'),
              _nutritionDivider(),
              _nutritionRow('Tiempo total',
                  '${(recipe!['prepMin'] as int? ?? 0) + (recipe!['cookMin'] as int? ?? 0)} min'),
              _nutritionDivider(),
              _nutritionRow('Dificultad',
                  recipe!['difficulty'] ?? 'fácil'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _nutritionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF8FA899))),
          Text(value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500,
                  color: Color(0xFFE8F0EC))),
        ],
      ),
    );
  }

  Widget _nutritionDivider() => Divider(
      color: Colors.white.withOpacity(0.05), height: 1);

  Widget _buildTips() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2420),
        borderRadius: BorderRadius.circular(12),
        border: const Border(
            left: BorderSide(color: Color(0xFF3ECF7C), width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CONSEJO DE PREPARACIÓN',
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w600,
                  color: Color(0xFF3ECF7C), letterSpacing: 0.08)),
          const SizedBox(height: 6),
          Text(
            _getTip(),
            style: const TextStyle(
                fontSize: 12, color: Color(0xFF8FA899),
                height: 1.5),
          ),
        ],
      ),
    );
  }

  String _getTip() {
    final mealType = recipe!['mealType'] as String? ?? '';
    switch (mealType) {
      case 'desayuno':
        return 'Prepara los ingredientes la noche anterior para ahorrar tiempo en la mañana.';
      case 'almuerzo':
        return 'Puedes duplicar la porción y guardar el resto para la cena del día siguiente.';
      case 'cena':
        return 'Evita cenas pesadas después de las 8pm para mejorar la digestión nocturna.';
      default:
        return 'Conserva en refrigeración si no lo consumes inmediatamente.';
    }
  }
}