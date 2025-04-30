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

  DropdownButton<String> getResult(List<CustomerModel> model) {
    List<DropdownMenuItem<String>> dropDownItems = [
      const DropdownMenuItem(
        value: 'Guest',
        child: Text('Guest'),
      )
    ];

    for (var des in model) {
      var item = DropdownMenuItem(
        value: des.phoneNumber,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text('${des.customerName} ${des.phoneNumber}'),
        ),
      );
      dropDownItems.add(item);
    }

    return DropdownButton(
      items: dropDownItems,
      isExpanded: true,
      value: selectedUserId,
      onChanged: (value) {
        setState(() {
          selectedUserId = value!;
          for (var element in model) {
            if (element.phoneNumber == selectedUserId) {
              selectedUserName = element;
              widget.onCustomerSelected(element);
            } else if (selectedUserId == 'Guest') {
              selectedUserName = CustomerModel(customerName: "Guest", phoneNumber: "00", type: "Guest", customerAddress: '', emailAddress: '', profilePicture: '', openingBalance: '0', remainedBalance: '0', dueAmount: '0', gst: '', receiveWhatsappUpdates: false);
            }
          }
        });
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

        for (var value1 in allCustomers) {
          listOfPhoneNumber.add(value1.phoneNumber.removeAllWhiteSpace().toLowerCase());
          if (value1.type != 'Supplier') {
            customersList.add(value1);
          }
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Flexible(
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(5),
                    bottomLeft: Radius.circular(5),
                  ),
                  border: Border.all(color: Colors.grey),
                ),
                child: DropdownButtonHideUnderline(
                  child: getResult(customersList),
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