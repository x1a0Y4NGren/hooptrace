import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:hooptrace/app/app_providers.dart';
import 'package:hooptrace/app/app_theme.dart';
import 'package:hooptrace/app/l10n/app_localizations.dart';
import 'package:hooptrace/app/provider_router.dart';
import 'package:hooptrace/core/data/app_database.dart';

/// Application composition root. The optional database and provider overrides
/// are test seams; production ownership lives in [appDatabaseProvider].
class HoopTraceApp extends StatelessWidget {
  const HoopTraceApp({this.database, super.key});

  final AppDatabase? database;

  @override
  Widget build(BuildContext context) {
    if (database == null) {
      return const ProviderScope(child: _HoopTraceAppView());
    }
    return ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(database!)],
      child: const _HoopTraceAppView(),
    );
  }
}

class _HoopTraceAppView extends ConsumerWidget {
  const _HoopTraceAppView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrap = ref.watch(databaseStartupProvider);
    final themeMode = bootstrap.value?.isReady == true
        ? ref.watch(themePreferencesControllerProvider).themeMode
        : ThemeMode.system;
    final languageController = bootstrap.value?.isReady == true
        ? ref.watch(languagePreferencesControllerProvider)
        : null;
    final locale = languageController?.locale ?? const Locale('zh');
    return bootstrap.when(
      loading: () => _buildMaterialApp(
        themeMode: themeMode,
        locale: locale,
        home: const _BootstrapLoadingPage(),
      ),
      error: (error, stackTrace) => _buildMaterialApp(
        themeMode: themeMode,
        locale: locale,
        home: const _BootstrapFailurePage(),
      ),
      data: (state) {
        if (!state.isReady) {
          return _buildMaterialApp(
            themeMode: themeMode,
            locale: locale,
            home: LegacyDatabaseBootstrapPage(version: state.version),
          );
        }
        if (languageController?.initialized != true) {
          return _buildMaterialApp(
            themeMode: themeMode,
            locale: locale,
            home: const _BootstrapLoadingPage(),
          );
        }
        return _buildMaterialApp(
          themeMode: themeMode,
          locale: locale,
          routerConfig: ref.watch(appRouterProvider),
        );
      },
    );
  }

  MaterialApp _buildMaterialApp({
    required ThemeMode themeMode,
    required Locale locale,
    Widget? home,
    GoRouter? routerConfig,
  }) {
    if (routerConfig != null) {
      return MaterialApp.router(
        title: 'HoopTrace',
        onGenerateTitle: (context) =>
            AppLocalizations.of(context)?.appName ?? 'HoopTrace',
        theme: buildHoopTraceTheme(),
        darkTheme: buildHoopTraceTheme(brightness: Brightness.dark),
        themeMode: themeMode,
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: routerConfig,
        debugShowCheckedModeBanner: false,
      );
    }
    return MaterialApp(
      title: 'HoopTrace',
      onGenerateTitle: (context) =>
          AppLocalizations.of(context)?.appName ?? 'HoopTrace',
      theme: buildHoopTraceTheme(),
      darkTheme: buildHoopTraceTheme(brightness: Brightness.dark),
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
      debugShowCheckedModeBanner: false,
    );
  }
}

class LegacyDatabaseBootstrapPage extends StatelessWidget {
  const LegacyDatabaseBootstrapPage({this.version, super.key});

  final int? version;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      key: const Key('legacy-bootstrap'),
      appBar: AppBar(title: Text(l10n.legacyBootstrapTitle)),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.storage_outlined, size: 56),
                  const SizedBox(height: 16),
                  Text(
                    l10n.legacyBootstrapHeadline,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.legacyBootstrapBody(
                      version == null ? '' : ' v$version',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BootstrapLoadingPage extends StatelessWidget {
  const _BootstrapLoadingPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(child: Center(child: CircularProgressIndicator())),
    );
  }
}

class _BootstrapFailurePage extends StatelessWidget {
  const _BootstrapFailurePage();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(l10n.bootstrapFailureBody, textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}
