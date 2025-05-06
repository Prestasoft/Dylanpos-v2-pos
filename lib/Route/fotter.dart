import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart' as rf;
import 'package:salespro_admin/Provider/general_setting_provider.dart';
import 'package:salespro_admin/Route/static_string.dart';

class FooterWidget extends StatelessWidget {
  const FooterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final _theme = Theme.of(context);
    final _textStyle = _theme.textTheme.bodyMedium?.copyWith(
      fontSize: rf.ResponsiveValue<double?>(
        context,
        conditionalValues: const [
          rf.Condition.between(start: 0, end: 290, value: 11),
          rf.Condition.between(start: 291, end: 340, value: 12),
        ],
      ).value,
    );

    return Consumer(
      builder: (_, ref, watch) {
        final settingProver = ref.watch(generalSettingProvider);
        return settingProver.when(data: (setting) {
          final companyName = setting.companyName.isNotEmpty == true ? setting.companyName : 'Victor Guzman Fotografia';
          return LayoutBuilder(
            builder: (context, constraints) => Container(
              padding: rf.ResponsiveValue<EdgeInsetsGeometry?>(
                context,
                conditionalValues: [
                  rf.Condition.smallerThan(
                    name: BreakpointName.LG.name,
                    value: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ],
                defaultValue: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 18,
                ),
              ).value,
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'COPYRIGHT © 2025 $companyName${constraints.maxWidth <= BreakpointName.SM.start ? '' : ', Todos los Derechos Reservados'}',
                      style: _textStyle,
                    ),
                  ),
                  Text.rich(
                    TextSpan(
                      text: 'Desarrollado por ',
                      children: [
                        TextSpan(
                          text: companyName,
                          style: _textStyle?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: _theme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    style: _textStyle,
                  )
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
      },
    );
  }
}
