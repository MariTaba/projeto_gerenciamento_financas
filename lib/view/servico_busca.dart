import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String dropdownValue = 'Tudo';
  String searchTerm = '';
  List<DocumentSnapshot> searchResults = [];

  void search() async {
    List<QueryDocumentSnapshot> searchResults = [];

    if (dropdownValue == 'Tudo') {
      Query queryEntrada = _firestore
          .collection('Entradas')
          .where('uid', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .where('nome', isEqualTo: searchTerm);

      Query querySaida = _firestore
          .collection('itens')
          .where('uid', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .where('nome', isEqualTo: searchTerm);

      final querySnapshotEntrada = await queryEntrada.get();
      final querySnapshotSaida = await querySaida.get();

      searchResults = [
        ...querySnapshotEntrada.docs,
        ...querySnapshotSaida.docs
      ];
    } else {
      Query? query;

      switch (dropdownValue) {
        case 'Planilha de Entrada':
          query = _firestore
              .collection('Entradas')
              .where('uid', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
              .where('nome', isEqualTo: searchTerm);
          break;
        case 'Planilha de Saída':
          query = _firestore
              .collection('itens')
              .where('uid', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
              .where('nome', isEqualTo: searchTerm);
          break;
      }

      if (query != null) {
        final querySnapshot = await query.get();
        searchResults = querySnapshot.docs;
      }
    }

    setState(() {
      this.searchResults = searchResults;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Busca'),
      ),
      body: Column(
        children: <Widget>[
          TextField(
            onChanged: (value) {
              setState(() {
                searchTerm = value;
              });
            },
            decoration: InputDecoration(
              labelText: "Digite o termo de busca",
            ),
          ),
          Row(
            children: <String>[
              'Planilha de Entrada',
              'Planilha de Saída',
              'Tudo'
            ].map((String value) {
              return Expanded(
                child: CheckboxListTile(
                  title: Text(value),
                  value: dropdownValue == value,
                  onChanged: (bool? newValue) {
                    setState(() {
                      if (newValue == true) {
                        dropdownValue = value;
                      }
                    });
                  },
                ),
              );
            }).toList(),
          ),
          ElevatedButton(
            onPressed: search,
            child: Text('Buscar'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: searchResults.length,
              itemBuilder: (context, index) {
                var data = searchResults[index].data() as Map<String, dynamic>?;
                if (data != null) {
                  return ListTile(
                    title: Text('Nome: ${data['nome'] ?? ''}'),
                    subtitle: Text('Descrição: ${data['descricao'] ?? ''}'),
                  );
                } else {
                  return ListTile(
                    title: Text('Documento sem dados'),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
