// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../controller/login_controller.dart';

int lstindex = 0;

class PrincipalView extends StatefulWidget {
  const PrincipalView({super.key});

  @override
  State<PrincipalView> createState() => _PrincipalViewState();
}

class _PrincipalViewState extends State<PrincipalView> {
  List<String> shoppingLists = ['Planilha 1'];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        bottomNavigationBar: BottomNavigationBar(
          onTap: (index) {
            switch (index) {
              case 0:
                setState(() {
                  shoppingLists.add('Nova planilha');
                  Navigator.pushNamed(
                    context,
                    'planilha',
                    arguments: shoppingLists.last,
                  );
                });
                break;
              case 1:
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Sobre'),
                      content: Text(
                          'trabalho desgraçado de mpct, podia sumir e eu nã sentiria falta\n V C  D I S S E  B O T ?'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text('Close'),
                        ),
                      ],
                    );
                  },
                );
                break;
              default:
                break;
            }
          },
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.add),
              label: 'Criar Planilha',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.info_outline),
              label: 'Sobre',
            ),
          ],
        ),
        body: Padding(
          padding: EdgeInsets.all(20),
          child: ListView.builder(
              itemCount: shoppingLists.length,
              itemBuilder: (context, index) {
                return Card(
                  child: ListTile(
                    title: Text(shoppingLists[index]),
                    onTap: () {
                      lstindex = index;
                      Navigator.pushNamed(context, 'planilha',
                          arguments: shoppingLists[index]);
                    },
                    onLongPress: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          TextEditingController listNameController =
                              TextEditingController(text: shoppingLists[index]);
                          return AlertDialog(
                            content: TextField(
                              controller: listNameController,
                              decoration:
                                  InputDecoration(hintText: 'Novo nome'),
                            ),
                            actions: [
                              TextButton(
                                child: Text('Salvar'),
                                onPressed: () {
                                  setState(() {
                                    shoppingLists[index] =
                                        listNameController.text;
                                  });
                                  Navigator.of(context).pop();
                                },
                              ),
                              TextButton(
                                child: Text('Deletar planilha'),
                                onPressed: () {
                                  setState(() {
                                    shoppingLists.removeAt(index);
                                  });
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                );
              }),
        ));
  }
}
