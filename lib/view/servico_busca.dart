// ignore_for_file: prefer_const_constructors

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
  String sortType = 'nome';
  List<DocumentSnapshot> searchResults = [];

  void search() async {
    setState(() {
      searchResults.clear();
    });
    String lowerCaseSearchTerm = searchTerm.toLowerCase();

    if (dropdownValue == 'Tudo') {
      Query queryEntradaNome = _firestore
          .collection('entradas')
          .where('uid', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .where('buscaNome', isEqualTo: lowerCaseSearchTerm);

      Query querySaidaNome = _firestore
          .collection('itens')
          .where('uid', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .where('buscaNome', isEqualTo: lowerCaseSearchTerm);

      final querySnapshotEntradaNome = await queryEntradaNome.get();
      final querySnapshotSaidaNome = await querySaidaNome.get();

      if (querySnapshotEntradaNome.docs.isEmpty &&
          querySnapshotSaidaNome.docs.isEmpty) {
        Query queryEntradaDescricao = _firestore
            .collection('entradas')
            .where('uid', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
            .where('buscaDescricao', isEqualTo: lowerCaseSearchTerm);

        Query querySaidaDescricao = _firestore
            .collection('itens')
            .where('uid', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
            .where('buscaDescricao', isEqualTo: lowerCaseSearchTerm);

        final querySnapshotEntradaDescricao = await queryEntradaDescricao.get();
        final querySnapshotSaidaDescricao = await querySaidaDescricao.get();

        searchResults = [
          ...querySnapshotEntradaDescricao.docs,
          ...querySnapshotSaidaDescricao.docs
        ];
      } else {
        searchResults = [
          ...querySnapshotEntradaNome.docs,
          ...querySnapshotSaidaNome.docs
        ];
      }
    } else {
      Query? queryNome;
      Query? queryDescricao;

      switch (dropdownValue) {
        case 'Planilha de Entrada':
          queryNome = _firestore
              .collection('entradas')
              .where('uid', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
              .where('buscaNome', isEqualTo: lowerCaseSearchTerm);

          queryDescricao = _firestore
              .collection('entradas')
              .where('uid', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
              .where('buscaDescricao', isEqualTo: lowerCaseSearchTerm);
          break;
        case 'Planilha de Saída':
          queryNome = _firestore
              .collection('itens')
              .where('uid', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
              .where('buscaNome', isEqualTo: lowerCaseSearchTerm);

          queryDescricao = _firestore
              .collection('itens')
              .where('uid', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
              .where('buscaDescricao', isEqualTo: lowerCaseSearchTerm);
          break;
      }

      if (queryNome != null) {
        final querySnapshotNome = await queryNome.get();

        if (querySnapshotNome.docs.isEmpty && queryDescricao != null) {
          final querySnapshotDescricao = await queryDescricao.get();
          searchResults = querySnapshotDescricao.docs;
        } else {
          searchResults = querySnapshotNome.docs;
        }
      }
    }

    if (sortType == 'nome') {
      searchResults.sort((a, b) {
        var aData = a.data() as Map<String, dynamic>;
        var bData = b.data() as Map<String, dynamic>;
        String aName = aData['nome'] ?? '';
        String bName = bData['nome'] ?? '';
        return aName.compareTo(bName);
      });
    } else if (sortType == 'dataCriacao') {
  searchResults.sort((a, b) {
    var aData = a.data() as Map<String, dynamic>;
    var bData = b.data() as Map<String, dynamic>;
    if (aData['dataCriacao'] is Timestamp && bData['dataCriacao'] is Timestamp) {
      DateTime aDate = (aData['dataCriacao'] as Timestamp).toDate();
      DateTime bDate = (bData['dataCriacao'] as Timestamp).toDate();
      return aDate.compareTo(bDate);
    } else {
      return 0;
    }
  });
}
    setState(() {});
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
          Row(
            children: <Widget>[
              PopupMenuButton<String>(
                onSelected: (String value) {
                  setState(() {
                    sortType = value;
                    search();
                  });
                },
                itemBuilder: (BuildContext context) {
                  return <String>['nome', 'dataCriacao'].map((String value) {
                    return PopupMenuItem<String>(
                      value: value,
                      child: Text(value == 'nome' ? 'Nome' : 'Data de Criação'),
                    );
                  }).toList();
                },
              ),
              ElevatedButton(
                onPressed: search,
                child: Text('Buscar'),
              ),
            ],
          ),
          Expanded(
  child: ListView.builder(
    itemCount: searchResults.length,
    itemBuilder: (context, index) {
      var data = searchResults[index].data() as Map<String, dynamic>?;
      if (data != null) {
        String planilhaId = data['planilhaId'];
        Future<DocumentSnapshot> planilhaDocFuture = FirebaseFirestore.instance.collection('planilhas').doc(planilhaId).get();
        return FutureBuilder<DocumentSnapshot>(
          future: planilhaDocFuture,
          builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              String planilhaNome = (snapshot.data?.data() as Map<String, dynamic>)?['nome'] ?? '';
              return ListTile(
                title: Text('${data['nome'] ?? ''}'),
                subtitle: Text(
                    'Descrição: ${data['descricao'] ?? ''}\nPlanilha: $planilhaNome'),
              );
            } else {
              return CircularProgressIndicator();
            }
          },
        );
      } else {
        return ListTile(
          title: Text('Documento sem dados'),
        );
      }
    },
  ),
)
        ],
      ),
    );
  }
}
