// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/commas.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;

import '../../Provider/areas_equipments_provider.dart';
import '../../model/admin_panel_models.dart';
import '../Widgets/Constant Data/constant.dart';
import '../Widgets/noDataFound.dart';

class AreasEquipmentsScreen extends ConsumerStatefulWidget {
  const AreasEquipmentsScreen({super.key});

  @override
  ConsumerState<AreasEquipmentsScreen> createState() =>
      _AreasEquipmentsScreenState();
}

class _AreasEquipmentsScreenState extends ConsumerState<AreasEquipmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _itemsPerPage = 10;
  int _currentPage = 1;
  String _searchQuery = '';
  String? _selectedState;
  final ScrollController _horizontalScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _horizontalScroll.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: kDarkWhite,
      body: Scrollbar(
        controller: _horizontalScroll,
        child: SingleChildScrollView(
          controller: _horizontalScroll,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    color: kWhite,
                  ),
                  child: Column(
                    children: [
                      TabBar(
                        controller: _tabController,
                        labelColor: kMainColor,
                        unselectedLabelColor: kGreyTextColor,
                        indicatorColor: kMainColor,
                        labelStyle: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                        tabs: [
                          Tab(
                              icon: const Icon(Icons.map),
                              text: lang.S.of(context).areas),
                          Tab(
                              icon: const Icon(Icons.devices_other),
                              text: lang.S.of(context).equipments),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    color: kWhite,
                  ),
                  child: Row(
                    children: [
                      // Dropdown cantidad
                      Container(
                        width: 150,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(color: kThemeOutlineColor),
                        ),
                        child: DropdownButton<int>(
                          isExpanded: true,
                          underline: const SizedBox(),
                          value: _itemsPerPage,
                          icon: const Icon(Icons.keyboard_arrow_down),
                          items: [
                            DropdownMenuItem(
                                value: 10,
                                child: Text('${lang.S.of(context).show} 10')),
                            DropdownMenuItem(
                                value: 20,
                                child: Text('${lang.S.of(context).show} 20')),
                            DropdownMenuItem(
                                value: 50,
                                child: Text('${lang.S.of(context).show} 50')),
                            DropdownMenuItem(
                                value: 100,
                                child: Text('${lang.S.of(context).show} 100')),
                            DropdownMenuItem(
                                value: -1, child: Text(lang.S.of(context).all)),
                          ],
                          onChanged: (int? newValue) {
                            setState(() {
                              _itemsPerPage = newValue ?? 10;
                              _currentPage = 1;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Campo búsqueda
                      Expanded(
                        child: TextFormField(
                          showCursor: true,
                          cursorColor: kTitleColor,
                          onChanged: (value) =>
                              setState(() => _searchQuery = value),
                          keyboardType: TextInputType.name,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.all(10.0),
                            hintText: lang.S.of(context).searchByName,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide(color: kThemeOutlineColor),
                            ),
                            suffixIcon: const Icon(FeatherIcons.search,
                                color: kTitleColor),
                          ),
                        ),
                      ),

                      // Filtro por estado SOLO si está en tab Equipos
                      if (_tabController.index == 1) ...[
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 180,
                          child: DropdownButtonFormField<String>(
                            value: _selectedState,
                            isExpanded: true,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.all(10.0),
                              hintText: 'Filtrar por estado',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide:
                                    BorderSide(color: kThemeOutlineColor),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: null, child: Text('Todos')),
                              DropdownMenuItem(
                                  value: 'Disponible',
                                  child: Text('Disponible')),
                              DropdownMenuItem(
                                  value: 'Averiado', child: Text('Averiado')),
                              DropdownMenuItem(
                                  value: 'Dañado', child: Text('Dañado')),
                            ],
                            onChanged: (value) => setState(() {
                              _selectedState = value;
                              _currentPage = 1;
                            }),
                          ),
                        ),
                      ],

                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () => _tabController.index == 0
                            ? _showAreaDialog()
                            : _showEquipmentDialog(),
                        icon: const Icon(Icons.add),
                        label: Text(lang.S.of(context).addNew),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kMainColor,
                          minimumSize: const Size(150, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    color: kWhite,
                  ),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildAreasTab(theme, screenWidth),
                        _buildEquipmentsTab(theme, screenWidth),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAreasTab(ThemeData theme, double screenWidth) {
    final areasAsync = ref.watch(areasProvider);
    final equipmentsAsync = ref.watch(equipmentsProvider);

    return areasAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (areas) {
        return equipmentsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(e.toString())),
          data: (equipments) {
            final areaCounts = <String, int>{};
            for (var equipment in equipments) {
              areaCounts.update(equipment.areaId, (value) => value + 1,
                  ifAbsent: () => 1);
            }

            final filtered = areas
                .where((a) =>
                    a.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    a.description
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase()))
                .toList();

            final totalPages = (_itemsPerPage == -1)
                ? 1
                : (filtered.length / _itemsPerPage).ceil();
            final startIndex = (_currentPage - 1) * _itemsPerPage;
            final endIndex = _itemsPerPage == -1
                ? filtered.length
                : (startIndex + _itemsPerPage).clamp(0, filtered.length);
            final paginated = filtered.sublist(startIndex, endIndex);

            return Column(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder:
                        (BuildContext context, BoxConstraints constraints) {
                      return Scrollbar(
                        controller: _horizontalScroll,
                        thumbVisibility: true,
                        radius: const Radius.circular(8),
                        thickness: 8,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          controller: _horizontalScroll,
                          child: ConstrainedBox(
                            constraints:
                                BoxConstraints(minWidth: constraints.maxWidth),
                            child: Theme(
                              data: theme.copyWith(
                                dividerTheme: const DividerThemeData(
                                    color: Colors.transparent),
                              ),
                              child: DataTable(
                                border: const TableBorder(
                                  horizontalInside:
                                      BorderSide(width: 1, color: kNeutral300),
                                ),
                                dataRowColor:
                                    const WidgetStatePropertyAll(Colors.white),
                                headingRowColor: WidgetStateProperty.all(
                                    const Color(0xFFF8F3FF)),
                                showBottomBorder: false,
                                dividerThickness: 0.0,
                                headingTextStyle: theme.textTheme.titleMedium,
                                columns: [
                                  DataColumn(
                                      label: Text(lang.S.of(context).SL)),
                                  DataColumn(
                                      label: Text(lang.S.of(context).name)),
                                  DataColumn(
                                      label:
                                          Text(lang.S.of(context).description)),
                                  DataColumn(
                                      label: Text(
                                          lang.S.of(context).quantityItems)),
                                  DataColumn(
                                      label: Text(lang.S.of(context).actions)),
                                ],
                                rows: List.generate(paginated.length, (i) {
                                  final area = paginated[i];
                                  final itemCount = areaCounts[area.id] ?? 0;
                                  return DataRow(cells: [
                                    DataCell(Text('${startIndex + i + 1}')),
                                    DataCell(Text(area.name)),
                                    DataCell(Text(area.description)),
                                    DataCell(Text('$itemCount')),
                                    DataCell(Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit,
                                              color: kMainColor),
                                          onPressed: () =>
                                              _showAreaDialog(area: area),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red),
                                          onPressed: () async {
                                            final confirm = await _confirmDelete(
                                                '${lang.S.of(context).deleteAreaConfirm}');
                                            if (confirm)
                                              await ref
                                                  .read(areasProvider.notifier)
                                                  .deleteArea(area.id);
                                          },
                                        ),
                                      ],
                                    )),
                                  ]);
                                }),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (filtered.isNotEmpty)
                  _buildPaginationControls(filtered.length, totalPages),
                if (filtered.isEmpty)
                  noDataFoundImage(text: lang.S.of(context).noDataFound),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildEquipmentsTab(ThemeData theme, double screenWidth) {
    final equipmentsAsync = ref.watch(equipmentsProvider);
    final areasAsync = ref.watch(areasProvider);

    return equipmentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (equipments) {
        return areasAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(e.toString())),
          data: (areas) {
            var filtered = equipments
                .where((e) =>
                    (e.name
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase()) ||
                        e.areaName
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase())) &&
                    (_selectedState == null || e.state == _selectedState))
                .toList();

            final totalPages = (_itemsPerPage == -1)
                ? 1
                : (filtered.length / _itemsPerPage).ceil();
            final startIndex = (_currentPage - 1) * _itemsPerPage;
            final endIndex = _itemsPerPage == -1
                ? filtered.length
                : (startIndex + _itemsPerPage).clamp(0, filtered.length);
            final paginated = filtered.sublist(startIndex, endIndex);

            final totalQty =
                filtered.fold<int>(0, (sum, item) => sum + item.quantity);
            final totalValue = filtered.fold<double>(
                0.0, (sum, item) => sum + (item.quantity * item.price));

            return Column(
              children: [
                // Tabla
                Expanded(
                  child: LayoutBuilder(
                    builder:
                        (BuildContext context, BoxConstraints constraints) {
                      return Scrollbar(
                        controller: _horizontalScroll,
                        thumbVisibility: true,
                        radius: const Radius.circular(8),
                        thickness: 8,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          controller: _horizontalScroll,
                          child: ConstrainedBox(
                            constraints:
                                BoxConstraints(minWidth: constraints.maxWidth),
                            child: Theme(
                              data: theme.copyWith(
                                  dividerTheme: const DividerThemeData(
                                      color: Colors.transparent)),
                              child: DataTable(
                                border: const TableBorder(
                                    horizontalInside: BorderSide(
                                        width: 1, color: kNeutral300)),
                                dataRowColor:
                                    const WidgetStatePropertyAll(Colors.white),
                                headingRowColor: WidgetStateProperty.all(
                                    const Color(0xFFF8F3FF)),
                                showBottomBorder: false,
                                dividerThickness: 0.0,
                                headingTextStyle: theme.textTheme.titleMedium,
                                columns: [
                                  DataColumn(
                                      label: Text(lang.S.of(context).SL)),
                                  DataColumn(
                                      label: Text(lang.S.of(context).name)),
                                  DataColumn(
                                      label: Text(lang.S.of(context).price)),
                                  DataColumn(
                                      label: Text(lang.S.of(context).quantity)),
                                  DataColumn(
                                      label: Text(lang.S.of(context).area)),
                                  DataColumn(
                                      label:
                                          Text(lang.S.of(context).totalValue)),
                                  DataColumn(label: Text("Estado")),
                                  DataColumn(
                                      label: Text(lang.S.of(context).actions)),
                                ],
                                rows: List.generate(paginated.length, (i) {
                                  final e = paginated[i];
                                  return DataRow(
                                    cells: [
                                      DataCell(Text('${startIndex + i + 1}')),
                                      DataCell(Text(e.name)),
                                      DataCell(Text(myFormat.format(e.price))),
                                      DataCell(Text('${e.quantity}')),
                                      DataCell(Text(e.areaName)),
                                      DataCell(Text(myFormat
                                          .format(e.price * e.quantity))),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: e.state == 'Disponible'
                                                ? Colors.green.withOpacity(0.2)
                                                : e.state == 'Averiado'
                                                    ? Colors.orange
                                                        .withOpacity(0.2)
                                                    : Colors.red
                                                        .withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            e.state,
                                            style: TextStyle(
                                              color: e.state == 'Disponible'
                                                  ? Colors.green
                                                  : e.state == 'Averiado'
                                                      ? Colors.orange
                                                      : Colors.red,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.build,
                                                  color: Colors.orange),
                                              onPressed: () async {
                                                final confirm =
                                                    await _confirmChangeState(
                                                  '¿Marcar equipo como averiado?',
                                                  'Esta acción cambiará el estado del equipo a "Averiado". ¿Deseas continuar?',
                                                );
                                                if (confirm) {
                                                  await ref
                                                      .read(equipmentsProvider
                                                          .notifier)
                                                      .updateEquipment(
                                                        e.copyWith(
                                                            state: 'Averiado'),
                                                      );
                                                }
                                              },
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.warning,
                                                  color: Colors.red),
                                              onPressed: () async {
                                                final confirm =
                                                    await _confirmChangeState(
                                                  '¿Marcar equipo como dañado?',
                                                  'Esta acción cambiará el estado del equipo a "Dañado". ¿Deseas continuar?',
                                                );
                                                if (confirm) {
                                                  await ref
                                                      .read(equipmentsProvider
                                                          .notifier)
                                                      .updateEquipment(
                                                        e.copyWith(
                                                            state: 'Dañado'),
                                                      );
                                                }
                                              },
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                  Icons.check_circle,
                                                  color: Colors.green),
                                              tooltip: 'Marcar como Disponible',
                                              onPressed: () async {
                                                final confirm =
                                                    await _confirmChangeState(
                                                  '¿Marcar equipo como disponible?',
                                                  'Esta acción cambiará el estado del equipo a "Disponible". ¿Deseas continuar?',
                                                );
                                                if (confirm) {
                                                  await ref
                                                      .read(equipmentsProvider
                                                          .notifier)
                                                      .updateEquipment(
                                                        e.copyWith(
                                                            state:
                                                                'Disponible'),
                                                      );
                                                }
                                              },
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.edit,
                                                  color: kMainColor),
                                              onPressed: () =>
                                                  _showEquipmentDialog(
                                                      equipment: e,
                                                      areas: areas),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete,
                                                  color: Colors.red),
                                              onPressed: () async {
                                                final confirm =
                                                    await _confirmDelete(
                                                        '${lang.S.of(context).deleteEquipmentConfirm}');
                                                if (confirm)
                                                  await ref
                                                      .read(equipmentsProvider
                                                          .notifier)
                                                      .deleteEquipment(e.id);
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Totales
                if (filtered.isNotEmpty)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                        border: Border.all(color: kMainColor.withOpacity(0.2)),
                      ),
                      constraints: const BoxConstraints(minWidth: 300),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.storage, color: kMainColor),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cantidad total: $totalQty',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Valor total: ${myFormat.format(totalValue)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                // Paginación
                if (filtered.isNotEmpty)
                  _buildPaginationControls(filtered.length, totalPages),
                if (filtered.isEmpty)
                  noDataFoundImage(text: lang.S.of(context).noDataFound),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPaginationControls(int totalItems, int totalPages) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              '${lang.S.of(context).showing} ${((_currentPage - 1) * _itemsPerPage + 1)} hasta ${((_currentPage - 1) * _itemsPerPage + _itemsPerPage).clamp(0, totalItems)} de $totalItems ${lang.S.of(context).entries}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            children: [
              InkWell(
                onTap: _currentPage > 1
                    ? () => setState(() => _currentPage--)
                    : null,
                child: Container(
                  height: 32,
                  width: 90,
                  decoration: BoxDecoration(
                    border: Border.all(color: kBorderColorTextField),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(4.0),
                      topLeft: Radius.circular(4.0),
                    ),
                  ),
                  child: Center(child: Text(lang.S.of(context).previous)),
                ),
              ),
              Container(
                height: 32,
                width: 32,
                decoration: BoxDecoration(
                  border: Border.all(color: kBorderColorTextField),
                  color: kMainColor,
                ),
                child: Center(
                  child: Text(
                    '$_currentPage',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
              if (totalPages > 1)
                Container(
                  height: 32,
                  width: 32,
                  decoration: BoxDecoration(
                    border: Border.all(color: kBorderColorTextField),
                  ),
                  child: Center(
                    child: Text('$totalPages'),
                  ),
                ),
              InkWell(
                onTap: _currentPage < totalPages
                    ? () => setState(() => _currentPage++)
                    : null,
                child: Container(
                  height: 32,
                  width: 90,
                  decoration: BoxDecoration(
                    border: Border.all(color: kBorderColorTextField),
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(4.0),
                      topRight: Radius.circular(4.0),
                    ),
                  ),
                  child: Center(child: Text(lang.S.of(context).next)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showAreaDialog({Area? area}) async {
    final nameController = TextEditingController(text: area?.name ?? '');
    final descController = TextEditingController(text: area?.description ?? '');
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(20),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  area == null
                      ? lang.S.of(context).addArea
                      : lang.S.of(context).editArea,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: nameController,
                  decoration:
                      InputDecoration(labelText: lang.S.of(context).name),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese un nombre';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: descController,
                  decoration: InputDecoration(
                      labelText: lang.S.of(context).description),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese una descripción';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(lang.S.of(context).cancel),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          final areaData = Area(
                            id: area?.id ?? '',
                            name: nameController.text,
                            description: descController.text,
                            quantityItem: 0,
                            createdAt: area?.createdAt ?? DateTime.now(),
                            updatedAt: DateTime.now(),
                          );
                          final notifier = ref.read(areasProvider.notifier);
                          area == null
                              ? await notifier.addArea(areaData)
                              : await notifier.updateArea(areaData);
                          Navigator.pop(ctx);
                        }
                      },
                      child: Text(lang.S.of(context).save),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showEquipmentDialog(
      {Equipment? equipment, List<Area>? areas}) async {
    final nameController = TextEditingController(text: equipment?.name ?? '');
    final descController =
        TextEditingController(text: equipment?.description ?? '');
    final priceController =
        TextEditingController(text: equipment?.price.toString() ?? '0');
    final qtyController =
        TextEditingController(text: equipment?.quantity.toString() ?? '0');
    String? selectedAreaId = equipment?.areaId;
    final formKey = GlobalKey<FormState>();

    areas ??= await ref.read(areasProvider.notifier).getAreas();

    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(20),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  equipment == null
                      ? lang.S.of(context).addEquipment
                      : lang.S.of(context).editEquipment,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: nameController,
                  decoration:
                      InputDecoration(labelText: lang.S.of(context).name),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese un nombre';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: descController,
                  decoration: InputDecoration(
                      labelText: lang.S.of(context).description),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese una descripción';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration:
                      InputDecoration(labelText: lang.S.of(context).price),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese un precio';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Por favor ingrese un valor numérico válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: qtyController,
                  keyboardType: TextInputType.number,
                  decoration:
                      InputDecoration(labelText: lang.S.of(context).quantity),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese una cantidad';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Por favor ingrese un valor numérico válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedAreaId,
                  decoration:
                      InputDecoration(labelText: lang.S.of(context).area),
                  validator: (value) {
                    if (value == null) {
                      return 'Por favor seleccione un área';
                    }
                    return null;
                  },
                  items: areas
                      ?.map((a) => DropdownMenuItem(
                            value: a.id,
                            child: Text(a.name),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => selectedAreaId = val),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(lang.S.of(context).cancel),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          final selectedArea =
                              areas?.firstWhere((a) => a.id == selectedAreaId);
                          final equipmentData = Equipment(
                            id: equipment?.id ?? '',
                            name: nameController.text,
                            description: descController.text,
                            price: double.tryParse(priceController.text) ?? 0.0,
                            quantity: int.tryParse(qtyController.text) ?? 0,
                            areaId: selectedAreaId ?? '',
                            areaName: selectedArea!.name,
                            state: 'Disponible',
                            createdAt: equipment?.createdAt ?? DateTime.now(),
                            updatedAt: DateTime.now(),
                          );
                          final notifier =
                              ref.read(equipmentsProvider.notifier);
                          equipment == null
                              ? await notifier.addEquipment(equipmentData)
                              : await notifier.updateEquipment(equipmentData);
                          Navigator.pop(ctx);
                        }
                      },
                      child: Text(lang.S.of(context).save),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(lang.S.of(context).confirmDelete),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(lang.S.of(context).cancel),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
                child: Text(lang.S.of(context).delete),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<bool> _confirmChangeState(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(lang.S.of(context).cancel),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirmar'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
