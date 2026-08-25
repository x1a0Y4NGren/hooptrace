import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooptrace/app/app_theme.dart';
import 'package:hooptrace/app/l10n/app_localizations.dart';
import 'package:hooptrace/app/l10n/app_localizations_zh.dart';
import 'package:hooptrace/core/domain/domain_enums.dart';
import 'package:hooptrace/core/export/automatic_backup_service.dart';
import 'package:hooptrace/core/export/backup_merge_service.dart';
import 'package:hooptrace/core/export/json_backup_codec.dart';
import 'package:hooptrace/core/settings/language_preferences.dart';
import 'package:hooptrace/core/settings/scoring_feedback.dart';
import 'package:hooptrace/core/settings/theme_preferences.dart';
import 'package:hooptrace/features/settings/settings_controller.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    required this.controller,
    this.onOpenProject,
    this.onOpenRules,
    this.onDataRestored,
    this.themeController,
    this.languageController,
    super.key,
  });

  final SettingsController controller;
  final VoidCallback? onOpenProject;
  final VoidCallback? onOpenRules;
  final VoidCallback? onDataRestored;
  final ThemePreferencesController? themeController;
  final LanguagePreferencesController? languageController;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  AppLocalizations _localizations(BuildContext context) {
    return AppLocalizations.of(context) ?? AppLocalizationsZh();
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
    widget.themeController?.addListener(_refresh);
    widget.languageController?.addListener(_refresh);
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant SettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_refresh);
      widget.controller.addListener(_refresh);
      unawaited(_load());
    }
    if (oldWidget.themeController != widget.themeController) {
      oldWidget.themeController?.removeListener(_refresh);
      widget.themeController?.addListener(_refresh);
    }
    if (oldWidget.languageController != widget.languageController) {
      oldWidget.languageController?.removeListener(_refresh);
      widget.languageController?.addListener(_refresh);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    widget.themeController?.removeListener(_refresh);
    widget.languageController?.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    try {
      await widget.controller.load();
    } on Object catch (error) {
      if (!mounted) return;
      _showMessage(_friendlyError(error, _localizations(context)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final backup = controller.backupState;
    final l10n = _localizations(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: SafeArea(
        child: Column(
          children: [
            if (controller.busy) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: ListView(
                // Keep the final row reachable at small heights and leave
                // enough scroll slack for 48dp targets after expanded motion
                // preview content.
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 320),
                children: [
                  _SettingsSection(
                    title: l10n.settingsDefaultSection,
                    children: [
                      _SettingTile(
                        icon: Icons.tune,
                        title: l10n.settingsDefaultRuleTitle,
                        subtitle: l10n.settingsDefaultRuleSubtitle,
                      ),
                    ],
                  ),
                  _SettingsSection(
                    title: l10n.settingsRulesSection,
                    children: [
                      _SettingTile(
                        icon: Icons.tune,
                        title: l10n.settingsRulesTemplateTitle,
                        subtitle: l10n.settingsRulesTemplateSubtitle,
                        onTap: widget.onOpenRules,
                      ),
                    ],
                  ),
                  _SettingsSection(
                    title: l10n.settingsAppearanceSection,
                    children: [
                      _ThemeSettingTile(
                        icon: Icons.palette_outlined,
                        title: l10n.settingsThemeTitle,
                        subtitle: l10n.settingsThemeSubtitle,
                        controller: widget.themeController,
                        l10n: l10n,
                      ),
                      _MotionSettingTile(
                        icon: Icons.motion_photos_on_outlined,
                        title: l10n.settingsMotionTitle,
                        subtitle: l10n.settingsMotionSubtitle,
                        preference: controller.feedbackState.motion,
                        enabled: !controller.busy,
                        l10n: l10n,
                        onChanged: _setMotionPreference,
                      ),
                      _MotionPreview(
                        preference: controller.feedbackState.motion,
                        l10n: l10n,
                      ),
                    ],
                  ),
                  _SettingsSection(
                    title: l10n.settingsLanguageSection,
                    children: [
                      if (widget.languageController != null)
                        _LanguageSettingTile(
                          icon: Icons.language_outlined,
                          title: l10n.settingsLanguageTitle,
                          subtitle: l10n.settingsLanguageSubtitle,
                          controller: widget.languageController,
                          l10n: l10n,
                        ),
                    ],
                  ),
                  _SettingsSection(
                    title: l10n.settingsFeedbackSection,
                    children: [
                      SwitchListTile(
                        key: const Key('scoring-feedback-haptic-switch'),
                        minTileHeight: 64,
                        secondary: const Icon(Icons.vibration),
                        title: Text(l10n.settingsHapticTitle),
                        subtitle: Text(
                          controller.feedbackState.haptic
                              ? l10n.settingsHapticEnabled
                              : l10n.settingsHapticDisabled,
                        ),
                        value: controller.feedbackState.haptic,
                        onChanged: controller.busy
                            ? null
                            : _setHapticFeedbackEnabled,
                      ),
                      SwitchListTile(
                        key: const Key('scoring-feedback-sound-switch'),
                        minTileHeight: 64,
                        secondary: const Icon(Icons.volume_up_outlined),
                        title: Text(l10n.settingsSoundTitle),
                        subtitle: Text(
                          controller.feedbackState.sound
                              ? l10n.settingsSoundEnabled
                              : l10n.settingsSoundDisabled,
                        ),
                        value: controller.feedbackState.sound,
                        onChanged: controller.busy
                            ? null
                            : _setSoundFeedbackEnabled,
                      ),
                    ],
                  ),
                  _SettingsSection(
                    title: l10n.settingsStatisticsSection,
                    children: [
                      _SettingTile(
                        icon: Icons.query_stats,
                        title: l10n.settingsStatisticsSection,
                        subtitle: l10n.settingsStatisticsSubtitle,
                      ),
                    ],
                  ),
                  _dataManagementSection(
                    controller: controller,
                    backup: backup,
                    l10n: l10n,
                  ),
                  _SettingsSection(
                    title: l10n.settingsPrivacySection,
                    children: [
                      _SettingTile(
                        icon: Icons.lock_outline,
                        title: l10n.settingsPrivacyTitle,
                        subtitle: l10n.settingsPrivacySubtitle,
                      ),
                    ],
                  ),
                  _SettingsSection(
                    title: l10n.settingsExperimentalSection,
                    children: [
                      _SettingTile(
                        icon: Icons.science_outlined,
                        title: l10n.settingsExperimentalTitle,
                        subtitle: l10n.settingsExperimentalSubtitle,
                        enabled: false,
                      ),
                    ],
                  ),
                  _SettingsSection(
                    title: l10n.settingsDiagnosticsSection,
                    children: [
                      _SettingTile(
                        icon: Icons.monitor_heart_outlined,
                        title: l10n.settingsDiagnosticsTitle,
                        subtitle: l10n.settingsDiagnosticsSubtitle,
                        enabled: false,
                      ),
                    ],
                  ),
                  _SettingsSection(
                    title: l10n.settingsProjectSection,
                    children: [
                      _SettingTile(
                        icon: Icons.info_outline,
                        title: l10n.settingsAboutTitle,
                        subtitle: l10n.settingsAboutSubtitle,
                        onTap: widget.onOpenProject,
                      ),
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

  Widget _dataManagementSection({
    required SettingsController controller,
    required AutomaticBackupState backup,
    required AppLocalizations l10n,
  }) {
    return _SettingsSection(
      title: l10n.settingsDataSection,
      children: [
        _SettingTile(
          icon: Icons.archive_outlined,
          title: l10n.settingsExportBackupTitle,
          subtitle: l10n.settingsExportBackupSubtitle,
          enabled: !controller.busy,
          onTap: () => _run(
            () => controller.shareJsonBackup(
              subject: l10n.exportFullBackupSubject,
            ),
            success: l10n.settingsExportBackupSuccess,
          ),
        ),
        _SettingTile(
          icon: Icons.settings_backup_restore,
          title: l10n.settingsRestoreTitle,
          subtitle: controller.canRestoreBackup
              ? l10n.settingsRestoreSubtitleMerge
              : l10n.settingsRestoreSubtitleBlocked,
          enabled: !controller.busy,
          onTap: _chooseRestoreMode,
        ),
        _SettingTile(
          icon: Icons.table_view_outlined,
          title: l10n.settingsExportCsvTitle,
          subtitle: l10n.settingsExportCsvSubtitle,
          enabled: !controller.busy,
          onTap: () => _run(
            () => controller.shareCsvExports(subject: l10n.exportCsvSubject),
            success: l10n.settingsExportCsvSuccess,
          ),
        ),
        SwitchListTile(
          key: const Key('automatic-backup-switch'),
          secondary: const Icon(Icons.backup_outlined),
          title: Text(l10n.settingsAutomaticBackupTitle),
          subtitle: Text(
            backup.enabled
                ? l10n.settingsAutomaticBackupEnabled
                : l10n.settingsAutomaticBackupDisabled,
          ),
          value: backup.enabled,
          onChanged: controller.busy ? null : _setAutomaticBackupEnabled,
        ),
        _SettingTile(
          icon: Icons.folder_outlined,
          title: l10n.settingsBackupDirectoryTitle,
          subtitle:
              backup.directoryLabel ??
              backup.directory ??
              l10n.settingsBackupDirectoryUnselected,
          enabled: !controller.busy,
          onTap: _configureDirectory,
        ),
        _SettingTile(
          icon: Icons.backup,
          title: l10n.settingsBackupNowTitle,
          subtitle: _lastBackupLabel(backup, l10n),
          enabled: !controller.busy && backup.isConfigured,
          onTap: _runBackupNow,
        ),
        ListTile(
          key: const Key('backup-retention-limit'),
          minTileHeight: 64,
          leading: const Icon(Icons.delete_sweep_outlined),
          title: Text(l10n.settingsBackupRetentionTitle),
          subtitle: Text(l10n.settingsBackupRetentionSubtitle),
          trailing: DropdownButton<int>(
            key: const Key('backup-retention-dropdown'),
            value: backup.retentionLimit,
            items: _retentionOptions(backup.retentionLimit)
                .map(
                  (value) => DropdownMenuItem<int>(
                    value: value,
                    child: Text('$value'),
                  ),
                )
                .toList(growable: false),
            onChanged: controller.busy
                ? null
                : (value) {
                    if (value != null) unawaited(_setRetentionLimit(value));
                  },
          ),
        ),
      ],
    );
  }

  Future<void> _chooseRestoreMode() async {
    final l10n = _localizations(context);
    final mode = await showDialog<RestoreMode>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.settingsRestoreDialogTitle),
        contentPadding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const Key('backup-mode-merge'),
              leading: const Icon(Icons.merge_type),
              title: Text(l10n.settingsMergeTitle),
              subtitle: Text(l10n.settingsMergeSubtitle),
              onTap: () => Navigator.pop(dialogContext, RestoreMode.merge),
            ),
            ListTile(
              key: const Key('backup-mode-replace'),
              enabled: widget.controller.canRestoreBackup,
              leading: const Icon(Icons.find_replace_outlined),
              title: Text(l10n.settingsReplaceTitle),
              subtitle: Text(
                widget.controller.canRestoreBackup
                    ? l10n.settingsReplaceSubtitle
                    : l10n.settingsReplaceBlocked,
              ),
              onTap: widget.controller.canRestoreBackup
                  ? () => Navigator.pop(dialogContext, RestoreMode.replace)
                  : null,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancelAction),
          ),
        ],
      ),
    );
    if (mode == null) return;
    if (mode == RestoreMode.replace && !await _confirmReplace()) return;
    try {
      final restored = await widget.controller.restoreBackup(
        mode: mode,
        safetySubject: l10n.exportSafetyBackupSubject,
        pickerDialogTitle: l10n.settingsRestorePickerTitle,
      );
      if (!mounted) return;
      if (!restored) {
        _showMessage(l10n.settingsRestoreNotSelected);
        return;
      }
      _showMessage(
        mode == RestoreMode.merge
            ? l10n.settingsMergeCompleted
            : l10n.settingsReplaceCompleted,
      );
      widget.onDataRestored?.call();
    } on Object catch (error) {
      _showMessage(_friendlyError(error, l10n));
    }
  }

  Future<bool> _confirmReplace() async {
    final l10n = _localizations(context);
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(l10n.settingsReplaceConfirmTitle),
            content: Text(l10n.settingsReplaceConfirmBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(l10n.cancelAction),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(l10n.settingsReplaceConfirmAction),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _configureDirectory() async {
    final l10n = _localizations(context);
    try {
      final selected = await widget.controller.configureBackupDirectory(
        dialogTitle: l10n.settingsBackupDirectoryPickerTitle,
      );
      if (!mounted) return;
      _showMessage(
        selected
            ? l10n.settingsDirectoryUpdated
            : l10n.settingsDirectoryNotSelected,
      );
    } on Object catch (error) {
      _showMessage(_friendlyError(error, l10n));
    }
  }

  Future<void> _setAutomaticBackupEnabled(bool enabled) async {
    final l10n = _localizations(context);
    try {
      final changed = await widget.controller.setAutomaticBackupEnabled(
        enabled,
        dialogTitle: l10n.settingsBackupDirectoryPickerTitle,
      );
      if (!mounted) return;
      if (!changed) {
        _showMessage(l10n.settingsAutomaticBackupNotConfigured);
      } else {
        _showMessage(
          enabled
              ? l10n.settingsAutomaticBackupTurnedOn
              : l10n.settingsAutomaticBackupTurnedOff,
        );
      }
    } on Object catch (error) {
      _showMessage(_friendlyError(error, l10n));
    }
  }

  Future<void> _setHapticFeedbackEnabled(bool enabled) async {
    final l10n = _localizations(context);
    try {
      await widget.controller.setHapticFeedbackEnabled(enabled);
      if (mounted) {
        _showMessage(
          enabled ? l10n.settingsHapticTurnedOn : l10n.settingsHapticTurnedOff,
        );
      }
    } on Object catch (error) {
      _showMessage(_friendlyError(error, l10n));
    }
  }

  Future<void> _setSoundFeedbackEnabled(bool enabled) async {
    final l10n = _localizations(context);
    try {
      await widget.controller.setSoundFeedbackEnabled(enabled);
      if (mounted) {
        _showMessage(
          enabled ? l10n.settingsSoundTurnedOn : l10n.settingsSoundTurnedOff,
        );
      }
    } on Object catch (error) {
      _showMessage(_friendlyError(error, l10n));
    }
  }

  Future<void> _setMotionPreference(MotionPreference preference) async {
    try {
      await widget.controller.setMotionPreference(preference);
    } on Object catch (error) {
      if (mounted) _showMessage(_friendlyError(error, _localizations(context)));
    }
  }

  Future<void> _runBackupNow() async {
    final l10n = _localizations(context);
    try {
      await widget.controller.runBackupNow();
      if (mounted) _showMessage(l10n.settingsBackupWritten);
    } on Object catch (error) {
      _showMessage(_friendlyError(error, l10n));
    }
  }

  Future<void> _setRetentionLimit(int value) async {
    final l10n = _localizations(context);
    try {
      await widget.controller.setBackupRetentionLimit(value);
      if (mounted) {
        _showMessage(l10n.settingsRetentionUpdated(value));
      }
    } on Object catch (error) {
      _showMessage(_friendlyError(error, l10n));
    }
  }

  Future<void> _run(
    Future<void> Function() action, {
    required String success,
  }) async {
    final l10n = _localizations(context);
    try {
      await action();
      if (mounted) _showMessage(success);
    } on Object catch (error) {
      _showMessage(_friendlyError(error, l10n));
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  static String _lastBackupLabel(
    AutomaticBackupState state,
    AppLocalizations l10n,
  ) {
    final value = state.lastBackupAt?.toLocal();
    if (value == null) return l10n.settingsBackupNever;
    String two(int number) => number.toString().padLeft(2, '0');
    return l10n.settingsBackupLastSuccess(
      '${value.year}-${two(value.month)}-${two(value.day)}',
      '${two(value.hour)}:${two(value.minute)}',
    );
  }

  static List<int> _retentionOptions(int current) {
    return <int>{1, 5, 10, 20, 30, 50, current}.toList()..sort();
  }

  static String _friendlyError(Object error, AppLocalizations l10n) {
    if (error is BackupChecksumException) {
      return l10n.settingsErrorChecksum;
    }
    if (error is UnsupportedBackupSchemaException) {
      return l10n.settingsErrorFutureVersion;
    }
    if (error is BackupFormatException ||
        error is BackupValidationException ||
        error is BackupRestoreException) {
      return l10n.settingsErrorInvalidBackup;
    }
    if (error is BackupMergeException) {
      return l10n.settingsErrorMerge;
    }
    if (error is BackupDirectoryNotConfiguredException) {
      return l10n.settingsErrorDirectoryRequired;
    }
    if (error is BackupDirectoryUnavailableException) {
      return l10n.settingsErrorDirectoryUnavailable;
    }
    if (error is AutomaticBackupWriteException) {
      return l10n.settingsErrorBackupWrite;
    }
    if (error is BackupRestoreBlockedException) {
      return l10n.settingsErrorRestoreBlocked;
    }
    return l10n.settingsErrorGeneric;
  }
}

class _MotionSettingTile extends StatelessWidget {
  const _MotionSettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.preference,
    required this.enabled,
    required this.l10n,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final MotionPreference preference;
  final bool enabled;
  final AppLocalizations l10n;
  final ValueChanged<MotionPreference> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: const Key('motion-preference-tile'),
      minTileHeight: 64,
      enabled: enabled,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: DropdownButtonHideUnderline(
        child: DropdownButton<MotionPreference>(
          key: const Key('motion-preference-dropdown'),
          value: preference,
          isDense: true,
          items: MotionPreference.values
              .map(
                (value) => DropdownMenuItem<MotionPreference>(
                  value: value,
                  child: Text(_motionPreferenceLabel(value, l10n)),
                ),
              )
              .toList(growable: false),
          onChanged: enabled
              ? (value) {
                  if (value != null) onChanged(value);
                }
              : null,
        ),
      ),
    );
  }
}

String _motionPreferenceLabel(
  MotionPreference preference,
  AppLocalizations l10n,
) {
  return switch (preference) {
    MotionPreference.standard => l10n.settingsMotionStandard,
    MotionPreference.reduced => l10n.settingsMotionReduced,
  };
}

class _MotionPreview extends StatelessWidget {
  const _MotionPreview({required this.preference, required this.l10n});

  final MotionPreference preference;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final reduced =
        preference == MotionPreference.reduced ||
        MediaQuery.maybeOf(context)?.disableAnimations == true;
    final duration = reduced
        ? Duration.zero
        : (Theme.of(context).extension<HoopTraceMotionTheme>()?.impact ??
              const Duration(milliseconds: 240));
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Semantics(
        label: l10n.settingsMotionPreview,
        container: true,
        child: AnimatedContainer(
          key: const Key('motion-preview'),
          duration: duration,
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              AnimatedScale(
                scale: reduced ? 1 : 1.08,
                duration: duration,
                child: Icon(
                  reduced ? Icons.accessibility_new : Icons.auto_awesome,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reduced
                          ? l10n.settingsMotionPreviewReduced
                          : l10n.settingsMotionPreviewStandard,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.settingsMotionHelp,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageSettingTile extends StatelessWidget {
  const _LanguageSettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.controller,
    required this.l10n,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final LanguagePreferencesController? controller;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final languageController = controller;
    return ListTile(
      key: const Key('language-preference-tile'),
      minTileHeight: 64,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: languageController == null
          ? null
          : DropdownButtonHideUnderline(
              child: DropdownButton<AppLanguagePreference>(
                key: const Key('language-preference-dropdown'),
                value: languageController.preference,
                isDense: true,
                items: AppLanguagePreference.values
                    .map(
                      (preference) => DropdownMenuItem<AppLanguagePreference>(
                        value: preference,
                        child: Text(_languagePreferenceLabel(preference, l10n)),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (preference) {
                  if (preference != null) {
                    unawaited(languageController.setPreference(preference));
                  }
                },
              ),
            ),
    );
  }
}

String _languagePreferenceLabel(
  AppLanguagePreference preference,
  AppLocalizations l10n,
) {
  return switch (preference) {
    AppLanguagePreference.chinese => l10n.settingsLanguageChinese,
    AppLanguagePreference.english => l10n.settingsLanguageEnglish,
  };
}

class _ThemeSettingTile extends StatelessWidget {
  const _ThemeSettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.controller,
    required this.l10n,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final ThemePreferencesController? controller;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final themeController = controller;
    return ListTile(
      key: const Key('theme-preference-tile'),
      minTileHeight: 64,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: themeController == null
          ? null
          : DropdownButtonHideUnderline(
              child: DropdownButton<AppThemePreference>(
                key: const Key('theme-preference-dropdown'),
                value: themeController.preference,
                isDense: true,
                items: AppThemePreference.values
                    .map(
                      (preference) => DropdownMenuItem<AppThemePreference>(
                        value: preference,
                        child: Text(_themePreferenceLabel(preference, l10n)),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (preference) {
                  if (preference != null) {
                    unawaited(themeController.setPreference(preference));
                  }
                },
              ),
            ),
    );
  }
}

String _themePreferenceLabel(
  AppThemePreference preference,
  AppLocalizations l10n,
) {
  return switch (preference) {
    AppThemePreference.system => l10n.settingsThemeSystem,
    AppThemePreference.light => l10n.settingsThemeLight,
    AppThemePreference.dark => l10n.settingsThemeDark,
  };
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.enabled = true,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minTileHeight: 64,
      enabled: enabled,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: onTap == null ? null : const Icon(Icons.chevron_right),
      onTap: enabled ? onTap : null,
    );
  }
}
