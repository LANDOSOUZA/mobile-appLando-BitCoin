import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: BitcoinApp(),
  ));
}

class BitcoinApp extends StatefulWidget {
  @override
  _BitcoinAppState createState() => _BitcoinAppState();
}
final formatador = NumberFormat.currency(locale: "pt_BR", symbol: "R\$");

class _BitcoinAppState extends State<BitcoinApp> {
  double bitcoinBRL = 0.0;
  double bitcoinUSD = 0.0;
  double bitcoinEUR = 0.0;

  bool carregando = true;

  TextEditingController valorController = TextEditingController();

  String origem = "BRL";
  String destino = "USD";

  double resultado = 0.0;

  @override
  void initState() {
    super.initState();
    buscarBitcoin();
  }

  Future<void> buscarBitcoin() async {
    setState(() => carregando = true);

    final url = Uri.parse("https://blockchain.info/ticker");
    final resposta = await http.get(url);

    if (resposta.statusCode == 200) {
      final dados = json.decode(resposta.body);

      setState(() {
        bitcoinBRL = dados["BRL"]["last"];
        bitcoinUSD = dados["USD"]["last"];
        bitcoinEUR = dados["EUR"]["last"];
        carregando = false;
      });
    } else {
      setState(() => carregando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao buscar dados")),
      );
    }
  }

  double getCotacao(String moeda) {
    switch (moeda) {
      case "BRL":
        return bitcoinBRL;
      case "USD":
        return bitcoinUSD;
      case "EUR":
        return bitcoinEUR;
      default:
        return 1.0;
    }
  }

  void converter() {
    if (carregando || bitcoinBRL == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Aguarde carregar as cotações")),
      );
      return;
    }

    double valor = double.tryParse(valorController.text) ?? 0.0;

    if (valor <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Digite um valor válido")),
      );
      return;
    }

    if (origem == destino) {
      setState(() => resultado = valor);
      return;
    }

    double cotOrigem = getCotacao(origem);
    double cotDestino = getCotacao(destino);

    setState(() {
      resultado = valor / cotOrigem * cotDestino;
    });
  }

  void limpar() {
    valorController.clear();
    setState(() {
      resultado = 0.0;
    });
  }

  Widget radioMoeda(String label, String value, bool isOrigem) {
    return Row(
      children: [
        Radio(
          value: value,
          groupValue: isOrigem ? origem : destino,
          onChanged: (v) {
            setState(() {
              if (isOrigem) {
                origem = v!;
              } else {
                destino = v!;
              }
            });
          },
        ),
        Text(label),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Consulta Bitcoin"),
        backgroundColor: Colors.orange[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            Text(
              "Preço do Bitcoin",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),

            carregando
                ? Center(child: CircularProgressIndicator())
                : Text(
                    "BTC em R\$: ${formatador.format(bitcoinBRL)}",
                    style: TextStyle(fontSize: 18),
                  ),

            SizedBox(height: 20),

            TextField(
              controller: valorController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Digite o valor a ser convertido",
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 20),

            Text("Origem", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Row(
              children: [
                radioMoeda("Real (R\$)", "BRL", true),
                radioMoeda("Dólar (\$)", "USD", true),
                radioMoeda("Euro (€)", "EUR", true),
              ],
            ),

            SizedBox(height: 10),

            Text("Destino", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Row(
              children: [
                radioMoeda("Real (R\$)", "BRL", false),
                radioMoeda("Dólar (\$)", "USD", false),
                radioMoeda("Euro (€)", "EUR", false),
              ],
            ),

            SizedBox(height: 20),

            Text(
              "Valor convertido: ${formatador.format(resultado)}",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: buscarBitcoin,
                  child: Text("Atualizar"),
                ),
                ElevatedButton(
                  onPressed: converter,
                  child: Text("Converter"),
                ),
                ElevatedButton(
                  onPressed: limpar,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: Text("Limpar"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
