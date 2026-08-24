import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooptrace/app/l10n/app_localizations.dart';
import 'package:hooptrace/app/l10n/app_localizations_zh.dart';
import 'package:hooptrace/app/l10n/rule_template_localizations.dart';
import 'package:hooptrace/core/data/repositories/rule_template_repository.dart';
import 'package:hooptrace/core/domain/domain_enums.dart';
import 'package:hooptrace/core/domain/entities/player.dart';
import 'package:hooptrace/core/domain/entities/rule_template.dart';
import 'package:hooptrace/features/pregame/pregame_controller.dart';

const _temporaryProfileId = '__temporary_profile__';

/// Kept as a page-level compatibility helper for route consumers; the
/// canonical human-readable validation vocabulary lives in the controller.
String pregameValidationErrorText(PregameValidationError error) {
  return pregameValidationErrorMessage(error);
}

String localizedPregameValidationErrorText(
  PregameValidationError error,
  AppLocalizations l10n,
) {
  return _validationText(error, l10n);
}

String _validationText(PregameValidationError error, AppLocalizations l10n) {
  return switch (error) {
    PregameValidationError.redParticipantRequired =>
      l10n.pregameValidationRedRequired,
    PregameValidationError.blueParticipantRequired =>
      l10n.pregameValidationBlueRequired,
    PregameValidationError.duplicatePlayerProfile =>
      l10n.pregameValidationDuplicateProfile,
    PregameValidationError.redPlayerProfileMissing =>
      l10n.pregameValidationRedMissing,
    PregameValidationError.bluePlayerProfileMissing =>
      l10n.pregameValidationBlueMissing,
    PregameValidationError.recordingModeRequired =>
      l10n.pregameValidationModeRequired,
    PregameValidationError.countdownTimerRequired =>
      l10n.pregameValidationCountdownRequired,
    PregameValidationError.invalidCountdownDuration =>
      l10n.pregameValidationCountdownDuration,
  };
}

class PregamePage extends StatefulWidget {
  const PregamePage({
    this.onStartMatch,
    this.players = const [],
    this.playersNotice,
    this.templates = RuleTemplateRepository.builtIns,
    this.onManageRules,
    super.key,
  });

  final ValueChanged<MatchSetup>? onStartMatch;
  final List<Player> players;
  final String? playersNotice;
  final List<RuleTemplate> templates;
  final VoidCallback? onManageRules;

  @override
  State<PregamePage> createState() => _PregamePageState();
}

class _PregamePageState extends State<PregamePage> {
  late final PregameController _controller;
  late final TextEditingController _redNameController;
  late final TextEditingController _blueNameController;
  late final TextEditingController _countdownMinutesController;
  List<PregameValidationError> _validationErrors = const [];
  Locale? _defaultNamesLocale;
  bool _redNameUsesLocalizedDefault = true;
  bool _blueNameUsesLocalizedDefault = true;

  @override
  void initState() {
    super.initState();
    _controller = PregameController(
      templates: widget.templates,
      players: widget.players,
    );
    _redNameController = TextEditingController(text: _controller.state.redName);
    _blueNameController = TextEditingController(
      text: _controller.state.blueName,
    );
    _countdownMinutesController = TextEditingController(
      text: _controller.state.countdownMinutesText,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context);
    if (_defaultNamesLocale == locale) return;
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
    if (_redNameUsesLocalizedDefault) {
      _setLocalizedDefaultName(red: true, value: l10n.pregameRed);
    }
    if (_blueNameUsesLocalizedDefault) {
      _setLocalizedDefaultName(red: false, value: l10n.pregameBlue);
    }
    _defaultNamesLocale = locale;
  }

  @override
  void didUpdateWidget(covariant PregamePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.templates != widget.templates) {
      _controller.setTemplates(widget.templates);
      _syncCountdownMinutesController();
    }
    if (oldWidget.players != widget.players) {
      // A repository stream can emit while this page is open. Updating the
      // available options must not recreate the controller or overwrite a
      // temporary name the user is currently typing.
      _controller.setPlayers(widget.players);
    }
  }

  @override
  void dispose() {
    _redNameController.dispose();
    _blueNameController.dispose();
    _countdownMinutesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
    final textTheme = Theme.of(context).textTheme;
    final state = _controller.state;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.pregameTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.pregamePlayers,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                _ParticipantSetup(
                  sideLabel: l10n.pregameRed,
                  profileKey: const Key('pregame-red-profile'),
                  nameKey: const Key('pregame-red-name'),
                  nameController: _redNameController,
                  selectedProfileId: state.redPlayerProfileId,
                  players: widget.players,
                  onProfileChanged: (value) => _selectProfile(true, value),
                  onNameChanged: (value) {
                    setState(() {
                      _redNameUsesLocalizedDefault = false;
                      _controller.setRedName(value);
                      _clearValidation();
                    });
                  },
                ),
                const SizedBox(height: 12),
                _ParticipantSetup(
                  sideLabel: l10n.pregameBlue,
                  profileKey: const Key('pregame-blue-profile'),
                  nameKey: const Key('pregame-blue-name'),
                  nameController: _blueNameController,
                  selectedProfileId: state.bluePlayerProfileId,
                  players: widget.players,
                  onProfileChanged: (value) => _selectProfile(false, value),
                  onNameChanged: (value) {
                    setState(() {
                      _blueNameUsesLocalizedDefault = false;
                      _controller.setBlueName(value);
                      _clearValidation();
                    });
                  },
                ),
                if (widget.playersNotice != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.playersNotice!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: const Key('pregame-rule-template'),
                  initialValue: state.ruleTemplateId,
                  decoration: InputDecoration(
                    labelText: l10n.pregameRuleTemplate,
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final template in widget.templates)
                      DropdownMenuItem(
                        value: template.id,
                        child: Text(_templateLabel(template, l10n)),
                      ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _controller.setRuleTemplateId(value);
                      _syncCountdownMinutesController();
                      _clearValidation();
                    });
                  },
                ),
                if (widget.onManageRules != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      height: 48,
                      child: TextButton.icon(
                        onPressed: widget.onManageRules,
                        icon: const Icon(Icons.tune),
                        label: Text(l10n.pregameManageRules),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                SwitchListTile(
                  key: const Key('pregame-timer'),
                  contentPadding: EdgeInsets.zero,
                  value: state.timerEnabled,
                  title: Text(l10n.pregameTimer),
                  subtitle: Text(
                    state.timerEnabled
                        ? l10n.pregameTimerEnabled
                        : l10n.pregameTimerDisabled,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _controller.setTimerEnabled(value);
                      _clearValidation();
                    });
                  },
                ),
                if (state.timerEnabled) ...[
                  const SizedBox(height: 4),
                  _SectionLabel(text: l10n.pregameClockMode),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _SelectionButton<ClockMode>(
                        key: const Key('pregame-clock-count-up'),
                        label: l10n.pregameCountUp,
                        selected: state.clockMode == ClockMode.countUp,
                        onPressed: () => _selectClockMode(ClockMode.countUp),
                      ),
                      _SelectionButton<ClockMode>(
                        key: const Key('pregame-clock-countdown'),
                        label: l10n.pregameCountDown,
                        selected: state.clockMode == ClockMode.countdown,
                        onPressed: () => _selectClockMode(ClockMode.countdown),
                      ),
                    ],
                  ),
                  if (state.clockMode == ClockMode.countdown) ...[
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('pregame-countdown-minutes'),
                      controller: _countdownMinutesController,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: false,
                      ),
                      decoration: InputDecoration(
                        labelText: l10n.pregameCountdownLabel,
                        helperText: l10n.pregameCountdownHelper,
                        suffixText: l10n.pregameMinutes,
                        border: OutlineInputBorder(),
                        errorText: _countdownErrorText(state, l10n),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _controller.setCountdownMinutesText(value);
                          _clearValidation();
                        });
                      },
                    ),
                  ],
                ],
                SwitchListTile(
                  key: const Key('pregame-win-by-two'),
                  contentPadding: EdgeInsets.zero,
                  value: state.winByTwo,
                  title: Text(l10n.pregameWinByTwo),
                  onChanged: (value) {
                    setState(() {
                      _controller.setWinByTwo(value);
                      _clearValidation();
                    });
                  },
                ),
                ExpansionTile(
                  key: const Key('pregame-advanced'),
                  tilePadding: EdgeInsets.zero,
                  title: Text(l10n.pregameAdvanced),
                  initiallyExpanded: state.advancedExpanded,
                  onExpansionChanged: _controller.setAdvancedExpanded,
                  children: [
                    _NumberSetting(
                      label: l10n.pregameTargetScore,
                      value: state.targetScore,
                      onChanged: (value) {
                        setState(() {
                          _controller.setTargetScore(value);
                          _clearValidation();
                        });
                      },
                    ),
                  ],
                ),
                if (_validationErrors.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _ValidationMessage(
                    key: Key('pregame-validation'),
                    errors: _validationErrors,
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  height: 54,
                  child: FilledButton(
                    key: const Key('pregame-start-match'),
                    onPressed: _startMatch,
                    child: Text(l10n.pregameStartMatch),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _selectProfile(bool red, String? value) {
    final accepted = red
        ? _controller.selectRedProfile(value)
        : _controller.selectBlueProfile(value);
    if (!accepted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              (AppLocalizations.of(context) ?? AppLocalizationsZh())
                  .pregameProfileConflict,
            ),
          ),
        );
      return;
    }
    if (red) {
      _redNameUsesLocalizedDefault = false;
    } else {
      _blueNameUsesLocalizedDefault = false;
    }
    if (value != null) {
      final name = red ? _controller.state.redName : _controller.state.blueName;
      final controller = red ? _redNameController : _blueNameController;
      controller.value = controller.value.copyWith(
        text: name,
        selection: TextSelection.collapsed(offset: name.length),
        composing: TextRange.empty,
      );
    }
    setState(_clearValidation);
  }

  void _setLocalizedDefaultName({required bool red, required String value}) {
    if (red) {
      _controller.setRedName(value);
      _redNameController.value = _redNameController.value.copyWith(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
        composing: TextRange.empty,
      );
    } else {
      _controller.setBlueName(value);
      _blueNameController.value = _blueNameController.value.copyWith(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
        composing: TextRange.empty,
      );
    }
  }

  void _selectClockMode(ClockMode mode) {
    setState(() {
      _controller.setClockMode(mode);
      _clearValidation();
    });
  }

  void _startMatch() {
    if (_redNameController.text != _controller.state.redName) {
      _controller.setRedName(_redNameController.text);
    }
    if (_blueNameController.text != _controller.state.blueName) {
      _controller.setBlueName(_blueNameController.text);
    }
    final validation = _controller.validate();
    if (!validation.isValid) {
      setState(() => _validationErrors = validation.errors);
      return;
    }
    setState(() => _validationErrors = const []);
    widget.onStartMatch?.call(_controller.createMatchSetup());
  }

  void _clearValidation() {
    if (_validationErrors.isNotEmpty) _validationErrors = const [];
  }

  void _syncCountdownMinutesController() {
    final text = _controller.state.countdownMinutesText;
    if (_countdownMinutesController.text == text) return;
    _countdownMinutesController.value = _countdownMinutesController.value
        .copyWith(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
          composing: TextRange.empty,
        );
  }

  static String? _countdownErrorText(
    PregameState state,
    AppLocalizations l10n,
  ) {
    final parsed = int.tryParse(state.countdownMinutesText);
    if (state.countdownDurationInputInvalid ||
        parsed == null ||
        parsed != state.timeLimitMinutes ||
        state.timeLimitMinutes < 1 ||
        state.timeLimitMinutes > 180) {
      return l10n.pregameCountdownInvalid;
    }
    return null;
  }

  static String _templateLabel(RuleTemplate template, AppLocalizations l10n) {
    return switch (template.id) {
      'free' => l10n.pregameFreeScoring,
      'eleven_win_by_two' => l10n.pregameElevenPoint,
      'twenty_one' => l10n.pregameTwentyOnePoint,
      'timed_ten' => l10n.ruleBuiltInTimedTen,
      _ => localizedRuleTemplateName(template, l10n),
    };
  }
}

class _ParticipantSetup extends StatelessWidget {
  const _ParticipantSetup({
    required this.sideLabel,
    required this.profileKey,
    required this.nameKey,
    required this.nameController,
    required this.selectedProfileId,
    required this.players,
    required this.onProfileChanged,
    required this.onNameChanged,
  });

  final String sideLabel;
  final Key profileKey;
  final Key nameKey;
  final TextEditingController nameController;
  final String? selectedProfileId;
  final List<Player> players;
  final ValueChanged<String?> onProfileChanged;
  final ValueChanged<String> onNameChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
    final profileItems = <DropdownMenuItem<String>>[
      DropdownMenuItem(
        value: _temporaryProfileId,
        child: Text(l10n.pregameTemporaryParticipant),
      ),
      for (final player in players)
        DropdownMenuItem(value: player.id, child: Text(player.nickname)),
    ];
    if (selectedProfileId != null &&
        players.every((player) => player.id != selectedProfileId)) {
      profileItems.add(
        DropdownMenuItem(
          value: selectedProfileId,
          enabled: false,
          child: Text(l10n.pregameDeletedPlayer),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(sideLabel, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        InputDecorator(
          decoration: InputDecoration(
            labelText: l10n.pregameParticipationMode,
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              key: profileKey,
              value: selectedProfileId ?? _temporaryProfileId,
              isExpanded: true,
              items: profileItems,
              onChanged: (value) {
                if (value == null) return;
                onProfileChanged(value == _temporaryProfileId ? null : value);
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          key: nameKey,
          controller: nameController,
          decoration: InputDecoration(
            labelText: selectedProfileId == null
                ? l10n.pregameTemporaryName(sideLabel)
                : l10n.pregameNameSnapshot(sideLabel),
            helperText: selectedProfileId == null
                ? l10n.pregameTemporaryHint
                : l10n.pregameSnapshotHint,
            border: const OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.next,
          onChanged: onNameChanged,
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _SelectionButton<T> extends StatelessWidget {
  const _SelectionButton({
    required this.label,
    required this.selected,
    required this.onPressed,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: SizedBox(
        height: 48,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            backgroundColor: selected
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
            side: BorderSide(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline,
              width: selected ? 2 : 1,
            ),
          ),
          onPressed: onPressed,
          child: Text(label),
        ),
      ),
    );
  }
}

class _ValidationMessage extends StatelessWidget {
  const _ValidationMessage({required this.errors, super.key});

  final List<PregameValidationError> errors;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
    final messages = errors
        .map((error) => _validationText(error, l10n))
        .toList();
    return Semantics(
      liveRegion: true,
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final message in messages)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(message),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NumberSetting extends StatelessWidget {
  const _NumberSetting({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: SegmentedButton<int>(
        segments: [
          ButtonSegment(value: value - 1, label: const Icon(Icons.remove)),
          ButtonSegment(
            value: value,
            label: Text('$value${l10n.pregamePoint}'),
          ),
          ButtonSegment(value: value + 1, label: const Icon(Icons.add)),
        ],
        selected: {value},
        onSelectionChanged: (selection) => onChanged(selection.first),
      ),
    );
  }
}
