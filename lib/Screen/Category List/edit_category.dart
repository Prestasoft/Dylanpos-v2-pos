import 'dart:convert';

import 'package:firebase_core/firebase_core.dart' as firebase_core;
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;

import '../../Provider/customer_provider.dart';
import '../../const.dart';
import '../../model/customer_model.dart';
import '../Widgets/Constant Data/button_global.dart';
import '../Widgets/Constant Data/constant.dart';

class EditCategories extends StatefulWidget {
  const EditCategories({super.key, required this.customerModel, required this.typeOfCustomerAdd, required this.popupContext, required this.allPreviousCustomer});

  final List<CustomerModel> allPreviousCustomer;
  final CustomerModel customerModel;
  final String typeOfCustomerAdd;
  final BuildContext popupContext;

  @override
  State<EditCategories> createState() => _EditCategoriesState();
}

class _EditCategoriesState extends State<EditCategories> {
  GlobalKey<FormState> addCustomer = GlobalKey<FormState>();

  late String customerKey;

  void getCustomerKey(String phoneNumber) async {
    await FirebaseDatabase.instance.ref(await getUserID()).child('Customers').orderByKey().get().then((value) {
      for (var element in value.children) {
        var data = jsonDecode(jsonEncode(element.value));
        if (data['phoneNumber'].toString() == phoneNumber) {
          customerKey = element.key.toString();
        }
      }
    });
  }

  String profilePicture = '';

  Uint8List? image;

  Future<void> uploadFile() async {
    if (kIsWeb) {
      try {
        Uint8List? bytesFromPicker = await ImagePickerWeb.getImageAsBytes();
        if (bytesFromPicker!.isNotEmpty) {
          EasyLoading.show(
            status: '${lang.S.of(context).uploading}... ',
            dismissOnTap: false,
          );
        }
        var snapshot = await FirebaseStorage.instance.ref('Profile Picture/${DateTime.now().millisecondsSinceEpoch}').putData(bytesFromPicker);
        var url = await snapshot.ref.getDownloadURL();
        EasyLoading.showSuccess('${lang.S.of(context).uploadSuccessful}!');
        setState(() {
          image = bytesFromPicker;
          profilePicture = url.toString();
        });
      } on firebase_core.FirebaseException catch (e) {
        EasyLoading.dismiss();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.code.toString())));
      }
    }
  }

  List<String> categories = [
    'Retailer',
    'Wholesaler',
    'Dealer',
    'Supplier',
  ];
  String pageName = 'Edit Customer';

  String selectedCategories = 'Retailer';

  DropdownButton<String> getCategories() {
    List<DropdownMenuItem<String>> dropDownItems = [];
    for (String des in categories) {
      var item = DropdownMenuItem(
        value: des,
        child: Text(des),
      );
      dropDownItems.add(item);
    }
    return DropdownButton(
      items: dropDownItems,
      value: selectedCategories,
      onChanged: (value) {
        setState(() {
          selectedCategories = value!;
        });
      },
    );
  }

  TextEditingController customerNameController = TextEditingController();
  TextEditingController customerPhoneController = TextEditingController();
  TextEditingController customerEmailController = TextEditingController();
  TextEditingController gstController = TextEditingController();
  TextEditingController customerAddressController = TextEditingController();
  bool receiveWhatsappUpdates = false;

  @override
  void initState() {
    checkCurrentUserAndRestartApp();
    if (widget.typeOfCustomerAdd == 'Buyer') {
      categories = [
        'Retailer',
        'Wholesaler',
        'Dealer',
      ];
    } else if (widget.typeOfCustomerAdd == 'Supplier') {
      categories = [
        'Supplier',
      ];
      selectedCategories = 'Supplier';
      pageName = 'Add Supplier';
    }
    selectedCategories = widget.customerModel.type;
    profilePicture = widget.customerModel.profilePicture;
    customerNameController.text = widget.customerModel.customerName;
    customerPhoneController.text = widget.customerModel.phoneNumber;
    customerEmailController.text = widget.customerModel.emailAddress;
    customerAddressController.text = widget.customerModel.customerAddress;
    gstController.text = widget.customerModel.gst;
    setWhatsapp();
    getCustomerKey(widget.customerModel.phoneNumber);
    super.initState();
  }

  void setWhatsapp() {
    if (widget.customerModel.receiveWhatsappUpdates != null) {
      receiveWhatsappUpdates = widget.customerModel.receiveWhatsappUpdates!;
    }
  }

  bool validateAndSave() {
    final form = addCustomer.currentState;
    if (form!.validate()) {
      form.save();
      return true;
    } else {
      return false;
    }
  }

  bool isPhoneNumberAlreadyUsed(String phoneNumber) {
    for (var element in widget.allPreviousCustomer) {
      if (element.phoneNumber == phoneNumber) {
        return true;
      }
    }
    return false;
  }

  ScrollController mainScroll = ScrollController();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: kDarkWhite,
        body: Scrollbar(
          controller: mainScroll,
          child: SingleChildScrollView(
            controller: mainScroll,
            scrollDirection: Axis.horizontal,
            child: Consumer(builder: (context, ref, _) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width < 1275 ? 1275 - 240 : MediaQuery.of(context).size.width - 240,
                    // width: context.width() < 1080 ? 1080 - 240 : MediaQuery.of(context).size.width - 240,
                    decoration: const BoxDecoration(color: kDarkWhite),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            //_______________________________top_bar____________________________
                            // const TopBar(),
                            const SizedBox(height: 20.0),
                            Container(
                              decoration: const BoxDecoration(color: kDarkWhite),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 10.0),
                                    child: Row(
                                      children: [
                                        Text(
                                          pageName,
                                          style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold, fontSize: 21.0),
                                        )
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 4,
                                        child: Padding(
                                          padding: const EdgeInsets.all(10.0),
                                          child: Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(10.0),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(10.0),
                                              color: kWhite,
                                            ),
                                            child: Form(
                                              key: addCustomer,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const SizedBox(height: 20.0),

                                                  ///__________Name_&_Phone___________________________________
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: TextFormField(
                                                          validator: (value) {
                                                            if (value.isEmptyOrNull) {
                                                              //return 'Customer Name Is Required.';
                                                              return '${lang.S.of(context).customerNameIsRequired}.';
                                                            } else {
                                                              return null;
                                                            }
                                                          },
                                                          onSaved: (value) {
                                                            customerNameController.text = value!;
                                                          },
                                                          controller: customerNameController,
                                                          showCursor: true,
                                                          cursorColor: kTitleColor,
                                                          decoration: kInputDecoration.copyWith(
                                                            errorBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.red)),
                                                            labelText: lang.S.of(context).customerName,
                                                            labelStyle: kTextStyle.copyWith(color: kTitleColor),
                                                            hintText: lang.S.of(context).enterCustomerName,
                                                            hintStyle: kTextStyle.copyWith(color: kGreyTextColor),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 20.0),
                                                      Expanded(
                                                        child: TextFormField(
                                                          validator: (value) {
                                                            if (value.isEmptyOrNull) {
                                                              //return 'Please enter a phone number.';
                                                              return '${lang.S.of(context).pleaseEnterAPhoneNumber}.';
                                                            } else if (double.tryParse(value!) == null) {
                                                              // return 'Enter a valid Phone Number';
                                                              return lang.S.of(context).enterAValidPhoneNumber;
                                                            } else if (isPhoneNumberAlreadyUsed(value) && value != widget.customerModel.phoneNumber) {
                                                              // return 'Phone number already Used';
                                                              return lang.S.of(context).phoneNumberAlreadyUsed;
                                                            }
                                                            return null;
                                                          },
                                                          onSaved: (value) {
                                                            customerPhoneController.text = value!;
                                                          },
                                                          controller: customerPhoneController,
                                                          cursorColor: kTitleColor,
                                                          decoration: kInputDecoration.copyWith(
                                                            errorBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.red)),
                                                            labelText: lang.S.of(context).phone,
                                                            labelStyle: kTextStyle.copyWith(color: kTitleColor),
                                                            hintStyle: kTextStyle.copyWith(color: kGreyTextColor),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 20.0),

                                                  ///__________Email_&_DeathOfBarth___________________________________
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: TextFormField(
                                                          validator: (value) {
                                                            return null;
                                                          },
                                                          onSaved: (value) {
                                                            customerEmailController.text = value!;
                                                          },
                                                          controller: customerEmailController,
                                                          showCursor: true,
                                                          cursorColor: kTitleColor,
                                                          decoration: kInputDecoration.copyWith(
                                                            labelText: lang.S.of(context).email,
                                                            labelStyle: kTextStyle.copyWith(color: kTitleColor),
                                                            hintText: lang.S.of(context).enterYourEmailAddress,
                                                            hintStyle: kTextStyle.copyWith(color: kGreyTextColor),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 20.0),
                                                      Expanded(
                                                        ///_____________Address_____________________________________________
                                                        child: TextFormField(
                                                          validator: (value) {
                                                            return null;
                                                          },
                                                          onSaved: (value) {
                                                            customerAddressController.text = value!;
                                                          },
                                                          controller: customerAddressController,
                                                          showCursor: true,
                                                          cursorColor: kTitleColor,
                                                          decoration: kInputDecoration.copyWith(
                                                            labelText: lang.S.of(context).address,
                                                            labelStyle: kTextStyle.copyWith(color: kTitleColor),
                                                            hintText: lang.S.of(context).enterYourAddress,
                                                            hintStyle: kTextStyle.copyWith(color: kGreyTextColor),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 20.0),

                                                  ///__________Opening_&_Type__________________________________________
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: TextFormField(
                                                          validator: (value) {
                                                            return null;
                                                          },
                                                          readOnly: true,
                                                          initialValue: widget.customerModel.dueAmount,
                                                          cursorColor: kTitleColor,
                                                          decoration: kInputDecoration.copyWith(
                                                            labelText: lang.S.of(context).openingBalance,
                                                            labelStyle: kTextStyle.copyWith(color: kTitleColor),
                                                            hintText: lang.S.of(context).enterOpeningBalance,
                                                            hintStyle: kTextStyle.copyWith(color: kGreyTextColor),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 20.0),
                                                      Expanded(
                                                        child: FormField(
                                                          builder: (FormFieldState<dynamic> field) {
                                                            return InputDecorator(
                                                              decoration: InputDecoration(
                                                                  enabledBorder: const OutlineInputBorder(
                                                                    borderRadius: BorderRadius.all(Radius.circular(8.0)),
                                                                    borderSide: BorderSide(color: kBorderColorTextField, width: 2),
                                                                  ),
                                                                  contentPadding: const EdgeInsets.all(6.0),
                                                                  floatingLabelBehavior: FloatingLabelBehavior.always,
                                                                  labelText: lang.S.of(context).type),
                                                              child: Theme(data: ThemeData(highlightColor: dropdownItemColor, focusColor: dropdownItemColor, hoverColor: dropdownItemColor), child: DropdownButtonHideUnderline(child: getCategories())),
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                    ],
                                                  ),

                                                  ///_________GST___________________________________
                                                  const SizedBox(height: 20.0),
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: TextFormField(
                                                          validator: (value) {
                                                            return null;
                                                          },
                                                          onSaved: (value) {
                                                            gstController.text = value!;
                                                          },
                                                          controller: gstController,
                                                          showCursor: true,
                                                          cursorColor: kTitleColor,
                                                          decoration: kInputDecoration.copyWith(
                                                            //labelText: 'Customer GST',
                                                            labelText: lang.S.of(context).customerGST,
                                                            labelStyle: kTextStyle.copyWith(color: kTitleColor),
                                                            // hintText: 'Enter customer GST number',
                                                            hintText: lang.S.of(context).enterCustomerGSTNumber,
                                                            hintStyle: kTextStyle.copyWith(color: kGreyTextColor),
                                                          ),
                                                        ),
                                                      ),
                                                      Expanded(
                                                        child: CheckboxListTile(
                                                          value: receiveWhatsappUpdates,
                                                          onChanged: (value) {
                                                            setState(() {
                                                              receiveWhatsappUpdates = value!;
                                                            });
                                                            // }, title: Text('Receive Whatsapp Updates?', style: kTextStyle.copyWith(color: kTitleColor),),),
                                                          },
                                                          title: Text(
                                                            '${lang.S.of(context).receiveWhatsappUpdates}?',
                                                            style: kTextStyle.copyWith(color: kTitleColor),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 20.0),

                                                  ///_______Button_______________________________________________________

                                                  const SizedBox(height: 30.0),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      SizedBox(
                                                        width: context.width() < 1080 ? 1080 * .18 : MediaQuery.of(context).size.width * .18,
                                                        child: ButtonGlobal(
                                                          buttontext: lang.S.of(context).cancel,
                                                          buttonDecoration: kButtonDecoration.copyWith(color: Colors.red),
                                                          onPressed: () {
                                                            Navigator.pop(widget.popupContext);
                                                            Navigator.pop(context);
                                                          },
                                                        ),
                                                      ),
                                                      const SizedBox(width: 30),
                                                      SizedBox(
                                                        width: context.width() < 1080 ? 1080 * .18 : MediaQuery.of(context).size.width * .18,
                                                        child: ButtonGlobal(
                                                          buttontext: lang.S.of(context).saveAndPublish,
                                                          buttonDecoration: kButtonDecoration.copyWith(color: kGreenTextColor),
                                                          onPressed: () async {
                                                            if (!isDemo) {
                                                              if (validateAndSave()) {
                                                                try {
                                                                  EasyLoading.show(status: '${lang.S.of(context).loading}...', dismissOnTap: false);
                                                                  DatabaseReference reference = FirebaseDatabase.instance.ref("${await getUserID()}/Customers/$customerKey");

                                                                  CustomerModel customerModel = CustomerModel(
                                                                    customerName: customerNameController.text,
                                                                    phoneNumber: customerPhoneController.text,
                                                                    type: selectedCategories,
                                                                    profilePicture: profilePicture,
                                                                    emailAddress: customerEmailController.text,
                                                                    customerAddress: customerAddressController.text,
                                                                    dueAmount: widget.customerModel.dueAmount,
                                                                    remainedBalance: widget.customerModel.remainedBalance,
                                                                    openingBalance: widget.customerModel.openingBalance,
                                                                    gst: gstController.text,
                                                                    receiveWhatsappUpdates: receiveWhatsappUpdates,
                                                                  );

                                                                  ///___________update_customer_________________________________________________________
                                                                  await reference.set(customerModel.toJson());

                                                                  ///_________chanePhone in All invoice_________________________________________________
                                                                  String key = '';
                                                                  widget.customerModel.phoneNumber != customerModel.phoneNumber || widget.customerModel.customerName != customerModel.customerName
                                                                      ? widget.customerModel.type != 'Supplier'
                                                                          ? await FirebaseDatabase.instance.ref(await getUserID()).child('Sales Transition').orderByKey().get().then((value) async {
                                                                              for (var element in value.children) {
                                                                                var data = jsonDecode(jsonEncode(element.value));
                                                                                if (data['customerPhone'].toString() == widget.customerModel.phoneNumber) {
                                                                                  key = element.key.toString();
                                                                                  DatabaseReference reference = FirebaseDatabase.instance.ref("${await getUserID()}/Sales Transition/$key");
                                                                                  await reference.update({'customerName': customerModel.customerName, 'customerPhone': customerModel.phoneNumber});
                                                                                }
                                                                              }
                                                                            })
                                                                          : await FirebaseDatabase.instance.ref(await getUserID()).child('Purchase Transition').orderByKey().get().then((value) async {
                                                                              for (var element in value.children) {
                                                                                var data = jsonDecode(jsonEncode(element.value));
                                                                                if (data['customerPhone'].toString() == widget.customerModel.phoneNumber) {
                                                                                  key = element.key.toString();
                                                                                  DatabaseReference reference = FirebaseDatabase.instance.ref("${await getUserID()}/Purchase Transition/$key");
                                                                                  await reference.update({'customerName': customerModel.customerName, 'customerPhone': customerModel.phoneNumber});
                                                                                }
                                                                              }
                                                                            })
                                                                      : null;

                                                                  //EasyLoading.showSuccess('Added Successfully!');
                                                                  EasyLoading.showSuccess('${lang.S.of(context).addedSuccessfully}!');

                                                                  ref.refresh(allCustomerProvider);
                                                                  // ignore: use_build_context_synchronously
                                                                  Navigator.pop(widget.popupContext);

                                                                  Future.delayed(const Duration(milliseconds: 100), () {
                                                                    Navigator.pop(context);
                                                                  });
                                                                } catch (e) {
                                                                  EasyLoading.dismiss();
                                                                  //ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                                                                }
                                                              }
                                                            } else {
                                                              EasyLoading.showInfo(demoText);
                                                            }
                                                          },
                                                        ),
                                                      ),
                                                    ],
                                                  ),

                                                  const SizedBox(height: 20.0),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 20.0),
                                      Expanded(
                                        flex: 2,
                                        child: Padding(
                                          padding: const EdgeInsets.all(10.0),
                                          child: Container(
                                            padding: const EdgeInsets.all(20.0),
                                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10.0), color: kWhite),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                const SizedBox(height: 10.0),
                                                DottedBorderWidget(
                                                  padding: const EdgeInsets.all(6),
                                                  color: kLitGreyColor,
                                                  child: ClipRRect(
                                                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                                                    child: Container(
                                                      width: context.width(),
                                                      padding: const EdgeInsets.all(10.0),
                                                      decoration: BoxDecoration(
                                                        borderRadius: BorderRadius.circular(20.0),
                                                      ),
                                                      child: Column(
                                                        children: [
                                                          Column(
                                                            crossAxisAlignment: CrossAxisAlignment.center,
                                                            children: [
                                                              Icon(MdiIcons.cloudUpload, size: 50.0, color: kLitGreyColor).onTap(() => uploadFile()),
                                                            ],
                                                          ),
                                                          const SizedBox(height: 5.0),
                                                          RichText(text: TextSpan(text: lang.S.of(context).uploadAImage, style: kTextStyle.copyWith(color: kGreenTextColor, fontWeight: FontWeight.bold), children: [TextSpan(text: lang.S.of(context).orDragAndDropPng, style: kTextStyle.copyWith(color: kGreyTextColor, fontWeight: FontWeight.bold))]))
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                image != null
                                                    ? Image.memory(
                                                        image!,
                                                        width: 150,
                                                        height: 150,
                                                      )
                                                    : Image.network(
                                                        profilePicture,
                                                        width: 150,
                                                        height: 150,
                                                      ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        // const Footer()
                      ],
                    ),
                  )
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}
