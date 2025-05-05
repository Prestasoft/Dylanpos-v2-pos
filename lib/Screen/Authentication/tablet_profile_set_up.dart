import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart' as firebase_core;
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;
import '../../Provider/profile_provider.dart';
import '../../const.dart';
import '../../model/personal_information_model.dart';
import '../Widgets/Constant Data/button_global.dart';
import '../Widgets/Constant Data/constant.dart';

class TabletProfileSetUp extends StatefulWidget {
  const TabletProfileSetUp({Key? key, required this.personalInformationModel})
      : super(key: key);
  final PersonalInformationModel personalInformationModel;

  static const String route = '/mprofilesetup';

  @override
  State<TabletProfileSetUp> createState() => _TabletProfileSetUpState();
}

class _TabletProfileSetUpState extends State<TabletProfileSetUp> {
  String initialCountry = 'Bangladesh';
  late String companyName, phoneNumber;
  String profilePicture = 'https://i.imgur.com/jlyGd1j.jpg';

  Uint8List? image;

  Future<void> uploadFile() async {
    // File file = File(filePath);
    if (kIsWeb) {
      try {
        Uint8List? bytesFromPicker = await ImagePickerWeb.getImageAsBytes();
        // File? file = await ImagePickerWeb.getImageAsFile();
        EasyLoading.show(
          status: '${lang.S.of(context).uploading}... ',
          dismissOnTap: false,
        );
        var snapshot = await FirebaseStorage.instance
            .ref('Profile Picture/${DateTime.now().millisecondsSinceEpoch}')
            .putData(bytesFromPicker!);
        var url = await snapshot.ref.getDownloadURL();
        //EasyLoading.showSuccess('Upload Successful!');
        EasyLoading.showSuccess('${lang.S.of(context).uploadSuccessful}!');
        setState(() {
          image = bytesFromPicker;
          profilePicture = url.toString();
        });
      } on firebase_core.FirebaseException catch (e) {
        EasyLoading.dismiss();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.code.toString(),
            ),
          ),
        );
      }
    }
  }

  List<String> categories = [
    'Select Business Category',
    'Fashion',
    'Electronic',
    'Computer Store',
    'Vegetable Store',
    'Meat Store',
    'Sweet Store',
  ];

  String dropdownValue = 'Select Business Category';

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
      value: dropdownValue,
      onChanged: (value) {
        setState(() {
          dropdownValue = value!;
        });
      },
    );
  }

  List<String> language = [
    'Select A Language',
    'English',
    'Bengali',
    'Hindi',
    'Urdu',
    'Chinese',
    'French',
    'Spanish',
  ];

  String selectedLanguage = 'Select A Language';

  DropdownButton<String> getLanguage() {
    List<DropdownMenuItem<String>> dropDownItems = [];
    for (String des in language) {
      var item = DropdownMenuItem(
        value: des,
        child: Text(des),
      );
      dropDownItems.add(item);
    }
    return DropdownButton(
      items: dropDownItems,
      value: selectedLanguage,
      onChanged: (value) {
        setState(() {
          selectedLanguage = value!;
        });
      },
    );
  }

  GlobalKey<FormState> globalKey = GlobalKey<FormState>();

  bool validateAndSave() {
    final form = globalKey.currentState;
    if (form!.validate()) {
      form.save();
      return true;
    }
    return false;
  }

  late String customerKey;

  void getCustomerKey(String phoneNumber) async {
    await FirebaseDatabase.instance
        .ref(await getUserID())
        .child('Customers')
        .orderByKey()
        .get()
        .then((value) {
      for (var element in value.children) {
        var data = jsonDecode(jsonEncode(element.value));
        if (data['phoneNumber'].toString() == phoneNumber) {
          customerKey = element.key.toString();
        }
      }
    });
  }

  @override
  void initState() {
    profilePicture = widget.personalInformationModel.pictureUrl;
    selectedLanguage = widget.personalInformationModel.language;
    dropdownValue = widget.personalInformationModel.businessCategory;
    companyNameController.text = widget.personalInformationModel.companyName;
    phoneNumberController.text = widget.personalInformationModel.phoneNumber;
    addressController.text = widget.personalInformationModel.countryName;
    getCustomerKey(widget.personalInformationModel.phoneNumber);
    super.initState();
  }

  TextEditingController companyNameController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();
  TextEditingController addressController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: Column(
                        children: [
                          Container(
                            height: 100,
                            width: 100,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage(appLogo),
                              ),
                            ),
                          ),
                          Divider(
                            thickness: 1.0,
                            color: kGreyTextColor.withOpacity(0.1),
                          ),
                          const SizedBox(height: 10.0),
                          Text(
                            lang.S.of(context).editYourProfile,
                            style: kTextStyle.copyWith(
                                color: kGreyTextColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 21.0),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10.0),
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20.0),
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10.0),
                                      color: kWhite),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      DottedBorderWidget(
                                        color: kLitGreyColor,
                                        child: ClipRRect(
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(12)),
                                          child: Container(
                                            width: context.width(),
                                            padding: const EdgeInsets.all(10.0),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(20.0),
                                            ),
                                            child: Column(
                                              children: [
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    Icon(MdiIcons.cloudUpload,
                                                            size: 50.0,
                                                            color:
                                                                kLitGreyColor)
                                                        .onTap(
                                                            () => uploadFile()),
                                                  ],
                                                ),
                                                const SizedBox(height: 5.0),
                                                RichText(
                                                    text: TextSpan(
                                                        text: lang.S
                                                            .of(context)
                                                            .uploadAImage,
                                                        style: kTextStyle.copyWith(
                                                            color:
                                                                kGreenTextColor,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                        children: [
                                                      TextSpan(
                                                          text: lang.S
                                                              .of(context)
                                                              .orDragAndDropPng,
                                                          style: kTextStyle.copyWith(
                                                              color:
                                                                  kGreyTextColor,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold))
                                                    ])),
                                                image != null
                                                    ? Image.memory(
                                                        image!,
                                                        width: 150,
                                                        height: 150,
                                                      )
                                                    : Image.network(
                                                        profilePicture,
                                                        width: 150,
                                                        height: 150),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10.0),
                                SizedBox(
                                  height: 60.0,
                                  child: FormField(
                                    builder: (FormFieldState<dynamic> field) {
                                      return InputDecorator(
                                        decoration: kInputDecoration.copyWith(
                                            floatingLabelBehavior:
                                                FloatingLabelBehavior.never,
                                            labelText: lang.S
                                                .of(context)
                                                .businessCategory,
                                            border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        5.0))),
                                        child: DropdownButtonHideUnderline(
                                            child: getCategories()),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 10.0),
                                Form(
                                    key: globalKey,
                                    child: Column(
                                      children: [
                                        AppTextField(
                                          controller: companyNameController,
                                          showCursor: true,
                                          cursorColor: kTitleColor,
                                          textFieldType: TextFieldType.EMAIL,
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              // return 'Company Name can\'n be empty';
                                              return lang.S
                                                  .of(context)
                                                  .companyNameCanNotBeEmpty;
                                            } else if (!value.contains('@')) {
                                              //return 'Please enter a Company Name';
                                              return lang.S
                                                  .of(context)
                                                  .pleaseEnterACompanyName;
                                            }
                                            return null;
                                          },
                                          onChanged: (value) {
                                            setState(() {
                                              companyName = value;
                                            });
                                          },
                                          decoration: kInputDecoration.copyWith(
                                            labelText:
                                                lang.S.of(context).companyName,
                                            labelStyle: kTextStyle.copyWith(
                                                color: kTitleColor),
                                            hintText: lang.S
                                                .of(context)
                                                .enterYourCompanyName,
                                            hintStyle: kTextStyle.copyWith(
                                                color: kGreyTextColor),
                                            prefixIcon: Icon(
                                                MdiIcons.officeBuilding,
                                                color: kTitleColor),
                                          ),
                                        ),
                                        const SizedBox(height: 10.0),
                                        AppTextField(
                                          controller: phoneNumberController,
                                          textFieldType: TextFieldType.PHONE,
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              // return 'Phone Number can\'n be empty';
                                              return lang.S
                                                  .of(context)
                                                  .phoneNumberCanNotBeEmpty;
                                            } else if (!value.contains('@')) {
                                              // return 'Please enter Phone Number';
                                              return lang.S
                                                  .of(context)
                                                  .pleaseEnterPhoneNumber;
                                            }
                                            return null;
                                          },
                                          onChanged: (value) {
                                            setState(() {
                                              phoneNumber = value;
                                            });
                                          },
                                          decoration: kInputDecoration.copyWith(
                                            labelText:
                                                lang.S.of(context).phoneNumber,
                                            hintText: lang.S
                                                .of(context)
                                                .enterYourPhoneNumber,
                                            floatingLabelBehavior:
                                                FloatingLabelBehavior.never,
                                            prefixIcon: Icon(MdiIcons.phone,
                                                color: kTitleColor),
                                          ),
                                        ),
                                        const SizedBox(height: 10.0),
                                        AppTextField(
                                          controller: addressController,
                                          textFieldType: TextFieldType.ADDRESS,
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              // return 'Address can\'n be empty';
                                              return lang.S
                                                  .of(context)
                                                  .addressCanNotBeEmpty;
                                            } else if (!value.contains('@')) {
                                              //return 'Please enter Your Address';
                                              return lang.S
                                                  .of(context)
                                                  .pleaseEnterYourAddress;
                                            }
                                            return null;
                                          },
                                          onChanged: (value) {
                                            setState(() {
                                              initialCountry = value;
                                            });
                                          },
                                          decoration: kInputDecoration.copyWith(
                                            labelText:
                                                lang.S.of(context).address,
                                            hintText: lang.S
                                                .of(context)
                                                .enterYourAddress,
                                            floatingLabelBehavior:
                                                FloatingLabelBehavior.never,
                                            prefixIcon: Icon(MdiIcons.warehouse,
                                                color: kTitleColor),
                                          ),
                                        ),
                                      ],
                                    )),
                                const SizedBox(height: 10.0),
                                SizedBox(
                                  height: 60.0,
                                  child: FormField(
                                    builder: (FormFieldState<dynamic> field) {
                                      return InputDecorator(
                                        decoration: kInputDecoration.copyWith(
                                            floatingLabelBehavior:
                                                FloatingLabelBehavior.never,
                                            labelText: lang.S
                                                .of(context)
                                                .selectYourLanguage,
                                            border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        5.0))),
                                        child: DropdownButtonHideUnderline(
                                            child: getLanguage()),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 20.0),
                                ButtonGlobal(
                                  buttontext: lang.S.of(context).continu,
                                  buttonDecoration: kButtonDecoration.copyWith(
                                      color: kGreenTextColor,
                                      borderRadius: BorderRadius.circular(8.0)),
                                  onPressed: () async {
                                    try {
                                      EasyLoading.show(
                                          status:
                                              '${lang.S.of(context).loading}...',
                                          dismissOnTap: false);
                                      DatabaseReference reference =
                                          FirebaseDatabase.instance.ref(
                                              "${FirebaseAuth.instance.currentUser!.uid}/Customers/$customerKey");
                                      PersonalInformationModel
                                          personalInformation =
                                          PersonalInformationModel(
                                        phoneNumber: phoneNumberController.text,
                                        pictureUrl: profilePicture,
                                        companyName: companyNameController.text,
                                        countryName: addressController.text,
                                        language: selectedLanguage,
                                        saleInvoiceCounter: 1,
                                        purchaseInvoiceCounter: 1,
                                        dueInvoiceCounter: 1,
                                        businessCategory: dropdownValue,
                                        shopOpeningBalance: 0,
                                        remainingShopBalance: 0,
                                        currency: '\$',
                                        currentLocale: 'en',
                                        gst: '',
                                      );
                                      await reference
                                          .set(personalInformation.toJson());
                                      // EasyLoading.showSuccess('Added Successfully!');
                                      EasyLoading.showSuccess(
                                          '${lang.S.of(context).addedSuccessfully}!');
                                      // ignore: unused_result
                                      ref.refresh(profileDetailsProvider);
                                      // ignore: use_build_context_synchronously
                                      context.go('/dashboard');
                                    } catch (e) {
                                      EasyLoading.dismiss();
                                      //ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                                    }
                                    // Navigator.pushNamed(context, '/otp');
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            )
          ],
        );
      },
    );
  }
}
