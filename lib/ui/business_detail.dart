import 'dart:math';

import 'package:flutter/cupertino.dart';

import '../format.dart';
import '../game.dart';
import '../models.dart';
import 'common.dart';

class BusinessDetailPage extends StatelessWidget {
  final GameState game;
  final String defId;
  const BusinessDetailPage({super.key, required this.game, required this.defId});

  @override
  Widget build(BuildContext context) {
    final def = defById(defId)!;
    return CupertinoPageScaffold(
      backgroundColor: kBg,
      navigationBar: CupertinoNavigationBar(
        middle: Text('${def.emoji} ${def.name}'),
        backgroundColor: kBg,
      ),
      child: SafeArea(
        child: ListenableBuilder(
          listenable: game,
          builder: (context, _) {
            final b = game.bizOf(defId);
            if (b == null) {
              return const Center(child: Text('Бизнес закрыт', style: TextStyle(color: kGrey)));
            }
            return ListView(
              padding: const EdgeInsets.only(top: 8, bottom: 32),
              children: [
                _header(b),
                _metrics(b),
                _pricePanel(b),
                _staffPanel(b),
                _upgrades(b),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _header(Biz b) {
    final profit = b.m.profit;
    return Panel(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Уровень ${b.level} из ${GameState.maxLevel}',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('${stars(b.rep)}  ${b.rep.toStringAsFixed(1)}',
                    style: const TextStyle(color: kAccent, fontSize: 14)),
              ],
            ),
          ),
          Text(
            rate(profit),
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: profit >= 0 ? kGreen : kRed),
          ),
        ],
      ),
    );
  }

  Widget _metrics(Biz b) {
    final m = b.m;
    final top = max(0.001, max(m.demand, m.capacity));
    final tips = <String>[];
    if (m.coverage < 1) {
      tips.add('Не хватает персонала — мощность упала. Наймите сотрудников.');
    }
    if (m.demand > m.capacity * 1.05) {
      tips.add('Спрос выше мощности: клиенты уходят. Поднимите уровень, наймите людей или поднимите цену.');
    }
    if (m.demand < m.capacity * 0.6) {
      tips.add('Спрос слабый: снизьте цену, вложитесь в рекламу или качество.');
    }
    if (m.profit < 0) {
      tips.add('Бизнес убыточен! Проверьте цену и расходы.');
    }
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Показатели', style: TextStyle(color: kGrey, fontSize: 13)),
          const SizedBox(height: 10),
          Text('Спрос: ${fmtNum(m.demand)} кл/с', style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 4),
          BarMeter(value: m.demand / top, color: kBlue),
          const SizedBox(height: 8),
          Text('Мощность: ${fmtNum(m.capacity)} кл/с', style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 4),
          BarMeter(value: m.capacity / top, color: kAccent),
          const SizedBox(height: 12),
          StatLine('Выручка', rate(m.revenue)),
          StatLine('Сырьё', '-${money(m.supplies)}/с'),
          StatLine('Зарплаты', '-${money(m.wages)}/с'),
          StatLine('Аренда', '-${money(m.rent)}/с'),
          StatLine('Реклама', '-${money(m.marketing)}/с'),
          if (tips.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final t in tips)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('💡 $t', style: const TextStyle(color: kAccent, fontSize: 13)),
              ),
          ],
        ],
      ),
    );
  }

  Widget _pricePanel(Biz b) {
    final forecast = game.forecastProfit(b, b.mult);
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Цена', style: TextStyle(color: kGrey, fontSize: 13)),
          const SizedBox(height: 6),
          Text(
            '${money(b.def.price * b.mult)}  (×${b.mult.toStringAsFixed(2)} от справедливой)',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          CupertinoSlider(
            value: b.mult.clamp(0.6, 2.0).toDouble(),
            min: 0.6,
            max: 2.0,
            onChanged: b.manager ? null : (v) => game.setMult(b, v),
          ),
          Text(
            'Прогноз прибыли при такой цене: ${rate(forecast)}',
            style: TextStyle(fontSize: 13, color: forecast >= 0 ? kGreen : kRed),
          ),
          const SizedBox(height: 6),
          Text(
            b.manager
                ? '🤝 Менеджер сам подбирает лучшую цену.'
                : 'Дорого — клиентов меньше и репутация падает. Дёшево — выручка меньше. Качество позволяет брать больше.',
            style: const TextStyle(color: kGrey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _staffPanel(Biz b) {
    final canHire = b.staff < b.slots && game.cash >= game.hireCost(b);
    return Panel(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Персонал', style: TextStyle(color: kGrey, fontSize: 13)),
                const SizedBox(height: 4),
                Text('${b.staff} из ${b.slots}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  'Найм ${money(game.hireCost(b))} · зарплата ${money(b.def.wage)}/с',
                  style: const TextStyle(color: kGrey, fontSize: 12),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 56,
            child: ActionButton(label: '−', color: kPanel2, enabled: b.staff > 0, onTap: () => game.fire(b)),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 56,
            child: ActionButton(label: '+', color: kBlue, enabled: canHire, onTap: () => game.hire(b)),
          ),
        ],
      ),
    );
  }

  Widget _upgrades(Biz b) {
    final maxLvl = b.level >= GameState.maxLevel;
    final maxQ = b.quality >= GameState.maxQuality;
    final maxM = b.marketing >= GameState.maxMarketing;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Развитие', style: TextStyle(color: kGrey, fontSize: 13)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ActionButton(
                  label: maxLvl ? 'Макс. уровень' : 'Уровень ${b.level + 1}',
                  sub: maxLvl ? null : '${money(game.levelCost(b))} · спрос и мощность',
                  enabled: !maxLvl && game.cash >= game.levelCost(b),
                  onTap: () => game.levelUp(b),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ActionButton(
                  label: maxQ ? 'Макс. качество' : 'Качество ${b.quality + 1}',
                  sub: maxQ ? null : '${money(game.qualityCost(b))} · цена и репутация',
                  enabled: !maxQ && game.cash >= game.qualityCost(b),
                  onTap: () => game.upgradeQuality(b),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ActionButton(
                  label: maxM ? 'Макс. реклама' : 'Реклама ${b.marketing + 1}',
                  sub: maxM ? null : '${money(game.marketingCost(b))} · +15% спроса',
                  enabled: !maxM && game.cash >= game.marketingCost(b),
                  onTap: () => game.upgradeMarketing(b),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ActionButton(
                  label: b.manager ? 'Менеджер нанят' : 'Менеджер',
                  sub: b.manager ? null : '${money(game.managerCost(b))} · авто-цена, +10% мощности',
                  enabled: !b.manager && game.cash >= game.managerCost(b),
                  color: kGreen,
                  onTap: () => game.hireManager(b),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Качество ${b.quality}/${GameState.maxQuality} · Реклама ${b.marketing}/${GameState.maxMarketing}',
            style: const TextStyle(color: kGrey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
