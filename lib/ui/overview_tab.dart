import 'package:flutter/cupertino.dart';

import '../format.dart';
import '../game.dart';
import 'common.dart';

class OverviewTab extends StatelessWidget {
  final GameState game;
  const OverviewTab({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: kBg,
      navigationBar: const CupertinoNavigationBar(middle: Text('📊 Overview'), backgroundColor: kBg),
      child: SafeArea(
        child: ListenableBuilder(
          listenable: game,
          builder: (context, _) {
            final children = <Widget>[];
            final toast = game.toast;
            if (toast != null) {
              children.add(Panel(color: const Color(0xFF2C3E73), child: Text(toast)));
            }
            children.add(_header());
            children.add(_chart());
            children.add(_market());
            if (game.events.isNotEmpty) {
              children.add(SectionTitle('Inbox (${game.events.length})'));
              for (final e in game.events) {
                children.add(_eventCard(e));
              }
            }
            children.add(const SectionTitle('Goals'));
            final active = game.activeMissions;
            if (active.isEmpty) {
              children.add(const Panel(child: Text('All goals complete. You are a legend! 🏆')));
            }
            for (final m in active) {
              children.add(_missionCard(m));
            }
            return ListView(padding: const EdgeInsets.only(top: 8, bottom: 24), children: children);
          },
        ),
      ),
    );
  }

  Widget _stat(String label, String value, Color? color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: kGrey, fontSize: 12)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  Widget _header() {
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Capital', style: TextStyle(color: kGrey, fontSize: 13)),
          Text(money(game.netWorth), style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Row(
            children: [
              _stat('Cash', money(game.cash), game.cash < 0 ? kRed : null),
              _stat('Debt', money(game.debt), game.debt > 0 ? kAccent : null),
              _stat('Profit', rate(game.profitRate), game.profitRate >= 0 ? kGreen : kRed),
            ],
          ),
          const SizedBox(height: 12),
          CupertinoSlidingSegmentedControl<int>(
            groupValue: game.speed,
            children: const {
              1: Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Text('Speed ×1')),
              2: Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Text('×2')),
              5: Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Text('×5')),
            },
            onValueChanged: (v) {
              if (v != null) game.setSpeed(v);
            },
          ),
          if (game.cash < 0)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                '⚠️ You are in the red! Bankruptcy at ${money(-game.bankruptcyLine)}. Cut costs or raise prices.',
                style: const TextStyle(color: kRed, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  Widget _chart() {
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Profit trend', style: TextStyle(color: kGrey, fontSize: 13)),
          const SizedBox(height: 8),
          if (game.history.length < 2)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('The chart appears once your business has been running.', style: TextStyle(color: kGrey)),
            )
          else
            Sparkline(values: game.history),
        ],
      ),
    );
  }

  Widget _market() {
    final phaseColor = game.phase == 1 ? kGreen : (game.phase == 2 ? kRed : kBlue);
    final supplyColor = game.supplyIdx > 1.15 ? kRed : (game.supplyIdx < 0.9 ? kGreen : kBlue);
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Pill(game.phaseLabel, color: phaseColor),
              const SizedBox(width: 8),
              Pill('Supplies ×${game.supplyIdx.toStringAsFixed(2)}', color: supplyColor),
            ],
          ),
          const SizedBox(height: 10),
          Text(game.headline, style: const TextStyle(fontSize: 14)),
          if (game.effects.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Active effects: ${game.effects.length}', style: const TextStyle(color: kGrey, fontSize: 12)),
          ],
        ],
      ),
    );
  }

  Widget _eventCard(GameEvent e) {
    final hasB = e.optB != null;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${e.emoji}  ${e.title}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(e.body, style: const TextStyle(fontSize: 14, color: Color(0xFFD0D0D5))),
          const SizedBox(height: 10),
          BarMeter(value: e.left / 120, color: kAccent, height: 4),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ActionButton(label: e.optA, color: kBlue, onTap: () => game.resolveEvent(e, 0)),
              ),
              if (hasB) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: ActionButton(label: e.optB!, color: kPanel2, onTap: () => game.resolveEvent(e, 1)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _missionCard(Mission m) {
    final done = game.missionDone(m);
    return Panel(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('Reward ${money(m.reward)}', style: const TextStyle(color: kGrey, fontSize: 13)),
              ],
            ),
          ),
          if (done)
            SizedBox(
              width: 110,
              child: ActionButton(label: 'Claim', color: kGreen, onTap: () => game.claim(m)),
            )
          else
            const Text('🎯', style: TextStyle(fontSize: 24)),
        ],
      ),
    );
  }
}
