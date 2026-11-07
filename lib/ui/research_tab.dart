import 'package:flutter/cupertino.dart';

import '../format.dart';
import '../game.dart';
import '../models.dart';
import 'common.dart';

class ResearchTab extends StatelessWidget {
  final GameState game;
  const ResearchTab({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: kBg,
      navigationBar: const CupertinoNavigationBar(middle: Text('🔬 Развитие'), backgroundColor: kBg),
      child: SafeArea(
        child: ListenableBuilder(
          listenable: game,
          builder: (context, _) {
            return ListView(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Text(
                    'Улучшения действуют сразу на все ваши бизнесы.',
                    style: TextStyle(color: kGrey, fontSize: 14),
                  ),
                ),
                for (final t in techDefs) _card(t),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _card(TechDef t) {
    final lvl = game.techLevel(t.id);
    final maxed = lvl >= t.maxLevel;
    final cost = game.techCost(t);
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(t.emoji, style: const TextStyle(fontSize: 30)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(t.desc, style: const TextStyle(color: kGrey, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Pill('Ур. $lvl/${t.maxLevel}', color: kAccent),
              const SizedBox(width: 8),
              if (lvl > 0) Pill(t.effect(lvl), color: kGreen),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ActionButton(
              label: maxed ? 'Максимум' : 'Улучшить за ${money(cost)}',
              sub: maxed ? null : 'Следующий уровень: ${t.effect(lvl + 1)}',
              enabled: !maxed && game.cash >= cost,
              onTap: () => game.buyTech(t),
            ),
          ),
        ],
      ),
    );
  }
}
