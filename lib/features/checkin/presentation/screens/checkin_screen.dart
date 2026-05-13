import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage.dart';

class CheckinScreen extends StatefulWidget {
  const CheckinScreen({super.key});
  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  int  _step    = 0;
  bool _loading = false;

  // Peso con picker Cupertino
  int?   _weightInt;   // parte entera  30–200
  int    _weightDec = 0; // decimal 0–9

  int    _wellbeing     = 3;
  String _activityLevel = 'moderado';
  String _healthGoal    = 'controlar_enfermedad';

  final List<Map<String, String>> _wellbeingOptions = [
    {'value': '1', 'emoji': '😞', 'label': 'Muy mal'},
    {'value': '2', 'emoji': '😕', 'label': 'Mal'},
    {'value': '3', 'emoji': '😐', 'label': 'Regular'},
    {'value': '4', 'emoji': '😊', 'label': 'Bien'},
    {'value': '5', 'emoji': '😄', 'label': 'Muy bien'},
  ];

  final List<Map<String, String>> _activityOptions = [
    {'value': 'sedentario', 'label': 'Sedentario',  'sub': 'Poco o ningún ejercicio'},
    {'value': 'moderado',   'label': 'Moderado',    'sub': 'Ejercicio 1-3 días/semana'},
    {'value': 'activo',     'label': 'Activo',      'sub': 'Ejercicio 4-5 días/semana'},
    {'value': 'muy_activo', 'label': 'Muy activo',  'sub': 'Ejercicio intenso diario'},
  ];

  final List<Map<String, String>> _goalOptions = [
    {'value': 'controlar_enfermedad', 'label': 'Controlar mi enfermedad', 'icon': '🏥'},
    {'value': 'perder_peso',          'label': 'Perder peso',             'icon': '⚖️'},
    {'value': 'ganar_musculo',        'label': 'Ganar masa muscular',     'icon': '💪'},
    {'value': 'comer_saludable',      'label': 'Comer más saludable',     'icon': '🥗'},
    {'value': 'mejorar_energia',      'label': 'Mejorar energía',         'icon': '⚡'},
  ];

  // ── PICKERS ───────────────────────────────────────────────
  void _showWeightPicker() {
    int tempInt = _weightInt ?? 70;
    int tempDec = _weightDec;

    final ints = List.generate(171, (i) => i + 30); // 30–200

    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 340,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(children: [
          _pickerHeader(
            onCancel: () => Navigator.pop(context),
            onDone: () {
              setState(() {
                _weightInt = tempInt;
                _weightDec = tempDec;
              });
              Navigator.pop(context);
            },
          ),
          Expanded(
            child: Row(children: [
              // Parte entera
              Expanded(
                flex: 3,
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(
                      initialItem: (tempInt - 30).clamp(0, 170)),
                  itemExtent: 44,
                  onSelectedItemChanged: (i) => tempInt = ints[i],
                  children: ints.map((v) => Center(
                    child: Text('$v',
                        style: const TextStyle(fontSize: 22, color: Colors.black)),
                  )).toList(),
                ),
              ),
              // Punto decimal (decorativo)
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text('.',
                    style: TextStyle(fontSize: 28,
                        fontWeight: FontWeight.w700, color: Colors.black)),
              ),
              // Decimal 0–9
              Expanded(
                flex: 2,
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(
                      initialItem: tempDec),
                  itemExtent: 44,
                  onSelectedItemChanged: (i) => tempDec = i,
                  children: List.generate(10, (i) => Center(
                    child: Text('$i',
                        style: const TextStyle(fontSize: 22, color: Colors.black)),
                  )),
                ),
              ),
              // Unidad
              const Padding(
                padding: EdgeInsets.only(right: 20, bottom: 4),
                child: Text(' kg',
                    style: TextStyle(fontSize: 18,
                        fontWeight: FontWeight.w600, color: Colors.black54)),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _pickerHeader({required VoidCallback onCancel, required VoidCallback onDone}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEBEBEB), width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: onCancel,
            child: const Text('Cancelar',
                style: TextStyle(fontSize: 16, color: Color(0xFF888888))),
          ),
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFDDDDDD),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          GestureDetector(
            onTap: onDone,
            child: Text('Listo',
                style: TextStyle(fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCheckin() async {
    setState(() => _loading = true);
    try {
      final userId = await sl<SecureStorage>().getUserId() ?? '0';
      final weight = _weightInt != null
          ? double.parse('$_weightInt.$_weightDec')
          : null;
      await sl<DioClient>().post('/checkin/$userId', {
        'weightKg':      weight,
        'wellbeing':     _wellbeing,
        'activityLevel': _activityLevel,
        'healthGoal':    _healthGoal,
      });
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Error al guardar. Intenta de nuevo.',
              style: TextStyle(color: Colors.white)),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _next() {
    if (_step < 2) setState(() => _step++);
    else           _saveCheckin();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildProgressBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: _buildStep(),
              ),
            ),
            _buildButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final titles = [
      '¿Cuánto pesas hoy?',
      '¿Cómo te sientes?',
      'Esta semana...',
    ];
    final subs = [
      'Actualizamos tus calorías recomendadas',
      'Tu bienestar general esta semana',
      'Confirma o actualiza tu actividad y objetivo',
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEEF1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFB3C1), width: 0.5),
              ),
              child: const Center(child: Text('📊', style: TextStyle(fontSize: 18))),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Check-in semanal  •  ${_step + 1}/3',
                    style: TextStyle(fontSize: 11, color: AppColors.primary,
                        fontWeight: FontWeight.w600)),
                Text(titles[_step],
                    style: const TextStyle(fontSize: 20,
                        fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              ],
            ),
          ]),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 48),
            child: Text(subs[_step],
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
      child: Row(
        children: List.generate(3, (i) => Expanded(
          child: Container(
            height: 3,
            margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
            decoration: BoxDecoration(
              color: i <= _step ? AppColors.primary : AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        )),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0: return _buildWeightStep();
      case 1: return _buildWellbeingStep();
      case 2: return _buildActivityGoalStep();
      default: return const SizedBox();
    }
  }

  // ── PASO 1: PESO ──────────────────────────────────────────
  Widget _buildWeightStep() {
    final hasValue  = _weightInt != null;
    final label     = hasValue ? '$_weightInt.$_weightDec kg' : 'Seleccionar peso';

    return Column(
      children: [
        const SizedBox(height: 24),
        const Text('⚖️', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 28),

        // Tile picker
        GestureDetector(
          onTap: _showWeightPicker,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasValue ? AppColors.primary : AppColors.border,
                width: hasValue ? 1.5 : 0.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.monitor_weight_outlined,
                    size: 22,
                    color: hasValue ? AppColors.primary : AppColors.textSecondary),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: hasValue ? 32 : 18,
                    fontWeight: hasValue ? FontWeight.w700 : FontWeight.w400,
                    color: hasValue ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
                if (!hasValue) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.textSecondary, size: 20),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),
        const Text(
          'Pésate en ayunas para mayor precisión',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),

        // Ajuste rápido +/- 0.5
        if (hasValue) ...[
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _quickAdjustBtn('-0.5', () {
                final current = _weightInt! + _weightDec / 10;
                final next    = (current - 0.5).clamp(30.0, 200.9);
                setState(() {
                  _weightInt = next.truncate();
                  _weightDec = ((next - next.truncate()) * 10).round();
                });
              }),
              const SizedBox(width: 16),
              _quickAdjustBtn('+0.5', () {
                final current = _weightInt! + _weightDec / 10;
                final next    = (current + 0.5).clamp(30.0, 200.9);
                setState(() {
                  _weightInt = next.truncate();
                  _weightDec = ((next - next.truncate()) * 10).round();
                });
              }),
            ],
          ),
        ],
      ],
    );
  }

  Widget _quickAdjustBtn(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Text(label,
            style: TextStyle(fontSize: 15,
                fontWeight: FontWeight.w600, color: AppColors.primary)),
      ),
    );
  }

  // ── PASO 2: BIENESTAR ─────────────────────────────────────
  Widget _buildWellbeingStep() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Text(_wellbeingOptions[_wellbeing - 1]['emoji']!,
            style: const TextStyle(fontSize: 72)),
        const SizedBox(height: 8),
        Text(_wellbeingOptions[_wellbeing - 1]['label']!,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        const SizedBox(height: 32),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: _wellbeingOptions.map((opt) {
            final val      = int.parse(opt['value']!);
            final isActive = _wellbeing == val;
            return GestureDetector(
              onTap: () => setState(() => _wellbeing = val),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFFFFEEF1)
                      : AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isActive ? AppColors.primary : AppColors.border,
                    width: isActive ? 2 : 0.5,
                  ),
                ),
                child: Text(opt['emoji']!,
                    style: TextStyle(fontSize: isActive ? 32 : 24)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border(
                left: BorderSide(color: AppColors.primary, width: 3)),
          ),
          child: const Text(
            'Considera tu energía, digestión y sueño durante esta semana.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
          ),
        ),
      ],
    );
  }

  // ── PASO 3: ACTIVIDAD Y OBJETIVO ─────────────────────────
  Widget _buildActivityGoalStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Nivel de actividad'),
        const SizedBox(height: 10),
        ..._activityOptions.map((a) {
          final selected = _activityLevel == a['value'];
          return GestureDetector(
            onTap: () => setState(() => _activityLevel = a['value']!),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: _itemDecor(selected),
              child: Row(children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a['label']!,
                        style: TextStyle(fontSize: 13,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                            color: AppColors.textPrimary)),
                    Text(a['sub']!,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                  ],
                )),
                if (selected)
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.primary, size: 18),
              ]),
            ),
          );
        }),

        const SizedBox(height: 20),
        _sectionLabel('Mi objetivo esta semana'),
        const SizedBox(height: 10),
        ..._goalOptions.map((g) {
          final selected = _healthGoal == g['value'];
          return GestureDetector(
            onTap: () => setState(() => _healthGoal = g['value']!),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: _itemDecor(selected),
              child: Row(children: [
                Text(g['icon']!, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 12),
                Expanded(child: Text(g['label']!,
                    style: TextStyle(fontSize: 13,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                        color: AppColors.textPrimary))),
                if (selected)
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.primary, size: 18),
              ]),
            ),
          );
        }),
      ],
    );
  }

  // ── BOTÓN INFERIOR ────────────────────────────────────────
  Widget _buildButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Row(children: [
        if (_step > 0) ...[
          GestureDetector(
            onTap: () => setState(() => _step--),
            child: Container(
              width: 48, height: 52,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: AppColors.textSecondary, size: 16),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: ElevatedButton(
            onPressed: _loading ? null : _next,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: _loading
                ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
                : Text(_step == 2 ? 'Guardar y continuar' : 'Continuar',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }

  // ── HELPERS ───────────────────────────────────────────────
  BoxDecoration _itemDecor(bool selected) => BoxDecoration(
    color: selected ? const Color(0xFFFFEEF1) : AppColors.surface,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: selected ? AppColors.primary : AppColors.border,
      width: selected ? 1.5 : 0.5,
    ),
  );

  Widget _sectionLabel(String text) => Text(text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
          color: AppColors.textSecondary));
}