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
      navigationBar: const CupertinoNavigationBar(middle: Text('🏦 Банк'), backgroundColor: kBg),
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
          const Text('Капитал', style: TextStyle(color: kGrey, fontSize: 13)),
          const SizedBox(height: 8),
          StatLine('Наличные', money(game.cash), color: game.cash < 0 ? kRed : null),
          StatLine('Бизнесы (60% стоимости)', money(game.assetValue * 0.6)),
          StatLine('Долг', '-${money(game.debt)}', color: game.debt > 0 ? kAccent : null),
          Container(height: 1, margin: const EdgeInsets.symmetric(vertical: 8), color: kPanel2),
          StatLine('Чистый капитал', money(game.netWorth), color: kGreen),
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
          const Text('Кредит', style: TextStyle(color: kGrey, fontSize: 13)),
          const SizedBox(height: 8),
          StatLine('Лимит', money(game.creditLimit)),
          StatLine('Доступно', money(avail)),
          StatLine('Ставка', '0.6% в минуту'),
          const SizedBox(height: 6),
          const Text(
            'Кредит ускоряет рост, но проценты списываются постоянно. Минус на счёте стоит ещё дороже: при глубоком минусе — банкротство.',
            style: TextStyle(color: kGrey, fontSize: 12),
          ),
          const SizedBox(height: 12),
          const Text('Взять в долг', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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
          const Text('Погасить', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final f in const [0.25, 0.5, 1.0]) ...[
                Expanded(
                  child: ActionButton(
                    label: money(repayMax * f),
                    sub: f == 1.0 ? 'всё возможное' : '${(f * 100).round()}%',
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
          const Text('IPO: выйти на биржу', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            'Продайте компанию и начните заново. За каждые очки наследия вы навсегда получаете +5% к выручке и +\$2 000 к стартовому капиталу. '
            'Доступно от капитала ${money(GameState.prestigeNetWorth)}.',
            style: const TextStyle(color: kGrey, fontSize: 13),
          ),
          const SizedBox(height: 10),
          StatLine('Очки наследия сейчас', '${game.legacy} ⭐'),
          StatLine('Получите за IPO', can ? '+${game.prestigePoints} ⭐' : '—', color: can ? kGreen : null),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ActionButton(
              label: can ? 'Провести IPO' : 'Пока рано',
              enabled: can,
              color: kAccent,
              onTap: () {
                showCupertinoDialog<void>(
                  context: context,
                  builder: (ctx) => CupertinoAlertDialog(
                    title: const Text('Провести IPO?'),
                    content: Text(
                      'Бизнесы, деньги и улучшения обнулятся. Вы получите +${game.prestigePoints} ⭐ наследия навсегда.',
                    ),
                    actions: [
                      CupertinoDialogAction(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Отмена'),
                      ),
                      CupertinoDialogAction(
                        isDestructiveAction: true,
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          game.prestige();
                        },
                        child: const Text('Провести'),
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
