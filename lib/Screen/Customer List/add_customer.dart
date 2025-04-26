import 'package:firebase_core/firebase_core.dart' as firebase_core;
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/Provider/subacription_plan_provider.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;

import '../../Provider/customer_provider.dart';
import '../../commas.dart';
import '../../const.dart';
import '../../model/customer_model.dart';
import '../../subscription.dart';
import '../Widgets/Constant Data/constant.dart';
import '../Widgets/dotted_border/dotted_border.dart';

class AddCustomer extends StatefulWidget {
  const AddCustomer({super.key, required this.typeOfCustomerAdd, required this.listOfPhoneNumber});

  final String typeOfCustomerAdd;
  final List<String> listOfPhoneNumber;

  @override
  State<AddCustomer> createState() => _AddCustomerState();
}

class _AddCustomerState extends State<AddCustomer> {
  bool saleButtonClicked = false;
  String profilePicture = 'https://firebasestorage.googleapis.com/v0/b/maanpos.appspot.com/o/Profile%20Picture%2Fblank-profile-picture-973460_1280.webp?alt=media&token=3578c1e0-7278-4c03-8b56-dd007a9befd3';

  bool receiveWhatsappUpdates = false;
  Uint8List? image;

  Future<void> uploadFile() async {
    if (kIsWeb) {
      try {
        Uint8List? bytesFromPicker = await ImagePickerWeb.getImageAsBytes();
        if (bytesFromPicker!.isNotEmpty) {
          EasyLoading.show(status: '${lang.S.of(context).uploading}... ', dismissOnTap: false);
        }

        var snapshot = await FirebaseStorage.instance.ref('Profile Picture/${DateTime.now().millisecondsSinceEpoch}').putData(bytesFromPicker);
        var url = await snapshot.ref.getDownloadURL();
        //EasyLoading.showSuccess('Upload Successful!');
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
  String pageName = 'Add Customer';

  String selectedCategories = 'Retailer';

  @override
  initState() {
    super.initState();
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
  }

  DropdownButton<String> getCategories() {
    List<DropdownMenuItem<String>> dropDownItems = [];
    for (String des in categories) {
      var item = DropdownMenuItem(
        value: des,
        child: Text(
          des,
          style: kTextStyle.copyWith(fontWeight: FontWeight.normal, color: kTitleColor),
        ),
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
  TextEditingController customerPreviousDueController = TextEditingController();
  TextEditingController customerAddressController = TextEditingController();

  String openingBalance = '';

  GlobalKey<FormState> addCustomer = GlobalKey<FormState>();

  bool validateAndSave() {
    final form = addCustomer.currentState;
    if (form!.validate()) {
      form.save();
      return true;
    } else {
      return false;
    }
  }

  ScrollController mainScroll = ScrollController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    return SafeArea(
      child: Scaffold(
        backgroundColor: kDarkWhite,
        body: Consumer(builder: (context, ref, _) {
          final currentSubcription = ref.watch(singleUserSubscriptionPlanProvider);
          return currentSubcription.when(data: (data) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // const TopBar(),
                  const SizedBox(height: 20.0),
                  Padding(
                    padding: const EdgeInsets.only(left: 10.0),
                    child: Row(
                      children: [
                        Text(
                          pageName,
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                        )
                      ],
                    ),
                  ),
                  ResponsiveGridRow(children: [
                    ResponsiveGridCol(
                        xs: 12,
                        md: screenWidth < 778 ? 12 : 8,
                        lg: screenWidth < 778 ? 12 : 8,
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
                                  const SizedBox(height: 5),

                                  ///__________Name_&_Phone___________________________________
                                  ResponsiveGridRow(children: [
                                    ResponsiveGridCol(
                                        xs: 12,
                                        md: 6,
                                        lg: 6,
                                        child: Padding(
                                          padding: const EdgeInsets.all(10.0),
                                          child: TextFormField(
                                            validator: (value) {
                                              if (value.isEmptyOrNull) {
                                                // return 'Customer Name Is Required.';
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
                                            decoration: InputDecoration(
                                              labelText: lang.S.of(context).customerName,
                                              hintText: lang.S.of(context).enterCustomerName,
                                            ),
                                          ),
                                        )),
                                    ResponsiveGridCol(
                                        xs: 12,
                                        md: 6,
                                        lg: 6,
                                        child: Padding(
                                          padding: const EdgeInsets.all(10.0),
                                          child: TextFormField(
                                            validator: (value) {
                                              if (value.isEmptyOrNull) {
                                                // return 'Phone Number is required.';
                                                return '${lang.S.of(context).phoneNumberIsRequired}.';
                                              } else if (widget.listOfPhoneNumber.contains(value.removeAllWhiteSpace().toLowerCase())) {
                                                //return 'Phone Number already exists';
                                                return lang.S.of(context).phoneNumberAlreadyExists;
                                              } else if (double.tryParse(value!) == null && value.isNotEmpty) {
                                                // return 'Please Enter valid phone number.';
                                                return '${lang.S.of(context).pleaseEnterValidPhoneNumber}.';
                                              } else {
                                                return null;
                                              }
                                            },
                                            onSaved: (value) {
                                              customerPhoneController.text = value!;
                                            },
                                            controller: customerPhoneController,
                                            showCursor: true,
                                            cursorColor: kTitleColor,
                                            decoration: InputDecoration(
                                              labelText: lang.S.of(context).phoneNumber,
                                              hintText: lang.S.of(context).enterYourPhoneNumber,
                                            ),
                                          ),
                                        )),
                                  ]),

                                  ///__________Email_&_Address___________________________________
                                  ResponsiveGridRow(children: [
                                    ResponsiveGridCol(
                                        xs: 12,
                                        md: 6,
                                        lg: 6,
                                        child: Padding(
                                          padding: const EdgeInsets.all(10.0),
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
                                            decoration: InputDecoration(
                                              labelText: lang.S.of(context).email,
                                              hintText: lang.S.of(context).enterYourEmailAddress,
                                            ),
                                          ),
                                        )),
                                    ResponsiveGridCol(
                                      xs: 12,
                                      md: 6,
                                      lg: 6,
                                      child: Padding(
                                        padding: const EdgeInsets.all(10.0),
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
                                          decoration: InputDecoration(
                                            labelText: lang.S.of(context).address,
                                            hintText: lang.S.of(context).enterYourAddress,
                                          ),
                                        ),
                                      ),
                                    )
                                  ]),

                                  ///__________Opening_&_Type__________________________________________
                                  ResponsiveGridRow(children: [
                                    ResponsiveGridCol(
                                        xs: 12,
                                        md: 6,
                                        lg: 6,
                                        child: Padding(
                                          padding: const EdgeInsets.all(10.0),
                                          child: TextFormField(
                                            onChanged: (value) {
                                              openingBalance = value.replaceAll(',', '');
                                              var formattedText = myFormat.format(int.parse(openingBalance));
                                              customerPreviousDueController.value = customerPreviousDueController.value.copyWith(
                                                text: formattedText,
                                                selection: TextSelection.collapsed(offset: formattedText.length),
                                              );
                                            },
                                            validator: (value) {
                                              if (double.tryParse(openingBalance) == null && openingBalance.isNotEmpty) {
                                                //return 'Please Enter valid balance.';
                                                return '${lang.S.of(context).pleaseEnterValidBalance}.';
                                              } else {
                                                return null;
                                              }
                                            },
                                            onSaved: (value) {
                                              customerPreviousDueController.text = value!;
                                            },
                                            controller: customerPreviousDueController,
                                            showCursor: true,
                                            cursorColor: kTitleColor,
                                            decoration: InputDecoration(
                                              labelText: lang.S.of(context).openingBalance,
                                              hintText: lang.S.of(context).enterOpeningBalance,
                                            ),
                                          ),
                                        )),
                                    ResponsiveGridCol(
                                        xs: 12,
                                        md: 6,
                                        lg: 6,
                                        child: Padding(
                                          padding: const EdgeInsets.all(10.0),
                                          child: SizedBox(
                                            height: 48,
                                            child: FormField(
                                              builder: (FormFieldState<dynamic> field) {
                                                return InputDecorator(
                                                  decoration: InputDecoration(contentPadding: const EdgeInsets.all(6.0), floatingLabelBehavior: FloatingLabelBehavior.always, labelText: lang.S.of(context).type),
                                                  child: Theme(data: ThemeData(highlightColor: dropdownItemColor, focusColor: dropdownItemColor, hoverColor: dropdownItemColor), child: DropdownButtonHideUnderline(child: getCategories())),
                                                );
                                              },
                                            ),
                                          ),
                                        ))
                                  ]),

                                  ///__________GST___________________________________
                                  Padding(
                                    padding: const EdgeInsets.all(10.0),
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
                                      decoration: InputDecoration(
                                        //labelText: 'Customer GST',
                                        labelText: lang.S.of(context).customerGST,
                                        labelStyle: kTextStyle.copyWith(color: kTitleColor),
                                        // hintText: 'Enter customer GST number',
                                        hintText: lang.S.of(context).enterCustomerGSTNumber,
                                        hintStyle: kTextStyle.copyWith(color: kGreyTextColor),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  data.whatsappMarketingEnabled
                                      ? CheckboxListTile(
                                          value: receiveWhatsappUpdates,
                                          onChanged: (value) {
                                            setState(() {
                                              receiveWhatsappUpdates = value!;
                                            });
                                          },
                                          title: Text(
                                            "${lang.S.of(context).receiveWhatsappUpdates}?",
                                            // 'Receive Whatsapp Updates?',
                                            style: kTextStyle.copyWith(color: kTitleColor),
                                          ),
                                        )
                                      : Container(),
                                ],
                              ),
                            ),
                          ),
                        )),
                    ResponsiveGridCol(
                        xs: 12,
                        md: screenWidth < 778 ? 12 : 4,
                        lg: screenWidth < 778 ? 12 : 4,
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.white,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Text(
                                    lang.S.of(context).saveAndPublished,
                                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                const Divider(
                                  thickness: 1.0,
                                  color: kNeutral300,
                                ),
                                ResponsiveGridRow(children: [
                                  ResponsiveGridCol(
                                    xs: 12,
                                    md: 6,
                                    lg: 6,
                                    child: Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: OutlinedButton(
                                        onPressed: () {
                                          GoRouter.of(context).pop();
                                        },
                                        child: Text(
                                          lang.S.of(context).cancel,
                                        ),
                                      ),
                                    ),
                                  ),
                                  ResponsiveGridCol(
                                      xs: 12,
                                      md: 6,
                                      lg: 6,
                                      child: Padding(
                                        padding: const EdgeInsets.all(10.0),
                                        child: ElevatedButton(
                                          onPressed: saleButtonClicked
                                              ? () {}
                                              : () async {
                                                  if (!isDemo) {
                                                    if (await checkUserRolePermission(type: 'parties') && await Subscription.subscriptionChecker(item: 'Parties')) {
                                                      if (validateAndSave()) {
                                                        try {
                                                          setState(() {
                                                            saleButtonClicked = true;
                                                          });
                                                          EasyLoading.show(status: '${lang.S.of(context).loading}...', dismissOnTap: false);
                                                          final DatabaseReference customerInformationRef = FirebaseDatabase.instance.ref().child(await getUserID()).child('Customers');
                                                          CustomerModel customerModel = CustomerModel(
                                                            customerName: customerNameController.text,
                                                            phoneNumber: customerPhoneController.text,
                                                            type: selectedCategories,
                                                            profilePicture: profilePicture,
                                                            emailAddress: customerEmailController.text,
                                                            customerAddress: customerAddressController.text,
                                                            dueAmount: openingBalance.isEmpty ? '0' : openingBalance,
                                                            openingBalance: openingBalance.isEmpty ? '0' : openingBalance,
                                                            remainedBalance: openingBalance.isEmpty ? '0' : openingBalance,
                                                            gst: gstController.text,
                                                            receiveWhatsappUpdates: receiveWhatsappUpdates,
                                                          );
                                                          await customerInformationRef.push().set(customerModel.toJson());

                                                          ///________subscription_plan_update_________________________________________________
                                                          Subscription.decreaseSubscriptionLimits(itemType: 'partiesNumber', context: context);

                                                          //EasyLoading.showSuccess('Added Successfully!');
                                                          EasyLoading.showSuccess('${lang.S.of(context).addedSuccessfully}!');
                                                          ref.refresh(buyerCustomerProvider);
                                                          ref.refresh(supplierProvider);
                                                          ref.refresh(allCustomerProvider);
                                                          Future.delayed(const Duration(milliseconds: 100), () {
                                                            // Navigator.pop(context);
                                                            GoRouter.of(context).pop();
                                                          });
                                                        } catch (e) {
                                                          setState(() {
                                                            saleButtonClicked = false;
                                                          });
                                                          EasyLoading.dismiss();
                                                          //ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                                                        }
                                                      }
                                                    } else {
                                                      //EasyLoading.showInfo("You don't have permission to add customer");
                                                      EasyLoading.showInfo(lang.S.of(context).youDonNotHavePermissionToAddCustomer);
                                                    }
                                                  } else {
                                                    EasyLoading.showInfo(demoText);
                                                  }
                                                },
                                          child: Text(lang.S.of(context).save),
                                        ),
                                      ))
                                ]),

                                ///____Image__________________
                                Container(
                                  padding: const EdgeInsets.all(20.0),
                                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(10.0), color: kWhite),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CustomDottedBorder(
                                        // padding: const EdgeInsets.all(6),
                                        color: kLitGreyColor,
                                        child: ClipRRect(
                                          borderRadius: const BorderRadius.all(Radius.circular(12)),
                                          child: image != null
                                              ? Image.memory(
                                                  fit: BoxFit.cover,
                                                  image!,
                                                  // width: 150,
                                                  height: 130,
                                                  width: screenWidth,
                                                )
                                              : Container(
                                                  height: 130,
                                                  alignment: Alignment.center,
                                                  width: context.width(),
                                                  padding: const EdgeInsets.all(10.0),
                                                  decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(20.0),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.center,
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Column(
                                                        crossAxisAlignment: CrossAxisAlignment.center,
                                                        children: [
                                                          SvgPicture.asset('images/blank_image.svg').onTap(
                                                            () => uploadFile(),
                                                          ),
                                                          // Icon(MdiIcons.cloudUpload, size: 50.0, color: kLitGreyColor).onTap(() => uploadFile()),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 5.0),
                                                      RichText(
                                                          textAlign: TextAlign.center,
                                                          text: TextSpan(
                                                              text: lang.S.of(context).uploadAImage,
                                                              style: theme.textTheme.titleMedium?.copyWith(
                                                                color: kGreenTextColor,
                                                              ),
                                                              children: [TextSpan(text: lang.S.of(context).orDragAndDropPng, style: theme.textTheme.titleMedium?.copyWith(color: kGreyTextColor))]))
                                                    ],
                                                  ),
                                                ),
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )),
                  ]),
                  // const Footer(),
                ],
              ),
            );
          }, error: (error, stack) {
            return Center(
              child: Text(error.toString()),
            );
          }, loading: () {
            return const Center(
              child: CircularProgressIndicator(),
            );
          });
        }),
      ),
    );
  }
}
