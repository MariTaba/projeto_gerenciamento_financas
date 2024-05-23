import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../controller/login_controller.dart';

class PrincipalView extends StatefulWidget {
  const PrincipalView({super.key});

  @override
  State<PrincipalView> createState() => _PrincipalViewState();
}

class _PrincipalViewState extends State<PrincipalView> {
  var txtTitulo = TextEditingController();
  var txtDescricao = TextEditingController();

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: Text('Resumo'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () {
              
            },
            icon: Icon(Icons.exit_to_app),
          )
        ],
      )
    ); 
  }
}