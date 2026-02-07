import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:iconly/iconly.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/Screen/HRM/employees/provider/designation_provider.dart';
import 'package:salespro_admin/Screen/HRM/employees/repo/employee_repo.dart';
import 'package:salespro_admin/Screen/HRM/Designation/add_designation.dart';
import 'package:salespro_admin/Screen/HRM/Designation/repo/designation_repo.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;
import 'package:salespro_admin/services/api_service.dart';

import '../../../const.dart';
import '../../Widgets/Constant Data/constant.dart';
import '../Designation/model/designation_model.dart';
import 'model/employee_model.dart';

class AddEmployeeScreen extends StatefulWidget {
  const AddEmployeeScreen({
    super.key,
    required this.listOfEmployees,
    this.employeeModel,
    required this.ref,
    required this.designations,
  });

  final List<EmployeeModel> listOfEmployees;
  final EmployeeModel? employeeModel;
  final List<DesignationModel> designations;
  final WidgetRef ref;

  @override
  State<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends State<AddEmployeeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Controladores de texto - Información Personal
  final TextEditingController nameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController cedulaController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController phoneNumber2Controller = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController cityController = TextEditingController();

  // Controladores - Información Laboral
  final TextEditingController salaryController = TextEditingController();
  final TextEditingController departmentController = TextEditingController();

  // Controladores - Seguridad Social
  final TextEditingController afpNumberController = TextEditingController();
  final TextEditingController sfsNumberController = TextEditingController();
  final TextEditingController nssController = TextEditingController();

  // Controladores - Información Bancaria
  final TextEditingController bankAccountController = TextEditingController();

  // Controladores - Contacto de Emergencia
  final TextEditingController emergencyNameController = TextEditingController();
  final TextEditingController emergencyPhoneController = TextEditingController();
  final TextEditingController emergencyRelationController = TextEditingController();

  // Controladores - Notas
  final TextEditingController notesController = TextEditingController();

  // Listas para dropdowns
  final List<String> genderList = ['Masculino', 'Femenino', 'Otro'];
  final List<String> maritalStatusList = [
    'Soltero/a',
    'Casado/a',
    'Divorciado/a',
    'Viudo/a',
    'Unión Libre'
  ];
  final List<String> employmentTypeList = ['Tiempo Completo', 'Medio Tiempo', 'Por Hora'];
  final List<String> contractTypeList = ['Indefinido', 'Temporal', 'Por Obra'];
  final List<String> salaryTypeList = ['Mensual', 'Quincenal', 'Semanal'];
  final List<String> paymentMethodList = ['Transferencia', 'Cheque', 'Efectivo'];
  final List<String> bankAccountTypeList = ['Ahorros', 'Corriente'];
  final List<String> statusList = ['Activo', 'Inactivo', 'Suspendido', 'Licencia'];

  // Valores seleccionados
  String? selectedGender;
  String? selectedMaritalStatus;
  String? selectedEmploymentType;
  String? selectedContractType;
  String? selectedSalaryType;
  String? selectedPaymentMethod;
  String? selectedProvince;
  String? selectedAFPProvider;
  String? selectedARSProvider;
  String? selectedBank;
  String? selectedBankAccountType;
  String? selectedStatus;
  DesignationModel? selectedDesignation;
  int dependents = 0;

  DateTime birthDate = DateTime.now().subtract(const Duration(days: 365 * 25));
  DateTime joiningDate = DateTime.now();
  DateTime? contractEndDate;

  // Lista mutable de designaciones para poder actualizarla cuando se agregue una nueva
  List<DesignationModel> _designations = [];

  // Estado para búsqueda de cédula en Padrón Electoral
  bool _isSearchingCedula = false;
  Uint8List? _photoFromPadron;

  @override
  void initState() {
    super.initState();
    checkCurrentUserAndRestartApp();
    _tabController = TabController(length: 5, vsync: this);
    _designations = List.from(widget.designations);

    if (widget.employeeModel != null) {
      _loadExistingData();
    } else {
      // Valores por defecto
      selectedStatus = 'Activo';
      selectedAFPProvider = AFPProviders.all.first;
      selectedARSProvider = ARSProviders.all.first;
      selectedSalaryType = 'Mensual';
      selectedPaymentMethod = 'Transferencia';
      selectedContractType = 'Indefinido';
      selectedMaritalStatus = 'Soltero/a';
    }
  }

  void _loadExistingData() {
    final employee = widget.employeeModel!;
    nameController.text = employee.name;
    lastNameController.text = employee.lastName;
    cedulaController.text = employee.cedula;
    phoneNumberController.text = employee.phoneNumber;
    phoneNumber2Controller.text = employee.phoneNumber2 ?? '';
    emailController.text = employee.email;
    addressController.text = employee.address;
    cityController.text = employee.city ?? '';
    salaryController.text = employee.salary.toString();
    departmentController.text = employee.department;
    afpNumberController.text = employee.afpNumber ?? '';
    sfsNumberController.text = employee.sfsNumber ?? '';
    nssController.text = employee.nss ?? '';
    bankAccountController.text = employee.bankAccountNumber ?? '';
    emergencyNameController.text = employee.emergencyContactName ?? '';
    emergencyPhoneController.text = employee.emergencyContactPhone ?? '';
    emergencyRelationController.text = employee.emergencyContactRelation ?? '';
    notesController.text = employee.notes ?? '';

    // Mapear valores de género antiguos (inglés) a nuevos (español)
    String? mappedGender = employee.gender;
    if (mappedGender == 'Male') {
      mappedGender = 'Masculino';
    } else if (mappedGender == 'Female') {
      mappedGender = 'Femenino';
    } else if (mappedGender == 'Other') {
      mappedGender = 'Otro';
    }
    // Verificar que el género esté en la lista
    selectedGender = genderList.contains(mappedGender) ? mappedGender : null;

    // Verificar estado civil
    selectedMaritalStatus = maritalStatusList.contains(employee.maritalStatus)
        ? employee.maritalStatus
        : null;

    // Verificar tipo de empleo
    selectedEmploymentType = employmentTypeList.contains(employee.employmentType)
        ? employee.employmentType
        : null;

    // Verificar tipo de contrato
    selectedContractType = contractTypeList.contains(employee.contractType)
        ? employee.contractType
        : null;

    // Verificar tipo de salario
    selectedSalaryType = salaryTypeList.contains(employee.salaryType)
        ? employee.salaryType
        : null;

    // Verificar método de pago
    selectedPaymentMethod = paymentMethodList.contains(employee.paymentMethod)
        ? employee.paymentMethod
        : null;

    selectedProvince = employee.province;

    // Verificar AFP
    selectedAFPProvider = AFPProviders.all.contains(employee.afpProvider)
        ? employee.afpProvider
        : AFPProviders.all.first;

    // Verificar ARS
    selectedARSProvider = ARSProviders.all.contains(employee.sfsProvider)
        ? employee.sfsProvider
        : ARSProviders.all.first;

    selectedBank = employee.bankName;

    // Verificar tipo de cuenta
    selectedBankAccountType = bankAccountTypeList.contains(employee.bankAccountType)
        ? employee.bankAccountType
        : null;

    // Verificar estado
    selectedStatus = statusList.contains(employee.status)
        ? employee.status
        : 'Activo';

    dependents = employee.dependents;
    birthDate = employee.birthDate;
    joiningDate = employee.joiningDate;
    contractEndDate = employee.contractEndDate;

    for (var element in _designations) {
      if (element.id == employee.designationId) {
        selectedDesignation = element;
        break;
      }
    }
  }

  /// Busca datos del ciudadano en el Padrón Electoral por cédula
  Future<void> _searchByCedula() async {
    String cedula = cedulaController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');

    if (cedula.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingrese una cédula para buscar')),
      );
      return;
    }

    if (cedula.length != 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La cédula debe tener 11 dígitos')),
      );
      return;
    }

    setState(() {
      _isSearchingCedula = true;
    });

    try {
      final uri = Uri.parse('${ApiService.baseUrl}/padron-electoral/$cedula');
      debugPrint('[AddEmployee] Consultando cédula: $uri');

      final response = await http.get(uri, headers: {
        'Content-Type': 'application/json',
      }).timeout(const Duration(seconds: 25));

      debugPrint('[AddEmployee] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['data'] != null) {
          final padronData = data['data'];

          // Actualizar campos del formulario
          setState(() {
            // Nombre y apellidos
            if (padronData['nombres'] != null) {
              nameController.text = padronData['nombres'];
            }

            String apellidos = '';
            if (padronData['apellido1'] != null) {
              apellidos = padronData['apellido1'];
            }
            if (padronData['apellido2'] != null && padronData['apellido2'].toString().isNotEmpty) {
              apellidos += ' ${padronData['apellido2']}';
            }
            if (apellidos.isNotEmpty) {
              lastNameController.text = apellidos.trim();
            }

            // Fecha de nacimiento
            if (padronData['fechaNacimiento'] != null) {
              try {
                birthDate = DateTime.parse(padronData['fechaNacimiento']);
              } catch (e) {
                debugPrint('Error parseando fecha: $e');
              }
            }

            // Género
            if (padronData['sexo'] != null) {
              final sexo = padronData['sexo'].toString().toUpperCase();
              if (sexo == 'M' || sexo == 'MASCULINO') {
                selectedGender = 'Masculino';
              } else if (sexo == 'F' || sexo == 'FEMENINO') {
                selectedGender = 'Femenino';
              }
            }

            // Estado civil
            if (padronData['estadoCivil'] != null) {
              final ec = padronData['estadoCivil'].toString().toUpperCase();
              if (ec == 'S' || ec == 'SOLTERO' || ec == 'SOLTERO/A') {
                selectedMaritalStatus = 'Soltero/a';
              } else if (ec == 'C' || ec == 'CASADO' || ec == 'CASADO/A') {
                selectedMaritalStatus = 'Casado/a';
              } else if (ec == 'D' || ec == 'DIVORCIADO' || ec == 'DIVORCIADO/A') {
                selectedMaritalStatus = 'Divorciado/a';
              } else if (ec == 'V' || ec == 'VIUDO' || ec == 'VIUDO/A') {
                selectedMaritalStatus = 'Viudo/a';
              } else if (ec == 'U' || ec == 'UNION LIBRE' || ec == 'UNIÓN LIBRE') {
                selectedMaritalStatus = 'Unión Libre';
              }
            }

            // Provincia
            if (padronData['provincia'] != null) {
              selectedProvince = padronData['provincia'];
            }

            // Ciudad/Municipio
            if (padronData['municipio'] != null) {
              cityController.text = padronData['municipio'];
            }

            // Dirección (usa colegio como referencia del sector)
            if (padronData['direccion'] != null && padronData['direccion'].toString().isNotEmpty) {
              addressController.text = 'Cerca de ${padronData['direccion']}';
            }

            // Foto
            if (padronData['foto'] != null && padronData['foto'].toString().isNotEmpty) {
              try {
                String base64Image = padronData['foto'];
                if (base64Image.contains(',')) {
                  base64Image = base64Image.split(',').last;
                }
                _photoFromPadron = base64.decode(base64Image);
              } catch (e) {
                debugPrint('Error decodificando foto: $e');
              }
            }
          });

          // Formatear cédula con guiones
          cedulaController.text = EmployeeModel.formatCedula(cedula);

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Datos encontrados: ${nameController.text} ${lastNameController.text}'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Cédula no encontrada'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else if (response.statusCode == 404) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cédula no encontrada en el Padrón Electoral'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      debugPrint('Error consultando cédula: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al consultar: ${e.toString().contains('TimeoutException') ? 'Tiempo de espera agotado' : e}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSearchingCedula = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    nameController.dispose();
    lastNameController.dispose();
    cedulaController.dispose();
    phoneNumberController.dispose();
    phoneNumber2Controller.dispose();
    emailController.dispose();
    addressController.dispose();
    cityController.dispose();
    salaryController.dispose();
    departmentController.dispose();
    afpNumberController.dispose();
    sfsNumberController.dispose();
    nssController.dispose();
    bankAccountController.dispose();
    emergencyNameController.dispose();
    emergencyPhoneController.dispose();
    emergencyRelationController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer(
      builder: (context, ref, child) {
        return SingleChildScrollView(
          child: Container(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(20)),
              color: kWhite,
            ),
            width: 800,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            widget.employeeModel != null
                                ? 'Editar Empleado'
                                : 'Agregar Empleado',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => GoRouter.of(context).pop(),
                          icon: const Icon(FeatherIcons.x,
                              color: kTitleColor, size: 22.0),
                        ),
                      ],
                    ),
                  ),

                  // Tabs
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    labelColor: kMainColor,
                    unselectedLabelColor: kNeutral500,
                    indicatorColor: kMainColor,
                    tabs: const [
                      Tab(text: 'Personal'),
                      Tab(text: 'Laboral'),
                      Tab(text: 'Seguridad Social'),
                      Tab(text: 'Bancaria'),
                      Tab(text: 'Emergencia'),
                    ],
                  ),
                  const Divider(height: 1, color: kNeutral300),

                  // Tab Content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildPersonalInfoTab(theme),
                        _buildLaboralInfoTab(theme),
                        _buildSocialSecurityTab(theme),
                        _buildBankingInfoTab(theme),
                        _buildEmergencyContactTab(theme),
                      ],
                    ),
                  ),

                  const Divider(height: 1, color: kNeutral300),

                  // Botones
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            onPressed: () => GoRouter.of(context).pop(),
                            child: Text(lang.S.of(context).cancel),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kGreenTextColor,
                            ),
                            onPressed: _saveEmployee,
                            child: Text(
                              widget.employeeModel != null
                                  ? lang.S.of(context).update
                                  : lang.S.of(context).saveAndPublish,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPersonalInfoTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Información Personal',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: kMainColor,
              )),
          const SizedBox(height: 16),
          ResponsiveGridRow(children: [
            ResponsiveGridCol(
              md: 6,
              xs: 12,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildTextField(
                  controller: nameController,
                  label: 'Nombre *',
                  hint: 'Ingrese el nombre',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El nombre es requerido';
                    }
                    return null;
                  },
                ),
              ),
            ),
            ResponsiveGridCol(
              md: 6,
              xs: 12,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildTextField(
                  controller: lastNameController,
                  label: 'Apellido *',
                  hint: 'Ingrese el apellido',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El apellido es requerido';
                    }
                    return null;
                  },
                ),
              ),
            ),
          ]),
          ResponsiveGridRow(children: [
            ResponsiveGridCol(
              md: 6,
              xs: 12,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: cedulaController,
                        decoration: const InputDecoration(
                          labelText: 'Cédula',
                          hintText: '000-0000000-0',
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9-]')),
                          LengthLimitingTextInputFormatter(13),
                        ],
                        validator: (value) {
                          // Cédula opcional, pero si se ingresa debe ser válida
                          if (value != null && value.trim().isNotEmpty) {
                            if (!EmployeeModel.isValidCedula(value)) {
                              return 'Cédula inválida';
                            }
                          }
                          return null;
                        },
                        onChanged: (value) {
                          if (value.length == 11 && !value.contains('-')) {
                            cedulaController.text = EmployeeModel.formatCedula(value);
                            cedulaController.selection = TextSelection.fromPosition(
                              TextPosition(offset: cedulaController.text.length),
                            );
                          }
                        },
                        onFieldSubmitted: (_) => _searchByCedula(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: ElevatedButton.icon(
                        onPressed: _isSearchingCedula ? null : _searchByCedula,
                        icon: _isSearchingCedula
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.search, size: 18),
                        label: Text(_isSearchingCedula ? 'Buscando...' : 'Buscar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kMainColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ResponsiveGridCol(
              md: 6,
              xs: 12,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Género'),
                  value: selectedGender,
                  items: genderList
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (value) => setState(() => selectedGender = value),
                ),
              ),
            ),
          ]),
          ResponsiveGridRow(children: [
            ResponsiveGridCol(
              md: 6,
              xs: 12,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Estado Civil'),
                  value: selectedMaritalStatus,
                  items: maritalStatusList
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => selectedMaritalStatus = value),
                ),
              ),
            ),
            ResponsiveGridCol(
              md: 6,
              xs: 12,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Dependientes (ISR):',
                          style: theme.textTheme.bodyMedium),
                    ),
                    IconButton(
                      onPressed: () {
                        if (dependents > 0) setState(() => dependents--);
                      },
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text('$dependents', style: theme.textTheme.titleMedium),
                    IconButton(
                      onPressed: () => setState(() => dependents++),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              ),
            ),
          ]),
          ResponsiveGridRow(children: [
            ResponsiveGridCol(
              md: 6,
              xs: 12,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildTextField(
                  controller: phoneNumberController,
                  label: 'Teléfono Principal',
                  hint: '809-000-0000',
                ),
              ),
            ),
            ResponsiveGridCol(
              md: 6,
              xs: 12,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildTextField(
                  controller: phoneNumber2Controller,
                  label: 'Teléfono Secundario',
                  hint: '809-000-0000',
                ),
              ),
            ),
          ]),
          ResponsiveGridRow(children: [
            ResponsiveGridCol(
              md: 6,
              xs: 12,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildTextField(
                  controller: emailController,
                  label: 'Correo Electrónico',
                  hint: 'empleado@empresa.com',
                ),
              ),
            ),
            ResponsiveGridCol(
              md: 6,
              xs: 12,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildDatePickerField(
                  context: context,
                  label: 'Fecha de Nacimiento',
                  selectedDate: birthDate,
                  onChanged: (value) => setState(() => birthDate = value),
                ),
              ),
            ),
          ]),
          ResponsiveGridRow(children: [
            ResponsiveGridCol(
              md: 12,
              xs: 12,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildTextField(
                  controller: addressController,
                  label: 'Dirección',
                  hint: 'Calle, número, sector',
                ),
              ),
            ),
          ]),
          ResponsiveGridRow(children: [
            ResponsiveGridCol(
              md: 6,
              xs: 12,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildTextField(
                  controller: cityController,
                  label: 'Ciudad',
                  hint: 'Ciudad o municipio',
                ),
              ),
            ),
            ResponsiveGridCol(
              md: 6,
              xs: 12,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Provincia'),
                  value: selectedProvince,
                  isExpanded: true,
                  items: ProvincesRD.all
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => selectedProvince = value),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildLaboralInfoTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Información Laboral',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: kMainColor,
              )),
          const SizedBox(height: 16),
          ResponsiveGridRow(children: [
            ResponsiveGridCol(
              md: 6,
              xs: 12,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<DesignationModel>(
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Cargo'),
                        value: selectedDesignation,
                        items: _designations
                            .map((d) => DropdownMenuItem(
                                value: d, child: Text(d.designation)))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => selectedDesignation = value),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: IconButton(
                        onPressed: () => _showAddDesignationDialog(),
                        icon: const Icon(Icons.add_circle, color: kMainColor),
                        tooltip: 'Agregar nuevo cargo',
                        style: IconButton.styleFrom(
                          backgroundColor: kMainColor.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ResponsiveGridCol(
              md: 6,
              xs: 12,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildTextField(
                  controller: departmentController,
                  label: 'Departamento',
                  hint: 'Ej: Ventas, Administración',
                ),
              ),
            ),
          ]),
          ResponsiveGridRow(children: [
            ResponsiveGridCol(
              md: 6,
              xs: 12,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: DropdownButtonFormField<String>(
                  decoration:
                      const InputDecoration(labelText: 'Tipo de Empleo'),
                  value: selectedEmploymentType,
                  items: employmentTypeList
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => selectedEmploymentType = value),
                ),
              ),
            ),
            ResponsiveGridCol(
              md: 6,
              xs: 12,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: DropdownButtonFormField<String>(
                  decoration:
                      const InputDecoration(labelText: 'Tipo de Contrato'),
                  value: selectedContractType,
                  items: contractTypeList
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => selectedContractType = value),
                ),
              ),
            ),
          ]),
          ResponsiveGridRow(children: [
            ResponsiveGridCol(
              md: 6,
              xs: 12,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildDatePickerField(
                  context: context,
                  label: 'Fecha de Ingreso',
                  selectedDate: joiningDate,
                  onChanged: (value) => setState(() => joiningDate = value),
                ),
              ),
            ),
            ResponsiveGridCol(
              md: 6,
              xs: 12,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildDatePickerField(
                  context: context,
                  label: 'Fin de Contrato',
                  selectedDate: contractEndDate,
                  onChanged: (value) => setState(() => contractEndDate = value),
                  allowNull: true,
                ),
              ),
            ),
          ]),
          ResponsiveGridRow(children: [
            ResponsiveGridCol(
              md: 4,
              xs: 12,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  controller: salaryController,
                  decoration: const InputDecoration(
                    labelText: 'Salario Bruto',
                    prefixText: 'RD\$ ',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                ),
              ),
            ),
            ResponsiveGridCol(
              md: 4,
              xs: 12,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: DropdownButtonFormField<String>(
                  decoration:
                      const InputDecoration(labelText: 'Frecuencia de Pago'),
                  value: selectedSalaryType,
                  items: salaryTypeList
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => selectedSalaryType = value),
                ),
              ),
            ),
            ResponsiveGridCol(
              md: 4,
              xs: 12,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Estado'),
                  value: selectedStatus,
                  items: statusList
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (value) => setState(() => selectedStatus = value),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSocialSecurityTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Seguridad Social (TSS)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: kMainColor,
              )),
          const SizedBox(height: 8),
          Text(
            'Información requerida para reportes TSS e IR-17',
            style: theme.textTheme.bodySmall?.copyWith(color: kNeutral500),
          ),
          const SizedBox(height: 16),

          // AFP Section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AFP (Fondo de Pensiones)',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    )),
                const SizedBox(height: 12),
                ResponsiveGridRow(children: [
                  ResponsiveGridCol(
                    md: 6,
                    xs: 12,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: DropdownButtonFormField<String>(
                        decoration:
                            const InputDecoration(labelText: 'Proveedor AFP'),
                        value: selectedAFPProvider,
                        items: AFPProviders.all
                            .map((a) =>
                                DropdownMenuItem(value: a, child: Text(a)))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => selectedAFPProvider = value),
                      ),
                    ),
                  ),
                  ResponsiveGridCol(
                    md: 6,
                    xs: 12,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: _buildTextField(
                        controller: afpNumberController,
                        label: 'Número de Cuenta AFP',
                        hint: 'Número de cuenta individual',
                      ),
                    ),
                  ),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // SFS/ARS Section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SFS/ARS (Seguro de Salud)',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    )),
                const SizedBox(height: 12),
                ResponsiveGridRow(children: [
                  ResponsiveGridCol(
                    md: 6,
                    xs: 12,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: DropdownButtonFormField<String>(
                        decoration:
                            const InputDecoration(labelText: 'ARS/SFS'),
                        value: selectedARSProvider,
                        isExpanded: true,
                        items: ARSProviders.all
                            .map((a) =>
                                DropdownMenuItem(value: a, child: Text(a)))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => selectedARSProvider = value),
                      ),
                    ),
                  ),
                  ResponsiveGridCol(
                    md: 6,
                    xs: 12,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: _buildTextField(
                        controller: sfsNumberController,
                        label: 'Número de Afiliación',
                        hint: 'Número de carnet ARS',
                      ),
                    ),
                  ),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 16),

          ResponsiveGridRow(children: [
            ResponsiveGridCol(
              md: 6,
              xs: 12,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildTextField(
                  controller: nssController,
                  label: 'NSS (Número Seguridad Social)',
                  hint: 'Si aplica',
                ),
              ),
            ),
          ]),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kNeutral100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tasas de Cotización Actuales',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    )),
                const SizedBox(height: 8),
                _buildRateRow('AFP Empleado:', '2.87%'),
                _buildRateRow('AFP Patronal:', '7.10%'),
                _buildRateRow('SFS Empleado:', '3.04%'),
                _buildRateRow('SFS Patronal:', '7.09%'),
                _buildRateRow('SRL Patronal:', '1.00% - 1.40%'),
                _buildRateRow('INFOTEP:', '1.00%'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRateRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          Text(value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildBankingInfoTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Información Bancaria',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: kMainColor,
              )),
          const SizedBox(height: 8),
          Text(
            'Datos para transferencia de nómina',
            style: theme.textTheme.bodySmall?.copyWith(color: kNeutral500),
          ),
          const SizedBox(height: 16),
          ResponsiveGridRow(children: [
            ResponsiveGridCol(
              md: 6,
              xs: 12,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: DropdownButtonFormField<String>(
                  decoration:
                      const InputDecoration(labelText: 'Método de Pago'),
                  value: selectedPaymentMethod,
                  items: paymentMethodList
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => selectedPaymentMethod = value),
                ),
              ),
            ),
            ResponsiveGridCol(
              md: 6,
              xs: 12,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Banco'),
                  value: selectedBank,
                  isExpanded: true,
                  items: BanksRD.all
                      .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                      .toList(),
                  onChanged: (value) => setState(() => selectedBank = value),
                ),
              ),
            ),
          ]),
          ResponsiveGridRow(children: [
            ResponsiveGridCol(
              md: 6,
              xs: 12,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildTextField(
                  controller: bankAccountController,
                  label: 'Número de Cuenta',
                  hint: 'Número de cuenta bancaria',
                ),
              ),
            ),
            ResponsiveGridCol(
              md: 6,
              xs: 12,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: DropdownButtonFormField<String>(
                  decoration:
                      const InputDecoration(labelText: 'Tipo de Cuenta'),
                  value: selectedBankAccountType,
                  items: bankAccountTypeList
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => selectedBankAccountType = value),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Contacto de Emergencia',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: kMainColor,
              )),
          const SizedBox(height: 16),
          ResponsiveGridRow(children: [
            ResponsiveGridCol(
              md: 6,
              xs: 12,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildTextField(
                  controller: emergencyNameController,
                  label: 'Nombre Completo',
                  hint: 'Nombre del contacto',
                ),
              ),
            ),
            ResponsiveGridCol(
              md: 6,
              xs: 12,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildTextField(
                  controller: emergencyPhoneController,
                  label: 'Teléfono',
                  hint: '809-000-0000',
                ),
              ),
            ),
          ]),
          ResponsiveGridRow(children: [
            ResponsiveGridCol(
              md: 6,
              xs: 12,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildTextField(
                  controller: emergencyRelationController,
                  label: 'Parentesco',
                  hint: 'Ej: Esposo/a, Padre, Madre, Hijo/a',
                ),
              ),
            ),
          ]),
          const SizedBox(height: 24),
          Text('Notas Adicionales',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: kMainColor,
              )),
          const SizedBox(height: 16),
          TextFormField(
            controller: notesController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Observaciones o notas sobre el empleado...',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      showCursor: true,
      cursorColor: kTitleColor,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
      ),
      validator: validator,
    );
  }

  Widget _buildDatePickerField({
    required BuildContext context,
    required String label,
    required DateTime? selectedDate,
    required Function(DateTime) onChanged,
    bool allowNull = false,
  }) {
    return InkWell(
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime(1950),
          lastDate: DateTime(2100),
        );

        if (pickedDate != null) {
          onChanged(pickedDate);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(IconlyLight.calendar, color: kNeutral500),
        ),
        child: Text(
          selectedDate != null
              ? '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'
              : allowNull
                  ? 'No definido'
                  : 'Seleccionar fecha',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }

  /// Muestra el diálogo para agregar un nuevo cargo/designación
  Future<void> _showAddDesignationDialog() async {
    await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStates) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: AddDesignationScreen(
                listOfIncomeCategory: _designations,
              ),
            );
          },
        );
      },
    );

    // Recargar la lista de designaciones después de agregar una nueva
    final updatedDesignations = await DesignationRepository().getAllDesignation();
    setState(() {
      _designations = updatedDesignations;
    });
  }

  void _saveEmployee() async {
    if (formKey.currentState?.validate() ?? false) {
      dynamic id = widget.employeeModel?.id ?? DateTime.now().millisecondsSinceEpoch;

      EmployeeModel employee = EmployeeModel(
        id: id,
        name: nameController.text.trim(),
        lastName: lastNameController.text.trim(),
        cedula: cedulaController.text.trim(),
        phoneNumber: phoneNumberController.text.trim(),
        phoneNumber2: phoneNumber2Controller.text.trim().isEmpty
            ? null
            : phoneNumber2Controller.text.trim(),
        email: emailController.text.trim(),
        address: addressController.text.trim(),
        city: cityController.text.trim().isEmpty ? null : cityController.text.trim(),
        province: selectedProvince,
        gender: selectedGender ?? 'Otro',
        maritalStatus: selectedMaritalStatus ?? 'Soltero/a',
        dependents: dependents,
        employmentType: selectedEmploymentType ?? 'Tiempo Completo',
        contractType: selectedContractType ?? 'Indefinido',
        designationId: selectedDesignation?.id ?? 0,
        designation: selectedDesignation?.designation ?? 'Sin Cargo',
        department: departmentController.text.trim().isEmpty
            ? 'General'
            : departmentController.text.trim(),
        birthDate: birthDate,
        joiningDate: joiningDate,
        contractEndDate: contractEndDate,
        salary: salaryController.text.trim().isEmpty
            ? 0.0
            : double.tryParse(salaryController.text.trim()) ?? 0.0,
        salaryType: selectedSalaryType ?? 'Mensual',
        paymentMethod: selectedPaymentMethod ?? 'Transferencia',
        bankName: selectedBank,
        bankAccountNumber: bankAccountController.text.trim().isEmpty
            ? null
            : bankAccountController.text.trim(),
        bankAccountType: selectedBankAccountType,
        afpNumber: afpNumberController.text.trim().isEmpty
            ? null
            : afpNumberController.text.trim(),
        afpProvider: selectedAFPProvider ?? AFPProviders.all.first,
        sfsNumber: sfsNumberController.text.trim().isEmpty
            ? null
            : sfsNumberController.text.trim(),
        sfsProvider: selectedARSProvider ?? ARSProviders.all.first,
        nss: nssController.text.trim().isEmpty ? null : nssController.text.trim(),
        emergencyContactName: emergencyNameController.text.trim().isEmpty
            ? null
            : emergencyNameController.text.trim(),
        emergencyContactPhone: emergencyPhoneController.text.trim().isEmpty
            ? null
            : emergencyPhoneController.text.trim(),
        emergencyContactRelation: emergencyRelationController.text.trim().isEmpty
            ? null
            : emergencyRelationController.text.trim(),
        status: selectedStatus ?? 'Activo',
        photoUrl: widget.employeeModel?.photoUrl,
        notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
        vacationDaysAccrued: widget.employeeModel?.vacationDaysAccrued ?? 0,
        vacationDaysTaken: widget.employeeModel?.vacationDaysTaken ?? 0,
      );

      bool result;
      if (widget.employeeModel != null) {
        result = await EmployeeRepository().updateEmployee(employee: employee);
      } else {
        result = await EmployeeRepository().addEmployee(employee: employee);
      }

      if (result) {
        // ignore: unused_result
        widget.ref.refresh(employeeProvider);
        if (mounted) {
          GoRouter.of(context).pop();
        }
      }
    }
  }
}
