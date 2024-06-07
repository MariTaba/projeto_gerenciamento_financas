// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';

class SobreView extends StatefulWidget {
  @override
  _SobreViewState createState() => _SobreViewState();
}

class _SobreViewState extends State<SobreView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sobre'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const <Widget>[
            Text(
              'Sobre:',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Trabalho para P2 - Programação Dispositivos Móveis.\n'
              'Mariana Nakamura Taba\n'
              'Angelo Ferdinand Imon Spano\n\n'
              'Este trabalho consiste em um aplicativo para gerenciar finanças pessoais, de forma simples e eficiente e servirá de base para desenvolvimento do aplicativo para o TCC.\n\n'
              'Muito obrigado!',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}