import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/navigator/navigator.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/core/utils/app_icons.dart';
import 'package:elostaz_travel/presentation/components/custom_app_bar/custom_app_bar.dart';
import 'package:elostaz_travel/presentation/components/custom_text/custom_text.dart';
import 'package:elostaz_travel/presentation/components/inputs/custom_text_form.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/add_bus_screen.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/provider/bus_provider.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/widgets/bus_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elostaz_travel/domain/bus/entity/bus_entity.dart';

/// Normalizes bus search text so Arabic-Indic digits (٠-٩ / ۰-۹) compare
/// equal to Western digits (0-9): a stored plate "١٢٣٤" is found by "1234".
String normalizeBusSearchText(String text) {
  final buffer = StringBuffer();
  for (final rune in text.trim().toLowerCase().runes) {
    if (rune >= 0x0660 && rune <= 0x0669) {
      buffer.writeCharCode(rune - 0x0660 + 0x30);
    } else if (rune >= 0x06F0 && rune <= 0x06F9) {
      buffer.writeCharCode(rune - 0x06F0 + 0x30);
    } else {
      buffer.writeCharCode(rune);
    }
  }
  return buffer.toString();
}

/// Applies [normalizeBusSearchText] to both the stored data and the query so
/// digit-style differences never hide an existing bus.
List<BusEntity> filterBusesBySearch(List<BusEntity> buses, String query) {
  final normalizedQuery = normalizeBusSearchText(query);
  return buses.where((bus) {
    final name = normalizeBusSearchText(bus.busName);
    final plate = normalizeBusSearchText(bus.plateNumber);
    return name.contains(normalizedQuery) || plate.contains(normalizedQuery);
  }).toList();
}

class BusTab extends ConsumerStatefulWidget {
  const BusTab({super.key});

  @override
  ConsumerState<BusTab> createState() => _BusTabState();
}

class _BusTabState extends ConsumerState<BusTab> {
  final searchController = TextEditingController();

  String searchQuery = '';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final busesState = ref.watch(busProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(
        showToolBar: true,
        bgColor: AppColors.primary,
        centerTitle: true,
        title: "العربيات",
        fontColor: AppColors.white,
        fontSize: 24.sp,
        iconPath: AppIcons.add,
        onPressed: () {
          NavigatorHandler.push(AddBusScreen());
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
            await ref.read(busProvider.notifier).refreshBuses();
          },
          child: busesState.when(
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
            data: (buses) {
              final filteredBuses = filterBusesBySearch(buses, searchQuery);

              return Column(
                children: [
                  CustomTextFormField(
                    controller: searchController,
                    hint: 'ابحث باسم أو نمرة العربية',
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
                    child: buses.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(height: 150.h),
                              const Center(
                                child: CustomText(
                                  title: "لا يوجد عربيات",
                                ),
                              ),
                            ],
                          )
                        : filteredBuses.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  SizedBox(height: 150.h),
                                  const Center(
                                    child: CustomText(
                                      title: "لا يوجد عربية بهذا الاسم",
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: filteredBuses.length,
                                itemBuilder: (context, index) {
                                  final bus = filteredBuses[index];

                                  return BusCard(
                                    bus: bus,
                                  );
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