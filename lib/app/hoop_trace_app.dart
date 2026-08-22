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
    final bootstrap = ref.watch(databaseBootstrapProvider);
    return bootstrap.when(
      loading: () => _buildMaterialApp(home: const _BootstrapLoadingPage()),
      error: (error, stackTrace) =>
          _buildMaterialApp(home: _BootstrapFailurePage(error: error)),
      data: (state) {
        if (!state.isReady) {
          return _buildMaterialApp(
            home: LegacyDatabaseBootstrapPage(version: state.version),
          );
        }
        return _buildMaterialApp(routerConfig: ref.watch(appRouterProvider));
      },
    );
  }

  MaterialApp _buildMaterialApp({Widget? home, GoRouter? routerConfig}) {
    if (routerConfig != null) {
      return MaterialApp.router(
        title: 'HoopTrace',
        theme: buildHoopTraceTheme(),
        locale: const Locale('zh'),
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
      theme: buildHoopTraceTheme(),
      locale: const Locale('zh'),
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
    return Scaffold(
      key: const Key('legacy-bootstrap'),
      appBar: AppBar(title: const Text('HoopTrace 数据兼容性检查')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.storage_outlined, size: 56),
                const SizedBox(height: 16),
                const Text(
                  '无法打开 HoopTrace v0.1 数据',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  '检测到不兼容的旧数据库版本${version == null ? '' : ' v$version'}。'
                  '现有文件会保持原样；HoopTrace 不会静默迁移、删除或清空它。'
                  '请先导出或备份旧文件，再使用当前版本创建新的本地数据。',
                  textAlign: TextAlign.center,
                ),
              ],
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
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _BootstrapFailurePage extends StatelessWidget {
  const _BootstrapFailurePage({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '本地数据库暂时无法打开。现有数据未被修改。\n$error',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
