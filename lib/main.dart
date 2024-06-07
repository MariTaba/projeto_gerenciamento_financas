// ignore_for_file: prefer_const_constructors

import 'package:device_preview/device_preview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:projeto_p2/view/entradas_view.dart';
import 'package:projeto_p2/view/planilha_view.dart';
import 'package:projeto_p2/view/servico_busca.dart';
import 'package:projeto_p2/view/sobre_view.dart';
import 'firebase_options.dart';
import 'view/cadastrar_view.dart';
import 'view/login_view.dart';
import 'view/principal_view.dart';

Future<void> main() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    DevicePreview(
      enabled: false,
      builder: (context) => MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: 'login',
      routes: {
        'login': (context) => LoginView(),
        'cadastrar': (context) => CadastrarView(),
        'principal': (context) => PrincipalView(),
        'busca': (context) => SearchPage(),
        'sobre': (context) => SobreView(),
        'planilha': (context) {
          final Map<String, Object?> arguments = ModalRoute.of(context)!
              .settings
              .arguments as Map<String, Object?>;
          final String planilhaId = arguments['planilhaId'] as String;
          return PlanilhaView(planilhaId: planilhaId);
        },
        'entradas': (context) {
          final Map<String, Object?> arguments = ModalRoute.of(context)!
              .settings
              .arguments as Map<String, Object?>;
          final String planilhaId = arguments['planilhaId'] as String;
          return EntradasView(planilhaId: planilhaId);
        },
      },
    );
  }
}
