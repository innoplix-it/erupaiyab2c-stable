// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../widgets/my_app_bar.dart';
import '../../../widgets/search_textfield.dart';
import '../models/faq_item.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  final _searchController = TextEditingController();
  int _expandedIndex = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final filteredFaqs = query.isEmpty
        ? _paymentsFaqs
        : _paymentsFaqs.where((item) {
            final q = item.question.toLowerCase();
            final a = item.answer.toLowerCase();
            return q.contains(query) || a.contains(query);
          }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          MyAppBar(
            title: "Faq’s",
            onBack: () => context.pop(),
            showHelp: true,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SearchTextfield(
                    hintText: "Search Faq’s",
                    controller: _searchController,
                    onChange: (_) => setState(() {}),
                  ),
                  SizedBox(height: 16.h),
                  if (filteredFaqs.isEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 28.h),
                      child: Center(
                        child: Text(
                          'No FAQs found.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: AppColors.textPrimary.withOpacity(0.6),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    )
                  else
                    ...filteredFaqs.asMap().entries.map(
                      (entry) {
                        final idx = entry.key;
                        final item = entry.value;
                        final isExpanded = _expandedIndex == idx;
                        return Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: _FaqCard(
                            question: item.question,
                            answer: item.answer,
                            isExpanded: isExpanded,
                            onTap: () {
                              setState(() {
                                _expandedIndex = isExpanded ? -1 : idx;
                              });
                            },
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqCard extends StatelessWidget {
  const _FaqCard({
    required this.question,
    required this.answer,
    required this.isExpanded,
    required this.onTap,
  });

  final String question;
  final String answer;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onTap,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    question,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: AppColors.textPrimary.withOpacity(0.7),
                  size: 20.sp,
                ),
              ],
            ),
          ),
          if (isExpanded) ...[
            SizedBox(height: 10.h),
            Divider(color: AppColors.lightBorder.withOpacity(0.9)),
            SizedBox(height: 8.h),
            Text(
              answer,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary.withOpacity(0.7),
                    height: 1.5,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

final List<FaqItem> _paymentsFaqs = FaqItem.fromJsonList([
  {
    'id': 'q1',
    'question': 'What is Erupaiya?',
    'answer':
        'Erupaiya is a digital payment platform that allows users to make BBPS bill payments, mobile recharges, credit card bill payments, and other utility payments quickly and securely from one mobile application.',
  },
  {
    'id': 'q2',
    'question': 'What services can I use on Erupaiya?',
    'answer':
        'Users can access services such as: Electricity Bill Payment, Mobile Recharge (Prepaid), Postpaid Mobile Bill Payment, Credit Card Bill Payment, DTH Recharge, Utility Bill Payments, Other BBPS supported services.',
  },
  {
    'id': 'q3',
    'question': 'What is BBPS?',
    'answer':
        'BBPS (Bharat Bill Payment System) is an integrated bill payment system managed by the National Payments Corporation of India that enables customers to pay multiple types of bills through a single platform.',
  },
  {
    'id': 'q4',
    'question': 'How do I register on Erupaiya?',
    'answer': 'You can register using your mobile number and OTP verification.',
  },
  {
    'id': 'q5',
    'question': 'What is the referral program?',
    'answer':
        'Erupaiya offers a lifetime referral earning program where users can invite friends and earn rewards when they use the app services.',
  },
  {
    'id': 'q6',
    'question': 'How does the lifetime referral program work?',
    'answer':
        'Share your referral code/link, your friend registers using your code, and when they use services, you receive reward E-coins.',
  },
  {
    'id': 'q7',
    'question': 'What are E-coins?',
    'answer':
        'E-coins are reward points earned through the referral program, promotions and cashback, and campaign rewards. These coins can later be withdrawn or used for payments after KYC verification.',
  },
  {
    'id': 'q8',
    'question': 'Can E-coins be converted into money?',
    'answer':
        'Yes. Once KYC is completed and bank details are added, E-coins can be withdrawn to your bank account.',
  },
  {
    'id': 'q9',
    'question': 'Can I use E-coins without KYC?',
    'answer':
        'No. KYC verification and bank account addition are mandatory before E-coins can be used or withdrawn.',
  },
  {
    'id': 'q10',
    'question': 'How do I complete KYC?',
    'answer':
        'You may be required to submit documents such as PAN Card, Aadhaar Card, and bank account details. Verification may take some time based on compliance checks.',
  },
  {
    'id': 'q11',
    'question': 'How long does it take to withdraw E-coins?',
    'answer':
        'Withdrawal requests are usually processed within 3–7 working days.',
  },
  {
    'id': 'q12',
    'question': 'What happens if my recharge fails but money is deducted?',
    'answer':
        'If the service fails and money is deducted, the amount will either be automatically reversed, or processed as a refund within 7 working days.',
  },
  {
    'id': 'q13',
    'question': 'Can I cancel a successful recharge or bill payment?',
    'answer':
        'No. Once a recharge or bill payment is successfully processed, it cannot be cancelled or refunded.',
  },
  {
    'id': 'q14',
    'question': 'What is the refund policy?',
    'answer':
        'Refunds are only applicable if payment is deducted and service is not delivered. Successful services are non-refundable.',
  },
  {
    'id': 'q15',
    'question': 'How long does a refund take?',
    'answer': 'Refunds are processed within 7 working days after verification.',
  },
  {
    'id': 'q16',
    'question': 'What payment methods are accepted?',
    'answer':
        'Users can pay using UPI, Debit Cards, Credit Cards, Net Banking, and Wallets (if supported).',
  },
  {
    'id': 'q17',
    'question': 'Is my data safe on Erupaiya?',
    'answer':
        'Yes. We implement security measures to protect your personal information and transaction details.',
  },
  {
    'id': 'q18',
    'question': 'How can I contact support?',
    'answer':
        'For any queries or issues, please contact: Email: support@erupaiya.com',
  },
]);
