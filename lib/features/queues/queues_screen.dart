import 'package:flutter/material.dart';
import '../network/network_screens.dart';
import '../../core/routeros/router_session.dart';

class QueuesScreen extends StatelessWidget {
  const QueuesScreen({super.key});
  @override
  Widget build(BuildContext c) => RouterListScreen(
    title: 'Simple Queues',
    loader: () => RouterSession.instance.service.simpleQueues(),
  );
}
