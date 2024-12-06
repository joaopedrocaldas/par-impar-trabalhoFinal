import 'package:flutter/material.dart';
import 'package:par_impar/tela_principal.dart';

void main() {
  runApp(_Inicio());
}

class _Inicio extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: "Par ou Impar",
        home: Scaffold(
          body: TelaPrincipal(),
        ));
  }
}
