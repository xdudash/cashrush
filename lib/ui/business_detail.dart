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
              return const Center(child: Text('Business closed', style: TextStyle(color: kGrey)));
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
                Text('Level ${b.level} of ${GameState.maxLevel}',
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
      tips.add('Not enough staff — capacity dropped. Hire more people.');
    }
    if (m.demand > m.capacity * 1.05) {
      tips.add('Demand exceeds capacity: customers are leaving. Upgrade, hire people or raise the price.');
    }
    if (m.demand < m.capacity * 0.6) {
      tips.add('Demand is weak: lower the price, or invest in marketing or quality.');
    }
    if (m.profit < 0) {
      tips.add('This business is losing money! Check your price and costs.');
    }
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Stats', style: TextStyle(color: kGrey, fontSize: 13)),
          const SizedBox(height: 10),
          Text('Demand: ${fmtNum(m.demand)} cust/s', style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 4),
          BarMeter(value: m.demand / top, color: kBlue),
          const SizedBox(height: 8),
          Text('Capacity: ${fmtNum(m.capacity)} cust/s', style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 4),
          BarMeter(value: m.capacity / top, color: kAccent),
          const SizedBox(height: 12),
          StatLine('Revenue', rate(m.revenue)),
          StatLine('Supplies', '-${money(m.supplies)}/s'),
          StatLine('Wages', '-${money(m.wages)}/s'),
          StatLine('Rent', '-${money(m.rent)}/s'),
          StatLine('Marketing', '-${money(m.marketing)}/s'),
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
          const Text('Price', style: TextStyle(color: kGrey, fontSize: 13)),
          const SizedBox(height: 6),
          Text(
            '${money(b.def.price * b.mult)}  (×${b.mult.toStringAsFixed(2)} of fair price)',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          CupertinoSlider(
            value: b.mult.clamp(0.6, 2.0).toDouble(),
            min: 0.6,
            max: 2.0,
            onChanged: b.manager ? null : (v) => game.setMult(b, v),
          ),
          Text(
            'Projected profit at this price: ${rate(forecast)}',
            style: TextStyle(fontSize: 13, color: forecast >= 0 ? kGreen : kRed),
          ),
          const SizedBox(height: 6),
          Text(
            b.manager
                ? '🤝 The manager sets the best price automatically.'
                : 'Too expensive: fewer customers and reputation drops. Too cheap: less revenue. Quality lets you charge more.',
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
                const Text('Staff', style: TextStyle(color: kGrey, fontSize: 13)),
                const SizedBox(height: 4),
                Text('${b.staff} of ${b.slots}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  'Hire ${money(game.hireCost(b))} · wage ${money(b.def.wage)}/s',
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
          const Text('Upgrades', style: TextStyle(color: kGrey, fontSize: 13)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ActionButton(
                  label: maxLvl ? 'Max level' : 'Level ${b.level + 1}',
                  sub: maxLvl ? null : '${money(game.levelCost(b))} · demand and capacity',
                  enabled: !maxLvl && game.cash >= game.levelCost(b),
                  onTap: () => game.levelUp(b),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ActionButton(
                  label: maxQ ? 'Max quality' : 'Quality ${b.quality + 1}',
                  sub: maxQ ? null : '${money(game.qualityCost(b))} · price and reputation',
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
                  label: maxM ? 'Max marketing' : 'Marketing ${b.marketing + 1}',
                  sub: maxM ? null : '${money(game.marketingCost(b))} · +15% demand',
                  enabled: !maxM && game.cash >= game.marketingCost(b),
                  onTap: () => game.upgradeMarketing(b),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ActionButton(
                  label: b.manager ? 'Manager hired' : 'Manager',
                  sub: b.manager ? null : '${money(game.managerCost(b))} · auto-pricing, +10% capacity',
                  enabled: !b.manager && game.cash >= game.managerCost(b),
                  color: kGreen,
                  onTap: () => game.hireManager(b),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Quality ${b.quality}/${GameState.maxQuality} · Marketing ${b.marketing}/${GameState.maxMarketing}',
            style: const TextStyle(color: kGrey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
