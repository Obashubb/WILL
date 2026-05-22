import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../controllers/auth_controller.dart';
import '../../helpers/greeting.dart';
import '../../models/insight.dart';
import '../../services/inference_service.dart';
import '../../services/wearable_service.dart';
import '../widgets/dashboard/greeting_block.dart';
import '../widgets/dashboard/metrics_grid.dart';
import '../widgets/dashboard/no_band_banner.dart';
import '../widgets/dashboard/section_label.dart';
import '../widgets/dashboard/watch_banner.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final auth = Get.find<AuthController>();
    final wearable = Get.find<WearableService>();
    final inference = Get.find<InferenceService>();

    return Obx(() {
      final firstName = auth.user.value?.firstName ?? '';
      final greeting = greetingFor(DateTime.now());
      final state = wearable.connectionState.value;
      final sample = wearable.latestSample.value;
      final insight = inference.latestInsight.value;
      final showWatch = insight?.severity == InsightSeverity.watch;
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          GreetingBlock(
            greeting: greeting,
            firstName: firstName,
            state: state,
          ),
          if (showWatch) ...[
            const SizedBox(height: 14),
            WatchBanner(insight: insight!),
          ],
          const SizedBox(height: 28),
          SectionLabel(
            title: 'Live health overview',
            trailing: sample == null
                ? 'Waiting for data'
                : 'Updated ${DateFormat.Hm().format(sample.timestamp)}',
          ),
          const SizedBox(height: 14),
          if (state == WearableConnectionState.idle) ...[
            NoBandBanner(onPair: () => wearable.startPairing()),
            const SizedBox(height: 14),
          ],
          MetricsGrid(sample: sample),
        ],
      );
    });
  }
}
