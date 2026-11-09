import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';

import '../core/logger/app_logger.dart';
import '../features/exercises/domain/entities/equipment.dart';
import '../features/exercises/domain/entities/exercise_entity.dart';
import '../core/units/app_weight_unit_controller.dart';
import '../features/exercises/domain/entities/load_type.dart';
import '../features/exercises/domain/entities/muscle_group.dart';
import '../features/exercises/presentation/cubit/exercises_cubit.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/gym_labels.dart';
import '../widgets/stored_image.dart';
import '../widgets/section_header.dart';

/// Creates or edits an exercise. Pops with the saved exercise id.
class ExerciseEditorPage extends StatefulWidget {
  const ExerciseEditorPage({super.key, this.exerciseId});

  final String? exerciseId;

  @override
  State<ExerciseEditorPage> createState() => _ExerciseEditorPageState();
}

class _ExerciseEditorPageState extends State<ExerciseEditorPage> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  late final TextEditingController _name;
  late final TextEditingController _notes;
  late Equipment _equipment;
  late LoadType _loadType;
  late WeightUnit _weightUnit;

  /// Until the user picks a load type, it follows the equipment.
  late bool _loadTypeTouched;
  late List<MuscleGroup> _primary;
  late List<MuscleGroup> _secondary;
  late List<String> _images;

  /// Images copied in during this edit; removed again if the edit is discarded.
  final _imported = <String>{};
  bool _saved = false;
  bool _saving = false;
  ExerciseEntity? _existing;
  late final ExercisesCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<ExercisesCubit>();
    _existing = widget.exerciseId == null
        ? null
        : _cubit.state.byId(widget.exerciseId!);
    _name = TextEditingController(text: _existing?.name ?? '');
    _notes = TextEditingController(text: _existing?.notes ?? '');
    _equipment = _existing?.equipment ?? Equipment.dumbbell;
    _loadType = _existing?.loadType ?? LoadType.defaultFor(_equipment);
    _weightUnit = _existing?.weightUnit ?? WeightUnit.lb;
    _loadTypeTouched = _existing != null;
    _primary = [...?_existing?.primaryMuscles];
    _secondary = [...?_existing?.secondaryMuscles];
    _images = [...?_existing?.imagePaths];
  }

  @override
  void dispose() {
    if (!_saved) {
      for (final name in _imported) {
        _cubit.discardImage(name);
      }
    }
    _name.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    final l10n = AppLocalizations.of(context)!;
    final cubit = _cubit;
    try {
      final files = source == ImageSource.camera
          ? [
              ?await _picker.pickImage(
                source: source,
                maxWidth: 1600,
                imageQuality: 85,
              ),
            ]
          : await _picker.pickMultiImage(maxWidth: 1600, imageQuality: 85);
      for (final f in files) {
        final name = await cubit.importImage(f.path);
        if (name == null) {
          if (mounted) showSnack(context, l10n.imageImportFailed);
          continue;
        }
        _imported.add(name);
        if (mounted) setState(() => _images.add(name));
      }
    } catch (e, s) {
      AppLogger.error('image pick failed', e, s);
      if (mounted) showSnack(context, l10n.imageImportFailed);
    }
  }

  void _removeImage(String name) {
    setState(() => _images.remove(name));
    if (_imported.remove(name)) _cubit.discardImage(name);
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    if (_primary.isEmpty) {
      showSnack(context, l10n.primaryMusclesRequired);
      return;
    }
    setState(() => _saving = true);
    final saved = await _cubit.save(
      id: _existing?.id,
      name: _name.text,
      primaryMuscles: _primary,
      secondaryMuscles: _secondary,
      equipment: _equipment,
      loadType: _loadType,
      weightUnit: _weightUnit,
      notes: _notes.text,
      imagePaths: _images,
    );
    if (!mounted) return;
    if (saved == null) {
      setState(() => _saving = false);
      showSnack(context, l10n.saveFailed);
      return;
    }
    _saved = true;
    context.pop(saved.id);
  }

  Widget _muscleChips(
    AppLocalizations l10n,
    List<MuscleGroup> selected,
    List<MuscleGroup> disabled,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final m in MuscleGroup.values)
          FilterChip(
            label: Text(muscleLabel(l10n, m)),
            selected: selected.contains(m),
            onSelected: disabled.contains(m)
                ? null
                : (v) => setState(() {
                    v ? selected.add(m) : selected.remove(m);
                  }),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final isNew = _existing == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? l10n.newExercise : l10n.editExercise),
        actions: [
          TextButton(onPressed: _saving ? null : _save, child: Text(l10n.save)),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            TextFormField(
              controller: _name,
              autofocus: isNew,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.exerciseNameLabel,
                hintText: l10n.exerciseNameHint,
                border: const OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l10n.fieldRequired : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Equipment>(
              initialValue: _equipment,
              decoration: InputDecoration(
                labelText: l10n.equipment,
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final e in Equipment.values)
                  DropdownMenuItem(
                    value: e,
                    child: Text(equipmentLabel(l10n, e)),
                  ),
              ],
              onChanged: (v) => setState(() {
                _equipment = v ?? _equipment;
                if (!_loadTypeTouched) {
                  _loadType = LoadType.defaultFor(_equipment);
                }
              }),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.loadTypeLabel,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            SegmentedButton<_LoadChoice>(
              segments: [
                ButtonSegment(
                  value: _LoadChoice.lb,
                  icon: const Icon(Icons.scale_outlined),
                  label: Text(l10n.settingsWeightUnitLb),
                ),
                ButtonSegment(
                  value: _LoadChoice.kg,
                  icon: const Icon(Icons.scale_outlined),
                  label: Text(l10n.settingsWeightUnitKg),
                ),
                ButtonSegment(
                  value: _LoadChoice.discs,
                  icon: const Icon(Icons.view_agenda_outlined),
                  label: Text(l10n.loadTypeDiscs),
                ),
              ],
              selected: {
                _loadType == LoadType.discs
                    ? _LoadChoice.discs
                    : _weightUnit == WeightUnit.kg
                    ? _LoadChoice.kg
                    : _LoadChoice.lb,
              },
              onSelectionChanged: (s) => setState(() {
                _loadTypeTouched = true;
                switch (s.first) {
                  case _LoadChoice.lb:
                    _loadType = LoadType.weight;
                    _weightUnit = WeightUnit.lb;
                  case _LoadChoice.kg:
                    _loadType = LoadType.weight;
                    _weightUnit = WeightUnit.kg;
                  case _LoadChoice.discs:
                    _loadType = LoadType.discs;
                }
              }),
            ),
            const SizedBox(height: 4),
            Text(
              _loadType == LoadType.discs
                  ? l10n.loadTypeDiscsHint
                  : l10n.loadTypeWeightHint,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            SectionHeader(
              l10n.primaryMuscles,
              padding: const EdgeInsets.fromLTRB(0, 20, 0, 4),
            ),
            Text(
              l10n.primaryMusclesHint,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            _muscleChips(l10n, _primary, _secondary),
            SectionHeader(
              l10n.secondaryMuscles,
              padding: const EdgeInsets.fromLTRB(0, 20, 0, 4),
            ),
            Text(
              l10n.secondaryMusclesHint,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            _muscleChips(l10n, _secondary, _primary),
            SectionHeader(
              l10n.referenceImages,
              padding: const EdgeInsets.fromLTRB(0, 20, 0, 8),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final name in _images)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: StoredImage(
                          path: name,
                          width: 104,
                          height: 104,
                          cacheWidth: 312,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: IconButton.filledTonal(
                          visualDensity: VisualDensity.compact,
                          iconSize: 18,
                          tooltip: l10n.removeImage,
                          icon: const Icon(Icons.close),
                          onPressed: () => _removeImage(name),
                        ),
                      ),
                    ],
                  ),
                _AddImageButton(
                  icon: Icons.photo_camera_outlined,
                  label: l10n.camera,
                  onTap: () => _pick(ImageSource.camera),
                ),
                _AddImageButton(
                  icon: Icons.photo_library_outlined,
                  label: l10n.gallery,
                  onTap: () => _pick(ImageSource.gallery),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _notes,
              minLines: 3,
              maxLines: 10,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.exerciseNotesLabel,
                hintText: l10n.exerciseNotesHint,
                alignLabelWithHint: true,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _LoadChoice { lb, kg, discs }

class _AddImageButton extends StatelessWidget {
  const _AddImageButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        width: 104,
        height: 104,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: scheme.primary),
            const SizedBox(height: 6),
            Text(label, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
      ),
    );
  }
}
