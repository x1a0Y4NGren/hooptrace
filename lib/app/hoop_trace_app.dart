import 'package:flutter/material.dart';
import 'package:hooptrace/app/app_router.dart';
import 'package:hooptrace/app/app_theme.dart';

class HoopTraceApp extends StatelessWidget {
  const HoopTraceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'HoopTrace',
      theme: buildHoopTraceTheme(),
      routerConfig: buildAppRouter(),
      debugShowCheckedModeBanner: false,
    );
  }
}
