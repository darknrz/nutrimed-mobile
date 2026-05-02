import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;
  bool _loading = false;

  // Paso 1 — País
  String _selectedCountry = 'PE';

  // Paso 2 — Condiciones
  List<Map<String, dynamic>> _diseases       = [];
  final Set<int>             _selectedDiseases = {};

  // Paso 3 — Datos físicos
  final _birthYearCtrl = TextEditingController();
  final _weightCtrl    = TextEditingController();
  final _heightCtrl    = TextEditingController();
  String _sex           = 'masculino';
  String _activityLevel = 'moderado';

  // Paso 4 — Objetivo
  String _healthGoal = 'controlar_enfermedad';

  final List<Map<String, String>> _countries = [
    {'code': 'PE', 'name': 'Perú',           'flag': '🇵🇪'},
    {'code': 'MX', 'name': 'México',          'flag': '🇲🇽'},
    {'code': 'CO', 'name': 'Colombia',        'flag': '🇨🇴'},
    {'code': 'AR', 'name': 'Argentina',       'flag': '🇦🇷'},
    {'code': 'CL', 'name': 'Chile',           'flag': '🇨🇱'},
    {'code': 'ES', 'name': 'España',          'flag': '🇪🇸'},
    {'code': 'BO', 'name': 'Bolivia',         'flag': '🇧🇴'},
    {'code': 'EC', 'name': 'Ecuador',         'flag': '🇪🇨'},
    {'code': 'VE', 'name': 'Venezuela',       'flag': '🇻🇪'},
    {'code': 'US', 'name': 'Estados Unidos',  'flag': '🇺🇸'},
  ];

  final List<Map<String, String>> _goals = [
    {'value': 'controlar_enfermedad', 'label': 'Controlar mi enfermedad', 'icon': '🏥'},
    {'value': 'perder_peso',          'label': 'Perder peso',             'icon': '⚖️'},
    {'value': 'ganar_musculo',        'label': 'Ganar masa muscular',     'icon': '💪'},
    {'value': 'comer_saludable',      'label': 'Comer más saludable',     'icon': '🥗'},
    {'value': 'mejorar_energia',      'label': 'Mejorar energía',         'icon': '⚡'},
  ];

  @override
  void initState() {
    super.initState();
    _loadDiseases();
  }

  Future<void> _loadDiseases() async {
    try {
      final res = await sl<DioClient>().get(ApiConstants.diseases);
      setState(() {
        _diseases = List<Map<String, dynamic>>.from(res.data);
      });
    } catch (e) {
      debugPrint('Error cargando enfermedades: $e');
    }
  }

  Future<void> _completeOnboarding() async {
    setState(() => _loading = true);
    try {
      final storage = sl<SecureStorage>();
      final userId  = await storage.getUserId();

      await sl<DioClient>().post(
        '${ApiConstants.onboarding}/$userId',
        {
          'countryCode':   _selectedCountry,
          'birthYear':     int.tryParse(_birthYearCtrl.text) ?? 1990,
          'sex':           _sex,
          'weightKg':      double.tryParse(_weightCtrl.text) ?? 70,
          'heightCm':      double.tryParse(_heightCtrl.text) ?? 165,
          'activityLevel': _activityLevel,
          'dietType':      'omnivoro',
          'healthGoal':    _healthGoal,
          'diseaseIds':    _selectedDiseases.toList(),
        },
      );

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
      content: Text(msg),
      backgroundColor: const Color(0xFFE85D4A),
    ));
  }

  void _next() {
    if (_step < 3) {
      setState(() => _step++);
    } else {
      _completeOnboarding();
    }
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  @override
  void dispose() {
    _birthYearCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1412),
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
            _buildBottomButtons(),
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
              if (_step > 0)
                GestureDetector(
                  onTap: _back,
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A2420),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0xFF2E3D36)),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new,
                        size: 14, color: Color(0xFF8FA899)),
                  ),
                ),
              if (_step > 0) const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Paso ${_step + 1} de 4',
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF3ECF7C),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.08),
                  ),
                  Text(
                    titles[_step],
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w600,
                        color: Color(0xFFE8F0EC)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(subs[_step],
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF8FA899))),
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
              color: i <= _step
                  ? const Color(0xFF3ECF7C)
                  : const Color(0xFF253028),
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

  // ── PASO 1: PAÍS ─────────────────────────────────────────
  Widget _buildCountryStep() {
    return Column(
      children: _countries.map((c) => GestureDetector(
        onTap: () => setState(() => _selectedCountry = c['code']!),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _selectedCountry == c['code']
                ? const Color(0xFF1A4A30)
                : const Color(0xFF1A2420),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _selectedCountry == c['code']
                  ? const Color(0xFF3ECF7C)
                  : const Color(0xFF253028),
              width: _selectedCountry == c['code'] ? 1.5 : 0.5,
            ),
          ),
          child: Row(
            children: [
              Text(c['flag']!, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 14),
              Text(c['name']!,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: _selectedCountry == c['code']
                        ? FontWeight.w600 : FontWeight.w400,
                    color: _selectedCountry == c['code']
                        ? const Color(0xFFE8F0EC)
                        : const Color(0xFF8FA899),
                  )),
              const Spacer(),
              if (_selectedCountry == c['code'])
                const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF3ECF7C), size: 20),
            ],
          ),
        ),
      )).toList(),
    );
  }

  // ── PASO 2: CONDICIONES ───────────────────────────────────
  Widget _buildDiseasesStep() {
    if (_diseases.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
            color: Color(0xFF3ECF7C)),
      );
    }
    return Column(
      children: [
        // Opción "Ninguna"
        GestureDetector(
          onTap: () => setState(() => _selectedDiseases.clear()),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _selectedDiseases.isEmpty
                  ? const Color(0xFF1A4A30)
                  : const Color(0xFF1A2420),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedDiseases.isEmpty
                    ? const Color(0xFF3ECF7C)
                    : const Color(0xFF253028),
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                const Text('✅', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 14),
                const Text('Ninguna por ahora',
                    style: TextStyle(fontSize: 15,
                        color: Color(0xFFE8F0EC))),
                const Spacer(),
                if (_selectedDiseases.isEmpty)
                  const Icon(Icons.check_circle_rounded,
                      color: Color(0xFF3ECF7C), size: 20),
              ],
            ),
          ),
        ),
        ..._diseases.map((d) {
          final id       = d['id'] as int;
          final selected = _selectedDiseases.contains(id);
          return GestureDetector(
            onTap: () => setState(() {
              if (selected) {
                _selectedDiseases.remove(id);
              } else {
                _selectedDiseases.add(id);
              }
            }),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF1A4A30)
                    : const Color(0xFF1A2420),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF3ECF7C)
                      : const Color(0xFF253028),
                  width: selected ? 1.5 : 0.5,
                ),
              ),
              child: Row(
                children: [
                  Text(d['iconCode'] ?? '🏥',
                      style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d['name'],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: selected
                                  ? const Color(0xFFE8F0EC)
                                  : const Color(0xFF8FA899),
                            )),
                      ],
                    ),
                  ),
                  if (selected)
                    const Icon(Icons.check_circle_rounded,
                        color: Color(0xFF3ECF7C), size: 20)
                  else
                    Container(
                      width: 20, height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFF566860)),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ── PASO 3: DATOS FÍSICOS ─────────────────────────────────
  Widget _buildPhysicalStep() {
    return Column(
      children: [
        // Sexo
        _sectionLabel('Sexo biológico'),
        Row(
          children: [
            _sexBtn('masculino', '👨', 'Masculino'),
            const SizedBox(width: 10),
            _sexBtn('femenino', '👩', 'Femenino'),
          ],
        ),
        const SizedBox(height: 20),

        // Año de nacimiento
        _sectionLabel('Año de nacimiento'),
        _inputField(_birthYearCtrl, 'Ej: 1990',
            TextInputType.number),
        const SizedBox(height: 20),

        // Peso y altura
        _sectionLabel('Peso y altura'),
        Row(
          children: [
            Expanded(child: _inputField(
                _weightCtrl, 'Peso (kg)',
                TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(child: _inputField(
                _heightCtrl, 'Altura (cm)',
                TextInputType.number)),
          ],
        ),
        const SizedBox(height: 20),

        // Nivel de actividad
        _sectionLabel('Nivel de actividad'),
        ...[
          {'value': 'sedentario', 'label': 'Sedentario',
            'sub': 'Poco o ningún ejercicio'},
          {'value': 'moderado',   'label': 'Moderado',
            'sub': 'Ejercicio 1-3 días/semana'},
          {'value': 'activo',     'label': 'Activo',
            'sub': 'Ejercicio 4-5 días/semana'},
          {'value': 'muy_activo', 'label': 'Muy activo',
            'sub': 'Ejercicio intenso diario'},
        ].map((a) => GestureDetector(
          onTap: () =>
              setState(() => _activityLevel = a['value']!),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _activityLevel == a['value']
                  ? const Color(0xFF1A4A30)
                  : const Color(0xFF1A2420),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _activityLevel == a['value']
                    ? const Color(0xFF3ECF7C)
                    : const Color(0xFF253028),
                width: _activityLevel == a['value'] ? 1.5 : 0.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a['label']!,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                            _activityLevel == a['value']
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: const Color(0xFFE8F0EC),
                          )),
                      Text(a['sub']!,
                          style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF8FA899))),
                    ],
                  ),
                ),
                if (_activityLevel == a['value'])
                  const Icon(Icons.check_circle_rounded,
                      color: Color(0xFF3ECF7C), size: 18),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Widget _sexBtn(String value, String emoji, String label) =>
      Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _sex = value),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: _sex == value
                  ? const Color(0xFF1A4A30)
                  : const Color(0xFF1A2420),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _sex == value
                    ? const Color(0xFF3ECF7C)
                    : const Color(0xFF253028),
                width: _sex == value ? 1.5 : 0.5,
              ),
            ),
            child: Column(
              children: [
                Text(emoji,
                    style: const TextStyle(fontSize: 28)),
                const SizedBox(height: 6),
                Text(label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: _sex == value
                          ? FontWeight.w600 : FontWeight.w400,
                      color: _sex == value
                          ? const Color(0xFFE8F0EC)
                          : const Color(0xFF8FA899),
                    )),
              ],
            ),
          ),
        ),
      );

  // ── PASO 4: OBJETIVO ──────────────────────────────────────
  Widget _buildGoalStep() {
    return Column(
      children: _goals.map((g) => GestureDetector(
        onTap: () => setState(() => _healthGoal = g['value']!),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: _healthGoal == g['value']
                ? const Color(0xFF1A4A30)
                : const Color(0xFF1A2420),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _healthGoal == g['value']
                  ? const Color(0xFF3ECF7C)
                  : const Color(0xFF253028),
              width: _healthGoal == g['value'] ? 1.5 : 0.5,
            ),
          ),
          child: Row(
            children: [
              Text(g['icon']!,
                  style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 14),
              Text(g['label']!,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: _healthGoal == g['value']
                        ? FontWeight.w600 : FontWeight.w400,
                    color: _healthGoal == g['value']
                        ? const Color(0xFFE8F0EC)
                        : const Color(0xFF8FA899),
                  )),
              const Spacer(),
              if (_healthGoal == g['value'])
                const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF3ECF7C), size: 20),
            ],
          ),
        ),
      )).toList(),
    );
  }

  // ── HELPERS ───────────────────────────────────────────────
  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text,
        style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w500,
            color: Color(0xFF8FA899))),
  );

  Widget _inputField(TextEditingController ctrl,
      String hint, TextInputType type) =>
      TextField(
        controller: ctrl,
        keyboardType: type,
        style: const TextStyle(
            color: Color(0xFFE8F0EC), fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
              color: Color(0xFF566860), fontSize: 13),
          filled: true,
          fillColor: const Color(0xFF1A2420),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
                color: Color(0xFF253028), width: 0.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
                color: Color(0xFF253028), width: 0.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
                color: Color(0xFF3ECF7C)),
          ),
          contentPadding: const EdgeInsets.symmetric(
              vertical: 12, horizontal: 14),
        ),
      );

  Widget _buildBottomButtons() {
    final isLast = _step == 3;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _loading ? null : _next,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3ECF7C),
            foregroundColor: const Color(0xFF0F1412),
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          child: _loading
              ? const SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF0F1412)))
              : Text(
            isLast ? 'Comenzar' : 'Continuar',
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}