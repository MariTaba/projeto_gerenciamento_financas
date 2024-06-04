import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PlanilhaView extends StatefulWidget {
  final String planilhaId;

  PlanilhaView({required this.planilhaId});

  @override
  _PlanilhaViewState createState() => _PlanilhaViewState();
}

class _PlanilhaViewState extends State<PlanilhaView> {
  final nomeController = TextEditingController();
  final descricaoController = TextEditingController();
  final valorTotalController = TextEditingController();
  final numeroParcelasController = TextEditingController();
  final parcelaInicialController = TextEditingController();

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
                      decoration: InputDecoration(labelText: 'Nome'),
                    ),
                    TextField(
                      controller: descricaoController,
                      decoration: InputDecoration(labelText: 'Descrição'),
                    ),
                    TextField(
                      controller: valorTotalController,
                      decoration: InputDecoration(labelText: 'Valor Total'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: numeroParcelasController,
                      decoration:
                          InputDecoration(labelText: 'Número de Parcelas'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: parcelaInicialController,
                      decoration: InputDecoration(labelText: 'Parcela Inicial'),
                      keyboardType: TextInputType.number,
                    ),
                    TextButton(
                      onPressed: addItem,
                      child: Text('Adicionar Item'),
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
    );
  }

  void addItem() {
    // Adicione a lógica para adicionar o item aqui
  }
}
