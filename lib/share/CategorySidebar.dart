import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show CircularProgressIndicator, Colors, Icons, Theme;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:salespro_admin/Provider/product_provider.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;
import '../Screen/Widgets/Constant Data/constant.dart'
    show
        kBlueTextColor,
        kDarkGreyColor,
        kGreyTextColor,
        kTextStyle,
        kTitleColor,
        kWhite;

class CategorySidebar extends ConsumerWidget {
  final String selectedCategory;
  final String isSelected;
  final Function(String) onCategorySelected;

  const CategorySidebar({
    super.key,
    required this.selectedCategory,
    required this.isSelected,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryList = ref.watch(categoryProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);

    return categoryList.when(
      data: (category) {
        return Container(
          height: screenWidth < 1240
              ? 110
              : context.height() < 720
                  ? 720 - 142
                  : context.height() - 160,
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
              color: kWhite,
              border:
                  Border.all(width: 1, color: kGreyTextColor.withOpacity(0.3)),
              borderRadius: const BorderRadius.all(Radius.circular(15))),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  child: Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5.0),
                        color: screenWidth < 1240
                            ? Colors.transparent
                            : isSelected == 'Categories'
                                ? kBlueTextColor
                                : kBlueTextColor.withOpacity(0.1)),
                    padding: EdgeInsets.only(
                        left: screenWidth < 1240 ? 0 : 15,
                        right: 8,
                        top: screenWidth < 1240 ? 0 : 5,
                        bottom: screenWidth < 1240 ? 0 : 5),
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            lang.S.of(context).categories,
                            textAlign: TextAlign.start,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                                color: isSelected == 'Categories'
                                    ? screenWidth < 1240
                                        ? kTitleColor
                                        : Colors.white
                                    : kDarkGreyColor,
                                fontSize: screenWidth < 1240 ? 20 : 14),
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_right,
                          color: isSelected == 'Categories'
                              ? Colors.white
                              : kDarkGreyColor,
                          size: 16,
                        )
                      ],
                    ),
                  ),
                  onTap: () => onCategorySelected('Categories'),
                ),
                const SizedBox(height: 5.0),
                SizedBox(
                  height: screenWidth < 1240 ? 50 : null,
                  child: ListView.builder(
                    scrollDirection:
                        screenWidth < 1240 ? Axis.horizontal : Axis.vertical,
                    itemCount: category.length,
                    shrinkWrap: true,
                    itemBuilder: (_, i) {
                      return GestureDetector(
                        onTap: () =>
                            onCategorySelected(category[i].categoryName),
                        child: Padding(
                          padding: EdgeInsets.only(
                              top: 5,
                              bottom: 4,
                              right: screenWidth < 1240 ? 10 : 0),
                          child: Container(
                            padding: const EdgeInsets.only(
                                left: 15.0, right: 8.0, top: 8.0, bottom: 8.0),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5.0),
                                color: isSelected == category[i].categoryName
                                    ? kBlueTextColor
                                    : kBlueTextColor.withOpacity(0.1)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                screenWidth < 1240
                                    ? Text(
                                        category[i].categoryName,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                                color: isSelected ==
                                                        category[i].categoryName
                                                    ? Colors.white
                                                    : kDarkGreyColor),
                                      )
                                    : Flexible(
                                        child: Text(
                                          category[i].categoryName,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: kTextStyle.copyWith(
                                              color: isSelected ==
                                                      category[i].categoryName
                                                  ? Colors.white
                                                  : kDarkGreyColor,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                Icon(
                                  Icons.keyboard_arrow_right,
                                  color: isSelected == category[i].categoryName
                                      ? Colors.white
                                      : kDarkGreyColor,
                                  size: 16,
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
      error: (e, stack) => Center(child: Text(e.toString())),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}
