import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart' as firebase_core;
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/Provider/general_setting_provider.dart';
import 'package:salespro_admin/Provider/profile_provider.dart';
import 'package:salespro_admin/Screen/Widgets/Constant%20Data/button_global.dart';
import 'package:salespro_admin/currency.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;
import 'package:salespro_admin/model/personal_information_model.dart';

import '../../Provider/shop_category_provider.dart';
import '../../Route/static_string.dart';
import '../../const.dart';
import '../../model/category_model.dart';
import '../../model/seller_info_model.dart';
import '../../model/shop_category_model.dart';
import '../../subscription.dart';
import '../WareHouse/warehouse_model.dart';
import '../Widgets/Constant Data/constant.dart';

class ProfileAdd extends StatefulWidget {
  static const String route = '/addProfile';

  const ProfileAdd({super.key});

  @override
  State<ProfileAdd> createState() => _ProfileAddState();
}

class _ProfileAddState extends State<ProfileAdd> {
  String profilePicture = 'https://firebasestorage.googleapis.com/v0/b/maanpos.appspot.com/o/Profile%20Picture%2Fblank-profile-picture-973460_1280.webp?alt=media&token=3578c1e0-7278-4c03-8b56-dd007a9befd3';

  Uint8List? image;

  Future<void> uploadFile() async {
    if (kIsWeb) {
      try {
        Uint8List? bytesFromPicker = await ImagePickerWeb.getImageAsBytes();
        bytesFromPicker != null
            ? EasyLoading.show(
                status: 'Uploading... ',
                dismissOnTap: false,
              )
            : null;
        var snapshot = await FirebaseStorage.instance.ref('Profile Picture/${DateTime.now().millisecondsSinceEpoch}').putData(bytesFromPicker!);
        var url = await snapshot.ref.getDownloadURL();
        EasyLoading.showSuccess('Upload Successful!');
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
    'Bag & Luggage',
    'Books & Stationery',
    'Clothing',
    'Construction & Raw materials',
    'Coffee & Tea',
    'Cosmetic & Jewellery',
    'Computer & Electronic',
    'E-Commerce',
    'Furniture',
    'General Store',
    'Gift, Toys & flowers',
    'Grocery, Fruits & Bakery',
    'Handicraft',
    'Home & Kitchen',
    'Hardware & sanitary',
    'Internet, Dish & TV',
    'Laundry',
    'Manufacturing',
    'Mobile Top up',
    'Motorbike & parts',
    'Mobile & Gadgets',
    'Trading',
    'Pharmacy',
    'Poultry & Agro',
    'Pet & Accessories',
    'Rice mill',
    'Super Shop',
    'Sunglasses',
    'Service & Repairing',
    'Sports & Exercise',
    'Shoes',
    'Saloon & Beauty Parlour',
    'Shop Rent & Office Rent',
    'Travel Ticket & Rental',
    'Thai Aluminium & Glass',
    'Vehicles & Parts',
    'Others',
  ];

  // DropdownButton<String> getCategories() {
  //   List<DropdownMenuItem<String>> dropDownItems = [];
  //   for (String des in categories) {
  //     var item = DropdownMenuItem(
  //       value: des,
  //       child: Text(des),
  //     );
  //     dropDownItems.add(item);
  //   }
  //   return DropdownButton(
  //     items: dropDownItems,
  //     value: dropdownValue,
  //     onChanged: (value) {
  //       setState(() {
  //         dropdownValue = value!;
  //       });
  //     },
  //   );
  // }

  //____________________________WareHouseModel_________________

  // WareHouseModel selectedWareHouse = WareHouseModel(warehouseName: 'InHouse', warehouseAddress: '', id: '');

  //__________________________________________________shop_category_______________________________

  ShopCategoryModel? selectedShopCategory;
  DropdownButton<ShopCategoryModel> getShopCategory({required List<ShopCategoryModel> list}) {
    List<DropdownMenuItem<ShopCategoryModel>> dropDownItems = [];
    for (var element in list) {
      dropDownItems.add(DropdownMenuItem(
        value: element,
        child: Text(
          element.categoryName.toString(),
          style: kTextStyle.copyWith(color: kGreyTextColor, fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
      ));
    }

    return DropdownButton(
      icon: const Icon(
        Icons.keyboard_arrow_down_outlined,
        color: kGreyTextColor,
      ),
      items: dropDownItems,
      hint: const Text('Select Shop Category'),
      value: selectedShopCategory,
      onChanged: (ShopCategoryModel? value) {
        setState(() {
          selectedShopCategory = value;
        });
      },
    );
  }

  // String dropdownValue = 'Select Business Category';

  ///_____post_General_category___________________________________________________________________
  Future<void> postGeneralCategory() async {
    final DatabaseReference categoryInformationRef = FirebaseDatabase.instance.ref().child(await getUserID()).child('Categories');
    CategoryModel categoryModel = CategoryModel(categoryName: 'General', size: false, color: false, capacity: false, type: false, weight: false, warranty: false);
    await categoryInformationRef.push().set(categoryModel.toJson());
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
    await FirebaseDatabase.instance.ref(await getUserID()).child('Customers').orderByKey().get().then((value) {
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
    super.initState();
  }

  int opiningBalance = 0;

  TextEditingController companyNameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController gstController = TextEditingController();
  TextEditingController shopOpeningBalanceController = TextEditingController();
  DateTime id = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final tabAndMobileScreen = isMobileAndTab(screenWidth);
    final kLargeFontSize = responsiveValue<double>(context, xs: 18, md: 20, lg: 28);
    final kRegularFontSize = responsiveValue<double>(context, xs: 14, md: 14, lg: 20);
    final kSmallFontSize = responsiveValue<double>(context, xs: 14, md: 14, lg: 18);
    return Scaffold(
        backgroundColor: kMainColor,
        body: Consumer(builder: (context, ref, watch) {
          AsyncValue<List<ShopCategoryModel>> categoryList = ref.watch(shopCategoryProvider);
          final settingProver = ref.watch(generalSettingProvider);
          return settingProver.when(data: (setting) {
            final dynamicNameLogo = setting.commonHeaderLogo.isNotEmpty ? setting.commonHeaderLogo : null;
            final dynamicLogo = setting.mainLogo.isNotEmpty ? setting.mainLogo : null;
            return Padding(
              padding: screenWidth < 400 ? const EdgeInsets.all(8) : const EdgeInsets.all(20.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SizedBox(height: mobileScreen?20: 76,width:mobileScreen?200:255,child: SvgPicture.asset(nameLogo,fit: BoxFit.contain,)),
                    dynamicNameLogo != null
                        ? Image.network(
                            dynamicNameLogo,
                            height: 50,
                          )
                        : SvgPicture.asset(nameLogo, height: 50),
                    Center(
                      child: ResponsiveGridRow(crossAxisAlignment: CrossAxisAlignment.center, children: [
                        ResponsiveGridCol(
                            lg: 6,
                            md: 6,
                            sm: 12,
                            xs: 12,
                            child: Center(
                              child: Container(
                                height: tabAndMobileScreen ? MediaQuery.of(context).size.width / 1.1 : MediaQuery.of(context).size.height / 1.2,
                                decoration: BoxDecoration(image: DecorationImage(image: AssetImage(tabAndMobileScreen ? 'images/loginLogo2.png' : 'images/login logo.png'))),
                              ),
                            )),
                        // ResponsiveGridCol(
                        //     lg:6,
                        //     md: 6,
                        //     xs: 12,
                        //     child: SvgPicture.asset(loginLogo)),
                        ResponsiveGridCol(
                          md: 6,
                          sm: 12,
                          lg: 6,
                          xs: 12,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Colors.white,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                dynamicLogo != null
                                    ? Container(
                                        height: 80,
                                        width: 80,
                                        decoration: BoxDecoration(
                                          image: DecorationImage(
                                            image: NetworkImage(dynamicLogo),
                                          ),
                                        ),
                                      )
                                    : Container(
                                        height: 80,
                                        width: 80,
                                        decoration: BoxDecoration(
                                          image: DecorationImage(
                                            image: AssetImage(appLogo),
                                          ),
                                        ),
                                      ),
                                const SizedBox(height: 30),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Container(
                                    //   padding: const EdgeInsets.all(20.0),
                                    //   decoration: BoxDecoration(borderRadius: BorderRadius.circular(10.0), color: kWhiteTextColor),
                                    //   child: Column(
                                    //     crossAxisAlignment: CrossAxisAlignment.center,
                                    //     children: [
                                    //       DottedBorderWidget(
                                    //         color: kLitGreyColor,
                                    //         child: ClipRRect(
                                    //           borderRadius: const BorderRadius.all(Radius.circular(12)),
                                    //           child: Container(
                                    //             width: context.width(),
                                    //             padding: const EdgeInsets.all(10.0),
                                    //             decoration: BoxDecoration(
                                    //               borderRadius: BorderRadius.circular(20.0),
                                    //             ),
                                    //             child: Column(
                                    //               children: [
                                    //                 Column(
                                    //                   crossAxisAlignment: CrossAxisAlignment.center,
                                    //                   children: [
                                    //                     const Icon(MdiIcons.cloudUpload, size: 50.0, color: kLitGreyColor).onTap(() => uploadFile()),
                                    //                   ],
                                    //                 ),
                                    //                 const SizedBox(height: 5.0),
                                    //                 RichText(
                                    //                     text: TextSpan(
                                    //                         text: 'Upload an image',
                                    //                         style: kTextStyle.copyWith(color: kGreenTextColor, fontWeight: FontWeight.bold),
                                    //                         children: [
                                    //                       TextSpan(
                                    //                           text: ' or drag & drop PNG, JPG',
                                    //                           style: kTextStyle.copyWith(color: kGreyTextColor, fontWeight: FontWeight.bold))
                                    //                     ])),
                                    //                 const SizedBox(height: 10.0),
                                    //                 image != null
                                    //                     ? Image.memory(
                                    //                         image!,
                                    //                         width: 120,
                                    //                         height: 120,
                                    //                       )
                                    //                     : Image.network(profilePicture, width: 120, height: 120),
                                    //               ],
                                    //             ),
                                    //           ),
                                    //         ),
                                    //       ),
                                    //     ],
                                    //   ),
                                    // ),
                                    // const SizedBox(height: 10.0),
                                    Form(
                                      key: globalKey,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ///_______Business_category______________________________________________
                                          categoryList.when(
                                            data: (warehouse) {
                                              return SizedBox(
                                                height: 50.0,
                                                child: FormField(
                                                  builder: (FormFieldState<dynamic> field) {
                                                    return InputDecorator(
                                                      decoration: InputDecoration(
                                                        labelText: lang.S.of(context).businessCategory,
                                                      ),
                                                      child: DropdownButtonHideUnderline(child: getShopCategory(list: warehouse ?? [])),
                                                    );
                                                  },
                                                ),
                                              );
                                            },
                                            error: (e, stack) {
                                              return Center(
                                                child: Text(
                                                  e.toString(),
                                                ),
                                              );
                                            },
                                            loading: () {
                                              return const Center(
                                                child: CircularProgressIndicator(),
                                              );
                                            },
                                          ),
                                          const SizedBox(height: 20.0),
                                          AppTextField(
                                            controller: companyNameController,
                                            showCursor: true,
                                            cursorColor: kTitleColor,
                                            textFieldType: TextFieldType.EMAIL,
                                            validator: (value) {
                                              if (value == null || value.isEmpty) {
                                                return 'Company Name can\'n be empty';
                                              }
                                              return null;
                                            },
                                            decoration: InputDecoration(
                                              labelText: lang.S.of(context).companyName,
                                              hintText: lang.S.of(context).enterYourCompanyName,
                                              prefixIcon: Icon(MdiIcons.officeBuilding, color: kTitleColor),
                                            ),
                                          ),
                                          const SizedBox(height: 20.0),

                                          ///_________phone_number_____________________________________________________
                                          TextFormField(
                                            controller: phoneController,
                                            validator: (value) {
                                              if (value == null || value.isEmpty) {
                                                return 'Phone number can\'n be empty';
                                              } else if (value.length < 8) {
                                                return 'Enter a valid phone number';
                                              }
                                              return null;
                                            },
                                            decoration: InputDecoration(
                                              labelText: lang.S.of(context).phoneNumber,
                                              hintText: lang.S.of(context).enterYourPhoneNumber,
                                              prefixIcon: Icon(MdiIcons.phone, color: kTitleColor),
                                            ),
                                          ),
                                          const SizedBox(height: 20.0),

                                          ///_________Address__________________________________________________________
                                          AppTextField(
                                            controller: addressController,
                                            showCursor: true,
                                            cursorColor: kTitleColor,
                                            textFieldType: TextFieldType.NAME,
                                            validator: (value) {
                                              return null;
                                            },
                                            decoration: const InputDecoration(
                                              labelText: 'Address',
                                              hintText: 'Enter your shop address',
                                              prefixIcon: Icon(Icons.location_city, color: kTitleColor),
                                            ),
                                          ),
                                          const SizedBox(height: 20.0),

                                          ///_________GST__________________________________________________________
                                          AppTextField(
                                            controller: gstController,
                                            showCursor: true,
                                            cursorColor: kTitleColor,
                                            textFieldType: TextFieldType.NUMBER,
                                            validator: (value) {
                                              return null;
                                            },
                                            decoration: const InputDecoration(
                                              labelText: 'Shop GST',
                                              hintText: 'Enter your shop GST number',
                                              prefixIcon: Icon(Icons.location_city, color: kTitleColor),
                                            ),
                                          ),
                                          const SizedBox(height: 20.0),

                                          ///_________Opening_balence_______________________________________________
                                          AppTextField(
                                            controller: shopOpeningBalanceController,
                                            textFieldType: TextFieldType.PHONE,
                                            validator: (value) {
                                              return null;
                                            },
                                            decoration: InputDecoration(
                                              labelText: lang.S.of(context).shopOpeningBalance,
                                              hintText: lang.S.of(context).enterYOurAmount,
                                              prefixIcon: Container(
                                                height: 48,
                                                width: 30,
                                                alignment: Alignment.center,
                                                child: Text(
                                                  currency,
                                                  style: Theme.of(context).textTheme.titleMedium,
                                                ),
                                              ),
                                            ),
                                            inputFormatters: [
                                              FilteringTextInputFormatter.digitsOnly,
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    // const SizedBox(height: 10.0),
                                    // SizedBox(
                                    //   height: 60.0,
                                    //   child: FormField(
                                    //     builder: (FormFieldState<dynamic> field) {
                                    //       return InputDecorator(
                                    //         decoration: kInputDecoration.copyWith(
                                    //             floatingLabelBehavior: FloatingLabelBehavior.never,
                                    //             labelText: 'Select Your Language',
                                    //             border: OutlineInputBorder(borderRadius: BorderRadius.circular(5.0))),
                                    //         child: DropdownButtonHideUnderline(child: getLanguage()),
                                    //       );
                                    //     },
                                    //   ),
                                    // ),
                                    const SizedBox(height: 20.0),

                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(minimumSize: Size(screenWidth, 48)),
                                      onPressed: () async {
                                        if (selectedShopCategory?.categoryName?.isEmpty ?? true) {
                                          EasyLoading.showError('Please select Business Category');
                                        } else if (validateAndSave()) {
                                          try {
                                            EasyLoading.show(status: 'Loading...', dismissOnTap: false);
                                            final DatabaseReference personalInformationRef = FirebaseDatabase.instance.ref().child(await getUserID()).child('Personal Information');
                                            PersonalInformationModel personalInformation = PersonalInformationModel(
                                              phoneNumber: phoneController.text,
                                              pictureUrl: profilePicture,
                                              companyName: companyNameController.text,
                                              countryName: addressController.text,
                                              language: '',
                                              dueInvoiceCounter: 1,
                                              purchaseInvoiceCounter: 1,
                                              saleInvoiceCounter: 1,
                                              businessCategory: selectedShopCategory!.categoryName.toString(),
                                              shopOpeningBalance: shopOpeningBalanceController.text == '' ? 0 : shopOpeningBalanceController.text.toInt(),
                                              remainingShopBalance: shopOpeningBalanceController.text == '' ? 0 : shopOpeningBalanceController.text.toDouble(),
                                              currency: '\$',
                                              currentLocale: 'en',
                                              gst: gstController.text,
                                            );

                                            ///________super_admin_data_post_________________________________________________________
                                            await personalInformationRef.set(personalInformation.toJson());
                                            SellerInfoModel sellerInfoModel = SellerInfoModel(
                                              businessCategory: selectedShopCategory?.categoryName.toString(),
                                              companyName: companyNameController.text,
                                              phoneNumber: phoneController.text,
                                              countryName: addressController.text,
                                              language: '',
                                              pictureUrl: profilePicture,
                                              userID: FirebaseAuth.instance.currentUser!.uid,
                                              email: FirebaseAuth.instance.currentUser!.email,
                                              subscriptionDate: DateTime.now().toString(),
                                              subscriptionName: 'Free',
                                              subscriptionMethod: 'Not Provided',
                                              userRegistrationDate: DateTime.now().toString(),
                                              gst: gstController.text,
                                            );
                                            //_______________warehouse_setup______________
                                            final DatabaseReference productInformationRef = FirebaseDatabase.instance.ref().child(await getUserID()).child('Warehouse List');
                                            WareHouseModel warehouse = WareHouseModel(warehouseName: 'InHouse', warehouseAddress: companyNameController.text, id: id.toString());
                                            await productInformationRef.push().set(warehouse.toJson());
                                            await FirebaseDatabase.instance.ref().child('Admin Panel').child('Seller List').push().set(sellerInfoModel.toJson());

                                            EasyLoading.showSuccess('Added Successfully', duration: const Duration(milliseconds: 1000));

                                            await postGeneralCategory();

                                            ///_________free_subscription_______________________________________

                                            final DatabaseReference subscriptionRef = FirebaseDatabase.instance.ref().child(FirebaseAuth.instance.currentUser!.uid).child('Subscription');
                                            await subscriptionRef.set(Subscription.freeSubscriptionModel.toJson());
                                            EasyLoading.showSuccess('Added Successfully!');
                                            ref.refresh(profileDetailsProvider);
                                            // ignore: use_build_context_synchronously
                                            // Navigator.pushNamed(context, MtHomeScreen.route);
                                            context.go('/dashboard');
                                          } catch (e) {
                                            EasyLoading.dismiss();
                                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                                          }
                                        }
                                        // Navigator.pushNamed(context, '/otp');
                                      },
                                      child: Text(lang.S.of(context).continu),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )
                      ]),
                    ),
                  ],
                ),
              ),
            );
          }, error: (e, stack) {
            return Text(e.toString());
          }, loading: () {
            return Center(
              child: CircularProgressIndicator(),
            );
          });
        }));
    return Scaffold(
      backgroundColor: kDarkWhite,
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SizedBox(
            width: context.width() < 750 ? 750 : MediaQuery.of(context).size.width,
            height: context.height() < 500 ? 500 : MediaQuery.of(context).size.height,
            child: Consumer(
              builder: (context, ref, _) {
                AsyncValue<List<ShopCategoryModel>> categoryList = ref.watch(shopCategoryProvider);
                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Center(
                    child: Container(
                      width: context.width() < 940 ? 477 : MediaQuery.of(context).size.width * .50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            height: 100,
                            width: 200,
                            decoration: BoxDecoration(
                              image: DecorationImage(image: AssetImage(appLogo), fit: BoxFit.fill),
                            ),
                          ),
                          Divider(
                            thickness: 1.0,
                            color: kGreyTextColor.withOpacity(0.1),
                          ),
                          // Text(
                          //   'Setup Your Profile',
                          //   style: kTextStyle.copyWith(color: kGreyTextColor, fontWeight: FontWeight.bold, fontSize: 21.0),
                          //   textAlign: TextAlign.center,
                          // ).visible(false),
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Container(
                                //   padding: const EdgeInsets.all(20.0),
                                //   decoration: BoxDecoration(borderRadius: BorderRadius.circular(10.0), color: kWhiteTextColor),
                                //   child: Column(
                                //     crossAxisAlignment: CrossAxisAlignment.center,
                                //     children: [
                                //       DottedBorderWidget(
                                //         color: kLitGreyColor,
                                //         child: ClipRRect(
                                //           borderRadius: const BorderRadius.all(Radius.circular(12)),
                                //           child: Container(
                                //             width: context.width(),
                                //             padding: const EdgeInsets.all(10.0),
                                //             decoration: BoxDecoration(
                                //               borderRadius: BorderRadius.circular(20.0),
                                //             ),
                                //             child: Column(
                                //               children: [
                                //                 Column(
                                //                   crossAxisAlignment: CrossAxisAlignment.center,
                                //                   children: [
                                //                     const Icon(MdiIcons.cloudUpload, size: 50.0, color: kLitGreyColor).onTap(() => uploadFile()),
                                //                   ],
                                //                 ),
                                //                 const SizedBox(height: 5.0),
                                //                 RichText(
                                //                     text: TextSpan(
                                //                         text: 'Upload an image',
                                //                         style: kTextStyle.copyWith(color: kGreenTextColor, fontWeight: FontWeight.bold),
                                //                         children: [
                                //                       TextSpan(
                                //                           text: ' or drag & drop PNG, JPG',
                                //                           style: kTextStyle.copyWith(color: kGreyTextColor, fontWeight: FontWeight.bold))
                                //                     ])),
                                //                 const SizedBox(height: 10.0),
                                //                 image != null
                                //                     ? Image.memory(
                                //                         image!,
                                //                         width: 120,
                                //                         height: 120,
                                //                       )
                                //                     : Image.network(profilePicture, width: 120, height: 120),
                                //               ],
                                //             ),
                                //           ),
                                //         ),
                                //       ),
                                //     ],
                                //   ),
                                // ),
                                // const SizedBox(height: 10.0),

                                Form(
                                  key: globalKey,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ///_______Business_category______________________________________________
                                      categoryList.when(
                                        data: (warehouse) {
                                          return SizedBox(
                                            height: 55.0,
                                            child: FormField(
                                              builder: (FormFieldState<dynamic> field) {
                                                return InputDecorator(
                                                  decoration: kInputDecoration.copyWith(labelText: lang.S.of(context).businessCategory, border: OutlineInputBorder(borderRadius: BorderRadius.circular(5.0))),
                                                  child: DropdownButtonHideUnderline(child: getShopCategory(list: warehouse ?? [])),
                                                );
                                              },
                                            ),
                                          );
                                        },
                                        error: (e, stack) {
                                          return Center(
                                            child: Text(
                                              e.toString(),
                                            ),
                                          );
                                        },
                                        loading: () {
                                          return const Center(
                                            child: CircularProgressIndicator(),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 10.0),
                                      AppTextField(
                                        controller: companyNameController,
                                        showCursor: true,
                                        cursorColor: kTitleColor,
                                        textFieldType: TextFieldType.EMAIL,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Company Name can\'n be empty';
                                          }
                                          return null;
                                        },
                                        decoration: kInputDecoration.copyWith(
                                          errorBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.red)),
                                          labelText: lang.S.of(context).companyName,
                                          labelStyle: kTextStyle.copyWith(color: kTitleColor),
                                          hintText: lang.S.of(context).enterYourCompanyName,
                                          hintStyle: kTextStyle.copyWith(color: kGreyTextColor),
                                          prefixIcon: Icon(MdiIcons.officeBuilding, color: kTitleColor),
                                        ),
                                      ),
                                      const SizedBox(height: 10.0),

                                      ///_________phone_number_____________________________________________________
                                      TextFormField(
                                        controller: phoneController,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Phone number can\'n be empty';
                                          } else if (value.length < 8) {
                                            return 'Enter a valid phone number';
                                          }
                                          return null;
                                        },
                                        decoration: kInputDecoration.copyWith(
                                          errorBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.red)),
                                          labelText: lang.S.of(context).phoneNumber,
                                          hintText: lang.S.of(context).enterYourPhoneNumber,
                                          floatingLabelBehavior: FloatingLabelBehavior.never,
                                          prefixIcon: Icon(MdiIcons.phone, color: kTitleColor),
                                        ),
                                      ),
                                      const SizedBox(height: 10.0),

                                      ///_________Address__________________________________________________________
                                      AppTextField(
                                        controller: addressController,
                                        showCursor: true,
                                        cursorColor: kTitleColor,
                                        textFieldType: TextFieldType.NAME,
                                        validator: (value) {
                                          return null;
                                        },
                                        decoration: kInputDecoration.copyWith(
                                          errorBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.red)),
                                          labelText: 'Address',
                                          labelStyle: kTextStyle.copyWith(color: kTitleColor),
                                          hintText: 'Enter your shop address',
                                          hintStyle: kTextStyle.copyWith(color: kGreyTextColor),
                                          prefixIcon: const Icon(Icons.location_city, color: kTitleColor),
                                        ),
                                      ),
                                      const SizedBox(height: 10.0),

                                      ///_________GST__________________________________________________________
                                      AppTextField(
                                        controller: gstController,
                                        showCursor: true,
                                        cursorColor: kTitleColor,
                                        textFieldType: TextFieldType.NUMBER,
                                        validator: (value) {
                                          return null;
                                        },
                                        decoration: kInputDecoration.copyWith(
                                          errorBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.red)),
                                          labelText: 'Shop GST',
                                          labelStyle: kTextStyle.copyWith(color: kTitleColor),
                                          hintText: 'Enter your shop GST number',
                                          hintStyle: kTextStyle.copyWith(color: kGreyTextColor),
                                          prefixIcon: const Icon(Icons.location_city, color: kTitleColor),
                                        ),
                                      ),
                                      const SizedBox(height: 10.0),

                                      ///_________Opening_balence_______________________________________________
                                      AppTextField(
                                        controller: shopOpeningBalanceController,
                                        textFieldType: TextFieldType.PHONE,
                                        validator: (value) {
                                          return null;
                                        },
                                        decoration: kInputDecoration.copyWith(
                                          labelText: lang.S.of(context).shopOpeningBalance,
                                          labelStyle: kTextStyle.copyWith(color: kTitleColor),
                                          hintText: lang.S.of(context).enterYOurAmount,
                                          prefixIcon: Container(
                                            height: 60,
                                            width: 30,
                                            alignment: Alignment.center,
                                            child: Text(currency),
                                          ),
                                        ),
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // const SizedBox(height: 10.0),
                                // SizedBox(
                                //   height: 60.0,
                                //   child: FormField(
                                //     builder: (FormFieldState<dynamic> field) {
                                //       return InputDecorator(
                                //         decoration: kInputDecoration.copyWith(
                                //             floatingLabelBehavior: FloatingLabelBehavior.never,
                                //             labelText: 'Select Your Language',
                                //             border: OutlineInputBorder(borderRadius: BorderRadius.circular(5.0))),
                                //         child: DropdownButtonHideUnderline(child: getLanguage()),
                                //       );
                                //     },
                                //   ),
                                // ),
                                const SizedBox(height: 20.0),
                                ButtonGlobal(
                                  buttontext: lang.S.of(context).continu,
                                  buttonDecoration: kButtonDecoration.copyWith(color: kGreenTextColor, borderRadius: BorderRadius.circular(8.0)),
                                  onPressed: () async {
                                    if (selectedShopCategory?.categoryName?.isEmpty ?? true) {
                                      EasyLoading.showError('Please select Business Category');
                                    } else if (validateAndSave()) {
                                      try {
                                        EasyLoading.show(status: 'Loading...', dismissOnTap: false);
                                        final DatabaseReference personalInformationRef = FirebaseDatabase.instance.ref().child(await getUserID()).child('Personal Information');
                                        PersonalInformationModel personalInformation = PersonalInformationModel(
                                          phoneNumber: phoneController.text,
                                          pictureUrl: profilePicture,
                                          companyName: companyNameController.text,
                                          countryName: addressController.text,
                                          language: '',
                                          dueInvoiceCounter: 1,
                                          purchaseInvoiceCounter: 1,
                                          saleInvoiceCounter: 1,
                                          businessCategory: selectedShopCategory!.categoryName.toString(),
                                          shopOpeningBalance: shopOpeningBalanceController.text == '' ? 0 : shopOpeningBalanceController.text.toInt(),
                                          remainingShopBalance: shopOpeningBalanceController.text == '' ? 0 : shopOpeningBalanceController.text.toDouble(),
                                          currency: '\$',
                                          currentLocale: 'en',
                                          gst: gstController.text,
                                        );

                                        ///________super_admin_data_post_________________________________________________________
                                        await personalInformationRef.set(personalInformation.toJson());
                                        SellerInfoModel sellerInfoModel = SellerInfoModel(
                                          businessCategory: selectedShopCategory?.categoryName.toString(),
                                          companyName: companyNameController.text,
                                          phoneNumber: phoneController.text,
                                          countryName: addressController.text,
                                          language: '',
                                          pictureUrl: profilePicture,
                                          userID: FirebaseAuth.instance.currentUser!.uid,
                                          email: FirebaseAuth.instance.currentUser!.email,
                                          subscriptionDate: DateTime.now().toString(),
                                          subscriptionName: 'Free',
                                          subscriptionMethod: 'Not Provided',
                                          userRegistrationDate: DateTime.now().toString(),
                                          gst: gstController.text,
                                        );
                                        //_______________warehouse_setup______________
                                        final DatabaseReference productInformationRef = FirebaseDatabase.instance.ref().child(await getUserID()).child('Warehouse List');
                                        WareHouseModel warehouse = WareHouseModel(warehouseName: 'InHouse', warehouseAddress: companyNameController.text, id: id.toString());
                                        await productInformationRef.push().set(warehouse.toJson());
                                        await FirebaseDatabase.instance.ref().child('Admin Panel').child('Seller List').push().set(sellerInfoModel.toJson());

                                        EasyLoading.showSuccess('Added Successfully', duration: const Duration(milliseconds: 1000));

                                        await postGeneralCategory();

                                        ///_________free_subscription_______________________________________

                                        final DatabaseReference subscriptionRef = FirebaseDatabase.instance.ref().child(FirebaseAuth.instance.currentUser!.uid).child('Subscription');
                                        await subscriptionRef.set(Subscription.freeSubscriptionModel.toJson());
                                        EasyLoading.showSuccess('Added Successfully!');
                                        ref.refresh(profileDetailsProvider);
                                        // ignore: use_build_context_synchronously
                                        // Navigator.pushNamed(context, MtHomeScreen.route);
                                        context.go('/dashboard');
                                      } catch (e) {
                                        EasyLoading.dismiss();
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                                      }
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
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
