import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salespro_admin/Screen/WareHouse/warehouse_model.dart';
import 'package:salespro_admin/Screen/Widgets/Constant%20Data/constant.dart';

class WarehouseDropdown extends ConsumerStatefulWidget {
  final Function(WareHouseModel) onWarehouseSelected;

  const WarehouseDropdown({
    super.key,
    required this.onWarehouseSelected,
  });

  @override
  ConsumerState<WarehouseDropdown> createState() => _WarehouseDropdownState();
}

class _WarehouseDropdownState extends ConsumerState<WarehouseDropdown> {
  WareHouseModel? selectedWareHouse;
  int i = 0;

  @override
  Widget build(BuildContext context) {
    final wareHouseList = ref.watch(warehouseProvider);

    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: wareHouseList.when(
        data: (warehouses) {
          return SizedBox(
            height: 48,
            child: FormField(
              builder: (FormFieldState<dynamic> field) {
                return InputDecorator(
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.all(8.0),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    labelText: 'Warehouse',
                  ),
                  child: Theme(
                    data: ThemeData(
                      highlightColor: dropdownItemColor,
                      focusColor: dropdownItemColor,
                      hoverColor: dropdownItemColor,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<WareHouseModel>(
                        isExpanded: true,
                        items: warehouses.map((warehouse) {
                          return DropdownMenuItem(
                            value: warehouse,
                            child: SizedBox(
                              width: 110,
                              child: Text(
                                warehouse.warehouseName,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          );
                        }).toList(),
                        value: selectedWareHouse ?? warehouses.first,
                        onChanged: (value) {
                          setState(() {
                            selectedWareHouse = value;
                          });
                          widget.onWarehouseSelected(value!);
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
        error: (e, stack) => Center(child: Text(e.toString())),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}