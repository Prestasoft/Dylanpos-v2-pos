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
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddCustomer extends StatefulWidget {
  const AddCustomer({
    super.key,
    required this.typeOfCustomerAdd,
    required this.listOfPhoneNumber,
  });

  final String typeOfCustomerAdd;
  final List<String> listOfPhoneNumber;

  @override
  State<AddCustomer> createState() => _AddCustomerState();
}

class _AddCustomerState extends State<AddCustomer> {
  bool saleButtonClicked = false;
  String profilePicture =
      'https://firebasestorage.googleapis.com/v0/b/maanpos.appspot.com/o/Profile%20Picture%2Fblank-profile-picture-973460_1280.webp?alt=media&token=3578c1e0-7278-4c03-8b56-dd007a9befd3';

  bool receiveWhatsappUpdates = false;
  Uint8List? image;

  Future<void> uploadFile() async {
    if (kIsWeb) {
      try {
        Uint8List? bytesFromPicker = await ImagePickerWeb.getImageAsBytes();
        if (bytesFromPicker!.isNotEmpty) {
          EasyLoading.show(
              status: '${lang.S.of(context).uploading}... ',
              dismissOnTap: false);
        }

        var snapshot = await FirebaseStorage.instance
            .ref('Profile Picture/${DateTime.now().millisecondsSinceEpoch}')
            .putData(bytesFromPicker);
        var url = await snapshot.ref.getDownloadURL();
        EasyLoading.showSuccess('${lang.S.of(context).uploadSuccessful}!');
        setState(() {
          image = bytesFromPicker;
          profilePicture = url.toString();
        });
      } on firebase_core.FirebaseException catch (e) {
        EasyLoading.dismiss();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.code.toString())));
      }
    }
  }

  List<String> categories = [
    'Retailer',
    'Wholesaler',
    'Dealer',
    'Supplier',
  ];
  String pageName = 'Agregar Cliente';

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
          style: kTextStyle.copyWith(
              fontWeight: FontWeight.normal, color: kTitleColor),
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

  TextEditingController searchCedulaController = TextEditingController();
  TextEditingController customerNameController = TextEditingController();
  TextEditingController customerPhoneController = TextEditingController();
  TextEditingController customerEmailController = TextEditingController();
  TextEditingController gstController = TextEditingController();
  TextEditingController customerPreviousDueController = TextEditingController();
  TextEditingController customerAddressController = TextEditingController();

  String openingBalance = '';

  GlobalKey<FormState> addCustomer = GlobalKey<FormState>();

  bool isSearching = false;

  Future<void> searchByCedula() async {
    String cedula = searchCedulaController.text.trim();
    if (cedula.isEmpty) return;

    setState(() {
      isSearching = true;
    });

    try {
      final response = await http
          .get(Uri.parse('https://pres.soft-nh.com/api/consulta_data/$cedula'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Actualizar nombre del cliente
        if (data["padron"] != null) {
          String fullName =
              "${data["padron"]["nombres"]} ${data["padron"]["apellido1"]} ${data["padron"]["apellido2"]}";
          customerNameController.text = fullName;
        }

        // Actualizar imagen del perfil
        if (data["foto"] != null && data["foto"]["Imagen"] != null) {
          String base64Image = data["foto"]["Imagen"];
          // Limpiar el formato de la imagen (remover encabezado si existe)
          if (base64Image.contains(',')) {
            base64Image = base64Image.split(',').last;
          }

          try {
            Uint8List decodedImage = base64.decode(base64Image);
            setState(() {
              image = decodedImage;
              // No necesitamos profilePicture aquí ya que no la estamos subiendo a Firebase todavía
              // El usuario puede decidir guardarla o no
            });
          } catch (e) {
            print('Error decoding image: $e');
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${response.statusCode}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al consultar la cédula: $e')));
    } finally {
      setState(() {
        isSearching = false;
      });
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

  ScrollController mainScroll = ScrollController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    return SafeArea(
      child: Scaffold(
        backgroundColor: kDarkWhite,
        body: Consumer(builder: (context, ref, _) {
          final currentSubcription =
              ref.watch(singleUserSubscriptionPlanProvider);
          return currentSubcription.when(data: (data) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20.0),
                  Padding(
                    padding: const EdgeInsets.only(left: 10.0),
                    child: Row(
                      children: [
                        Text(
                          pageName,
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
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
                                                return '${lang.S.of(context).customerNameIsRequired}.';
                                              } else {
                                                return null;
                                              }
                                            },
                                            onSaved: (value) {
                                              customerNameController.text =
                                                  value!;
                                            },
                                            controller: customerNameController,
                                            showCursor: true,
                                            cursorColor: kTitleColor,
                                            decoration: InputDecoration(
                                              labelText: lang.S
                                                  .of(context)
                                                  .customerName,
                                              hintText: lang.S
                                                  .of(context)
                                                  .enterCustomerName,
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
                                                return '${lang.S.of(context).phoneNumberIsRequired}.';
                                              } else if (widget
                                                  .listOfPhoneNumber
                                                  .contains(value
                                                      .removeAllWhiteSpace()
                                                      .toLowerCase())) {
                                                return lang.S
                                                    .of(context)
                                                    .phoneNumberAlreadyExists;
                                              } else if (double.tryParse(
                                                          value!) ==
                                                      null &&
                                                  value.isNotEmpty) {
                                                return '${lang.S.of(context).pleaseEnterValidPhoneNumber}.';
                                              } else {
                                                return null;
                                              }
                                            },
                                            onSaved: (value) {
                                              customerPhoneController.text =
                                                  value!;
                                            },
                                            controller: customerPhoneController,
                                            showCursor: true,
                                            cursorColor: kTitleColor,
                                            decoration: InputDecoration(
                                              labelText: lang.S
                                                  .of(context)
                                                  .phoneNumber,
                                              hintText: lang.S
                                                  .of(context)
                                                  .enterYourPhoneNumber,
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
                                              customerEmailController.text =
                                                  value!;
                                            },
                                            controller: customerEmailController,
                                            showCursor: true,
                                            cursorColor: kTitleColor,
                                            decoration: InputDecoration(
                                              labelText:
                                                  lang.S.of(context).email,
                                              hintText: lang.S
                                                  .of(context)
                                                  .enterYourEmailAddress,
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
                                            customerAddressController.text =
                                                value!;
                                          },
                                          controller: customerAddressController,
                                          showCursor: true,
                                          cursorColor: kTitleColor,
                                          decoration: InputDecoration(
                                            labelText:
                                                lang.S.of(context).address,
                                            hintText: lang.S
                                                .of(context)
                                                .enterYourAddress,
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
                                              openingBalance =
                                                  value.replaceAll(',', '');
                                              var formattedText =
                                                  myFormat.format(int.parse(
                                                      openingBalance));
                                              customerPreviousDueController
                                                      .value =
                                                  customerPreviousDueController
                                                      .value
                                                      .copyWith(
                                                text: formattedText,
                                                selection:
                                                    TextSelection.collapsed(
                                                        offset: formattedText
                                                            .length),
                                              );
                                            },
                                            validator: (value) {
                                              if (double.tryParse(
                                                          openingBalance) ==
                                                      null &&
                                                  openingBalance.isNotEmpty) {
                                                return '${lang.S.of(context).pleaseEnterValidBalance}.';
                                              } else {
                                                return null;
                                              }
                                            },
                                            onSaved: (value) {
                                              customerPreviousDueController
                                                  .text = value!;
                                            },
                                            controller:
                                                customerPreviousDueController,
                                            showCursor: true,
                                            cursorColor: kTitleColor,
                                            decoration: InputDecoration(
                                              labelText: lang.S
                                                  .of(context)
                                                  .openingBalance,
                                              hintText: lang.S
                                                  .of(context)
                                                  .enterOpeningBalance,
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
                                              builder: (FormFieldState<dynamic>
                                                  field) {
                                                return InputDecorator(
                                                  decoration: InputDecoration(
                                                      contentPadding:
                                                          const EdgeInsets.all(
                                                              6.0),
                                                      floatingLabelBehavior:
                                                          FloatingLabelBehavior
                                                              .always,
                                                      labelText: lang.S
                                                          .of(context)
                                                          .type),
                                                  child: Theme(
                                                      data: ThemeData(
                                                          highlightColor:
                                                              dropdownItemColor,
                                                          focusColor:
                                                              dropdownItemColor,
                                                          hoverColor:
                                                              dropdownItemColor),
                                                      child: DropdownButtonHideUnderline(
                                                          child:
                                                              getCategories())),
                                                );
                                              },
                                            ),
                                          ),
                                        ))
                                  ]),

                                  ///__________Cédula (GST) con botón de búsqueda___________________________________
                                  Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: TextFormField(
                                      controller: searchCedulaController,
                                      decoration: InputDecoration(
                                        labelText: 'Cédula',
                                        hintText: 'Ingrese el número de cédula',
                                        suffixIcon: isSearching
                                            ? Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : IconButton(
                                                icon: Icon(Icons.search),
                                                onPressed: searchByCedula,
                                              ),
                                      ),
                                      onFieldSubmitted: (value) {
                                        searchByCedula();
                                      },
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
                                            style: kTextStyle.copyWith(
                                                color: kTitleColor),
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
                                    style: theme.textTheme.titleLarge
                                        ?.copyWith(fontWeight: FontWeight.w600),
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
                                                    if (await Subscription
                                                        .subscriptionChecker(
                                                            item: 'Parties')) {
                                                      if (validateAndSave()) {
                                                        try {
                                                          setState(() {
                                                            saleButtonClicked =
                                                                true;
                                                          });
                                                          EasyLoading.show(
                                                              status:
                                                                  '${lang.S.of(context).loading}...',
                                                              dismissOnTap:
                                                                  false);

                                                          // Subir imagen a Firebase si se obtuvo del API
                                                          if (image != null) {
                                                            var snapshot =
                                                                await FirebaseStorage
                                                                    .instance
                                                                    .ref(
                                                                        'Profile Picture/${DateTime.now().millisecondsSinceEpoch}')
                                                                    .putData(
                                                                        image!);
                                                            profilePicture =
                                                                await snapshot
                                                                    .ref
                                                                    .getDownloadURL();
                                                          }

                                                          final DatabaseReference
                                                              customerInformationRef =
                                                              FirebaseDatabase
                                                                  .instance
                                                                  .ref()
                                                                  .child(
                                                                      await getUserID())
                                                                  .child(
                                                                      'Customers');
                                                          CustomerModel
                                                              customerModel =
                                                              CustomerModel(
                                                            customerName:
                                                                customerNameController
                                                                    .text,
                                                            phoneNumber:
                                                                customerPhoneController
                                                                    .text,
                                                            type:
                                                                selectedCategories,
                                                            profilePicture:
                                                                profilePicture,
                                                            emailAddress:
                                                                customerEmailController
                                                                    .text,
                                                            customerAddress:
                                                                customerAddressController
                                                                    .text,
                                                            dueAmount:
                                                                openingBalance
                                                                        .isEmpty
                                                                    ? '0'
                                                                    : openingBalance,
                                                            openingBalance:
                                                                openingBalance
                                                                        .isEmpty
                                                                    ? '0'
                                                                    : openingBalance,
                                                            remainedBalance:
                                                                openingBalance
                                                                        .isEmpty
                                                                    ? '0'
                                                                    : openingBalance,
                                                            gst: searchCedulaController
                                                                .text, // Guardamos la cédula aquí
                                                            receiveWhatsappUpdates:
                                                                receiveWhatsappUpdates,
                                                          );
                                                          await customerInformationRef
                                                              .push()
                                                              .set(customerModel
                                                                  .toJson());

                                                          ///________subscription_plan_update_________________________________________________
                                                          Subscription
                                                              .decreaseSubscriptionLimits(
                                                                  itemType:
                                                                      'partiesNumber',
                                                                  context:
                                                                      context);

                                                          EasyLoading.showSuccess(
                                                              '${lang.S.of(context).addedSuccessfully}!');
                                                          ref.refresh(
                                                              buyerCustomerProvider);
                                                          ref.refresh(
                                                              supplierProvider);
                                                          ref.refresh(
                                                              allCustomerProvider);
                                                          Future.delayed(
                                                              const Duration(
                                                                  milliseconds:
                                                                      100), () {
                                                            GoRouter.of(context)
                                                                .pop();
                                                          });
                                                        } catch (e) {
                                                          setState(() {
                                                            saleButtonClicked =
                                                                false;
                                                          });
                                                          EasyLoading.dismiss();
                                                        }
                                                      }
                                                    } else {
                                                      EasyLoading.showInfo(lang
                                                          .S
                                                          .of(context)
                                                          .youDonNotHavePermissionToAddCustomer);
                                                    }
                                                  } else {
                                                    EasyLoading.showInfo(
                                                        demoText);
                                                  }
                                                },
                                          child: Text(lang.S.of(context).save),
                                        ),
                                      ))
                                ]),

                                ///____Image__________________
                                Container(
                                  padding: const EdgeInsets.all(20.0),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10.0),
                                    color: kWhite,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CustomDottedBorder(
                                        color: kLitGreyColor,
                                        child: Container(
                                          height: 130,
                                          width: double.infinity,
                                          alignment: Alignment.center,
                                          child: ClipRRect(
                                            borderRadius:
                                                const BorderRadius.all(
                                                    Radius.circular(12)),
                                            child: image != null
                                                ? Container(
                                                    constraints: BoxConstraints(
                                                      maxHeight: 130,
                                                      maxWidth: 130,
                                                    ),
                                                    child: Image.memory(
                                                      image!,
                                                      fit: BoxFit.contain,
                                                    ),
                                                  )
                                                : Container(
                                                    height: 130,
                                                    alignment: Alignment.center,
                                                    width: context.width(),
                                                    padding:
                                                        const EdgeInsets.all(
                                                            10.0),
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20.0),
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .center,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .center,
                                                          children: [
                                                            SvgPicture.asset(
                                                                    'images/blank_image.svg')
                                                                .onTap(() =>
                                                                    uploadFile()),
                                                          ],
                                                        ),
                                                        const SizedBox(
                                                            height: 5.0),
                                                        RichText(
                                                          textAlign:
                                                              TextAlign.center,
                                                          text: TextSpan(
                                                            text: lang.S
                                                                .of(context)
                                                                .uploadAImage,
                                                            style: theme
                                                                .textTheme
                                                                .titleMedium
                                                                ?.copyWith(
                                                              color:
                                                                  kGreenTextColor,
                                                            ),
                                                            children: [
                                                              TextSpan(
                                                                text:
                                                                    ' ', // Espacio entre los textos
                                                              ),
                                                              TextSpan(
                                                                text: lang.S
                                                                    .of(context)
                                                                    .orDragAndDropPng,
                                                                style: theme
                                                                    .textTheme
                                                                    .titleMedium
                                                                    ?.copyWith(
                                                                  color:
                                                                      kGreyTextColor,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )),
                  ]),
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
