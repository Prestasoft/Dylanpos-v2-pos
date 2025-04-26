import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/Screen/Widgets/Constant%20Data/constant.dart';

Future<bool> showDeleteConfirmationDialog({
  required BuildContext context,
  required String itemName, // Name of the item to delete
}) async {
  return await showDialog(
    barrierDismissible: false,
    context: context,
    builder: (BuildContext dialogContext) {
      final theme = Theme.of(context);
      final screenWidth = MediaQuery.of(context).size.width;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Container(
            width: 450,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(
                Radius.circular(15),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Are you sure you want to delete this  $itemName?',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ResponsiveGridRow(children: [
                    ResponsiveGridCol(
                      md: 6,
                      lg: 6,
                      xs: 6,
                      child: Padding(
                        padding: const EdgeInsetsDirectional.only(end: 20),
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                              foregroundColor: kMainColor,
                              minimumSize: Size(screenWidth, 48),
                              side: const BorderSide(
                                color: kMainColor,
                              )),
                          onPressed: () {
                            GoRouter.of(dialogContext).pop();
                            // Navigator.pop(dialogContext, false); // Return false on cancel
                          },
                          child: Text(
                            'Cancel',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: kMainColor),
                          ),
                        ),
                      ),
                    ),
                    ResponsiveGridCol(
                      md: 6,
                      lg: 6,
                      xs: 6,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(screenWidth, 48),
                        ),
                        onPressed: () {
                          GoRouter.of(dialogContext).pop(true);

                          // Navigator.pop(dialogContext, true); // Return true on delete
                        },
                        child: const Text(
                          'Delete',
                        ),
                      ),
                    )
                  ]),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
