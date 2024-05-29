import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../controller/login_controller.dart';

class PrincipalView extends StatefulWidget {
  const PrincipalView({super.key});

  @override
  State<PrincipalView> createState() => _PrincipalViewState();
}

class _PrincipalViewState extends State<PrincipalView> {
  double _rendaMensal = 0;
  double _outrasReceitas = 0;
  double _gastos = 0;
  double _saldoFinal = 0;
  final _formKey = GlobalKey<FormState>();

  // FirebaseFirestore instance (assuming you have it set up)
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _saveFinances() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Calculate final balance
      _saldoFinal = _rendaMensal + _outrasReceitas - _gastos;

      // Create a document in the 'finances' collection
      await _firestore.collection('finances').add({
        'rendaMensal': _rendaMensal,
        'outrasReceitas': _outrasReceitas,
        'gastos': _gastos,
        'saldoFinal': _saldoFinal,
        'timestamp': Timestamp.now(), // Add timestamp for sorting
      });

      // Clear form fields for new entries
      _formKey.currentState!.reset();
      setState(() {
        _rendaMensal = 0;
        _outrasReceitas = 0;
        _gastos = 0;
      });
    }
  }

  Future<void> _getFinances() async {
    // Retrieve latest finance data from Firestore (consider pagination for large datasets)
    final querySnapshot = await _firestore
        .collection('finances')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();
    if (querySnapshot.docs.isNotEmpty) {
      final finances = querySnapshot.docs.first.data();
      setState(() {
        _rendaMensal = finances['rendaMensal'] ?? 0.0;
        _outrasReceitas = finances['outrasReceitas'] ?? 0.0;
        _gastos = finances['gastos'] ?? 0.0;
        _saldoFinal = finances['saldoFinal'] ?? 0.0;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _getFinances(); // Fetch initial data on app launch
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Tarefas'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              onPressed: () {
                LoginController().logout();
                Navigator.pop(context);
              },
              icon: Icon(Icons.exit_to_app),
            )
          ],
        ),
        body: Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
                // Allow content to scroll if it overflows
                child: Column(children: [
              // Form for entering data
              Form(
                  key: _formKey,
                  child: Column(children: [
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Renda Mensal'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Insira sua renda mensal';
                        }
                        return null;
                      },
                      onSaved: (newValue) => setState(
                          () => _rendaMensal = double.parse(newValue!)),
                    ),
                    TextFormField(
                      decoration: InputDecoration(
                          labelText: 'Outras Receitas (opcional)'),
                      keyboardType: TextInputType.number,
                      onSaved: (newValue) => setState(() => _outrasReceitas =
                          double.parse(
                              newValue ?? '0.0')), // Handle null values
                    ),
                    TextFormField(
                        decoration: InputDecoration(labelText: 'Gastos do Mês'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Insira seus gastos do mês';
                          }
                        })
                  ]))
            ]))));
  }
}
