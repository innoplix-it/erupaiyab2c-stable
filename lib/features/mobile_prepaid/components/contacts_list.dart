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
            backgroundImage: photoBytes == null ? null : MemoryImage(photoBytes),
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
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24.r,
            backgroundColor: const Color(0xFFE8E8E8),
            backgroundImage: photoBytes == null ? null : MemoryImage(photoBytes),
            child: photoBytes != null
                ? null
                : Icon(
                    Icons.person,
                    color: const Color(0xFFBDBDBD),
                    size: 26.sp,
                  ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.sp,
                    height: 1.2,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  phone.isEmpty ? 'No number' : phone,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w500,
                    fontSize: 12.sp,
                    height: 1.2,
                    color: const Color(0xFF8A8A8A),
                  ),
                ),
              ],
            ),
          ),
          if (phone.isNotEmpty)
            Image.asset(
              FileConstants.tiltArrow,
              width: 16.w,
              height: 16.w,
              fit: BoxFit.contain,
            ),
        ],
      ),
    );
  }
}



