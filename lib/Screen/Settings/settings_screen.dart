import 'package:firebase_core/firebase_core.dart' as firebase_core;
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:salespro_admin/Provider/invoice_settings_provider.dart';
import 'package:salespro_admin/Screen/Widgets/Constant%20Data/button_global.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;
import 'package:salespro_admin/model/invoice_model.dart';

import '../../Provider/profile_provider.dart';
import '../../const.dart';
import '../Widgets/Constant Data/constant.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);
  static const String route = '/settings';

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String initialCountry = 'Bangladesh';
  late String companyName, phoneNumber;
  String profilePicture = 'https://i.imgur.com/jlyGd1j.jpg';
  bool showLogo = true;
  bool isRight = false;
  Uint8List? image;
  TextEditingController companyAddressController = TextEditingController();
  TextEditingController companyPhoneController = TextEditingController();
  TextEditingController companyEmailController = TextEditingController();
  TextEditingController companyWebsiteController = TextEditingController();
  TextEditingController companyDescriptionController = TextEditingController();

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
        var snapshot = await FirebaseStorage.instance.ref('Profile Picture/${DateTime.now().millisecondsSinceEpoch}').putData(bytesFromPicker!);
        var url = await snapshot.ref.getDownloadURL();
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

  get mainScroll => null;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    checkCurrentUserAndRestartApp();
  }

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
            child: Consumer(builder: (_, ref, watch) {
              final profile = ref.watch(profileDetailsProvider);
              final invoiceSettings = ref.watch(invoiceSettingsProvider);
              return invoiceSettings.when(data: (invoice) {
                return profile.when(data: (data) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // const SizedBox(
                      //   width: 240,
                      //   child: SideBarWidget(
                      //     index: 13,
                      //     isTab: false,
                      //   ),
                      // ),
                      Container(
                        width: MediaQuery.of(context).size.width < 1275 ? 1275 - 240 : MediaQuery.of(context).size.width - 240,
                        // width: context.width() < 1080 ? 1080 - 240 : MediaQuery.of(context).size.width - 240,
                        decoration: const BoxDecoration(color: kDarkWhite),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              //_______________________________top_bar____________________________
                              // const TopBar(),

                              Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Container(
                                  width: 600,
                                  padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 10.0, bottom: 10.0),
                                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(20.0), color: kWhite),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            lang.S.of(context).setting,
                                            style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold, fontSize: 18.0),
                                          ),
                                          const Spacer(),

                                          ///___________search________________________________________________-
                                        ],
                                      ),
                                      const SizedBox(height: 5.0),
                                      Divider(
                                        thickness: 1.0,
                                        color: kGreyTextColor.withOpacity(0.2),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(20.0),
                                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10.0), color: kWhite),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            DottedBorderWidget(
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
                                                      image == null
                                                          ? Column(
                                                              crossAxisAlignment: CrossAxisAlignment.center,
                                                              children: [
                                                                Icon(MdiIcons.cloudUpload, size: 50.0, color: kLitGreyColor).onTap(() => uploadFile()),
                                                                const SizedBox(height: 10.0),
                                                                RichText(text: TextSpan(text: lang.S.of(context).uploadAnInvoiceLogo, style: kTextStyle.copyWith(color: kGreenTextColor, fontWeight: FontWeight.bold), children: [TextSpan(text: lang.S.of(context).orDragAndDropPng, style: kTextStyle.copyWith(color: kGreyTextColor, fontWeight: FontWeight.bold))])),
                                                              ],
                                                            )
                                                          : Image.network(profilePicture, width: 150, height: 150),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(
                                              height: 10.0,
                                            ),
                                            Row(
                                              children: [
                                                Text(
                                                  lang.S.of(context).showLogoInInvoice,
                                                  style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
                                                ),
                                                const Spacer(),
                                                CupertinoSwitch(
                                                  value: showLogo,
                                                  onChanged: (bool value) {
                                                    setState(() {
                                                      showLogo = value;
                                                    });
                                                  },
                                                ),
                                              ],
                                            ),
                                            const SizedBox(
                                              height: 10.0,
                                            ).visible(showLogo),
                                            Row(
                                              children: [
                                                Text(
                                                  lang.S.of(context).logoPositionInInvoice,
                                                  style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
                                                ),
                                                const Spacer(),
                                                Row(
                                                  children: [
                                                    Text(
                                                      lang.S.of(context).left,
                                                      style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
                                                    ),
                                                    Padding(
                                                      padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                                                      child: CupertinoSwitch(
                                                        value: isRight,
                                                        onChanged: (bool value) {
                                                          setState(() {
                                                            isRight = value;
                                                          });
                                                        },
                                                      ),
                                                    ),
                                                    Text(
                                                      lang.S.of(context).right,
                                                      style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ).visible(showLogo),
                                            const SizedBox(
                                              height: 10.0,
                                            ),
                                            AppTextField(
                                              showCursor: true,
                                              cursorColor: kTitleColor,
                                              textFieldType: TextFieldType.NAME,
                                              decoration: kInputDecoration.copyWith(
                                                labelText: lang.S.of(context).companyName,
                                                labelStyle: kTextStyle.copyWith(color: kTitleColor),
                                                hintText: lang.S.of(context).enterYourCompanyAddress,
                                                hintStyle: kTextStyle.copyWith(color: kGreyTextColor),
                                              ),
                                            ),
                                            const SizedBox(
                                              height: 10.0,
                                            ),
                                            AppTextField(
                                              showCursor: true,
                                              cursorColor: kTitleColor,
                                              textFieldType: TextFieldType.PHONE,
                                              decoration: kInputDecoration.copyWith(
                                                labelText: lang.S.of(context).companyPhoneNumber,
                                                labelStyle: kTextStyle.copyWith(color: kTitleColor),
                                                hintText: lang.S.of(context).enterCompanyPhoneNumber,
                                                hintStyle: kTextStyle.copyWith(color: kGreyTextColor),
                                              ),
                                            ),
                                            const SizedBox(
                                              height: 10.0,
                                            ),
                                            AppTextField(
                                              showCursor: true,
                                              cursorColor: kTitleColor,
                                              textFieldType: TextFieldType.EMAIL,
                                              decoration: kInputDecoration.copyWith(
                                                labelText: lang.S.of(context).companyEmailAddress,
                                                labelStyle: kTextStyle.copyWith(color: kTitleColor),
                                                hintText: lang.S.of(context).enterCompanyEmailAddress,
                                                hintStyle: kTextStyle.copyWith(color: kGreyTextColor),
                                              ),
                                            ),
                                            const SizedBox(
                                              height: 10.0,
                                            ),
                                            AppTextField(
                                              showCursor: true,
                                              cursorColor: kTitleColor,
                                              textFieldType: TextFieldType.NAME,
                                              decoration: kInputDecoration.copyWith(
                                                labelText: lang.S.of(context).companyWebsiteUrl,
                                                labelStyle: kTextStyle.copyWith(color: kTitleColor),
                                                hintText: lang.S.of(context).enterCompanyWebsiteUrl,
                                                hintStyle: kTextStyle.copyWith(color: kGreyTextColor),
                                              ),
                                            ),
                                            const SizedBox(
                                              height: 10.0,
                                            ),
                                            AppTextField(
                                              showCursor: true,
                                              cursorColor: kTitleColor,
                                              textFieldType: TextFieldType.MULTILINE,
                                              decoration: kInputDecoration.copyWith(
                                                labelText: lang.S.of(context).companyDescription,
                                                labelStyle: kTextStyle.copyWith(color: kTitleColor),
                                                hintText: lang.S.of(context).enterCompanyDesciption,
                                                hintStyle: kTextStyle.copyWith(color: kGreyTextColor),
                                              ),
                                            ),
                                            const SizedBox(
                                              height: 10.0,
                                            ),
                                            ButtonGlobalWithoutIcon(
                                              buttontext: lang.S.of(context).saveChanges,
                                              buttonDecoration: kButtonDecoration.copyWith(color: kMainColor),
                                              onPressed: () async {
                                                final dbRef = FirebaseDatabase.instance.ref().child(await getUserID()).child('Invoice Settings');
                                                InvoiceModel inv = InvoiceModel(phoneNumber: data.phoneNumber, companyName: data.companyName, pictureUrl: profilePicture, emailAddress: companyEmailController.text, address: companyAddressController.text, description: companyDescriptionController.text, website: companyWebsiteController.text, isRight: isRight, showInvoice: showLogo);
                                              },
                                              buttonTextColor: Colors.white,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    ],
                  );
                }, error: (e, stack) {
                  return Center(
                    child: Text(e.toString()),
                  );
                }, loading: () {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                });
              }, error: (e, stack) {
                return Center(
                  child: Text(e.toString()),
                );
              }, loading: () {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              });
            }),
          ),
        ),
      ),
    );
  }
}
