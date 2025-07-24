import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;
import '../../Provider/bank_provider.dart';
import '../../model/bank_model.dart';
import '../Widgets/Constant Data/constant.dart';

class EditBank extends ConsumerStatefulWidget {
  const EditBank({Key? key, required this.bank, required this.refresh}) : super(key: key);

  final BankModel bank;
  final VoidCallback refresh;

  @override
  ConsumerState<EditBank> createState() => _EditBankState();
}

class _EditBankState extends ConsumerState<EditBank> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController _bankNameController;
  late TextEditingController _accountNumberController;
  late TextEditingController _accountHolderController;
  late TextEditingController _branchController;

  @override
  void initState() {
    super.initState();
    _bankNameController = TextEditingController(text: widget.bank.bankName);
    _accountNumberController = TextEditingController(text: widget.bank.accountNumber);
    _accountHolderController = TextEditingController(text: widget.bank.accountHolder);
    _branchController = TextEditingController(text: widget.bank.branch);
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountHolderController.dispose();
    _branchController.dispose();
    super.dispose();
  }

  Future<void> _updateBank() async {
    if (_formKey.currentState!.validate()) {
      try {
        EasyLoading.show(status: 'Actualizando banco...');
        
        final bankNotifier = ref.read(bankNotifierProvider.notifier);
        
        // Verificar si el nombre del banco ya existe (excluyendo el banco actual)
        if (_bankNameController.text.trim() != widget.bank.bankName) {
          bool exists = await bankNotifier.checkBankNameExists(
            _bankNameController.text.trim(),
            excludeBankId: widget.bank.bankId,
          );
          if (exists) {
            EasyLoading.showError('Ya existe un banco con ese nombre');
            return;
          }
        }

        final updatedBank = BankModel(
          bankId: widget.bank.bankId,
          bankName: _bankNameController.text.trim(),
          accountNumber: _accountNumberController.text.trim(),
          accountHolder: _accountHolderController.text.trim(),
          branch: _branchController.text.trim(),
          isActive: widget.bank.isActive,
          createdAt: widget.bank.createdAt,
        );

        await bankNotifier.updateBank(updatedBank);
        
        EasyLoading.showSuccess('Banco actualizado exitosamente');
        widget.refresh();
        Navigator.pop(context);
      } catch (e) {
        EasyLoading.showError('Error al actualizar el banco: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4.0),
                    decoration: const BoxDecoration(
                      shape: BoxShape.rectangle,
                    ),
                    child: const Icon(
                      Icons.account_balance,
                      color: kBlueTextColor,
                    ),
                  ),
                  const SizedBox(width: 10.0),
                  Text(
                    'Editar Banco',
                    style: kTextStyle.copyWith(
                      color: kTitleColor,
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(4.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey.shade100,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: kTitleColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20.0),
              TextFormField(
                controller: _bankNameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Banco *',
                  hintText: 'Ej: Banco Popular',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el nombre del banco';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15.0),
              TextFormField(
                controller: _accountNumberController,
                decoration: const InputDecoration(
                  labelText: 'Número de Cuenta',
                  hintText: 'Ej: 123456789',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15.0),
              TextFormField(
                controller: _accountHolderController,
                decoration: const InputDecoration(
                  labelText: 'Titular de la Cuenta',
                  hintText: 'Ej: Juan Pérez',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15.0),
              TextFormField(
                controller: _branchController,
                decoration: const InputDecoration(
                  labelText: 'Sucursal',
                  hintText: 'Ej: Santo Domingo',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 25.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5.0),
                        color: kRedTextColor.withOpacity(0.1),
                      ),
                      child: Text(
                        'Cancelar',
                        style: kTextStyle.copyWith(color: kRedTextColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10.0),
                  GestureDetector(
                    onTap: _updateBank,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5.0),
                        color: kGreenTextColor,
                      ),
                      child: Text(
                        'Actualizar Banco',
                        style: kTextStyle.copyWith(color: kWhite),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}