import 'dart:math';

import 'package:flutter/cupertino.dart';

import '../format.dart';
import '../game.dart';
import 'common.dart';

class BankTab extends StatelessWidget {
  final GameState game;
  const BankTab({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: kBg,
      navigationBar: const CupertinoNavigationBar(middle: Text('🏦 Bank'), backgroundColor: kBg),
      child: SafeArea(
        child: ListenableBuilder(
          listenable: game,
          builder: (context, _) {
            return ListView(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              children: [
                _worth(),
                _loan(),
                _ipo(context),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _worth() {
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Capital', style: TextStyle(color: kGrey, fontSize: 13)),
          const SizedBox(height: 8),
          StatLine('Cash', money(game.cash), color: game.cash < 0 ? kRed : null),
          StatLine('Businesses (60% of value)', money(game.assetValue * 0.6)),
          StatLine('Debt', '-${money(game.debt)}', color: game.debt > 0 ? kAccent : null),
          Container(height: 1, margin: const EdgeInsets.symmetric(vertical: 8), color: kPanel2),
          StatLine('Net worth', money(game.netWorth), color: kGreen),
        ],
      ),
    );
  }

  Widget _loan() {
    final avail = game.creditAvailable;
    final repayMax = min(game.debt, max(0.0, game.cash));
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Loan', style: TextStyle(color: kGrey, fontSize: 13)),
          const SizedBox(height: 8),
          StatLine('Limit', money(game.creditLimit)),
          StatLine('Available', money(avail)),
          StatLine('Rate', '0.6% per minute'),
          const SizedBox(height: 6),
          const Text(
            'A loan speeds up growth, but interest is charged continuously. Overdrafts cost even more: going too deep into the red means bankruptcy.',
            style: TextStyle(color: kGrey, fontSize: 12),
          ),
          const SizedBox(height: 12),
          const Text('Borrow', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final f in const [0.25, 0.5, 1.0]) ...[
                Expanded(
                  child: ActionButton(
                    label: money(avail * f),
                    sub: '${(f * 100).round()}%',
                    enabled: avail * f >= 1,
                    color: kBlue,
                    onTap: () => game.borrow(avail * f),
                  ),
                ),
                if (f != 1.0) const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 14),
          const Text('Repay', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final f in const [0.25, 0.5, 1.0]) ...[
                Expanded(
                  child: ActionButton(
                    label: money(repayMax * f),
                    sub: f == 1.0 ? 'max' : '${(f * 100).round()}%',
                    enabled: repayMax * f >= 1,
                    color: kGreen,
                    onTap: () => game.repay(repayMax * f),
                  ),
                ),
                if (f != 1.0) const SizedBox(width: 8),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _ipo(BuildContext context) {
    final can = game.canPrestige;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('IPO: go public', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            'Sell the company and start over. Each legacy point permanently gives you +5% revenue and +\$2,000 starting capital. '
            'Available from a net worth of ${money(GameState.prestigeNetWorth)}.',
            style: const TextStyle(color: kGrey, fontSize: 13),
          ),
          const SizedBox(height: 10),
          StatLine('Legacy points now', '${game.legacy} ⭐'),
          StatLine('You get from IPO', can ? '+${game.prestigePoints} ⭐' : '—', color: can ? kGreen : null),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ActionButton(
              label: can ? 'Go public' : 'Too early',
              enabled: can,
              color: kAccent,
              onTap: () {
                showCupertinoDialog<void>(
                  context: context,
                  builder: (ctx) => CupertinoAlertDialog(
                    title: const Text('Go public?'),
                    content: Text(
                      'Your businesses, cash and upgrades will reset. You will get +${game.prestigePoints} ⭐ legacy permanently.',
                    ),
                    actions: [
                      CupertinoDialogAction(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Cancel'),
                      ),
                      CupertinoDialogAction(
                        isDestructiveAction: true,
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          game.prestige();
                        },
                        child: const Text('Confirm'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
