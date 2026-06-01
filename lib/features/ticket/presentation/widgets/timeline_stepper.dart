import 'package:flutter/material.dart';
import 'package:arvi_b3_uts/features/ticket/domain/ticket_model.dart';
import 'package:intl/intl.dart';

class TimelineStepper extends StatelessWidget {
  final List<TicketTimeline> timelineEvents;

  const TimelineStepper({super.key, required this.timelineEvents});

  @override
  Widget build(BuildContext context) {
    if (timelineEvents.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(timelineEvents.length, (index) {
        final event = timelineEvents[index];
        final isLast = index == timelineEvents.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Theme.of(context).cardColor, width: 3),
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24.0, top: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.description,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'By: ${event.actorRole} \u2022 ${DateFormat('MMM dd, yyyy HH:mm').format(event.timestamp)}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
