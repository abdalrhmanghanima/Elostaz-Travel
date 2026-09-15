import 'package:elostaz_travel/core/dimens/dimens.dart';
import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/navigator/navigator.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/core/utils/app_icons.dart';
import 'package:elostaz_travel/domain/factory/entity/factory_entity.dart';
import 'package:elostaz_travel/presentation/components/custom_app_bar/custom_app_bar.dart';
import 'package:elostaz_travel/presentation/components/custom_svg/custom_svg_icon.dart';
import 'package:elostaz_travel/presentation/components/custom_text/custom_text.dart';
import 'package:elostaz_travel/presentation/components/inputs/custom_text_form.dart';
import 'package:elostaz_travel/presentation/home/tabs/factory/add_factory_screen.dart';
import 'package:elostaz_travel/presentation/home/tabs/factory/factory_details_screen.dart';
import 'package:elostaz_travel/presentation/home/tabs/factory/provider/factory_provider.dart';
import 'package:elostaz_travel/presentation/home/tabs/factory/widgets/factory_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FactoryTab extends ConsumerStatefulWidget {
  const FactoryTab({super.key});

  @override
  ConsumerState<FactoryTab> createState() => _FactoryTabState();
}

class _FactoryTabState extends ConsumerState<FactoryTab> {
  final searchController = TextEditingController();
  String searchQuery = '';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final factoriesState = ref.watch(factoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(
        showToolBar: true,
        bgColor: AppColors.primary,
        centerTitle: true,
        title: "المصانع",
        fontColor: AppColors.white,
        fontSize: 24.sp,
        iconPath: AppIcons.add,
        onPressed: () {
          NavigatorHandler.push(const AddFactoryScreen());
        },
        leadingHeight: 19.h,
      ),
      body: Padding(
        padding: EdgeInsets.only(
          top: 16.h,
          left: 16.w,
          right: 16.w,
        ),
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.white,
          onRefresh: () async {
            await ref.read(factoriesProvider.notifier).getFactories();
          },
          child: factoriesState.when(
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, stackTrace) => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: 150.h),
                Center(
                  child: CustomText(
                    title: error.toString(),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            data: (factories) {
              final filteredFactories = factories.where((factory) {
                final name = factory.name.trim().toLowerCase();
                final query = searchQuery.trim().toLowerCase();
                return name.contains(query);
              }).toList();

              return Column(
                children: [
                  CustomTextFormField(
                    controller: searchController,
                    hint: 'ابحث باسم المصنع',
                    prefix: Icon(
                      Icons.search_rounded,
                      size: 23.sp,
                      color: const Color(0xFF777B85),
                    ),
                    onChange: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                  ),

                  SizedBox(height: 16.h),

                  Expanded(
                    child: factories.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(height: 150.h),
                              Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.factory_outlined,
                                      size: 54.sp,
                                      color: const Color(0xFFD1D5DB),
                                    ),
                                    SizedBox(height: 12.h),
                                    const CustomText(
                                      title: "لا توجد مصانع مسجلة",
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : filteredFactories.isEmpty
                            ? ListView(
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                children: [
                                  SizedBox(height: 150.h),
                                  const Center(
                                    child: CustomText(
                                      title: "لا يوجد مصنع بهذا الاسم",
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                itemCount: filteredFactories.length,
                                itemBuilder: (context, index) {
                                  final factory = filteredFactories[index];
                                  return FactoryCard(factory: factory);
                                },
                              ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
