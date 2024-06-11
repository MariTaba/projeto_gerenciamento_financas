// ignore_for_file: prefer_const_constructors

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PrincipalView extends StatefulWidget {
  const PrincipalView({Key? key}) : super(key: key);

  @override
  _PrincipalViewState createState() => _PrincipalViewState();
}

class _PrincipalViewState extends State<PrincipalView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  double calcularTotal(List<DocumentSnapshot> planilhas) {
    return planilhas.fold(0, (prev, doc) => prev + doc['valorTotal']);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Planilhas'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              Navigator.pushNamed(context, 'busca');
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('planilhas')
            .where('uid', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Text('Algo deu errado');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Text("Carregando");
          }

          if (snapshot.data != null) {
            List<DocumentSnapshot> planilhasEntrada = [];
            List<DocumentSnapshot> planilhasSaida = [];

            for (var doc in snapshot.data!.docs) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              if (data['tipoPlanilha'] == 'E') {
                planilhasEntrada.add(doc);
              } else if (data['tipoPlanilha'] == 'S') {
                planilhasSaida.add(doc);
              }
            }

            double totalEntrada = calcularTotal(planilhasEntrada);
            double totalSaida = calcularTotal(planilhasSaida);
            double saldo = totalEntrada - totalSaida;

            return ListView(
    children: <Widget>[
      Text('Saldo Calculado: R\$ ${saldo.toStringAsFixed(2)}',
          style: TextStyle(fontSize: 24, color: saldo >= 0 ? Colors.green : Colors.red)),
      Text('Entradas: R\$ ${totalEntrada.toStringAsFixed(2)}',
          style: TextStyle(fontSize: 24, color: Colors.green[800])),
      ...planilhasEntrada.map((planilha) => Container(
            color: Colors.green.withOpacity(0.4),
            child: buildListTile(planilha, 'Saldo Total:', context),
          )),
      Text('Saídas: R\$ ${(totalSaida * -1).toStringAsFixed(2)}',
          style: TextStyle(fontSize: 24, color: Colors.red[800])),
      ...planilhasSaida.map((planilha) => Container(
            color: Colors.red.withOpacity(0.4),
            child: buildListTile(
                planilha, 'Valor do próximo vencimento:', context),
          )),
    ],
  );
} else {
  return Text('Nenhuma planilha encontrada');
}
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              TextEditingController planilhaNomeController =
                  TextEditingController();
              String? tipoPlanilha;
              return StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return AlertDialog(
                    title: Text('Criar nova planilha'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: planilhaNomeController,
                          decoration:
                              InputDecoration(hintText: "Nome da planilha"),
                        ),
                        ListTile(
                          title: const Text('Saída'),
                          leading: Radio<String>(
                            value: 'S',
                            groupValue: tipoPlanilha,
                            onChanged: (String? value) {
                              setState(() {
                                tipoPlanilha = value;
                              });
                            },
                          ),
                        ),
                        ListTile(
                          title: const Text('Entrada'),
                          leading: Radio<String>(
                            value: 'E',
                            groupValue: tipoPlanilha,
                            onChanged: (String? value) {
                              setState(() {
                                tipoPlanilha = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: Text('Cancelar'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                        child: Text('Criar'),
                        onPressed: () async {
                          User? user = FirebaseAuth.instance.currentUser;
                          if (user != null && tipoPlanilha != null) {
                            String userUID = user.uid;
                            await FirebaseFirestore.instance
                                .collection('planilhas')
                                .add({
                              'nome': planilhaNomeController.text,
                              'uid': userUID,
                              'tipoPlanilha': tipoPlanilha,
                              'valorTotal': 0.0,
                            });
                          }
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Widget buildListTile(
      DocumentSnapshot planilha, String title, BuildContext context) {
    Map<String, dynamic> data = planilha.data() as Map<String, dynamic>;
    double valorTotal = 0.0;
    if (data['valorTotal'] != null) {
      valorTotal = data['valorTotal'] is double
          ? data['valorTotal']
          : double.parse(data['valorTotal'].toString());
    }
    if (data['tipoPlanilha'] == 'S') {
      valorTotal *= -1;
    }
    return ListTile(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(data['nome'] ?? 'Sem nome'),
          Text('$title ${valorTotal.toStringAsFixed(2)}'),
        ],
      ),
      onTap: () {
        if (data['tipoPlanilha'] == 'S') {
          Navigator.of(context).pushNamed(
            'planilha',
            arguments: {'planilhaId': planilha.id},
          );
        } else if (data['tipoPlanilha'] == 'E') {
          Navigator.of(context).pushNamed(
            'entradas',
            arguments: {'planilhaId': planilha.id},
          );
        }
      },
      onLongPress: () {
        showDialog(
          context: context,
          builder: (context) {
            TextEditingController planilhaNomeController =
                TextEditingController();
            return AlertDialog(
              title: Text('Renomear ou Excluir'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Você deseja renomear ou excluir a planilha?'),
                  TextField(
                    controller: planilhaNomeController,
                    decoration:
                        InputDecoration(hintText: "Novo nome da planilha"),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Renomear'),
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('planilhas')
                        .doc(planilha.id)
                        .update({'nome': planilhaNomeController.text});
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('Excluir'),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text('Confirmação'),
                          content: Text(
                              'Você tem certeza que deseja excluir esta planilha?'),
                          actions: <Widget>[
                            TextButton(
                              child: Text('Cancelar'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                            TextButton(
                              child: Text('Confirmar'),
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection('planilhas')
                                    .doc(planilha.id)
                                    .delete();
                                Navigator.of(context).pop();
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
    );
  }
}
