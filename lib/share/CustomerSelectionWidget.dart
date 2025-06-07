import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show
        CircularProgressIndicator,
        Colors,
        DropdownButton,
        DropdownButtonHideUnderline,
        DropdownMenuItem;
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/model/customer_model.dart';
import '../Provider/customer_provider.dart' show allCustomerProvider;
import '../Screen/Widgets/Constant Data/constant.dart'
    show kBlueTextColor, kNeutral400, kTextStyle, kTitleColor;

class CustomerSelectionWidget extends ConsumerWidget {
  final String? selectedUserId;
  final CustomerModel selectedUserName;
  final String previousDue;
  final String selectedCustomerType;
  final Function(String?) onCustomerChanged;
  final Function(String) onCustomerTypeChanged;

  const CustomerSelectionWidget({
    super.key,
    required this.selectedUserId,
    required this.selectedUserName,
    required this.previousDue,
    required this.selectedCustomerType,
    required this.onCustomerChanged,
    required this.onCustomerTypeChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerList = ref.watch(allCustomerProvider);

    return customerList.when(
      data: (allCustomers) {
        List<String> listOfPhoneNumber = [];
        List<CustomerModel> customersList = [];

        for (var value1 in allCustomers) {
          listOfPhoneNumber
              .add(value1.phoneNumber.removeAllWhiteSpace().toLowerCase());
          if (value1.type != 'Supplier') {
            customersList.add(value1);
          }
        }

        return ResponsiveGridRow(children: [
          ResponsiveGridCol(
            xs: 120,
            md: 40,
            lg: 48,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Flexible(
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(5),
                            bottomLeft: Radius.circular(5)),
                        border: Border.all(color: kNeutral400),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: _buildCustomerDropdown(customersList),
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
                            bottomRight: Radius.circular(5)),
                        color: kBlueTextColor,
                      ),
                      child: const Center(
                        child: Icon(
                          FeatherIcons.userPlus,
                          size: 18.0,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          ResponsiveGridCol(
            xs: 120,
            md: 40,
            lg: 24,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: kNeutral400),
                ),
                child: DropdownButtonHideUnderline(
                  child: _buildCustomerTypeDropdown(),
                ),
              ),
            ),
          ),
        ]);
      },
      error: (e, stack) => Center(child: Text(e.toString())),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }

  DropdownButton<String> _buildCustomerDropdown(List<CustomerModel> model) {
    List<DropdownMenuItem<String>> dropDownItems = [
      const DropdownMenuItem(value: 'Guest', child: Text('Guest'))
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
      onChanged: onCustomerChanged,
    );
  }

  DropdownButton<String> _buildCustomerTypeDropdown() {
    List<DropdownMenuItem<String>> dropDownItems = [];
    for (String des in ['Regular', 'Frecuente', 'Corporativo']) {
      var item = DropdownMenuItem(
        value: des,
        child: Text(
          des,
          style: kTextStyle.copyWith(
              overflow: TextOverflow.ellipsis, color: kTitleColor),
        ),
      );
      dropDownItems.add(item);
    }

    return DropdownButton(
      items: dropDownItems,
      value: selectedCustomerType,
      onChanged: (value) => onCustomerTypeChanged(value!),
    );
  }
}
