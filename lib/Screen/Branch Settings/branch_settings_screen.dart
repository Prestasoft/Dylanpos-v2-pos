import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../Provider/branch_settings_provider.dart';
import '../../const.dart';
import '../../model/branch_settings_model.dart';
import '../Widgets/Constant Data/constant.dart';
import '../Widgets/Constant Data/button_global.dart';

class BranchSettingsScreen extends StatefulWidget {
  const BranchSettingsScreen({Key? key}) : super(key: key);
  static const String route = '/branch-settings';

  @override
  State<BranchSettingsScreen> createState() => _BranchSettingsScreenState();
}

class _BranchSettingsScreenState extends State<BranchSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();

  // Controladores de texto
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _rncController = TextEditingController();
  final TextEditingController _branchNameController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _instagramController = TextEditingController();
  final TextEditingController _facebookController = TextEditingController();
  final TextEditingController _footerTextController = TextEditingController();

  String? _logoUrl;
  bool _showLogoInInvoice = true;
  bool _logoOnRight = false;
  Uint8List? _selectedImage;
  bool _isLoading = false;
  bool _hasInitialized = false;
  String? _currentBranchId;

  @override
  void dispose() {
    _scrollController.dispose();
    _companyNameController.dispose();
    _rncController.dispose();
    _branchNameController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _instagramController.dispose();
    _facebookController.dispose();
    _footerTextController.dispose();
    super.dispose();
  }

  void _initializeControllers(BranchSettingsModel settings) {
    if (_hasInitialized) return;

    _companyNameController.text = settings.companyName;
    _rncController.text = settings.rnc;
    _branchNameController.text = settings.branchName;
    _cityController.text = settings.city;
    _addressController.text = settings.address;
    _phoneController.text = settings.phone;
    _whatsappController.text = settings.whatsapp ?? '';
    _emailController.text = settings.email ?? '';
    _websiteController.text = settings.website ?? '';
    _instagramController.text = settings.instagram ?? '';
    _facebookController.text = settings.facebook ?? '';
    _footerTextController.text = settings.invoiceFooterText ?? '';
    _logoUrl = settings.logoUrl;
    _showLogoInInvoice = settings.showLogoInInvoice;
    _logoOnRight = settings.logoOnRight;
    _currentBranchId = settings.branchId;
    _hasInitialized = true;
  }

  Future<void> _uploadLogo() async {
    if (!kIsWeb) return;

    try {
      Uint8List? bytesFromPicker = await ImagePickerWeb.getImageAsBytes();
      if (bytesFromPicker == null) return;

      EasyLoading.show(status: 'Subiendo logo...');

      var snapshot = await FirebaseStorage.instance
          .ref('Branch Logos/${DateTime.now().millisecondsSinceEpoch}')
          .putData(bytesFromPicker);

      var url = await snapshot.ref.getDownloadURL();

      EasyLoading.showSuccess('Logo subido correctamente');

      setState(() {
        _selectedImage = bytesFromPicker;
        _logoUrl = url;
      });
    } catch (e) {
      EasyLoading.showError('Error al subir el logo');
    }
  }

  Future<void> _saveSettings(WidgetRef ref) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    EasyLoading.show(status: 'Guardando...');

    try {
      final settings = BranchSettingsModel(
        branchId: _currentBranchId ?? '',
        companyName: _companyNameController.text.trim(),
        rnc: _rncController.text.trim(),
        logoUrl: _logoUrl,
        branchName: _branchNameController.text.trim(),
        city: _cityController.text.trim(),
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        whatsapp: _whatsappController.text.trim().isEmpty ? null : _whatsappController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        website: _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
        instagram: _instagramController.text.trim().isEmpty ? null : _instagramController.text.trim(),
        facebook: _facebookController.text.trim().isEmpty ? null : _facebookController.text.trim(),
        showLogoInInvoice: _showLogoInInvoice,
        logoOnRight: _logoOnRight,
        invoiceFooterText: _footerTextController.text.trim().isEmpty ? null : _footerTextController.text.trim(),
      );

      final notifier = ref.read(branchSettingsNotifierProvider.notifier);
      final success = await notifier.saveSettings(settings);

      if (success) {
        EasyLoading.showSuccess('Configuración guardada correctamente');
      } else {
        EasyLoading.showError('Error al guardar la configuración');
      }
    } catch (e) {
      EasyLoading.showError('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: kDarkWhite,
        body: Consumer(
          builder: (context, ref, _) {
            final branchSettingsAsync = ref.watch(branchSettingsProvider);

            return branchSettingsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (settings) {
                _initializeControllers(settings);

                return Scrollbar(
                  controller: _scrollController,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(20.0),
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Título
                              _buildHeader(),
                              const SizedBox(height: 20),

                              // Sección: Información del Negocio
                              _buildBusinessInfoSection(),
                              const SizedBox(height: 20),

                              // Sección: Información de la Sucursal
                              _buildBranchInfoSection(),
                              const SizedBox(height: 20),

                              // Sección: Contacto
                              _buildContactSection(),
                              const SizedBox(height: 20),

                              // Sección: Configuración de Factura
                              _buildInvoiceSettingsSection(),
                              const SizedBox(height: 30),

                              // Botón Guardar
                              _buildSaveButton(ref),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kMainColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(MdiIcons.storefront, color: kMainColor, size: 30),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Configuración de Sucursal',
                  style: kTextStyle.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: kTitleColor,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Configure la información que aparecerá en las facturas',
                  style: kTextStyle.copyWith(
                    fontSize: 14,
                    color: kGreyTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: kMainColor, size: 24),
              const SizedBox(width: 10),
              Text(
                title,
                style: kTextStyle.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kTitleColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Divider(color: kGreyTextColor.withOpacity(0.2)),
          const SizedBox(height: 15),
          ...children,
        ],
      ),
    );
  }

  Widget _buildBusinessInfoSection() {
    return _buildSectionCard(
      title: 'Información del Negocio',
      icon: MdiIcons.domain,
      children: [
        // Logo
        Center(
          child: Column(
            children: [
              GestureDetector(
                onTap: _uploadLogo,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: kDarkWhite,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: kMainColor.withOpacity(0.3)),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(_selectedImage!, fit: BoxFit.contain),
                        )
                      : _logoUrl != null && _logoUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(_logoUrl!, fit: BoxFit.contain),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(MdiIcons.cloudUpload, size: 40, color: kMainColor),
                                const SizedBox(height: 10),
                                Text(
                                  'Subir Logo',
                                  style: kTextStyle.copyWith(
                                    color: kMainColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Haga clic para subir el logo de la empresa',
                style: kTextStyle.copyWith(fontSize: 12, color: kGreyTextColor),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Nombre de la empresa
        _buildTextField(
          controller: _companyNameController,
          label: 'Nombre de la Empresa',
          hint: 'Ej: Victor Guzman Fotografía',
          icon: MdiIcons.officeBuildingMarker,
          isRequired: true,
        ),
        const SizedBox(height: 15),

        // RNC
        _buildTextField(
          controller: _rncController,
          label: 'RNC (Registro Nacional del Contribuyente)',
          hint: 'Ej: 131-XXXXXX-X',
          icon: MdiIcons.cardAccountDetails,
          isRequired: true,
        ),
      ],
    );
  }

  Widget _buildBranchInfoSection() {
    return _buildSectionCard(
      title: 'Información de la Sucursal',
      icon: MdiIcons.mapMarker,
      children: [
        // Nombre de la sucursal
        _buildTextField(
          controller: _branchNameController,
          label: 'Nombre de la Sucursal',
          hint: 'Ej: Sucursal Santiago',
          icon: MdiIcons.store,
        ),
        const SizedBox(height: 15),

        // Ciudad
        _buildTextField(
          controller: _cityController,
          label: 'Ciudad',
          hint: 'Ej: Santiago de los Caballeros',
          icon: MdiIcons.city,
          isRequired: true,
        ),
        const SizedBox(height: 15),

        // Dirección
        _buildTextField(
          controller: _addressController,
          label: 'Dirección',
          hint: 'Ej: Av. 27 de Febrero #123, Plaza Central',
          icon: MdiIcons.mapMarkerRadius,
          isRequired: true,
          maxLines: 2,
        ),
        const SizedBox(height: 15),

        // Teléfono
        _buildTextField(
          controller: _phoneController,
          label: 'Teléfono Principal',
          hint: 'Ej: 809-XXX-XXXX',
          icon: MdiIcons.phone,
          isRequired: true,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 15),

        // WhatsApp
        _buildTextField(
          controller: _whatsappController,
          label: 'WhatsApp',
          hint: 'Ej: 809-XXX-XXXX',
          icon: MdiIcons.whatsapp,
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildContactSection() {
    return _buildSectionCard(
      title: 'Información de Contacto',
      icon: MdiIcons.contactsOutline,
      children: [
        // Email
        _buildTextField(
          controller: _emailController,
          label: 'Correo Electrónico',
          hint: 'Ej: info@empresa.com',
          icon: MdiIcons.email,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 15),

        // Website
        _buildTextField(
          controller: _websiteController,
          label: 'Sitio Web',
          hint: 'Ej: www.empresa.com',
          icon: MdiIcons.web,
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 15),

        // Instagram
        _buildTextField(
          controller: _instagramController,
          label: 'Instagram',
          hint: 'Ej: @empresa',
          icon: MdiIcons.instagram,
        ),
        const SizedBox(height: 15),

        // Facebook
        _buildTextField(
          controller: _facebookController,
          label: 'Facebook',
          hint: 'Ej: /empresa',
          icon: MdiIcons.facebook,
        ),
      ],
    );
  }

  Widget _buildInvoiceSettingsSection() {
    return _buildSectionCard(
      title: 'Configuración de Factura',
      icon: MdiIcons.fileDocumentOutline,
      children: [
        // Mostrar logo en factura
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(MdiIcons.image, color: kGreyTextColor, size: 20),
                const SizedBox(width: 10),
                Text(
                  'Mostrar logo en la factura',
                  style: kTextStyle.copyWith(
                    color: kTitleColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            CupertinoSwitch(
              value: _showLogoInInvoice,
              activeColor: kMainColor,
              onChanged: (value) => setState(() => _showLogoInInvoice = value),
            ),
          ],
        ),
        const SizedBox(height: 15),

        // Posición del logo
        if (_showLogoInInvoice) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(MdiIcons.formatHorizontalAlignLeft, color: kGreyTextColor, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Posición del logo',
                    style: kTextStyle.copyWith(
                      color: kTitleColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text('Izquierda', style: kTextStyle.copyWith(color: kGreyTextColor)),
                  const SizedBox(width: 10),
                  CupertinoSwitch(
                    value: _logoOnRight,
                    activeColor: kMainColor,
                    onChanged: (value) => setState(() => _logoOnRight = value),
                  ),
                  const SizedBox(width: 10),
                  Text('Derecha', style: kTextStyle.copyWith(color: kGreyTextColor)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
        ],

        // Texto de pie de factura
        _buildTextField(
          controller: _footerTextController,
          label: 'Texto del pie de factura',
          hint: 'Ej: ¡Gracias por su preferencia!',
          icon: MdiIcons.textBoxOutline,
          maxLines: 2,
        ),

        const SizedBox(height: 20),

        // Vista previa
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: kDarkWhite,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kMainColor.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vista Previa del Encabezado',
                style: kTextStyle.copyWith(
                  color: kMainColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Divider(),
              const SizedBox(height: 10),
              _buildInvoicePreview(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInvoicePreview() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_showLogoInInvoice && !_logoOnRight) ...[
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: kDarkWhite,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: _logoUrl != null && _logoUrl!.isNotEmpty
                      ? Image.network(_logoUrl!, fit: BoxFit.contain)
                      : Icon(MdiIcons.image, color: kGreyTextColor),
                ),
                const SizedBox(width: 15),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _companyNameController.text.isEmpty ? 'Nombre de la Empresa' : _companyNameController.text,
                      style: kTextStyle.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (_rncController.text.isNotEmpty)
                      Text('RNC: ${_rncController.text}', style: kTextStyle.copyWith(fontSize: 12)),
                    if (_phoneController.text.isNotEmpty)
                      Text('Tel: ${_phoneController.text}', style: kTextStyle.copyWith(fontSize: 12)),
                    if (_addressController.text.isNotEmpty)
                      Text(_addressController.text, style: kTextStyle.copyWith(fontSize: 12)),
                    if (_cityController.text.isNotEmpty)
                      Text(_cityController.text, style: kTextStyle.copyWith(fontSize: 12)),
                  ],
                ),
              ),
              if (_showLogoInInvoice && _logoOnRight) ...[
                const SizedBox(width: 15),
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: kDarkWhite,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: _logoUrl != null && _logoUrl!.isNotEmpty
                      ? Image.network(_logoUrl!, fit: BoxFit.contain)
                      : Icon(MdiIcons.image, color: kGreyTextColor),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isRequired = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        hintText: hint,
        prefixIcon: Icon(icon, color: kMainColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: kGreyTextColor.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: kGreyTextColor.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: kMainColor, width: 2),
        ),
        filled: true,
        fillColor: kWhite,
      ),
      validator: isRequired
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Este campo es requerido';
              }
              return null;
            }
          : null,
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildSaveButton(WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : () => _saveSettings(ref),
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Icon(MdiIcons.contentSave),
        label: Text(
          _isLoading ? 'Guardando...' : 'Guardar Configuración',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: kMainColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
