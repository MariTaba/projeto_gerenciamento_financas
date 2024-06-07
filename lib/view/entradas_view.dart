// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class EntradasView extends StatefulWidget {
  final String planilhaId;

  const EntradasView({Key? key, required this.planilhaId}) : super(key: key);

  @override
  _EntradasViewState createState() => _EntradasViewState();
}

class _EntradasViewState extends State<EntradasView> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  late Future<String> planilhaNome;

  final nomeController = TextEditingController();
  final descricaoController = TextEditingController();
  final valorController = TextEditingController();

  Future<String> fetchPlanilhaNome() async {
    DocumentSnapshot doc =
        await firestore.collection('planilhas').doc(widget.planilhaId).get();
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return data['nome'] ?? '';
  }

  Future<void> updatePlanilhaTotal() async {
    final querySnapshot = await firestore
        .collection('entradas')
        .where('planilhaId', isEqualTo: widget.planilhaId)
        .get();

    final valorTotal = querySnapshot.docs
        .fold(0.0, (t, doc) => t + (doc.data()['valor'] ?? 0.0));

    await firestore
        .collection('planilhas')
        .doc(widget.planilhaId)
        .update({'valorTotal': valorTotal});
  }

  Future<double> fetchValorTotal() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('entradas')
        .where('uid', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .where('planilhaId', isEqualTo: widget.planilhaId)
        .get();

    double valorTotal = 0.0;

    for (var doc in querySnapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      if (data.containsKey('valor') && data['valor'] != null) {
        valorTotal += double.parse(data['valor'].toString());
      }
    }

    return valorTotal;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: FutureBuilder<String>(
            future: fetchPlanilhaNome(),
            builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Text('${snapshot.data ?? 'Sem nome'}'),
                );
              } else if (snapshot.connectionState == ConnectionState.none) {
                return Text("No data");
              }
              return CircularProgressIndicator();
            },
          ),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.search),
              onPressed: () {
                Navigator.pushNamed(context, 'busca');
              },
            ),
          ],
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(60.0),
            child: Column(
              children: [
                FutureBuilder<double>(
                  future: fetchValorTotal(),
                  builder:
                      (BuildContext context, AsyncSnapshot<double> snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                            'Valor Total das Entradas: R\$ ${(snapshot.data ?? 0).toStringAsFixed(2)}'),
                      );
                    } else if (snapshot.connectionState ==
                        ConnectionState.none) {
                      return Text("No data");
                    }
                    return CircularProgressIndicator();
                  },
                ),
              ],
            ),
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('entradas')
              .where('uid', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
              .where('planilhaId', isEqualTo: widget.planilhaId)
              .snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) {
              return Text('Algo deu errado');
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Text("Carregando");
            }

            return ListView(
              children: snapshot.data!.docs.map((DocumentSnapshot document) {
                Map<String, dynamic> data =
                    document.data() as Map<String, dynamic>;
                return GestureDetector(
                  onLongPress: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Editar ou Deletar'),
                          content:
                              Text('Você deseja editar ou deletar este item?'),
                          actions: <Widget>[
                            TextButton(
                              child: Text('Editar'),
                              onPressed: () {
                                Navigator.of(context).pop();

                                nomeController.text = document['nome'];
                                descricaoController.text =
                                    document['descricao'];
                                valorController.text =
                                    document['valor'].toString();

                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text("Editar Item"),
                                      content: SingleChildScrollView(
                                        child: ListBody(
                                          children: <Widget>[
                                            TextField(
                                              controller: nomeController,
                                              decoration: const InputDecoration(
                                                  labelText: 'Nome'),
                                            ),
                                            TextField(
                                              controller: descricaoController,
                                              decoration: const InputDecoration(
                                                  labelText: 'Descrição'),
                                            ),
                                            TextField(
                                              controller: valorController,
                                              decoration: const InputDecoration(
                                                  labelText: 'Valor'),
                                              keyboardType: TextInputType
                                                  .numberWithOptions(
                                                      decimal: true),
                                              inputFormatters: [
                                                FilteringTextInputFormatter
                                                    .allow(RegExp(
                                                        r'^\d+\.?\d{0,2}')),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      actions: <Widget>[
                                        TextButton(
                                          child: Text('Salvar'),
                                          onPressed: () async {
                                            await document.reference.update({
                                              'nome': nomeController.text,
                                              'descricao':
                                                  descricaoController.text,
                                              'valor': double.parse(
                                                  valorController.text),
                                              'buscaNome': nomeController.text
                                                  .toLowerCase(),
                                              'buscaDescricao':
                                                  descricaoController.text
                                                      .toLowerCase(),
                                            });
                                            updatePlanilhaTotal();
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                        TextButton(
                                          child: Text('Cancelar'),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                            TextButton(
                              child: Text('Deletar'),
                              onPressed: () async {
                                final confirmDelete = await showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text("Confirmar"),
                                      content: const Text(
                                          "Você realmente deseja deletar este item?"),
                                      actions: <Widget>[
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(true),
                                          child: const Text("DELETAR"),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(false),
                                          child: const Text("CANCELAR"),
                                        ),
                                      ],
                                    );
                                  },
                                );
                                if (confirmDelete) {
                                  await document.reference.delete();
                                  updatePlanilhaTotal();
                                  Navigator.of(context).pop();
                                }
                              },
                            )
                          ],
                        );
                      },
                    );
                  },
                  child: ListTile(
                    title: Text(data['nome']),
                    subtitle: Text(
                        '${data['descricao']} - Valor: R\$ ${data['valor'].toStringAsFixed(2)}'),
                  ),
                );
              }).toList(),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                final _formKey = GlobalKey<FormState>();

                nomeController.clear();
                descricaoController.clear();
                valorController.clear();

                return AlertDialog(
                  title: Text('Adicionar Entrada'),
                  content: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        TextFormField(
                          controller: nomeController,
                          decoration: InputDecoration(labelText: 'Nome'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, insira um nome';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: descricaoController,
                          decoration: InputDecoration(labelText: 'Descrição'),
                        ),
                        TextFormField(
                          controller: valorController,
                          decoration: InputDecoration(labelText: 'Valor Total'),
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, insira um valor';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      child: Text('Cancelar'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    TextButton(
                      child: Text('Salvar'),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          firestore.collection('entradas').add({
                            'nome': nomeController.text,
                            'descricao': descricaoController.text,
                            'valor': double.parse(valorController.text),
                            'uid': FirebaseAuth.instance.currentUser!.uid,
                            'buscaNome': nomeController.text.toLowerCase(),
                            'buscaDescricao':
                                descricaoController.text.toLowerCase(),
                            'planilhaId': widget.planilhaId,
                            'dataCriacao': DateTime.now(),
                          });
                          updatePlanilhaTotal();
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  ],
                );
              },
            );
          },
          child: Icon(Icons.add),
        ));
  }
}
