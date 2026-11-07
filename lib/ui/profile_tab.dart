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
    return h > 0 ? '$h ч $m мин' : '$m мин';
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: kBg,
      navigationBar: const CupertinoNavigationBar(middle: Text('👤 Профиль'), backgroundColor: kBg),
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
                      StatLine('Чистый капитал', money(game.netWorth)),
                      StatLine('Всего заработано', money(game.lifetimeProfit)),
                      StatLine('Бизнесов', '${game.bizList.length} из ${businessDefs.length}'),
                      StatLine('Сотрудников', '${game.totalStaff}'),
                      StatLine('Очки наследия', '${game.legacy} ⭐ (+${game.legacy * 5}% к выручке)'),
                      StatLine('IPO проведено', '${game.prestiges}'),
                      StatLine('Банкротств', '${game.bankruptcies}'),
                      StatLine('Время в игре', _time(game.playSeconds)),
                    ],
                  ),
                ),
                const SectionTitle('Все цели'),
                Panel(
                  child: Column(
                    children: [
                      for (final m in missions) _missionRow(m),
                    ],
                  ),
                ),
                const SectionTitle('Настройки'),
                Panel(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Вибрация', style: TextStyle(fontSize: 16)),
                      CupertinoSwitch(value: game.haptics, onChanged: game.setHaptics),
                    ],
                  ),
                ),
                Panel(
                  onTap: () => _confirmReset(context),
                  child: const Text(
                    'Сбросить весь прогресс',
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
        title: const Text('Сбросить всё?'),
        content: const Text('Весь прогресс, включая наследие, будет удалён без возможности восстановления.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Отмена'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(ctx).pop();
              game.resetAll();
            },
            child: const Text('Сбросить'),
          ),
        ],
      ),
    );
  }
}
