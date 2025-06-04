import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salespro_admin/Provider/customer_provider.dart';
import 'package:salespro_admin/model/customer_model.dart';



class CustomerSelectionModal extends ConsumerWidget {
  final CustomerModel? initialCustomer;
  final void Function(CustomerModel) onCustomerSelected;

  const CustomerSelectionModal({
    super.key,
    required this.initialCustomer,
    required this.onCustomerSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerList = ref.watch(allCustomerProvider);

    return customerList.when(
      data: (allCustomers) {
        List<CustomerModel> customersList = allCustomers
            .where((c) => c.type != 'Supplier')
            .toList();

        List<CustomerModel> filtered = [...customersList];
        String searchQuery = '';

        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Seleccionar Cliente',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Buscar cliente por nombre',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      searchQuery = value.toLowerCase();
                      setState(() {
                        filtered = customersList.where((customer) {
                          return customer.customerName
                              .toLowerCase()
                              .contains(searchQuery);
                        }).toList();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final customer = filtered[index];
                        return ListTile(
                          leading: const Icon(Icons.person),
                          title: Text(customer.customerName),
                          subtitle: Text(customer.phoneNumber),
                          onTap: () {
                            onCustomerSelected(customer);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      error: (e, stack) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Error: $e'),
      ),
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
