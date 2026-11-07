import 'package:flutter/cupertino.dart';

import '../format.dart';
import '../game.dart';
import '../models.dart';
import 'business_detail.dart';
import 'common.dart';

class BusinessTab extends StatelessWidget {
  final GameState game;
  const BusinessTab({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: kBg,
      navigationBar: const CupertinoNavigationBar(middle: Text('🏢 Бизнесы'), backgroundColor: kBg),
      child: SafeArea(
        child: ListenableBuilder(
          listenable: game,
          builder: (context, _) {
            final children = <Widget>[];
            if (game.bizList.isEmpty) {
              children.add(const Panel(
                child: Text('У вас пока нет бизнеса. Откройте первый ниже 👇', style: TextStyle(fontSize: 15)),
              ));
            } else {
              children.add(const SectionTitle('Ваши бизнесы'));
              for (final b in game.bizList) {
                children.add(_bizCard(context, b));
              }
            }
            final locked = businessDefs.where((d) => game.bizOf(d.id) == null).toList();
            if (locked.isNotEmpty) {
              children.add(const SectionTitle('Открыть новый'));
              for (final d in locked) {
                children.add(_openCard(d));
              }
            }
            return ListView(padding: const EdgeInsets.only(top: 8, bottom: 24), children: children);
          },
        ),
      ),
    );
  }

  String _status(Biz b) {
    final m = b.m;
    if (m.coverage < 1) return '⚠️ Не хватает персонала';
    if (m.demand > m.capacity * 1.05) return '🔥 Спрос выше мощности';
    if (m.demand < m.capacity * 0.6) return '📉 Слабый спрос';
    return '✅ Работает ровно';
  }

  Widget _bizCard(BuildContext context, Biz b) {
    final profit = b.m.profit;
    return Panel(
      onTap: () {
        Navigator.of(context).push(
          CupertinoPageRoute<void>(builder: (_) => BusinessDetailPage(game: game, defId: b.def.id)),
        );
      },
      child: Row(
        children: [
          Text(b.def.emoji, style: const TextStyle(fontSize: 38)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(b.def.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  'Ур. ${b.level}  ·  ${stars(b.rep)}',
                  style: const TextStyle(color: kAccent, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(_status(b), style: const TextStyle(color: kGrey, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                rate(profit),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: profit >= 0 ? kGreen : kRed),
              ),
              const Text('›', style: TextStyle(color: kGrey, fontSize: 22)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _openCard(BusinessDef d) {
    final lockedByWorth = game.netWorth < d.unlockNetWorth;
    final canBuy = game.canOpen(d);
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(d.emoji, style: TextStyle(fontSize: 34, color: lockedByWorth ? const Color(0x55FFFFFF) : null)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(d.desc, style: const TextStyle(color: kGrey, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (lockedByWorth)
            Text('🔒 Нужен капитал ${money(d.unlockNetWorth)}', style: const TextStyle(color: kGrey, fontSize: 14))
          else
            SizedBox(
              width: double.infinity,
              child: ActionButton(
                label: 'Открыть за ${money(d.openCost)}',
                enabled: canBuy,
                color: kGreen,
                onTap: () => game.openBusiness(d),
              ),
            ),
        ],
      ),
    );
  }
}
