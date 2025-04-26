import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/Provider/sms_template_provider.dart';
import 'package:salespro_admin/Repository/sms_template_repo.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;

import '../../Provider/subacription_plan_provider.dart';
import '../../const.dart';
import '../../model/whatsapp_marketing_sms_template_model.dart';
import '../Widgets/Constant Data/constant.dart';

class WhatsappMarketingScreen extends StatefulWidget {
  const WhatsappMarketingScreen({super.key});

  @override
  State<WhatsappMarketingScreen> createState() => _WhatsappMarketingScreenState();
}

class _WhatsappMarketingScreenState extends State<WhatsappMarketingScreen> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    checkCurrentUserAndRestartApp();
    // voidLink(context: context);
  }

  int selectedItem = 10;
  int itemCount = 10;
  ScrollController mainScroll = ScrollController();
  TextEditingController salesTemplateController = TextEditingController();
  TextEditingController salesReturnTemplateController = TextEditingController();
  TextEditingController quotationTemplateController = TextEditingController();
  TextEditingController purchaseTemplateController = TextEditingController();
  TextEditingController purchaseReturnTemplateController = TextEditingController();
  TextEditingController dueTemplateController = TextEditingController();
  TextEditingController bulkTemplateController = TextEditingController();

  // Sales list of strings
  List<String> salesFields = ['{{CUSTOMER_NAME}}', '{{CUSTOMER_ADDRESS}}', '{{CUSTOMER_GST}}', '{{INVOICE_NUMBER}}', '{{PURCHASE_DATE}}', '{{TOTAL_AMOUNT}}', '{{DUE_AMOUNT}}', '{{SERVICE_CHARGE}}', '{{VAT}}', '{{DISCOUNT_AMOUNT}}', '{{TOTAL_QUANTITY}}', '{{PAYMENT_TYPE}}', '{{INVOICE_URL}}'];

// Purchase list of strings
  List<String> purchaseFields = ['{{CUSTOMER_NAME}}', '{{CUSTOMER_ADDRESS}}', '{{INVOICE_NUMBER}}', '{{PURCHASE_DATE}}', '{{TOTAL_AMOUNT}}', '{{DUE_AMOUNT}}', '{{DISCOUNT_AMOUNT}}', '{{PAYMENT_TYPE}}', '{{INVOICE_URL}}'];

// Due list of strings
  List<String> dueFields = ['{{CUSTOMER_NAME}}', '{{CUSTOMER_ADDRESS}}', '{{CUSTOMER_GST}}', '{{INVOICE_NUMBER}}', '{{PURCHASE_DATE}}', '{{TOTAL_DUE}}', '{{DUE_AMOUNT_AFTER_PAY}}', '{{PAY_DUE_AMOUNT}}', '{{PAYMENT_TYPE}}', '{{INVOICE_URL}}'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    return SafeArea(
      child: Scaffold(
          backgroundColor: kDarkWhite,
          body: Consumer(builder: (_, ref, watch) {
            final subscriptionData = ref.watch(singleUserSubscriptionPlanProvider);
            final templates = ref.watch(smsTemplateProvider);
            return subscriptionData.when(
              data: (subscription) {
                return subscription.whatsappMarketingEnabled
                    ? templates.when(data: (templates) {
                        salesTemplateController.text = templates.saleTemplate ?? "";
                        salesReturnTemplateController.text = templates.saleReturnTemplate ?? "";
                        quotationTemplateController.text = templates.quotationTemplate ?? "";
                        purchaseTemplateController.text = templates.purchaseTemplate ?? "";
                        purchaseReturnTemplateController.text = templates.purchaseReturnTemplate ?? "";
                        dueTemplateController.text = templates.dueTemplate ?? "";
                        bulkTemplateController.text = templates.bulkSmsTemplate ?? "";
                        return SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: kWhite,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: defaultBoxShadow(),
                                ),
                                child: Column(
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(10.0),
                                          child: Text(lang.S.of(context).whatsappMarketingSMSTemplate,
                                              // "Whatsapp Marketing SMS Template",
                                              style: theme.textTheme.titleLarge?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              )),
                                        ),
                                        const Divider(
                                          thickness: 1,
                                          height: 1,
                                          color: kNeutral300,
                                        ),
                                        const SizedBox(height: 20),

                                        ///------------sales templates-----------------------------------
                                        ResponsiveGridRow(rowSegments: 120, children: [
                                          ResponsiveGridCol(
                                              xs: 120,
                                              md: screenWidth < 768 ? 120 : 70,
                                              lg: 70,
                                              child: ResponsiveGridRow(rowSegments: 120, children: [
                                                ResponsiveGridCol(
                                                  xs: 120,
                                                  md: 20,
                                                  lg: 20,
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(10.0),
                                                    child: Text(
                                                        // "Sales Template:",
                                                        "${lang.S.of(context).salesTemplate}:",
                                                        style: secondaryTextStyle(size: 16)),
                                                  ),
                                                ),
                                                ResponsiveGridCol(
                                                    xs: 120,
                                                    md: 100,
                                                    lg: 100,
                                                    child: Padding(
                                                      padding: const EdgeInsets.all(10.0),
                                                      child: TextFormField(
                                                        controller: salesTemplateController,
                                                        maxLines: 5,
                                                        decoration: InputDecoration(
                                                          hintText: lang.S.of(context).enterSalesTemplate,
                                                          contentPadding: const EdgeInsets.all(10),
                                                        ),
                                                      ),
                                                    ))
                                              ])),
                                          ResponsiveGridCol(
                                              xs: 120,
                                              md: screenWidth < 768 ? 120 : 50,
                                              lg: 50,
                                              child: Padding(
                                                padding: const EdgeInsets.all(10.0),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                        //"Shortcodes",
                                                        lang.S.of(context).shortcodes,
                                                        style: theme.textTheme.titleMedium?.copyWith(
                                                          fontWeight: FontWeight.w600,
                                                        )),
                                                    10.height,
                                                    Wrap(
                                                      children: List.generate(salesFields.length, (index) {
                                                        return InkWell(
                                                          onTap: () {
                                                            salesTemplateController.text = salesTemplateController.text + salesFields[index];
                                                          },
                                                          child: Container(
                                                            padding: const EdgeInsets.all(5),
                                                            margin: const EdgeInsets.all(5),
                                                            decoration: BoxDecoration(
                                                              color: deepSkyBlue,
                                                              borderRadius: BorderRadius.circular(5),
                                                            ),
                                                            child: Text(
                                                              salesFields[index],
                                                              style: secondaryTextStyle(color: kWhite),
                                                            ),
                                                          ),
                                                        );
                                                      }),
                                                    ),
                                                  ],
                                                ),
                                              )),
                                        ]),

                                        ///--------------------sales return templates--------------------
                                        ResponsiveGridRow(rowSegments: 120, children: [
                                          ResponsiveGridCol(
                                              xs: 120,
                                              md: screenWidth < 768 ? 120 : 70,
                                              lg: 70,
                                              child: ResponsiveGridRow(rowSegments: 120, children: [
                                                ResponsiveGridCol(
                                                  xs: 120,
                                                  md: 20,
                                                  lg: 20,
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(10.0),
                                                    child: Text(
                                                        // "Sales Template:",
                                                        "${lang.S.of(context).salesReturnTemplate}:",
                                                        style: secondaryTextStyle(size: 16)),
                                                  ),
                                                ),
                                                ResponsiveGridCol(
                                                    xs: 120,
                                                    md: 100,
                                                    lg: 100,
                                                    child: Padding(
                                                      padding: const EdgeInsets.all(10.0),
                                                      child: TextFormField(
                                                        controller: salesReturnTemplateController,
                                                        maxLines: 5,
                                                        decoration: InputDecoration(
                                                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                                          hintText: lang.S.of(context).enterSalesReturnTemplate,
                                                          //"Enter Sales Return Template",
                                                        ),
                                                      ),
                                                    ))
                                              ])),
                                          ResponsiveGridCol(
                                              xs: 120,
                                              md: screenWidth < 768 ? 120 : 50,
                                              lg: 50,
                                              child: Padding(
                                                padding: const EdgeInsets.all(10.0),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(lang.S.of(context).shortcodes,
                                                        // "Shortcodes",
                                                        style: theme.textTheme.titleMedium?.copyWith(
                                                          fontWeight: FontWeight.w600,
                                                        )),
                                                    10.height,
                                                    Wrap(
                                                      children: List.generate(salesFields.length, (index) {
                                                        return InkWell(
                                                          onTap: () {
                                                            salesReturnTemplateController.text = salesReturnTemplateController.text + salesFields[index];
                                                          },
                                                          child: Container(
                                                            padding: const EdgeInsets.all(5),
                                                            margin: const EdgeInsets.all(5),
                                                            decoration: BoxDecoration(
                                                              color: deepSkyBlue,
                                                              borderRadius: BorderRadius.circular(5),
                                                            ),
                                                            child: Text(
                                                              salesFields[index],
                                                              style: secondaryTextStyle(color: kWhite),
                                                            ),
                                                          ),
                                                        );
                                                      }),
                                                    ),
                                                  ],
                                                ),
                                              )),
                                        ]),

                                        ///---------------------quatation templates-------------------
                                        ResponsiveGridRow(rowSegments: 120, children: [
                                          ResponsiveGridCol(
                                              xs: 120,
                                              md: screenWidth < 768 ? 120 : 70,
                                              lg: 70,
                                              child: ResponsiveGridRow(rowSegments: 120, children: [
                                                ResponsiveGridCol(
                                                  xs: 120,
                                                  md: 20,
                                                  lg: 20,
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(10.0),
                                                    child: Text(
                                                        // "Sales Template:",
                                                        "${lang.S.of(context).quotationTemplate}:",
                                                        style: secondaryTextStyle(size: 16)),
                                                  ),
                                                ),
                                                ResponsiveGridCol(
                                                    xs: 120,
                                                    md: 100,
                                                    lg: 100,
                                                    child: Padding(
                                                      padding: const EdgeInsets.all(10.0),
                                                      child: TextFormField(
                                                        controller: quotationTemplateController,
                                                        maxLines: 5,
                                                        decoration: InputDecoration(
                                                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                                          hintText: lang.S.of(context).enterQuotationTemplate,
                                                          // "Enter Quotation Template",
                                                          hintStyle: secondaryTextStyle(size: 16),
                                                        ),
                                                      ),
                                                    ))
                                              ])),
                                          ResponsiveGridCol(
                                              xs: 120,
                                              md: screenWidth < 768 ? 120 : 50,
                                              lg: 50,
                                              child: Padding(
                                                padding: const EdgeInsets.all(10.0),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(lang.S.of(context).shortcodes,
                                                        //"Shortcodes",
                                                        style: boldTextStyle(size: 16)),
                                                    10.height,
                                                    Wrap(
                                                      children: List.generate(salesFields.length, (index) {
                                                        return InkWell(
                                                          onTap: () {
                                                            quotationTemplateController.text = quotationTemplateController.text + salesFields[index];
                                                          },
                                                          child: Container(
                                                            padding: const EdgeInsets.all(5),
                                                            margin: const EdgeInsets.all(5),
                                                            decoration: BoxDecoration(
                                                              color: deepSkyBlue,
                                                              borderRadius: BorderRadius.circular(5),
                                                            ),
                                                            child: Text(
                                                              salesFields[index],
                                                              style: secondaryTextStyle(color: kWhite),
                                                            ),
                                                          ),
                                                        );
                                                      }),
                                                    ),
                                                  ],
                                                ),
                                              )),
                                        ]),

                                        ///-------------------------purchase templates--------------------------
                                        ResponsiveGridRow(rowSegments: 120, children: [
                                          ResponsiveGridCol(
                                              xs: 120,
                                              md: screenWidth < 768 ? 120 : 70,
                                              lg: 70,
                                              child: ResponsiveGridRow(rowSegments: 120, children: [
                                                ResponsiveGridCol(
                                                  xs: 120,
                                                  md: 20,
                                                  lg: 20,
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(10.0),
                                                    child: Text(
                                                        // "Sales Template:",
                                                        "${lang.S.of(context).purchaseTemplate}:",
                                                        style: secondaryTextStyle(size: 16)),
                                                  ),
                                                ),
                                                ResponsiveGridCol(
                                                    xs: 120,
                                                    md: 100,
                                                    lg: 100,
                                                    child: Padding(
                                                      padding: const EdgeInsets.all(10.0),
                                                      child: TextFormField(
                                                        controller: purchaseTemplateController,
                                                        maxLines: 5,
                                                        decoration: InputDecoration(
                                                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                                          hintText: lang.S.of(context).enterPurchaseTemplate,
                                                          //"Enter Purchase Template",
                                                          hintStyle: secondaryTextStyle(size: 16),
                                                        ),
                                                      ),
                                                    ))
                                              ])),
                                          ResponsiveGridCol(
                                              xs: 120,
                                              md: screenWidth < 768 ? 120 : 50,
                                              lg: 50,
                                              child: Padding(
                                                padding: const EdgeInsets.all(10.0),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(lang.S.of(context).shortcodes,
                                                        // "Shortcodes",
                                                        style: theme.textTheme.titleMedium?.copyWith(
                                                          fontWeight: FontWeight.w600,
                                                        )),
                                                    10.height,
                                                    Wrap(
                                                      children: List.generate(purchaseFields.length, (index) {
                                                        return InkWell(
                                                          onTap: () {
                                                            purchaseTemplateController.text = purchaseTemplateController.text + purchaseFields[index];
                                                          },
                                                          child: Container(
                                                            padding: EdgeInsets.all(5),
                                                            margin: EdgeInsets.all(5),
                                                            decoration: BoxDecoration(
                                                              color: deepSkyBlue,
                                                              borderRadius: BorderRadius.circular(5),
                                                            ),
                                                            child: Text(
                                                              salesFields[index],
                                                              style: secondaryTextStyle(color: kWhite),
                                                            ),
                                                          ),
                                                        );
                                                      }),
                                                    ),
                                                  ],
                                                ),
                                              )),
                                        ]),

                                        ///-----------------------purchase return templates--------------------
                                        ResponsiveGridRow(rowSegments: 120, children: [
                                          ResponsiveGridCol(
                                              xs: 120,
                                              md: screenWidth < 768 ? 120 : 70,
                                              lg: 70,
                                              child: ResponsiveGridRow(rowSegments: 120, children: [
                                                ResponsiveGridCol(
                                                  xs: 120,
                                                  md: 20,
                                                  lg: 20,
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(10.0),
                                                    child: Text(
                                                        // "Sales Template:",
                                                        "${lang.S.of(context).purchaseReturnTemplate}:",
                                                        style: secondaryTextStyle(size: 16)),
                                                  ),
                                                ),
                                                ResponsiveGridCol(
                                                    xs: 120,
                                                    md: 100,
                                                    lg: 100,
                                                    child: Padding(
                                                      padding: const EdgeInsets.all(10.0),
                                                      child: TextFormField(
                                                        controller: purchaseReturnTemplateController,
                                                        maxLines: 5,
                                                        decoration: InputDecoration(
                                                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                                          hintText: lang.S.of(context).enterPurchaseReturnTemplate,
                                                          // "Enter Purchase Return Template",
                                                        ),
                                                      ),
                                                    ))
                                              ])),
                                          ResponsiveGridCol(
                                              xs: 120,
                                              md: screenWidth < 768 ? 120 : 50,
                                              lg: 50,
                                              child: Padding(
                                                padding: const EdgeInsets.all(10.0),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(lang.S.of(context).shortcodes,
                                                        // "Shortcodes",
                                                        style: theme.textTheme.titleMedium?.copyWith(
                                                          fontWeight: FontWeight.w600,
                                                        )),
                                                    10.height,
                                                    Wrap(
                                                      children: List.generate(purchaseFields.length, (index) {
                                                        return InkWell(
                                                          onTap: () {
                                                            purchaseReturnTemplateController.text = purchaseReturnTemplateController.text + purchaseFields[index];
                                                          },
                                                          child: Container(
                                                            padding: const EdgeInsets.all(5),
                                                            margin: const EdgeInsets.all(5),
                                                            decoration: BoxDecoration(
                                                              color: deepSkyBlue,
                                                              borderRadius: BorderRadius.circular(5),
                                                            ),
                                                            child: Text(
                                                              salesFields[index],
                                                              style: secondaryTextStyle(color: kWhite),
                                                            ),
                                                          ),
                                                        );
                                                      }),
                                                    ),
                                                  ],
                                                ),
                                              )),
                                        ]),

                                        ///-----------------------------due templates--------------------
                                        ResponsiveGridRow(rowSegments: 120, children: [
                                          ResponsiveGridCol(
                                              xs: 120,
                                              md: screenWidth < 768 ? 120 : 70,
                                              lg: 70,
                                              child: ResponsiveGridRow(rowSegments: 120, children: [
                                                ResponsiveGridCol(
                                                  xs: 120,
                                                  md: 20,
                                                  lg: 20,
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(10.0),
                                                    child: Text(
                                                        // "Sales Template:",
                                                        "${lang.S.of(context).dueTemplate}:",
                                                        style: secondaryTextStyle(size: 16)),
                                                  ),
                                                ),
                                                ResponsiveGridCol(
                                                    xs: 120,
                                                    md: 100,
                                                    lg: 100,
                                                    child: Padding(
                                                      padding: const EdgeInsets.all(10.0),
                                                      child: TextFormField(
                                                        controller: dueTemplateController,
                                                        maxLines: 5,
                                                        decoration: InputDecoration(
                                                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                                          hintText: lang.S.of(context).enterDueTemplate,
                                                          // "Enter Due Template",
                                                        ),
                                                      ),
                                                    ))
                                              ])),
                                          ResponsiveGridCol(
                                              xs: 120,
                                              md: screenWidth < 768 ? 120 : 50,
                                              lg: 50,
                                              child: Padding(
                                                padding: const EdgeInsets.all(10.0),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(lang.S.of(context).shortcodes,
                                                        //"Shortcodes",
                                                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                                                    10.height,
                                                    Wrap(
                                                      children: List.generate(dueFields.length, (index) {
                                                        return InkWell(
                                                          onTap: () {
                                                            dueTemplateController.text = dueTemplateController.text + dueFields[index];
                                                          },
                                                          child: Container(
                                                            padding: const EdgeInsets.all(5),
                                                            margin: const EdgeInsets.all(5),
                                                            decoration: BoxDecoration(
                                                              color: deepSkyBlue,
                                                              borderRadius: BorderRadius.circular(5),
                                                            ),
                                                            child: Text(
                                                              dueFields[index],
                                                              style: secondaryTextStyle(color: kWhite),
                                                            ),
                                                          ),
                                                        );
                                                      }),
                                                    ),
                                                  ],
                                                ),
                                              )),
                                        ]),

                                        ///---------------------Bulk sms templates--------------------
                                        ResponsiveGridRow(rowSegments: 120, children: [
                                          ResponsiveGridCol(
                                              xs: 120,
                                              md: screenWidth < 768 ? 120 : 70,
                                              lg: 70,
                                              child: ResponsiveGridRow(rowSegments: 120, children: [
                                                ResponsiveGridCol(
                                                  xs: 120,
                                                  md: 20,
                                                  lg: 20,
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(10.0),
                                                    child: Text(
                                                        // "Sales Template:",
                                                        "${lang.S.of(context).bulkTemplate}:",
                                                        style: secondaryTextStyle(size: 16)),
                                                  ),
                                                ),
                                                ResponsiveGridCol(
                                                    xs: 120,
                                                    md: 100,
                                                    lg: 100,
                                                    child: Padding(
                                                      padding: const EdgeInsets.all(10.0),
                                                      child: TextFormField(
                                                        controller: bulkTemplateController,
                                                        maxLines: 5,
                                                        decoration: InputDecoration(
                                                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                                          hintText: lang.S.of(context).enterBulkSMSTemplate,
                                                        ),
                                                      ),
                                                    ))
                                              ])),
                                          ResponsiveGridCol(xs: 120, md: screenWidth < 768 ? 120 : 50, lg: 50, child: const SizedBox.shrink()),
                                        ]),
                                        // Row(
                                        //   mainAxisAlignment: MainAxisAlignment.start,
                                        //   crossAxisAlignment: CrossAxisAlignment.start,
                                        //   children: [
                                        //     SizedBox(
                                        //       width: 100,
                                        //       child: Text(
                                        //           //"Bulk Template:",
                                        //           "${lang.S.of(context).bulkTemplate}:",
                                        //           style: secondaryTextStyle(size: 16)),
                                        //     ),
                                        //     10.width,
                                        //     Expanded(
                                        //       child: TextFormField(
                                        //         controller: bulkTemplateController,
                                        //         maxLines: 5,
                                        //         decoration: InputDecoration(
                                        //           contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                        //           hintText: lang.S.of(context).enterBulkSMSTemplate,
                                        //           //  "Enter Bulk SMS Template",
                                        //           hintStyle: secondaryTextStyle(size: 16),
                                        //           border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                        //           enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                        //           focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                        //         ),
                                        //       ),
                                        //     ),
                                        //     10.width,
                                        //     Expanded(child: SizedBox()),
                                        //   ],
                                        // ),
                                        // 20.height,
                                        Center(
                                          child: Padding(
                                            padding: const EdgeInsets.all(10.0),
                                            child: ElevatedButton(
                                              onPressed: () async {
                                                EasyLoading.show(
                                                  status: lang.S.of(context).updatingTemplate,
                                                  // 'Updating Template'
                                                );
                                                await SmsTemplateRepo().updateTemplate(WhatsappMarketingSmsTemplateModel(
                                                  saleTemplate: salesTemplateController.text,
                                                  purchaseTemplate: purchaseTemplateController.text,
                                                  purchaseReturnTemplate: purchaseReturnTemplateController.text,
                                                  saleReturnTemplate: salesReturnTemplateController.text,
                                                  quotationTemplate: quotationTemplateController.text,
                                                  dueTemplate: dueTemplateController.text,
                                                  bulkSmsTemplate: bulkTemplateController.text,
                                                ));
                                                EasyLoading.dismiss();
                                              },
                                              child: Text(
                                                lang.S.of(context).updateTemplate,
                                                //"Update Template"
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }, error: (e, stack) {
                        return Center(
                          child: Text(e.toString()),
                        );
                      }, loading: () {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      })
                    : Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: kWhite,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: defaultBoxShadow(),
                              ),
                              child: Column(
                                children: [
                                  20.height,
                                  Text(lang.S.of(context).whatsappMarketingIsNotEnabledInYourCurrentSubscriptionPlan,
                                      //"Whatsapp Marketing is not enabled in your current subscription plan",
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      )),
                                  20.height,
                                  Center(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        context.go('/subscription/purchase-plan', extra: {
                                          'initialSelectedPackage': 'Yearly',
                                          'initPackageValue': 0,
                                        });
                                      },
                                      child: Text(
                                        lang.S.of(context).updateNow,
                                      ),
                                    ),
                                  ),
                                  20.height,
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
              },
              error: (e, stack) {
                return Center(
                  child: Text(e.toString()),
                );
              },
              loading: () {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              },
            );
          })),
    );
  }
}
