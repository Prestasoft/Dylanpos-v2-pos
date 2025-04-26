import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;

import 'constant.dart';

class ExportButton extends StatelessWidget {
  const ExportButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 40.0,
          width: 300,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8.0), border: Border.all(color: kGreyTextColor.withOpacity(0.1))),
          child: AppTextField(
            showCursor: true,
            cursorColor: kTitleColor,
            textFieldType: TextFieldType.NAME,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.all(10.0),
              hintText: ('${lang.S.of(context).search}...'),
              hintStyle: kTextStyle.copyWith(color: kGreyTextColor),
              border: InputBorder.none,
              suffixIcon: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Container(
                    padding: const EdgeInsets.all(2.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.0),
                      color: kGreyTextColor.withOpacity(0.1),
                    ),
                    child: const Icon(
                      FeatherIcons.search,
                      color: kTitleColor,
                    )),
              ),
            ),
          ),
        ),
        const Spacer(),
        Icon(
          MdiIcons.contentCopy,
          color: kTitleColor,
        ),
        const SizedBox(width: 5.0),
        Icon(MdiIcons.microsoftExcel, color: kTitleColor),
        const SizedBox(width: 5.0),
        Icon(MdiIcons.fileDelimited, color: kTitleColor),
        const SizedBox(width: 5.0),
        Icon(MdiIcons.filePdfBox, color: kTitleColor),
        const SizedBox(width: 5.0),
        const Icon(FeatherIcons.printer, color: kTitleColor),
      ],
    );
  }
}

class ExportButton2 extends StatelessWidget {
  const ExportButton2({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Icon(
          MdiIcons.contentCopy,
          color: kTitleColor,
        ),
        const SizedBox(width: 5.0),
        Icon(MdiIcons.microsoftExcel, color: kTitleColor),
        const SizedBox(width: 5.0),
        Icon(MdiIcons.fileDelimited, color: kTitleColor),
        const SizedBox(width: 5.0),
        Icon(MdiIcons.filePdfBox, color: kTitleColor),
        const SizedBox(width: 5.0),
        const Icon(FeatherIcons.printer, color: kTitleColor),
      ],
    );
  }
}

class EmptyWidget extends StatelessWidget {
  const EmptyWidget({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Visibility(child: SizedBox(height: 20)),
          Container(
            height: (MediaQuery.of(context).size.height - 315).isNegative ? 0 : MediaQuery.of(context).size.height - 315,
            width: 600,
            decoration: const BoxDecoration(
              image: DecorationImage(image: AssetImage('images/empty_screen.png'), fit: BoxFit.contain),
            ),
          ),
          Visibility(visible: MediaQuery.of(context).size.height != 0, child: const SizedBox(height: 20)),
          Text(
            title,
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18.0),
          ),
          Visibility(visible: MediaQuery.of(context).size.height != 0, child: const SizedBox(height: 20)),
        ],
      ),
    );
  }
}
