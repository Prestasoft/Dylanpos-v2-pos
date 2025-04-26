import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:salespro_admin/Provider/subacription_plan_provider.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;

import '../../const.dart';
import '../Widgets/Constant Data/constant.dart';

class AddCategory extends StatefulWidget {
  const AddCategory({super.key});

  @override
  State<AddCategory> createState() => _AddCategoryState();
}

class _AddCategoryState extends State<AddCategory> {
  @override
  initState() {
    super.initState();
    checkCurrentUserAndRestartApp();
  }

  TextEditingController customerNameController = TextEditingController();

  GlobalKey<FormState> addCategory = GlobalKey<FormState>();

  bool validateAndSave() {
    final form = addCategory.currentState;
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
    return SafeArea(
      child: Scaffold(
        backgroundColor: kDarkWhite,
        body: Scrollbar(
          controller: mainScroll,
          child: SingleChildScrollView(
            controller: mainScroll,
            scrollDirection: Axis.horizontal,
            child: Consumer(builder: (context, ref, _) {
              final currentSubcription = ref.watch(singleUserSubscriptionPlanProvider);
              return currentSubcription.when(data: (data) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SizedBox(
                    //   width: 240,
                    //   child: SideBarWidget(
                    //     index: 3,
                    //     isTab: false,
                    //   ),
                    // ),
                    Container(
                      width: MediaQuery.of(context).size.width < 1275 ? 1275 - 240 : MediaQuery.of(context).size.width - 240,
                      // width: context.width() < 1080 ? 1080 - 240 : MediaQuery.of(context).size.width - 240,
                      decoration: const BoxDecoration(color: kDarkWhite),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // const TopBar(),
                          const SizedBox(height: 20.0),
                          Container(
                            height: MediaQuery.of(context).size.height - 240,
                            decoration: const BoxDecoration(color: kDarkWhite),
                            child: SingleChildScrollView(
                              controller: mainScroll,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 10.0),
                                    child: Row(
                                      children: [
                                        Text(
                                          "Add Category",
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
                                              key: addCategory,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const SizedBox(height: 20.0),

                                                  ///__________Name_&_Phone___________________________________
                                                  Expanded(
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
                                                      decoration: kInputDecoration.copyWith(
                                                        errorBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.red)),
                                                        labelText: lang.S.of(context).customerName,
                                                        labelStyle: kTextStyle.copyWith(color: kTitleColor),
                                                        hintText: lang.S.of(context).enterCustomerName,
                                                        hintStyle: kTextStyle.copyWith(color: kGreyTextColor),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 20.0),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                    )
                  ],
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
        ),
      ),
    );
  }
}
