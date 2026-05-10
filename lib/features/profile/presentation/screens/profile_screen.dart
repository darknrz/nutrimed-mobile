import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage.dart';

// ── MODELOS ───────────────────────────────────────────────────
class _Disease {
  final int    id;
  final String name;
  final String iconCode;
  _Disease({required this.id, required this.name, required this.iconCode});
  factory _Disease.fromJson(Map<String, dynamic> j) => _Disease(
    id:       j['id'],
    name:     j['name'] ?? '',
    iconCode: j['iconCode'] ?? '🏥',
  );
}

class _Profile {
  final int    id;
  final String name;
  final String email;
  final String? picture;
  final String? sex;
  final int?    birthYear;
  final double? weightKg;
  final double? heightCm;
  final String? activityLevel;
  final String? healthGoal;
  final List<_Disease> diseases;

  _Profile({
    required this.id,    required this.name,
    required this.email, this.picture,
    this.sex,            this.birthYear,
    this.weightKg,       this.heightCm,
    this.activityLevel,  this.healthGoal,
    required this.diseases,
  });

  factory _Profile.fromJson(Map<String, dynamic> j) => _Profile(
    id:            j['id'],
    name:          j['name']          ?? '',
    email:         j['email']         ?? '',
    picture:       j['picture'],
    sex:           j['sex'],
    birthYear:     j['birthYear'],
    weightKg:      (j['weightKg']  as num?)?.toDouble(),
    heightCm:      (j['heightCm']  as num?)?.toDouble(),
    activityLevel: j['activityLevel'],
    healthGoal:    j['healthGoal'],
    diseases: (j['diseases'] as List<dynamic>? ?? [])
        .map((d) => _Disease.fromJson(d as Map<String, dynamic>))
        .toList(),
  );
}

// ── SCREEN ────────────────────────────────────────────────────
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  _Profile?       _profile;
  List<_Disease>  _allDiseases    = [];
  bool            _loading        = true;
  bool            _saving         = false;
  bool            _editMode       = false;
  bool            _uploadingPhoto = false;

  late TextEditingController _nameCtrl;

  // Pickers numéricos (reemplazan controllers de texto)
  int?   _editBirthYear;
  int?   _editWeightKg;
  int?   _editHeightCm;

  String  _sex           = 'masculino';
  String  _activityLevel = 'moderado';
  String  _healthGoal    = 'controlar_enfermedad';
  final Set<int> _selectedDiseases = {};

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _loadData();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final userId = await sl<SecureStorage>().getUserId();
      final results = await Future.wait([
        sl<DioClient>().get('/users/$userId/profile'),
        sl<DioClient>().get(ApiConstants.diseases),
      ]);
      final profile  = _Profile.fromJson(results[0].data as Map<String, dynamic>);
      final diseases = (results[1].data as List<dynamic>)
          .map((d) => _Disease.fromJson(d as Map<String, dynamic>))
          .toList();
      setState(() {
        _profile     = profile;
        _allDiseases = diseases;
        _loading     = false;
        _populateEditors(profile);
      });
    } catch (e) {
      setState(() => _loading = false);
      _showSnack('Error al cargar perfil');
    }
  }

  void _populateEditors(_Profile p) {
    _nameCtrl.text  = p.name;
    _editBirthYear  = p.birthYear;
    _editWeightKg   = p.weightKg?.toInt();
    _editHeightCm   = p.heightCm?.toInt();
    _sex            = p.sex           ?? 'masculino';
    _activityLevel  = p.activityLevel ?? 'moderado';
    _healthGoal     = p.healthGoal    ?? 'controlar_enfermedad';
    _selectedDiseases..clear()..addAll(p.diseases.map((d) => d.id));
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    try {
      final userId = await sl<SecureStorage>().getUserId();
      final res = await sl<DioClient>().put('/users/$userId/profile', {
        'name':          _nameCtrl.text.trim(),
        'birthYear':     _editBirthYear,
        'sex':           _sex,
        'weightKg':      _editWeightKg,
        'heightCm':      _editHeightCm,
        'activityLevel': _activityLevel,
        'healthGoal':    _healthGoal,
        'diseaseIds':    _selectedDiseases.toList(),
      });
      setState(() {
        _profile  = _Profile.fromJson(res.data as Map<String, dynamic>);
        _editMode = false;
        _saving   = false;
      });
      _showSnack('Perfil actualizado ✓', success: true);
    } catch (e) {
      setState(() => _saving = false);
      _showSnack('Error al guardar');
    }
  }

  Future<void> _logout() async {
    await sl<SecureStorage>().clearTokens();
    if (mounted) context.go('/login');
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512, maxHeight: 512, imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _uploadingPhoto = true);
    try {
      final userId       = await sl<SecureStorage>().getUserId();
      final signatureRes = await sl<DioClient>().get('/users/$userId/upload-signature');
      final sigData      = signatureRes.data;

      final formData = FormData.fromMap({
        'file':      await MultipartFile.fromFile(picked.path, filename: picked.name),
        'api_key':   sigData['api_key'],
        'timestamp': sigData['timestamp'],
        'signature': sigData['signature'],
        'folder':    sigData['folder'],
      });

      final cloudRes = await Dio().post(
        'https://api.cloudinary.com/v1_1/${sigData['cloud_name']}/image/upload',
        data: formData,
      );
      final pictureUrl = cloudRes.data['secure_url'] as String;
      await sl<DioClient>().patch('/users/$userId/picture', {'pictureUrl': pictureUrl});

      if (!mounted) return;
      setState(() {
        _profile = _Profile(
          id: _profile!.id, name: _profile!.name, email: _profile!.email,
          picture: pictureUrl, sex: _profile!.sex, birthYear: _profile!.birthYear,
          weightKg: _profile!.weightKg, heightCm: _profile!.heightCm,
          activityLevel: _profile!.activityLevel, healthGoal: _profile!.healthGoal,
          diseases: _profile!.diseases,
        );
      });
      _showSnack('Foto actualizada ✓', success: true);
    } catch (e) {
      _showSnack('Error al subir foto');
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  void _showSnack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: success ? const Color(0xFF22C55E) : AppColors.error,
    ));
  }

  // ── PICKERS ───────────────────────────────────────────────
  void _showYearPicker() {
    final now      = DateTime.now().year;
    int   tempYear = _editBirthYear ?? 1990;
    final years    = List.generate(83, (i) => now - 10 - i);

    showCupertinoModalPopup(
      context: context,
      builder: (_) => _pickerSheet(
        onCancel: () => Navigator.pop(context),
        onDone:   () { setState(() => _editBirthYear = tempYear); Navigator.pop(context); },
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
    );
  }

  void _showWeightPicker() {
    int   tempWeight = _editWeightKg ?? 70;
    final weights    = List.generate(171, (i) => i + 30);

    showCupertinoModalPopup(
      context: context,
      builder: (_) => _pickerSheet(
        onCancel: () => Navigator.pop(context),
        onDone:   () { setState(() => _editWeightKg = tempWeight); Navigator.pop(context); },
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
    );
  }

  void _showHeightPicker() {
    int   tempHeight = _editHeightCm ?? 165;
    final heights    = List.generate(121, (i) => i + 120);

    showCupertinoModalPopup(
      context: context,
      builder: (_) => _pickerSheet(
        onCancel: () => Navigator.pop(context),
        onDone:   () { setState(() => _editHeightCm = tempHeight); Navigator.pop(context); },
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
    );
  }

  Widget _pickerSheet({
    required VoidCallback onCancel,
    required VoidCallback onDone,
    required Widget child,
  }) {
    return Container(
      height: 320,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(children: [
        Container(
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
        ),
        Expanded(child: child),
      ]),
    );
  }

  // ── BUILD ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  children: [
                    _buildAvatar(),
                    const SizedBox(height: 20),
                    if (_editMode) ...[
                      _buildEditForm(),
                    ] else ...[
                      _buildInfoSection(),
                      const SizedBox(height: 16),
                      _buildDiseasesSection(),
                      const SizedBox(height: 16),
                      _buildPhysicalSection(),
                      const SizedBox(height: 16),
                      _buildGoalSection(),
                      const SizedBox(height: 24),
                      _buildLogoutButton(),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Mi Perfil',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          GestureDetector(
            onTap: () {
              if (_editMode) {
                setState(() {
                  _editMode = false;
                  if (_profile != null) _populateEditors(_profile!);
                });
              } else {
                setState(() => _editMode = true);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: _editMode ? const Color(0xFFF0F0F0) : const Color(0xFFFFEEF1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _editMode ? AppColors.border : AppColors.primary,
                  width: 0.5,
                ),
              ),
              child: Text(
                _editMode ? 'Cancelar' : 'Editar',
                style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500,
                  color: _editMode ? AppColors.textSecondary : AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final initials = (_profile?.name.isNotEmpty == true)
        ? _profile!.name.trim().split(' ')
        .map((p) => p.isNotEmpty ? p[0] : '')
        .take(2).join().toUpperCase()
        : '?';

    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 88, height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFEEF1),
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: ClipOval(
                child: _uploadingPhoto
                    ? const Center(child: CircularProgressIndicator(
                    color: AppColors.primary, strokeWidth: 2))
                    : (_profile?.picture != null && _profile!.picture!.isNotEmpty)
                    ? CachedNetworkImage(
                  imageUrl: _profile!.picture!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary, strokeWidth: 2)),
                  errorWidget: (_, __, ___) => Center(
                    child: Text(initials,
                        style: const TextStyle(fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                  ),
                )
                    : Center(child: Text(initials,
                    style: const TextStyle(fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary))),
              ),
            ),
            Positioned(
              bottom: 0, right: 0,
              child: GestureDetector(
                onTap: _uploadingPhoto ? null : _pickAndUploadPhoto,
                child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      size: 14, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(_profile?.name ?? '',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        const SizedBox(height: 2),
        Text(_profile?.email ?? '',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      ],
    );
  }

  // ── VISTA INFO ────────────────────────────────────────────
  Widget _buildInfoSection() {
    return _card(title: 'INFORMACIÓN', icon: '👤', children: [
      _infoRow('Nombre',   _profile?.name ?? '-'),
      _infoRow('Sexo',     _sexLabel(_profile?.sex)),
      _infoRow('Año nac.', _profile?.birthYear?.toString() ?? '-'),
    ]);
  }

  Widget _buildPhysicalSection() {
    final w = _profile?.weightKg;
    final h = _profile?.heightCm;
    String imc = '-';
    if (w != null && h != null && h > 0) {
      final hm = h / 100;
      imc = '${(w / (hm * hm)).toStringAsFixed(1)} kg/m²';
    }
    return _card(title: 'DATOS FÍSICOS', icon: '📊', children: [
      _infoRow('Peso',      w != null ? '${w.toStringAsFixed(1)} kg' : '-'),
      _infoRow('Altura',    h != null ? '${h.toStringAsFixed(0)} cm' : '-'),
      _infoRow('IMC',       imc),
      _infoRow('Actividad', _activityLabel(_profile?.activityLevel)),
    ]);
  }

  Widget _buildDiseasesSection() {
    final diseases = _profile?.diseases ?? [];
    return _card(title: 'MIS CONDICIONES', icon: '🏥', children: [
      if (diseases.isEmpty)
        const Text('Sin condiciones registradas',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary))
      else
        Wrap(
          spacing: 6, runSpacing: 6,
          children: diseases.map((d) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEEF1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFB3C1), width: 0.5),
            ),
            child: Text('${d.iconCode} ${d.name}',
                style: const TextStyle(fontSize: 12, color: Color(0xFFAA1530))),
          )).toList(),
        ),
    ]);
  }

  Widget _buildGoalSection() {
    return _card(title: 'OBJETIVO', icon: '🎯', children: [
      _infoRow('Meta', _goalLabel(_profile?.healthGoal)),
    ]);
  }

  // ── FORMULARIO EDICIÓN ────────────────────────────────────
  Widget _buildEditForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _formLabel('Nombre completo'),
        _inputField(_nameCtrl, 'Tu nombre'),
        const SizedBox(height: 20),

        _formLabel('Sexo biológico'),
        Row(children: [
          _sexBtn('masculino', '👨', 'Masculino'),
          const SizedBox(width: 10),
          _sexBtn('femenino',  '👩', 'Femenino'),
        ]),
        const SizedBox(height: 20),

        _formLabel('Año de nacimiento'),
        _pickerTile(
          icon:  Icons.cake_outlined,
          label: _editBirthYear != null ? '$_editBirthYear' : 'Seleccionar año',
          onTap: _showYearPicker,
        ),
        const SizedBox(height: 16),

        _formLabel('Peso'),
        _pickerTile(
          icon:  Icons.monitor_weight_outlined,
          label: _editWeightKg != null ? '$_editWeightKg kg' : 'Seleccionar peso',
          onTap: _showWeightPicker,
        ),
        const SizedBox(height: 16),

        _formLabel('Altura'),
        _pickerTile(
          icon:  Icons.straighten_outlined,
          label: _editHeightCm != null ? '$_editHeightCm cm' : 'Seleccionar altura',
          onTap: _showHeightPicker,
        ),
        const SizedBox(height: 20),

        _formLabel('Nivel de actividad'),
        ..._activityOptions(),
        const SizedBox(height: 16),

        _formLabel('Mi objetivo'),
        ..._goalOptions(),
        const SizedBox(height: 16),

        _formLabel('Mis condiciones'),
        _buildDiseasePicker(),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saving ? null : _saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: _saving
                ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
                : const Text('Guardar cambios',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
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

  Widget _buildDiseasePicker() {
    return Column(
      children: [
        _diseaseOption(
          id: -1, icon: '✅', name: 'Ninguna',
          selected: _selectedDiseases.isEmpty,
          onTap: () => setState(() => _selectedDiseases.clear()),
        ),
        ..._allDiseases.map((d) => _diseaseOption(
          id: d.id, icon: d.iconCode, name: d.name,
          selected: _selectedDiseases.contains(d.id),
          onTap: () => setState(() {
            if (_selectedDiseases.contains(d.id)) _selectedDiseases.remove(d.id);
            else _selectedDiseases.add(d.id);
          }),
        )),
      ],
    );
  }

  List<Widget> _activityOptions() {
    final options = [
      {'value': 'sedentario', 'label': 'Sedentario', 'sub': 'Poco o ningún ejercicio'},
      {'value': 'moderado',   'label': 'Moderado',   'sub': 'Ejercicio 1-3 días/semana'},
      {'value': 'activo',     'label': 'Activo',     'sub': 'Ejercicio 4-5 días/semana'},
      {'value': 'muy_activo', 'label': 'Muy activo', 'sub': 'Ejercicio intenso diario'},
    ];
    return options.map((a) => GestureDetector(
      onTap: () => setState(() => _activityLevel = a['value']!),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: _selectionDecor(_activityLevel == a['value']),
        child: Row(children: [
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(a['label']!,
                  style: TextStyle(fontSize: 14,
                      fontWeight: _activityLevel == a['value']
                          ? FontWeight.w600 : FontWeight.w400,
                      color: AppColors.textPrimary)),
              Text(a['sub']!,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          )),
          if (_activityLevel == a['value'])
            const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18),
        ]),
      ),
    )).toList();
  }

  List<Widget> _goalOptions() {
    final goals = [
      {'value': 'controlar_enfermedad', 'label': 'Controlar mi enfermedad', 'icon': '🏥'},
      {'value': 'perder_peso',          'label': 'Perder peso',             'icon': '⚖️'},
      {'value': 'ganar_musculo',        'label': 'Ganar masa muscular',     'icon': '💪'},
      {'value': 'comer_saludable',      'label': 'Comer más saludable',     'icon': '🥗'},
      {'value': 'mejorar_energia',      'label': 'Mejorar energía',         'icon': '⚡'},
    ];
    return goals.map((g) => GestureDetector(
      onTap: () => setState(() => _healthGoal = g['value']!),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: _selectionDecor(_healthGoal == g['value']),
        child: Row(children: [
          Text(g['icon']!, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Text(g['label']!,
              style: TextStyle(fontSize: 14,
                  fontWeight: _healthGoal == g['value']
                      ? FontWeight.w600 : FontWeight.w400,
                  color: AppColors.textPrimary)),
          const Spacer(),
          if (_healthGoal == g['value'])
            const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18),
        ]),
      ),
    )).toList();
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Cerrar sesión',
              style: TextStyle(color: AppColors.textPrimary)),
          content: const Text('¿Estás seguro que deseas salir?',
              style: TextStyle(color: AppColors.textSecondary)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () { Navigator.pop(context); _logout(); },
              child: Text('Salir', style: TextStyle(color: AppColors.error)),
            ),
          ],
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0EE),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error, width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: AppColors.error, size: 18),
            const SizedBox(width: 8),
            Text('Cerrar sesión',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
                    color: AppColors.error)),
          ],
        ),
      ),
    );
  }

  // ── HELPERS ───────────────────────────────────────────────
  Widget _card({required String title, required String icon,
    required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(title,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                    color: AppColors.primary, letterSpacing: 0.08)),
          ]),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          Text(value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _formLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
            color: AppColors.textSecondary)),
  );

  Widget _inputField(TextEditingController ctrl, String hint,
      [TextInputType type = TextInputType.text]) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border, width: 0.5)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border, width: 0.5)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary)),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      ),
    );
  }

  Widget _sexBtn(String value, String emoji, String label) => Expanded(
    child: GestureDetector(
      onTap: () => setState(() => _sex = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: _selectionDecor(_sex == value),
        child: Column(children: [
          Text(emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(fontSize: 13,
                  fontWeight: _sex == value ? FontWeight.w600 : FontWeight.w400,
                  color: _sex == value
                      ? AppColors.textPrimary : AppColors.textSecondary)),
        ]),
      ),
    ),
  );

  Widget _diseaseOption({required int id, required String icon,
    required String name, required bool selected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: _selectionDecor(selected),
        child: Row(children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(child: Text(name,
              style: TextStyle(fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? AppColors.textPrimary : AppColors.textSecondary))),
          selected
              ? const Icon(Icons.check_circle_rounded,
              color: AppColors.primary, size: 18)
              : Container(
              width: 18, height: 18,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border))),
        ]),
      ),
    );
  }

  BoxDecoration _selectionDecor(bool selected) => BoxDecoration(
    color: selected ? const Color(0xFFFFEEF1) : AppColors.surface,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
        color: selected ? AppColors.primary : AppColors.border,
        width: selected ? 1.5 : 0.5),
  );

  String _sexLabel(String? sex) {
    if (sex == 'masculino') return 'Masculino';
    if (sex == 'femenino')  return 'Femenino';
    return '-';
  }

  String _activityLabel(String? a) {
    const m = {'sedentario': 'Sedentario', 'moderado': 'Moderado',
      'activo': 'Activo', 'muy_activo': 'Muy activo'};
    return m[a] ?? '-';
  }

  String _goalLabel(String? g) {
    const m = {
      'controlar_enfermedad': 'Controlar mi enfermedad',
      'perder_peso':          'Perder peso',
      'ganar_musculo':        'Ganar masa muscular',
      'comer_saludable':      'Comer más saludable',
      'mejorar_energia':      'Mejorar energía',
    };
    return m[g] ?? '-';
  }
}