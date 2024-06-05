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
  final parcelaInicialController = TextEditingController();

  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                content: Column(
                  children: [
                    TextField(
                      controller: nomeController,
                      decoration: const InputDecoration(labelText: 'Nome'),
                    ),
                    TextField(
                      controller: descricaoController,
                      decoration: const InputDecoration(labelText: 'Descrição'),
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
                          labelText: 'Número de Parcelas'),
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: false),
                      onChanged: (value) {
                        if (int.parse(parcelaInicialController.text) >
                            int.parse(value)) {
                          parcelaInicialController.text = value;
                        }
                      },
                    ),
                    TextField(
                      controller: parcelaInicialController,
                      decoration:
                          const InputDecoration(labelText: 'Parcela Inicial'),
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: false),
                      onChanged: (value) {
                        if (int.parse(value) >
                            int.parse(numeroParcelasController.text)) {
                          parcelaInicialController.text =
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
              );
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
                              // implementar a lógica de edição aqui
                              Navigator.of(context).pop();
                            },
                          ),
                          TextButton(
                            child: Text('Deletar'),
                            onPressed: () async {
                              await document.reference.delete();
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
                child: ListTile(
                  title: Text(data['nome']),
                  subtitle: Text(data['descricao']),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  void addItem() async {
    await firestore.collection('itens').add({
      'uid': FirebaseAuth.instance.currentUser!.uid,
      'planilhaId': widget.planilhaId,
      'nome': nomeController.text,
      'descricao': descricaoController.text,
      'valorTotal': double.parse(valorTotalController.text),
      'numeroParcelas': int.parse(numeroParcelasController.text),
      'parcelaInicial': int.parse(parcelaInicialController.text),
    });
    Navigator.pop(context);
  }
}
