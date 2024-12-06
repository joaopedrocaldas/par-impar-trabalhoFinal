import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:par_impar/resultado.dart';

class Aposta extends StatefulWidget {
  Function callback = () {};

  Aposta({required this.callback});

  @override
  State<Aposta> createState() => _ApostaState();
}

class _ApostaState extends State<Aposta> {
  var numero = 1.0;
  var aposta = 10.0;
  var parImpar = 0;
  TextEditingController username = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Column(
        children: [
          TextFormField(
            controller: username,
            decoration: const InputDecoration(
              label: Text('Nome do Usuário'),
              border: OutlineInputBorder(),
            ),
          ),
          Text('Aposta: ${aposta.toInt()}'),
          Slider(
            value: aposta,
            min: 10,
            max: 1000,
            divisions: 10,
            onChanged: (valor) {
              setState(() {
                aposta = valor;
              });
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Radio(
                value: 1,
                groupValue: parImpar,
                onChanged: (valor) {
                  setState(() {
                    if (valor != null) {
                      parImpar = valor;
                    }
                  });
                },
              ),
              const Text('Ímpar'),
              Radio(
                value: 2,
                groupValue: parImpar,
                onChanged: (valor) {
                  setState(() {
                    if (valor != null) {
                      parImpar = valor;
                    }
                  });
                },
              ),
              const Text('Par'),
            ],
          ),
          Text('Número: ${numero.toInt()}'),
          Slider(
              value: numero,
              min: 1,
              max: 5,
              onChanged: (valor) {
                setState(() {
                  numero = valor;
                });
              }),
          ElevatedButton(
            onPressed: () async {
              String usernameText = username.text;


              String? opponentUsername = await fetchOpponentUsername();


              await criarNovoJogador(usernameText);

              if (opponentUsername != null) {
                await efetuarJogo(usernameText, opponentUsername);
              } else {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      content: Text('Nenhum adversário disponível'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text('Fechar'),
                        ),
                      ],
                    );
                  },
                );
                widget.callback(usernameText, aposta, numero, parImpar);
              }
            },
            child: const Text('Apostar!'),
          )
        ],
      ),
    );
  }

  Future<void> criarNovoJogador(String username) async {
    var novoJogadorUrl = Uri.https('par-impar.glitch.me', 'novo');
    await http.post(
      novoJogadorUrl,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username}),
    );

    var apostaUrl = Uri.https('par-impar.glitch.me', 'aposta');
    await http.post(
      apostaUrl,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'valor': aposta,
        'parimpar': parImpar,
        'numero': numero.toInt(),
      }),
    );
  }

  Future<void> efetuarJogo(String username1, String username2) async {
    var url = Uri.https('par-impar.glitch.me', 'jogar/$username1/$username2');

    try {
      var response = await http.get(url);

      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);

        if (jsonData.containsKey('vencedor') &&
            jsonData.containsKey('perdedor')) {
          var vencedor = jsonData['vencedor'].toString(); 
          var perdedor = jsonData['perdedor'].toString(); 

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  Resultado(winner: vencedor, loser: perdedor),
            ),
          );
        } else {
          // 'vencedor' and 'perdedor' keys do not exist, handle accordingly
          if (jsonData.containsKey('mensagem')) {
            // Display a message or handle the situation in another way
            print('Message from the server: ${jsonData['mensagem']}');
          } else {
            // Handle missing keys in the response by showing a default result
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Resultado(winner: 'N/A', loser: 'N/A'),
              ),
            );
          }
        }
      } else {
        print('Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<String?> fetchOpponentUsername() async {
    try {
      var response =
          await http.get(Uri.parse('https://par-impar.glitch.me/jogadores'));

      if (response.statusCode == 200) {
        var responseBody = jsonDecode(response.body);

        if (responseBody.containsKey('jogadores') &&
            responseBody['jogadores'] is List<dynamic>) {
          var jogadoresList = responseBody['jogadores'];

          if (jogadoresList.isNotEmpty) {
            Random random = Random();
            int randomIndex = random.nextInt(jogadoresList.length);

            return jogadoresList[randomIndex]['username'];
          } else {
            return null;
          }
        } else {
          print('Error: Unexpected response format');
          return null;
        }
      } else {
        print('Error fetching players: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching players: $e');
      return null;
    }
  }

  Future<int?> fetchPlayerPoints(String username) async {
    try {
      var response = await http
          .get(Uri.parse('https://par-impar.glitch.me/pontos/$username'));

      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);
        if (jsonData.containsKey('pontos')) {
          return jsonData['pontos'];
        } else {
          print('Error: Unexpected response format');
          return null;
        }
      } else {
        print('Error fetching player points: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching player points: $e');
      return null;
    }
  }
}
