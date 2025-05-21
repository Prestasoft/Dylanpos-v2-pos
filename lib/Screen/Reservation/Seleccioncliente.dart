import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:salespro_admin/model/customer_model.dart';
import 'package:salespro_admin/Provider/customer_provider.dart';

class CustomerSelector extends ConsumerStatefulWidget {
  final Function(CustomerModel) onCustomerSelected;
  final String? initialCustomerId;
  final CustomerModel? initialCustomer;

  const CustomerSelector({
    Key? key,
    required this.onCustomerSelected,
    this.initialCustomerId,
    this.initialCustomer,
  }) : super(key: key);

  @override
  ConsumerState<CustomerSelector> createState() => _CustomerSelectorState();
}

class _CustomerSelectorState extends ConsumerState<CustomerSelector> {
  String? selectedUserId;
  CustomerModel selectedUserName = CustomerModel(
    customerName: "Guest",
    phoneNumber: "00",
    type: "Guest",
    customerAddress: '',
    emailAddress: '',
    profilePicture: '',
    openingBalance: '0',
    remainedBalance: '0',
    dueAmount: '0',
    gst: '',
    receiveWhatsappUpdates: false,
  );

  @override
  void initState() {
    super.initState();
    if (widget.initialCustomer != null) {
      selectedUserId = widget.initialCustomer?.phoneNumber;
      selectedUserName = widget.initialCustomer!;
    } else {
      selectedUserId = widget.initialCustomerId ?? 'Guest';
    }
  }

  void _openCustomerSearchDialog(List<CustomerModel> customers) {
    showDialog(
      context: context,
      builder: (context) {
        String searchQuery = '';
        List<CustomerModel> filtered = [
          ...customers
        ];

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: const Text('Seleccionar Cliente'),
              content: SizedBox(
                width: 400,
                height: 500,
                child: Column(
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Buscar cliente por nombre',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        searchQuery = value.toLowerCase();
                        setDialogState(() {
                          final filteredCustomers = customers.where((customer) {
                            return customer.customerName
                                .toLowerCase()
                                .contains(searchQuery);
                          }).toList();

                          // Mostrar Guest solo si la búsqueda está vacía
                          if (searchQuery.isEmpty) {
                            filtered = [
                              ...filteredCustomers,
                            ];
                          } else {
                            filtered = filteredCustomers;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final customer = filtered[index];
                          return ListTile(
                            leading: const Icon(Icons.person),
                            title: Text(customer.customerName),
                            subtitle: Text(customer.phoneNumber),
                            onTap: () {
                              setState(() {
                                selectedUserId = customer.phoneNumber;
                                selectedUserName = customer;
                              });
                              widget.onCustomerSelected(customer);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final customerList = ref.watch(allCustomerProvider);

    return customerList.when(
      data: (allCustomers) {
        List<String> listOfPhoneNumber = [];
        List<CustomerModel> customersList = [];

        for (var value in allCustomers) {
          listOfPhoneNumber
              .add(value.phoneNumber.removeAllWhiteSpace().toLowerCase());
          if (value.type != 'Supplier') {
            customersList.add(value);
          }
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Flexible(
              child: GestureDetector(
                onTap: () {
                  _openCustomerSearchDialog(customersList);
                },
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(5),
                      bottomLeft: Radius.circular(5),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          selectedUserName.customerName != 'Guest'
                              ? '${selectedUserName.customerName} (${selectedUserName.phoneNumber})'
                              : 'Guest',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                context.push(
                  '/add-customer',
                  extra: {
                    'typeOfCustomerAdd': 'Buyer',
                    'listOfPhoneNumber': listOfPhoneNumber,
                  },
                );
              },
              child: Container(
                height: 40,
                width: 40,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(5),
                    bottomRight: Radius.circular(5),
                  ),
                  color: Colors.blue,
                ),
                child: const Center(
                  child: Icon(
                    Icons.person_add,
                    size: 18.0,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );
      },
      error: (e, stack) => Text('Error: $e'),
      loading: () => const CircularProgressIndicator(),
    );
  }
}
