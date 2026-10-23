import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../constants/routes_constant.dart';
import '../../../widgets/my_app_bar.dart';
import '../controllers/support_tickets_controller.dart';
import '../models/support_ticket.dart';

class SupportTicketsScreen extends HookConsumerWidget {
  const SupportTicketsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(supportTicketsControllerProvider);
    final controller = ref.read(supportTicketsControllerProvider.notifier);

    useEffect(() {
      Future.microtask(controller.fetchTickets);
      return null;
    }, const []);

    final lastError = useRef<String?>(null);
    useEffect(() {
      if (state.errorMessage != null && state.errorMessage != lastError.value) {
        lastError.value = state.errorMessage;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.red.shade400,
            ),
          );
        });
      }
      return null;
    }, [state.errorMessage]);

    final screen = MediaQuery.sizeOf(context);
    final width = screen.width;
    double u(double px) => width * (px / _frameW);
    double v(double px) => screen.height * (px / _frameH);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          MyAppBar(
            title: 'Tickets',
            titleStyle: MyAppBar.sharedTitleStyle(context),
            onBack: () => context.pop(),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: controller.fetchTickets,
              child: ListView(
                padding: EdgeInsets.fromLTRB(u(28), v(16), u(28), v(24)),
                children: [
                  Text(
                    'Open Tickets',
                    style: _pj(u(16), weight: FontWeight.w700),
                  ),
                  SizedBox(height: u(16)),
                  if (state.isLoading && state.tickets.isEmpty)
                    Skeletonizer(
                      enabled: true,
                      child: IgnorePointer(
                        child: Column(
                          children: List.generate(
                            6,
                            (index) => Padding(
                              padding: EdgeInsets.only(bottom: u(16)),
                              child: _TicketCard(
                                ticket: _SupportTicketSkeletons.ticket,
                                onTap: () {},
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  else if (state.tickets.isEmpty)
                    Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: v(26)),
                        child: Text(
                          'No tickets found',
                          style: _pj(
                            u(13),
                            weight: FontWeight.w500,
                            color: const Color(0xFFADADAD),
                          ),
                        ),
                      ),
                    )
                  else
                    ...state.tickets.map(
                      (ticket) => Padding(
                        padding: EdgeInsets.only(bottom: u(16)),
                        child: _TicketCard(
                          ticket: ticket,
                          onTap: () => context.push(
                            RouteConstants.supportTicketDetail,
                            extra: ticket.id,
                          ),
                        ),
                      ),
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

class _TicketCard extends StatelessWidget {
  const _TicketCard({
    required this.ticket,
    required this.onTap,
  });

  final SupportTicket ticket;
  final VoidCallback onTap;

  String get _title {
    final description = ticket.description.trim();
    if (description.isNotEmpty) return description;

    final issue = ticket.issueType.trim();
    if (issue.isNotEmpty) return issue;

    return 'Ticket';
  }

  String get _subtitle {
    final service =
        ticket.service.trim().isEmpty ? 'Service' : ticket.service.trim();
    final date = _formatDate(ticket.createdAtRaw);
    if (date.isEmpty) return service;
    return '$service  •  $date';
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    double u(double px) => width * (px / _frameW);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(u(12)),
      child: Container(
        padding: EdgeInsets.fromLTRB(u(12), u(14), u(12), u(14)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(u(12)),
          border: Border.all(color: const Color(0xFFEBEBEB)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _pj(u(14), weight: FontWeight.w700),
                  ),
                  SizedBox(height: u(8)),
                  Text(
                    _subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _pj(
                      u(12),
                      weight: FontWeight.w500,
                      color: const Color(0xFFADADAD),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: u(8)),
            _TicketStatusChip(status: ticket.status),
          ],
        ),
      ),
    );
  }
}

class _SupportTicketSkeletons {
  const _SupportTicketSkeletons._();

  static const ticket = SupportTicket(
    id: '0',
    transactionId: '',
    service: 'BBPS',
    issueType: 'Recharge',
    isTransactionRelated: true,
    description: '',
    status: 'Open',
    createdAtRaw: '2026-01-01 00:00:00',
    screenshot: null,
  );
}

class _TicketStatusChip extends StatelessWidget {
  const _TicketStatusChip({required this.status});

  final String status;

  Color get _color {
    final normalized = status.trim().toLowerCase();
    if (normalized == 'resolved') return const Color(0xFF058337);
    if (normalized == 'reopened') return const Color(0xFFB07B00);
    if (normalized == 'closed') return const Color(0xFFF54237);
    return const Color(0xFFDAA507);
  }

  String get _label {
    final normalized = status.trim().toLowerCase();
    if (normalized.isEmpty) return 'Open';
    if (normalized == 'in_progress') return 'In Progress';
    return normalized[0].toUpperCase() + normalized.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final badgeH = MediaQuery.sizeOf(context).width * (24 / _frameW);
    return Container(
      key: Key('ticket-status-$_label'),
      height: badgeH,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: badgeH * (10 / 24)),
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(badgeH * (7 / 24)),
      ),
      child: Text(
        _label,
        style: _pj(
          badgeH * (11 / 24),
          weight: FontWeight.w600,
          color: Colors.white,
          height: 1,
        ),
      ),
    );
  }
}

const _frameW = 448.0;
const _frameH = 986.0;

TextStyle _pj(
  double size, {
  FontWeight weight = FontWeight.w500,
  Color color = Colors.black,
  double height = 1.2,
}) {
  return GoogleFonts.plusJakartaSans(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
  );
}

String _formatDate(String raw) {
  final s = raw.trim();
  if (s.isEmpty) return '';
  final parsed = DateTime.tryParse(s.replaceFirst(' ', 'T'));
  if (parsed == null) return s;
  return DateFormat("d MMM''yy").format(parsed);
}
