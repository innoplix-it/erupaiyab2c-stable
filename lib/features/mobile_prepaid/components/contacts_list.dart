// ignore_for_file: deprecated_member_use

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../constants/file_constants.dart';

String normalizeMobile(String input) {
  final digits = input.replaceAll(RegExp(r'\D'), '');
  if (digits.length > 10 && digits.startsWith('91')) {
    return digits.substring(digits.length - 10);
  }
  return digits;
}

class ContactsList extends StatelessWidget {
  const ContactsList({
    super.key,
    required this.contacts,
    required this.visibleCount,
    required this.onSelect,
    this.prepaidStyle = false,
  });

  final List<Contact> contacts;
  final int visibleCount;
  final ValueChanged<String> onSelect;
  final bool prepaidStyle;

  @override
  Widget build(BuildContext context) {
    final displayContacts = contacts.length > visibleCount
        ? contacts.take(visibleCount).toList()
        : contacts;
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: displayContacts.length,
      separatorBuilder: (_, __) => prepaidStyle
          ? SizedBox(height: 4.h)
          : Divider(
              height: 1.h,
              thickness: 1,
              color: Colors.black.withOpacity(0.06),
            ),
      itemBuilder: (context, index) {
        final contact = displayContacts[index];
        final phone =
            contact.phones.isNotEmpty ? contact.phones.first.number : '';
        final photoBytes = contact.photoOrThumbnail;
        return InkWell(
          onTap: phone.isEmpty ? null : () => onSelect(normalizeMobile(phone)),
          borderRadius: BorderRadius.circular(12.r),
          child: prepaidStyle
              ? _prepaidRow(contact.displayName, phone, photoBytes)
              : _defaultRow(contact.displayName, phone, photoBytes),
        );
      },
    );
  }

  Widget _defaultRow(String name, String phone, Uint8List? photoBytes) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 12.h),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22.r,
            backgroundColor: Colors.black.withOpacity(0.08),
            backgroundImage:
                photoBytes == null ? null : MemoryImage(photoBytes),
            child: photoBytes != null
                ? null
                : Icon(Icons.person, color: Colors.white, size: 22.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.sp,
                    color: const Color(0xFF292D32),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  phone.isEmpty ? 'No number' : phone,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w500,
                    fontSize: 12.sp,
                    color: const Color(0xFF7C7C7C),
                  ),
                ),
              ],
            ),
          ),
          if (phone.isNotEmpty)
            Image.asset(
              FileConstants.tiltArrow,
              width: 18.r,
              height: 18.r,
              fit: BoxFit.contain,
            ),
        ],
      ),
    );
  }

  Widget _prepaidRow(String name, String phone, Uint8List? photoBytes) {
    // Avatar: rounded-square (squircle) contact photo — matches Figma
    // (50px box @440 ≈ 41.r, ~28% corner radius ≈ 12.r, 1px #E2E2E2 border)
    final avatarSize = 41.r;
    final avatarRadius = 12.r;
    return Container(
      constraints: BoxConstraints(minHeight: 50.h),
      alignment: Alignment.center,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Rounded-square contact avatar (Figma: 1px #E2E2E2 border, centered)
          Container(
            width: avatarSize,
            height: avatarSize,
            padding: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(avatarRadius),
              border: Border.all(
                color: const Color(0xFFE2E2E2),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(avatarRadius - 1),
              child: photoBytes != null
                  ? Image.memory(
                      photoBytes,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      width: double.infinity,
                      height: double.infinity,
                    )
                  : Center(
                      child: Icon(
                        Icons.person,
                        color: const Color(0xFFBDBDBD),
                        size: avatarSize * 0.55,
                      ),
                    ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w500,
                    fontSize: 14.sp,
                    height: 1.0,
                    letterSpacing: 0,
                    color: const Color(0xFF000000),
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  phone.isEmpty ? 'No number' : phone,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w400,
                    fontSize: 12.sp,
                    height: 1.0,
                    letterSpacing: 0,
                    color: const Color(0xFF7C7C7C),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Center(
            child: Image.asset(
              FileConstants.tiltArrow,
              width: 24.r,
              height: 24.r,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}
