import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int  _step    = 0;
  bool _loading = false;

  String             _selectedCountry  = 'PE';
  List<Map<String, dynamic>> _diseases = [];
  final Set<int>     _selectedDiseases = {};

  // Paso 3 — valores con picker
  int?   _birthYear;
  int?   _weightKg;
  int?   _heightCm;
  String _sex           = 'masculino';
  String _activityLevel = 'moderado';

  // Paso 4
  String _healthGoal = 'controlar_enfermedad';

  final List<Map<String, String>> _countries = [
    {'code': 'PE', 'name': 'Perú',          'flag': '🇵🇪'},
    {'code': 'MX', 'name': 'México',         'flag': '🇲🇽'},
    {'code': 'CO', 'name': 'Colombia',       'flag': '🇨🇴'},
    {'code': 'AR', 'name': 'Argentina',      'flag': '🇦🇷'},
    {'code': 'CL', 'name': 'Chile',          'flag': '🇨🇱'},
    {'code': 'ES', 'name': 'España',         'flag': '🇪🇸'},
    {'code': 'BO', 'name': 'Bolivia',        'flag': '🇧🇴'},
    {'code': 'EC', 'name': 'Ecuador',        'flag': '🇪🇨'},
    {'code': 'VE', 'name': 'Venezuela',      'flag': '🇻🇪'},
    {'code': 'US', 'name': 'Estados Unidos', 'flag': '🇺🇸'},
  ];

  final List<Map<String, String>> _goals = [
    {'value': 'controlar_enfermedad', 'label': 'Controlar mi enfermedad', 'icon': '🏥'},
    {'value': 'perder_peso',          'label': 'Perder peso',             'icon': '⚖️'},
    {'value': 'ganar_musculo',        'label': 'Ganar masa muscular',     'icon': '💪'},
    {'value': 'comer_saludable',      'label': 'Comer más saludable',     'icon': '🥗'},
    {'value': 'mejorar_energia',      'label': 'Mejorar energía',         'icon': '⚡'},
  ];

  @override
  void initState() { super.initState(); _loadDiseases(); }

  Future<void> _loadDiseases() async {
    try {
      final res = await sl<DioClient>().get(ApiConstants.diseases);
      setState(() => _diseases = List<Map<String, dynamic>>.from(res.data));
    } catch (e) { debugPrint('Error cargando enfermedades: $e'); }
  }

  Future<void> _completeOnboarding() async {
    setState(() => _loading = true);
    try {
      final storage = sl<SecureStorage>();
      final userId  = await storage.getUserId();
      await sl<DioClient>().post('${ApiConstants.onboarding}/$userId', {
        'countryCode':   _selectedCountry,
        'birthYear':     _birthYear     ?? 1990,
        'sex':           _sex,
        'weightKg':      _weightKg      ?? 70,
        'heightCm':      _heightCm      ?? 165,
        'activityLevel': _activityLevel,
        'dietType':      'omnivoro',
        'healthGoal':    _healthGoal,
        'diseaseIds':    _selectedDiseases.toList(),
      });
      await storage.setNeedsOnboarding(false);
      if (mounted) context.go('/home');
    } catch (e) {
      _showError('Error al guardar perfil: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: AppColors.error,
    ));
  }

  void _next() { if (_step < 3) setState(() => _step++); else _completeOnboarding(); }
  void _back() { if (_step > 0) setState(() => _step--); }

  // ── PICKERS ───────────────────────────────────────────────
  void _showYearPicker() {
    final now      = DateTime.now().year;
    int   tempYear = _birthYear ?? 1995;
    final years    = List.generate(83, (i) => now - 10 - i);

    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 320,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(children: [
          _pickerHeader(
            onCancel: () => Navigator.pop(context),
            onDone:   () { setState(() => _birthYear = tempYear); Navigator.pop(context); },
          ),
          Expanded(
            child: CupertinoPicker(
              scrollController: FixedExtentScrollController(
                  initialItem: years.indexOf(tempYear).clamp(0, years.length - 1)),
              itemExtent: 40,
              onSelectedItemChanged: (i) => tempYear = years[i],
              children: years.map((y) => Center(
                child: Text('$y', style: const TextStyle(fontSize: 18, color: Colors.black)),
              )).toList(),
            ),
          ),
        ]),
      ),
    );
  }

  void _showWeightPicker() {
    int   tempWeight = _weightKg ?? 70;
    final weights    = List.generate(171, (i) => i + 30);

    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 320,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(children: [
          _pickerHeader(
            onCancel: () => Navigator.pop(context),
            onDone:   () { setState(() => _weightKg = tempWeight); Navigator.pop(context); },
          ),
          Expanded(
            child: CupertinoPicker(
              scrollController: FixedExtentScrollController(
                  initialItem: (tempWeight - 30).clamp(0, 170)),
              itemExtent: 40,
              onSelectedItemChanged: (i) => tempWeight = weights[i],
              children: weights.map((w) => Center(
                child: Text('$w kg', style: const TextStyle(fontSize: 18, color: Colors.black)),
              )).toList(),
            ),
          ),
        ]),
      ),
    );
  }

  void _showHeightPicker() {
    int   tempHeight = _heightCm ?? 165;
    final heights    = List.generate(121, (i) => i + 120);

    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 320,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(children: [
          _pickerHeader(
            onCancel: () => Navigator.pop(context),
            onDone:   () { setState(() => _heightCm = tempHeight); Navigator.pop(context); },
          ),
          Expanded(
            child: CupertinoPicker(
              scrollController: FixedExtentScrollController(
                  initialItem: (tempHeight - 120).clamp(0, 120)),
              itemExtent: 40,
              onSelectedItemChanged: (i) => tempHeight = heights[i],
              children: heights.map((h) => Center(
                child: Text('$h cm', style: const TextStyle(fontSize: 18, color: Colors.black)),
              )).toList(),
            ),
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

  // ── BUILD ─────────────────────────────────────────────────
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
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: _buildCurrentStep(),
              ),
            ),
            _buildBottomButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final titles = [
      '¿Dónde estás?',
      '¿Tienes alguna condición?',
      'Tu perfil físico',
      '¿Cuál es tu objetivo?',
    ];
    final subs = [
      'Selecciona tu país para recetas locales',
      'Selecciona todas las que apliquen',
      'Esto personaliza tus calorías recomendadas',
      'Define cómo priorizamos tus recetas',
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (_step > 0) ...[
                GestureDetector(
                  onTap: _back,
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new,
                        size: 14, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Paso ${_step + 1} de 4',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.primary,
                          fontWeight: FontWeight.w600, letterSpacing: 0.08)),
                  Text(titles[_step],
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(subs[_step],
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: List.generate(4, (i) => Expanded(
          child: Container(
            height: 3,
            margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
            decoration: BoxDecoration(
              color: i <= _step ? AppColors.primary : AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        )),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case 0: return _buildCountryStep();
      case 1: return _buildDiseasesStep();
      case 2: return _buildPhysicalStep();
      case 3: return _buildGoalStep();
      default: return const SizedBox();
    }
  }

  // ── PASO 1: PAÍS ──────────────────────────────────────────
  Widget _buildCountryStep() {
    return Column(
      children: _countries.map((c) {
        final selected = _selectedCountry == c['code'];
        return GestureDetector(
          onTap: () => setState(() => _selectedCountry = c['code']!),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: _itemDecor(selected),
            child: Row(children: [
              Text(c['flag']!, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 14),
              Text(c['name']!,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                  )),
              const Spacer(),
              if (selected)
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.primary, size: 20),
            ]),
          ),
        );
      }).toList(),
    );
  }

  // ── PASO 2: CONDICIONES ───────────────────────────────────
  Widget _buildDiseasesStep() {
    if (_diseases.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _selectedDiseases.clear()),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: _itemDecor(_selectedDiseases.isEmpty),
            child: Row(children: [
              const Text('✅', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 14),
              const Text('Ninguna por ahora',
                  style: TextStyle(fontSize: 15, color: AppColors.textPrimary)),
              const Spacer(),
              if (_selectedDiseases.isEmpty)
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.primary, size: 20),
            ]),
          ),
        ),
        ..._diseases.map((d) {
          final id       = d['id'] as int;
          final selected = _selectedDiseases.contains(id);
          return GestureDetector(
            onTap: () => setState(() {
              if (selected) _selectedDiseases.remove(id);
              else          _selectedDiseases.add(id);
            }),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: _itemDecor(selected),
              child: Row(children: [
                Text(d['iconCode'] ?? '🏥', style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(d['name'],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                        color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                      )),
                ),
                if (selected)
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.primary, size: 20)
                else
                  Container(
                    width: 20, height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border),
                    ),
                  ),
              ]),
            ),
          );
        }),
      ],
    );
  }

  // ── PASO 3: DATOS FÍSICOS ─────────────────────────────────
  Widget _buildPhysicalStep() {
    final activities = [
      {'value': 'sedentario', 'label': 'Sedentario', 'sub': 'Poco o ningún ejercicio'},
      {'value': 'moderado',   'label': 'Moderado',   'sub': 'Ejercicio 1-3 días/semana'},
      {'value': 'activo',     'label': 'Activo',     'sub': 'Ejercicio 4-5 días/semana'},
      {'value': 'muy_activo', 'label': 'Muy activo', 'sub': 'Ejercicio intenso diario'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Sexo biológico'),
        Row(children: [
          _sexBtn('masculino', '👨', 'Masculino'),
          const SizedBox(width: 10),
          _sexBtn('femenino',  '👩', 'Femenino'),
        ]),
        const SizedBox(height: 24),

        _sectionLabel('Año de nacimiento'),
        _pickerTile(
          icon:  Icons.cake_outlined,
          label: _birthYear != null ? '$_birthYear' : 'Seleccionar año',
          onTap: _showYearPicker,
        ),
        const SizedBox(height: 16),

        _sectionLabel('Peso'),
        _pickerTile(
          icon:  Icons.monitor_weight_outlined,
          label: _weightKg != null ? '$_weightKg kg' : 'Seleccionar peso',
          onTap: _showWeightPicker,
        ),
        const SizedBox(height: 16),

        _sectionLabel('Altura'),
        _pickerTile(
          icon:  Icons.straighten_outlined,
          label: _heightCm != null ? '$_heightCm cm' : 'Seleccionar altura',
          onTap: _showHeightPicker,
        ),
        const SizedBox(height: 24),

        _sectionLabel('Nivel de actividad'),
        ...activities.map((a) {
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
                        style: TextStyle(fontSize: 14,
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
      ],
    );
  }

  Widget _pickerTile({required IconData icon, required String label,
    required VoidCallback onTap}) {
    final hasValue = !label.contains('Seleccionar');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasValue ? AppColors.primary : AppColors.border,
            width: hasValue ? 1.5 : 0.5,
          ),
        ),
        child: Row(children: [
          Icon(icon, size: 20,
              color: hasValue ? AppColors.primary : AppColors.textSecondary),
          const SizedBox(width: 12),
          Text(label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                color: hasValue ? AppColors.textPrimary : AppColors.textSecondary,
              )),
          const Spacer(),
          const Icon(Icons.chevron_right_rounded,
              size: 20, color: AppColors.textSecondary),
        ]),
      ),
    );
  }

  Widget _sexBtn(String value, String emoji, String label) => Expanded(
    child: GestureDetector(
      onTap: () => setState(() => _sex = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: _itemDecor(_sex == value),
        child: Column(children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(fontSize: 13,
                  fontWeight: _sex == value ? FontWeight.w600 : FontWeight.w400,
                  color: _sex == value
                      ? AppColors.textPrimary : AppColors.textSecondary)),
        ]),
      ),
    ),
  );

  // ── PASO 4: OBJETIVO ──────────────────────────────────────
  Widget _buildGoalStep() {
    return Column(
      children: _goals.map((g) {
        final selected = _healthGoal == g['value'];
        return GestureDetector(
          onTap: () => setState(() => _healthGoal = g['value']!),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: _itemDecor(selected),
            child: Row(children: [
              Text(g['icon']!, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 14),
              Text(g['label']!,
                  style: TextStyle(fontSize: 15,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected
                          ? AppColors.textPrimary : AppColors.textSecondary)),
              const Spacer(),
              if (selected)
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.primary, size: 20),
            ]),
          ),
        );
      }).toList(),
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

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
            color: AppColors.textSecondary)),
  );

  Widget _buildBottomButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: SizedBox(
        width: double.infinity,
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
              : Text(_step == 3 ? 'Comenzar' : 'Continuar',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}