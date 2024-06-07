// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class PlanilhaView extends StatefulWidget {
  final String planilhaId;

  const PlanilhaView({Key? key, required this.planilhaId}) : super(key: key);

  @override
  _PlanilhaViewState createState() => _PlanilhaViewState();
}

class _PlanilhaViewState extends State<PlanilhaView> {
  final nomeController = TextEditingController();
  final descricaoController = TextEditingController();
  final valorTotalController = TextEditingController();
  final numeroParcelasController = TextEditingController();
  final parcelaAtualController = TextEditingController();

  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  Future<String> fetchPlanilhaNome() async {
    DocumentSnapshot doc =
        await firestore.collection('planilhas').doc(widget.planilhaId).get();
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return data['nome'] ?? '';
  }

  Future<double> fetchValorTotal() async {
    DocumentSnapshot doc =
        await firestore.collection('planilhas').doc(widget.planilhaId).get();
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    if (data.containsKey('valorTotal') && data['valorTotal'] != null) {
      return double.parse(data['valorTotal'].toString());
    } else {
      return 0.0;
    }
  }

  Future<double> calculateRemainingValue() async {
    QuerySnapshot querySnapshot = await firestore
        .collection('itens')
        .where('planilhaId', isEqualTo: widget.planilhaId)
        .get();
    double total = 0.0;
    for (var doc in querySnapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      double valorRestante = ((data['valorTotal'] / data['numeroParcelas']) *
          (data['numeroParcelas'] - data['parcelaAtual']));
      total += valorRestante;
    }
    return total;
  }

  Future<void> updateValorRestante() async {
    double valorRestante = await calculateRemainingValue();
    await firestore
        .collection('planilhas')
        .doc(widget.planilhaId)
        .update({'valorRestante': valorRestante});
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
                          'Valor Total dos Vencimentos: R\$ ${(snapshot.data ?? 0).toStringAsFixed(2)}'),
                    );
                  } else if (snapshot.connectionState == ConnectionState.none) {
                    return Text("No data");
                  }
                  return CircularProgressIndicator();
                },
              ),
              FutureBuilder<double>(
                future: calculateRemainingValue(),
                builder:
                    (BuildContext context, AsyncSnapshot<double> snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                          'Valor Restante nas Proximas Faturas: ${snapshot.data?.toStringAsFixed(2) ?? '0'}'),
                    );
                  } else if (snapshot.connectionState == ConnectionState.none) {
                    return Text("No data");
                  }
                  return CircularProgressIndicator();
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                  title: Text("Adicionar Item"),
                  content: SingleChildScrollView(
                    child: ListBody(
                      children: <Widget>[
                        TextField(
                          controller: nomeController,
                          decoration: const InputDecoration(labelText: 'Nome'),
                        ),
                        TextField(
                          controller: descricaoController,
                          decoration:
                              const InputDecoration(labelText: 'Descrição'),
                        ),
                        TextField(
                          controller: valorTotalController,
                          decoration:
                              const InputDecoration(labelText: 'Valor Total'),
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                        ),
                        TextField(
                          controller: numeroParcelasController,
                          decoration: const InputDecoration(
                              labelText: 'Número total de Parcelas'),
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: false),
                          onChanged: (value) {
                            if (int.parse(parcelaAtualController.text) >
                                int.parse(value)) {
                              parcelaAtualController.text = value;
                            }
                          },
                        ),
                        TextField(
                          controller: parcelaAtualController,
                          decoration:
                              const InputDecoration(labelText: 'Parcela atual'),
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: false),
                          onChanged: (value) {
                            if (int.parse(value) >
                                int.parse(numeroParcelasController.text)) {
                              parcelaAtualController.text =
                                  numeroParcelasController.text;
                            }
                          },
                        ),
                        TextButton(
                          onPressed: addItem,
                          child: const Text('Adicionar Item'),
                        ),
                      ],
                    ),
                  ));
            },
          );
        },
        child: Icon(Icons.add),
        tooltip: 'Adicionar Item',
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection('itens')
            .where('uid', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
            .where('planilhaId', isEqualTo: widget.planilhaId)
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
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
              double valorTotal = data['valorTotal'];
              int numeroParcelas = data['numeroParcelas'];
              int parcelaAtual = data['parcelaAtual'];
              double valorRestante = (valorTotal / numeroParcelas) *
                  (numeroParcelas - parcelaAtual);
              return GestureDetector(
                onLongPress: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Editar ou Deletar'),
                        content:
                            Text('Você deseja editar ou deletar este item?'),
                        actions: [
                          TextButton(
                            child: Text('Editar'),
                            onPressed: () {
                              Navigator.of(context).pop();

                              nomeController.text = data['nome'];
                              descricaoController.text = data['descricao'];
                              valorTotalController.text =
                                  data['valorTotal'].toString();
                              numeroParcelasController.text =
                                  data['numeroParcelas'].toString();
                              parcelaAtualController.text =
                                  data['parcelaAtual'].toString();

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
                                            controller: valorTotalController,
                                            decoration: const InputDecoration(
                                                labelText: 'Valor Total'),
                                            keyboardType:
                                                TextInputType.numberWithOptions(
                                                    decimal: true),
                                            inputFormatters: [
                                              FilteringTextInputFormatter.allow(
                                                  RegExp(r'^\d+\.?\d{0,2}')),
                                            ],
                                          ),
                                          TextField(
                                            controller:
                                                numeroParcelasController,
                                            decoration: const InputDecoration(
                                                labelText:
                                                    'Número total de Parcelas'),
                                            keyboardType:
                                                TextInputType.numberWithOptions(
                                                    decimal: false),
                                            onChanged: (value) {
                                              if (int.parse(
                                                      parcelaAtualController
                                                          .text) >
                                                  int.parse(value)) {
                                                parcelaAtualController.text =
                                                    value;
                                              }
                                            },
                                          ),
                                          TextField(
                                            controller: parcelaAtualController,
                                            decoration: const InputDecoration(
                                                labelText: 'Parcela atual'),
                                            keyboardType:
                                                TextInputType.numberWithOptions(
                                                    decimal: false),
                                            onChanged: (value) {
                                              if (int.parse(value) >
                                                  int.parse(
                                                      numeroParcelasController
                                                          .text)) {
                                                parcelaAtualController.text =
                                                    numeroParcelasController
                                                        .text;
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    actions: <Widget>[
                                      TextButton(
                                        child: Text('Salvar'),
                                        onPressed: () async {
                                          double valorTotal = double.parse(
                                              valorTotalController.text);
                                          int numeroParcelas = int.parse(
                                              numeroParcelasController.text);
                                          double valorParcial =
                                              valorTotal / numeroParcelas;
                                          await document.reference.update({
                                            'nome': nomeController.text,
                                            'descricao':
                                                descricaoController.text,
                                            'valorTotal': valorTotal,
                                            'numeroParcelas': numeroParcelas,
                                            'parcelaAtual': int.parse(
                                                parcelaAtualController.text),
                                            'valorParcial': valorParcial,
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
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          '${data['descricao']} - Valor Total: ${valorTotal.toStringAsFixed(2)} - Valor neste vencimento: ${data['valorParcial'].toStringAsFixed(2)}'),
                      Text(
                          'Parcela: ${parcelaAtual.toString()} de ${numeroParcelas.toString()}'),
                      Text(
                          'Valor restante nas proximas faturas : ${valorRestante.toStringAsFixed(2)}'),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  void addItem() async {
    double valorTotal = double.parse(valorTotalController.text);
    int numeroParcelas = int.parse(numeroParcelasController.text);
    double valorParcial = valorTotal / numeroParcelas;

    await firestore.collection('itens').add({
      'uid': FirebaseAuth.instance.currentUser!.uid,
      'planilhaId': widget.planilhaId,
      'nome': nomeController.text,
      'descricao': descricaoController.text,
      'valorTotal': valorTotal,
      'numeroParcelas': numeroParcelas,
      'parcelaAtual': int.parse(parcelaAtualController.text),
      'valorParcial': valorParcial,
      'dataCriacao': DateTime.now(),
      'buscaNome': nomeController.text.toLowerCase(),
      'buscaDescricao': descricaoController.text.toLowerCase(),
    });
    updatePlanilhaValorRestante();
    updatePlanilhaTotal();
    Navigator.pop(context);
  }

  void updatePlanilhaTotal() async {
    QuerySnapshot querySnapshot = await firestore
        .collection('itens')
        .where('planilhaId', isEqualTo: widget.planilhaId)
        .get();
    double total = 0.0;
    for (var doc in querySnapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      total += data['valorParcial'];
    }
    await firestore.collection('planilhas').doc(widget.planilhaId).update({
      'valorTotal': total,
    });
    updatePlanilhaValorRestante();
  }

  void updatePlanilhaValorRestante() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('itens')
        .where('planilhaId', isEqualTo: widget.planilhaId)
        .get();
    double total = 0.0;
    for (var doc in querySnapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      double valorRestante = ((data['valorTotal'] / data['numeroParcelas']) *
          (data['numeroParcelas'] - data['parcelaAtual']));
      total += valorRestante;
    }
    await FirebaseFirestore.instance
        .collection('planilhas')
        .doc(widget.planilhaId)
        .update({'valorRestante': total});
  }
}
