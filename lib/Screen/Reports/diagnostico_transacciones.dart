import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:salespro_admin/const.dart';
import 'package:salespro_admin/model/daily_transaction_model.dart';

class DiagnosticoTransaccionesDiarias extends StatefulWidget {
  const DiagnosticoTransaccionesDiarias({super.key});

  @override
  State<DiagnosticoTransaccionesDiarias> createState() => _DiagnosticoTransaccionesDiariasState();
}

class _DiagnosticoTransaccionesDiariasState extends State<DiagnosticoTransaccionesDiarias> {
  bool isLoading = true;
  String errorMessage = '';
  List<Map<String, dynamic>> rawData = [];
  List<DailyTransactionModel> parsedData = [];
  
  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    
    try {
      // Intenta obtener datos directamente de Firebase
      final userId = await getUserID();
      final snapshot = await FirebaseDatabase.instance.ref(userId).child('Daily Transaction').orderByKey().get();
      
      List<Map<String, dynamic>> tempRawData = [];
      List<DailyTransactionModel> tempParsedData = [];
      
      if (snapshot.exists) {
        for (var element in snapshot.children) {
          // Guardar datos sin procesar
          Map<String, dynamic> rawJson = Map<String, dynamic>.from(jsonDecode(jsonEncode(element.value)));
          tempRawData.add(rawJson);
          
          // Intentar parsear a modelo
          try {
            DailyTransactionModel model = DailyTransactionModel.fromJson(rawJson);
            tempParsedData.add(model);
          } catch (parseError) {
            print('Error al parsear transacción: $parseError');
            // Continuar con la siguiente transacción
          }
        }
      }
      
      setState(() {
        rawData = tempRawData;
        parsedData = tempParsedData;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error al cargar datos: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Diagnóstico de Transacciones Diarias'),
      ),
      body: isLoading 
          ? Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage, style: TextStyle(color: Colors.red)))
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total de transacciones encontradas: ${rawData.length}', 
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text('Transacciones parseadas correctamente: ${parsedData.length}',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 16),
                      
                      if (rawData.isEmpty)
                        Text('No se encontraron transacciones en la base de datos.',
                            style: TextStyle(color: Colors.red, fontSize: 16))
                      else
                        ...rawData.take(10).map((data) => _buildTransactionCard(data)),
                      
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _cargarDatos,
                        child: Text('Recargar datos'),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> data) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${data['id'] ?? 'No disponible'}', 
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Nombre: ${data['name'] ?? 'No disponible'}'),
            Text('Tipo: ${data['type'] ?? 'No disponible'}'),
            Text('Fecha: ${data['date'] ?? 'No disponible'}'),
            Text('Total: ${data['total'] ?? 'No disponible'}'),
            Text('Entrada: ${data['paymentIn'] ?? 'No disponible'}'),
            Text('Salida: ${data['paymentOut'] ?? 'No disponible'}'),
            Text('Balance: ${data['remainingBalance'] ?? 'No disponible'}'),
            
            SizedBox(height: 8),
            Text('Datos completos:', style: TextStyle(fontWeight: FontWeight.bold)),
            Container(
              padding: EdgeInsets.all(8),
              color: Colors.grey.shade200,
              width: double.infinity,
              child: Text(
                JsonEncoder.withIndent('  ').convert(data),
                style: TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
