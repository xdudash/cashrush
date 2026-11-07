import 'package:flutter/cupertino.dart';

import '../format.dart';
import '../game.dart';
import '../models.dart';
import 'common.dart';

class ProfileTab extends StatelessWidget {
  final GameState game;
  const ProfileTab({super.key, required this.game});

  String _time(double seconds) {
    final h = (seconds / 3600).floor();
    final m = ((seconds % 3600) / 60).floor();
    return h > 0 ? '$h h $m min' : '$m min';
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: kBg,
      navigationBar: const CupertinoNavigationBar(middle: Text('👤 Profile'), backgroundColor: kBg),
      child: SafeArea(
        child: ListenableBuilder(
          listenable: game,
          builder: (context, _) {
            return ListView(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              children: [
                Panel(
                  child: Column(
                    children: [
                      StatLine('Net worth', money(game.netWorth)),
                      StatLine('Total earned', money(game.lifetimeProfit)),
                      StatLine('Businesses', '${game.bizList.length} of ${businessDefs.length}'),
                      StatLine('Employees', '${game.totalStaff}'),
                      StatLine('Legacy points', '${game.legacy} ⭐ (+${game.legacy * 5}% revenue)'),
                      StatLine('IPOs completed', '${game.prestiges}'),
                      StatLine('Bankruptcies', '${game.bankruptcies}'),
                      StatLine('Play time', _time(game.playSeconds)),
                    ],
                  ),
                ),
                const SectionTitle('All goals'),
                Panel(
                  child: Column(
                    children: [
                      for (final m in missions) _missionRow(m),
                    ],
                  ),
                ),
                const SectionTitle('Settings'),
                Panel(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Haptics', style: TextStyle(fontSize: 16)),
                      CupertinoSwitch(value: game.haptics, onChanged: game.setHaptics),
                    ],
                  ),
                ),
                Panel(
                  onTap: () => _confirmReset(context),
                  child: const Text(
                    'Reset all progress',
                    style: TextStyle(color: kRed, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _missionRow(Mission m) {
    final claimed = game.claimed.contains(m.id);
    final done = game.missionDone(m);
    final icon = claimed ? '✅' : (done ? '🎁' : '🔒');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              m.title,
              style: TextStyle(fontSize: 14, color: claimed ? kGrey : null),
            ),
          ),
          Text(money(m.reward), style: const TextStyle(color: kGrey, fontSize: 13)),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context) {
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Reset everything?'),
        content: const Text('All progress, including legacy, will be permanently deleted.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(ctx).pop();
              game.resetAll();
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
