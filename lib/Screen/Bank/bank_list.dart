import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../Provider/bank_provider.dart';
import '../../model/bank_model.dart';
import '../Widgets/Constant Data/constant.dart';
import 'add_bank.dart';
import 'edit_bank.dart';

class BankList extends ConsumerStatefulWidget {
  const BankList({Key? key}) : super(key: key);

  static const String route = '/bank/bank-list';

  @override
  ConsumerState<BankList> createState() => _BankListState();
}

class _BankListState extends ConsumerState<BankList> {
  String searchItem = '';

  void refresh() {
    ref.refresh(banksStreamProvider);
  }

  @override
  Widget build(BuildContext context) {
    print('DEBUG: Building BankList widget');
    final banksAsync = ref.watch(banksStreamProvider);
    
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Lista de Bancos'),
        backgroundColor: kMainColor,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: kMainColor,
              ),
              icon: const Icon(Icons.add),
              label: const Text('Agregar Banco'),
              onPressed: () {
                print('DEBUG: Botón presionado - mostrando diálogo');
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return AddBank(refresh: refresh);
                  },
                );
              },
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Barra de búsqueda
            Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: TextFormField(
                decoration: const InputDecoration(
                  hintText: 'Buscar banco...',
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    searchItem = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 20),
            // Lista de bancos
            Expanded(
              child: banksAsync.when(
                data: (banks) {
                  print('DEBUG: Bancos cargados: ${banks.length}');
                  final filteredBanks = banks.where((bank) {
                    return searchItem.isEmpty || 
                           (bank.bankName?.toLowerCase().contains(searchItem.toLowerCase()) ?? false);
                  }).toList();

                  if (filteredBanks.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.account_balance,
                            size: 100,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            searchItem.isEmpty 
                              ? 'No hay bancos registrados' 
                              : 'No se encontraron bancos',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (searchItem.isEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              'Haz clic en "Agregar Banco" para comenzar',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredBanks.length,
                    itemBuilder: (context, index) {
                      final bank = filteredBanks[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: kMainColor,
                            child: const Icon(
                              Icons.account_balance,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            bank.bankName ?? 'Sin nombre',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (bank.accountNumber?.isNotEmpty ?? false)
                                Text('Cuenta: ${bank.accountNumber}'),
                              if (bank.accountHolder?.isNotEmpty ?? false)
                                Text('Titular: ${bank.accountHolder}'),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'edit') {
                                showDialog(
                                  context: context,
                                  builder: (context) => EditBank(
                                    bank: bank,
                                    refresh: refresh,
                                  ),
                                );
                              } else if (value == 'delete') {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Confirmar eliminación'),
                                    content: Text('¿Está seguro de eliminar el banco ${bank.bankName}?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(false),
                                        child: const Text('Cancelar'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(true),
                                        child: const Text(
                                          'Eliminar',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  try {
                                    EasyLoading.show(status: 'Eliminando banco...');
                                    await ref.read(bankNotifierProvider.notifier)
                                        .deleteBank(bank.bankId!);
                                    EasyLoading.showSuccess('Banco eliminado');
                                  } catch (e) {
                                    EasyLoading.showError('Error al eliminar');
                                  }
                                }
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 20),
                                    SizedBox(width: 8),
                                    Text('Editar'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, size: 20, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Eliminar', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) {
                  print('ERROR: $error');
                  print('STACK: $stack');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 60,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Error al cargar bancos',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: refresh,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}