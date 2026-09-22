// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../constants/app_colors.dart';
import '../../../widgets/custom_elevated_button.dart';

class FilterPlansSheet extends StatefulWidget {
  const FilterPlansSheet({
    super.key,
    required this.validityOptions,
    required this.dataOptions,
    required this.initialValiditySelected,
    required this.initialDataSelected,
    required this.onApply,
  });

  final List<String> validityOptions;
  final List<String> dataOptions;
  final Set<String> initialValiditySelected;
  final Set<String> initialDataSelected;
  final void Function(Set<String> validity, Set<String> data) onApply;

  @override
  State<FilterPlansSheet> createState() => _FilterPlansSheetState();
}

class _FilterPlansSheetState extends State<FilterPlansSheet> {
  static const _allLabel = 'All';

  late final Set<String> _selectedValidity = widget.initialValiditySelected
          .where((e) => e.trim().isNotEmpty)
          .toSet()
          .isEmpty
      ? <String>{_allLabel}
      : Set<String>.from(widget.initialValiditySelected);
  late final Set<String> _selectedData = widget.initialDataSelected
          .where((e) => e.trim().isNotEmpty)
          .toSet()
          .isEmpty
      ? <String>{_allLabel}
      : Set<String>.from(widget.initialDataSelected);

  void _clearAll() {
    _selectedValidity
      ..clear()
      ..add(_allLabel);
    _selectedData
      ..clear()
      ..add(_allLabel);
    widget.onApply(const <String>{}, const <String>{});
    Navigator.of(context).pop();
  }

  Widget _chipGroup({
    required List<String> options,
    required Set<String> selected,
  }) {
    final resolved = <String>[
      _allLabel,
      ...options.where((e) => e.trim().isNotEmpty && e.trim() != _allLabel),
    ];
    return Wrap(
      spacing: 10.w,
      runSpacing: 10.h,
      children: [
        for (final option in resolved)
          InkWell(
            onTap: () {
              setState(() {
                if (option == _allLabel) {
                  selected
                    ..clear()
                    ..add(_allLabel);
                  return;
                }
                selected.remove(_allLabel);
                if (selected.contains(option)) {
                  selected.remove(option);
                } else {
                  selected.add(option);
                }
                if (selected.isEmpty) selected.add(_allLabel);
              });
            },
            borderRadius: BorderRadius.circular(6.r),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: selected.contains(option)
                    ? AppColors.primary.withOpacity(0.1)
                    : Colors.white,
                borderRadius: BorderRadius.circular(6.r),
                border: Border.all(
                  color: selected.contains(option)
                      ? AppColors.primary.withOpacity(0.35)
                      : AppColors.textPrimary.withOpacity(0.08),
                ),
              ),
              child: Text(
                option,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: selected.contains(option)
                          ? AppColors.primary
                          : AppColors.textPrimary.withOpacity(0.85),
                    ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 18.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Filter Plans',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  splashRadius: 20,
                ),
              ],
            ),
            Divider(color: AppColors.textPrimary.withOpacity(0.08)),
            SizedBox(height: 10.h),
            Text(
              'Validity',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
            ),
            SizedBox(height: 10.h),
            _chipGroup(
              options: widget.validityOptions,
              selected: _selectedValidity,
            ),
            SizedBox(height: 18.h),
            Text(
              'Data',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
            ),
            SizedBox(height: 10.h),
            _chipGroup(
              options: widget.dataOptions,
              selected: _selectedData,
            ),
            SizedBox(height: 22.h),
            Row(
              children: [
                Expanded(
                  child: CustomElevatedButton(
                    onPressed: _clearAll,
                    label: 'Clear All',
                    uppercaseLabel: false,
                    isBorder: true,
                    height: 36.h,
                    backgroundColor: Colors.white,
                    borderColor: AppColors.textPrimary.withOpacity(0.18),
                    labelColor: Colors.black,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: CustomElevatedButton(
                    onPressed: () {
                      widget.onApply(
                        _selectedValidity.where((e) => e != _allLabel).toSet(),
                        _selectedData.where((e) => e != _allLabel).toSet(),
                      );
                      Navigator.of(context).pop();
                    },
                    label: 'Apply',
                    uppercaseLabel: false,
                    height: 36.h,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
