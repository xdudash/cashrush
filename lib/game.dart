import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'format.dart';
import 'models.dart';

/// Результат расчёта одного бизнеса за секунду.
class Metrics {
  final double demand; // клиентов/с, которые хотят купить
  final double capacity; // клиентов/с, которых можем обслужить
  final double served;
  final double revenue;
  final double supplies;
  final double wages;
  final double rent;
  final double marketing;
  final double coverage; // доля заполненных штатных мест 0..1

  const Metrics(this.demand, this.capacity, this.served, this.revenue, this.supplies, this.wages, this.rent,
      this.marketing, this.coverage);

  double get costs => supplies + wages + rent + marketing;
  double get profit => revenue - costs;
}

/// Купленный бизнес.
class Biz {
  final BusinessDef def;
  int level;
  int staff;
  double mult; // множитель цены (1.0 = справедливая цена)
  int quality;
  int marketing;
  bool manager;
  double invested;
  double rep; // репутация 1..5
  double autoTimer = 0;
  Metrics m = const Metrics(0, 0, 0, 0, 0, 0, 0, 0, 0);

  Biz(
    this.def, {
    this.level = 1,
    this.staff = 1,
    this.mult = 1.0,
    this.quality = 0,
    this.marketing = 0,
    this.manager = false,
    this.invested = 0,
    this.rep = 3.0,
  });

  int get slots => 2 * level;

  Map<String, dynamic> toJson() => {
        'id': def.id,
        'level': level,
        'staff': staff,
        'mult': mult,
        'quality': quality,
        'marketing': marketing,
        'manager': manager,
        'invested': invested,
        'rep': rep,
      };

  static Biz? fromJson(Map<String, dynamic> j) {
    final def = defById(j['id'] as String? ?? '');
    if (def == null) return null;
    return Biz(
      def,
      level: (j['level'] as num?)?.toInt() ?? 1,
      staff: (j['staff'] as num?)?.toInt() ?? 1,
      mult: (j['mult'] as num?)?.toDouble() ?? 1.0,
      quality: (j['quality'] as num?)?.toInt() ?? 0,
      marketing: (j['marketing'] as num?)?.toInt() ?? 0,
      manager: j['manager'] as bool? ?? false,
      invested: (j['invested'] as num?)?.toDouble() ?? def.openCost,
      rep: (j['rep'] as num?)?.toDouble() ?? 3.0,
    );
  }
}

enum EffectKind { demand, supply, revenue }

/// Временный эффект (реклама блогера, контракт с поставщиком и т.д.).
class Effect {
  final EffectKind kind;
  final String? bizId; // null — действует на все бизнесы
  final double mult;
  double left;
  Effect(this.kind, this.bizId, this.mult, this.left);
}

/// Событие во «входящих»: нужно принять решение.
class GameEvent {
  final int id;
  final String type;
  final String emoji;
  final String title;
  final String body;
  final String optA;
  final String? optB;
  double left;
  final Map<String, dynamic> p;

  GameEvent({
    required this.id,
    required this.type,
    required this.emoji,
    required this.title,
    required this.body,
    required this.optA,
    this.optB,
    this.left = 120,
    this.p = const {},
  });
}

class Mission {
  final String id;
  final String title;
  final double reward;
  final bool Function(GameState g) test;
  Mission(this.id, this.title, this.reward, this.test);
}

final missions = <Mission>[
  Mission('m1', 'Открой первый бизнес', 200, (g) => g.bizList.isNotEmpty),
  Mission('m2', 'Найми 4 сотрудников', 300, (g) => g.totalStaff >= 4),
  Mission('m3', 'Подними качество до 2 уровня', 400, (g) => g.bizList.any((b) => b.quality >= 2)),
  Mission('m4', 'Выйди на прибыль \$5 в секунду', 600, (g) => g.profitRate >= 5),
  Mission('m5', 'Купи первое улучшение в «Развитии»', 1500, (g) => g.techTotal >= 1),
  Mission('m6', 'Открой 3 разных бизнеса', 2500, (g) => g.bizList.length >= 3),
  Mission('m7', 'Возьми кредит и полностью верни его', 3000, (g) => g.repaidLoan),
  Mission('m8', 'Найми менеджера', 5000, (g) => g.bizList.any((b) => b.manager)),
  Mission('m9', 'Капитал \$100 тыс.', 10000, (g) => g.netWorth >= 1e5),
  Mission('m10', 'Прибыль \$100 в секунду', 15000, (g) => g.profitRate >= 100),
  Mission('m11', 'Открой 5 бизнесов', 60000, (g) => g.bizList.length >= 5),
  Mission('m12', 'Капитал \$1 млн', 100000, (g) => g.netWorth >= 1e6),
  Mission('m13', 'Прибыль \$2 тыс. в секунду', 400000, (g) => g.profitRate >= 2000),
  Mission('m14', 'Открой все 8 бизнесов', 2000000, (g) => g.bizList.length >= businessDefs.length),
  Mission('m15', 'Капитал \$50 млн', 3000000, (g) => g.netWorth >= 5e7),
  Mission('m16', 'Проведи первое IPO', 5000000, (g) => g.prestiges >= 1),
];

class GameState extends ChangeNotifier {
  static const _saveKey = 'tycoon_save_v2';
  static const maxLevel = 10;
  static const maxQuality = 5;
  static const maxMarketing = 5;
  static const _maxOffline = Duration(hours: 8);
  static const _loanRate = 0.0001; // в секунду от долга (0.6% в минуту)
  static const prestigeNetWorth = 2e7;

  final _rng = Random();
  SharedPreferences? _prefs;

  // ---- Состояние игрока ----
  double cash = 1500;
  double debt = 0;
  double lifetimeProfit = 0;
  double playSeconds = 0;
  int legacy = 0;
  int prestiges = 0;
  int bankruptcies = 0;
  bool everBorrowed = false;
  bool repaidLoan = false;
  bool haptics = true;
  bool seenIntro = false;
  int speed = 1;
  final List<Biz> bizList = [];
  final Map<String, int> tech = {};
  final Set<String> claimed = {};

  // ---- Рынок ----
  int phase = 0; // 0 стабильно, 1 бум, 2 спад
  double phaseLeft = 150;
  double supplyIdx = 1.0;
  double _supplyTimer = 0;
  String headline = 'Рынок спокоен. Самое время открывать бизнес.';
  final List<Effect> effects = [];

  // ---- События ----
  final List<GameEvent> events = [];
  double _eventTimer = 60;
  int _eventId = 1;

  // ---- Служебное ----
  final List<double> history = [];
  double _histTimer = 0;
  double profitRate = 0;
  String? toast;
  Timer? _toastTimer;
  double offlineEarned = 0;
  bool bankruptFlag = false;
  Timer? _ticker;
  int _tickCount = 0;
  DateTime? _pausedAt;

  // ---------- Производные значения ----------

  int techLevel(String id) => tech[id] ?? 0;
  int get techTotal => tech.values.fold(0, (a, b) => a + b);
  int get totalStaff => bizList.fold(0, (a, b) => a + b.staff);
  double get assetValue => bizList.fold(0.0, (a, b) => a + b.invested);
  double get netWorth => cash + assetValue * 0.6 - debt;

  double get econFactor => phase == 1 ? 1.2 : (phase == 2 ? 0.75 : 1.0);
  String get phaseLabel => phase == 1 ? 'Бум 📈' : (phase == 2 ? 'Спад 📉' : 'Стабильно ➖');

  double get creditLimit => max(1000.0, netWorth * 0.5) * (1 + 0.3 * techLevel('credit'));
  double get creditAvailable => max(0.0, creditLimit - debt);
  double get bankruptcyLine => 500 + 0.25 * assetValue;

  bool get canPrestige => netWorth >= prestigeNetWorth;
  int get prestigePoints => sqrt(max(0.0, netWorth) / 1e6).floor();

  Biz? bizOf(String id) {
    for (final b in bizList) {
      if (b.def.id == id) return b;
    }
    return null;
  }

  double tempMult(EffectKind kind, String? bizId) {
    var m = 1.0;
    for (final e in effects) {
      if (e.kind == kind && (e.bizId == null || e.bizId == bizId)) m *= e.mult;
    }
    return m;
  }

  List<Mission> get activeMissions {
    final res = <Mission>[];
    for (final m in missions) {
      if (!claimed.contains(m.id)) res.add(m);
      if (res.length >= 3) break;
    }
    return res;
  }

  // ---------- Экономика бизнеса ----------

  /// Цель репутации зависит от качества, цены и укомплектованности.
  double repTarget(Biz b, double mult, {bool overloaded = false}) {
    final coverage = b.staff / b.slots;
    var t = 3.0 + 0.45 * b.quality + 0.2 * techLevel('brand');
    final rel = mult / (1 + 0.10 * b.quality);
    t -= rel > 1 ? (rel - 1) * 2.0 : (rel - 1) * 0.8;
    if (coverage < 0.5) t -= 0.7;
    if (overloaded) t -= 0.6;
    return t.clamp(1.0, 5.0).toDouble();
  }

  Metrics evaluate(Biz b, double mult, {double? rep}) {
    final d = b.def;
    final scale = 1 + 0.75 * (b.level - 1);
    final coverage = b.staff / b.slots;
    final relPrice = mult / (1 + 0.10 * b.quality);
    final priceF = pow(relPrice, -d.elasticity).toDouble();
    final mktF = 1 + 0.15 * b.marketing;
    final repF = 0.55 + 0.15 * (rep ?? b.rep);
    final techDemand = 1 + 0.06 * techLevel('loyalty');
    final demand = d.demand *
        scale *
        priceF *
        mktF *
        repF *
        econFactor *
        techDemand *
        tempMult(EffectKind.demand, d.id);
    var capacity = d.demand * 1.35 * scale * (0.2 + 0.8 * coverage) * (1 + 0.07 * techLevel('logistics'));
    if (b.manager) capacity *= 1.1;
    final served = min(demand, capacity);
    final legacyF = 1 + 0.05 * legacy;
    final revenue = served * d.price * mult * legacyF * tempMult(EffectKind.revenue, null);
    final unit = d.price *
        d.costRatio *
        (1 + 0.08 * b.quality) *
        supplyIdx *
        (1 - 0.05 * techLevel('wholesale')) *
        tempMult(EffectKind.supply, null);
    return Metrics(
      demand,
      capacity,
      served,
      revenue,
      served * unit,
      b.staff * d.wage * (1 - 0.05 * techLevel('automation')),
      d.rent * b.level,
      b.marketing * d.marketingCost,
      coverage,
    );
  }

  /// Прогноз прибыли при установившейся репутации.
  double forecastProfit(Biz b, double mult) => evaluate(b, mult, rep: repTarget(b, mult)).profit;

  double bestMult(Biz b) {
    var best = b.mult;
    var bestProfit = -1e300;
    for (var i = 12; i <= 40; i++) {
      final m = i * 0.05;
      final p = forecastProfit(b, m);
      if (p > bestProfit) {
        bestProfit = p;
        best = m;
      }
    }
    return best;
  }

  // ---------- Цикл ----------

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _load();
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      step(0.25 * speed);
      _tickCount++;
      if (_tickCount % 40 == 0) save();
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _toastTimer?.cancel();
    super.dispose();
  }

  void onPaused() {
    _pausedAt = DateTime.now();
    save();
  }

  void onResumed() {
    final p = _pausedAt;
    _pausedAt = null;
    if (p == null) return;
    _applyOffline(DateTime.now().difference(p));
    notifyListeners();
  }

  void clearOffline() => offlineEarned = 0;

  void _applyOffline(Duration elapsed) {
    if (elapsed.inSeconds < 60 || bizList.isEmpty) return;
    final capped = elapsed > _maxOffline ? _maxOffline : elapsed;
    // Офлайн приносит 50% от последней прибыли; убыток офлайн не списываем.
    final earned = max(0.0, profitRate) * 0.5 * capped.inSeconds;
    if (earned <= 0) return;
    cash += earned;
    lifetimeProfit += earned;
    offlineEarned += earned;
  }

  void step(double dt) {
    playSeconds += dt;
    _economyStep(dt);

    for (final e in effects) {
      e.left -= dt;
    }
    effects.removeWhere((e) => e.left <= 0);

    var totalProfit = 0.0;
    for (final b in bizList) {
      if (b.manager) {
        b.autoTimer += dt;
        if (b.autoTimer >= 8) {
          b.autoTimer = 0;
          b.mult = bestMult(b);
        }
      }
      final m = evaluate(b, b.mult);
      b.m = m;
      totalProfit += m.profit;
      final overloaded = m.demand > m.capacity * 1.5;
      b.rep += (repTarget(b, b.mult, overloaded: overloaded) - b.rep) * min(1.0, 0.02 * dt);
    }

    final interest = debt * _loanRate;
    var overdraft = 0.0;
    if (cash < 0) overdraft = -cash * 0.0003;
    final net = totalProfit - interest - overdraft;
    cash += net * dt;
    if (totalProfit > 0) lifetimeProfit += totalProfit * dt;
    profitRate += (net - profitRate) * min(1.0, 0.2 * dt);

    _histTimer += dt;
    if (_histTimer >= 2) {
      _histTimer = 0;
      history.add(net);
      if (history.length > 90) history.removeAt(0);
    }

    _eventTimer -= dt;
    if (_eventTimer <= 0) {
      _eventTimer = 70 + _rng.nextDouble() * 70;
      _spawnEvent();
    }
    for (final e in List<GameEvent>.from(events)) {
      e.left -= dt;
      if (e.left <= 0) resolveEvent(e, e.optB == null ? 0 : 1, auto: true);
    }

    if (bizList.isNotEmpty && cash < -bankruptcyLine) _bankrupt();
  }

  void _economyStep(double dt) {
    phaseLeft -= dt;
    if (phaseLeft <= 0) {
      final r = _rng.nextDouble();
      if (phase == 0) {
        phase = r < 0.5 ? 1 : 2;
      } else {
        phase = r < 0.8 ? 0 : (phase == 1 ? 2 : 1);
      }
      phaseLeft = 120 + _rng.nextDouble() * 180;
      const boom = [
        'Экономика на подъёме: люди тратят больше!',
        'Бум потребления — спрос вырос на 20%.',
      ];
      const bust = [
        'Кризис: покупатели экономят, спрос упал.',
        'Рецессия. Держитесь за качество и не раздувайте расходы.',
      ];
      const calm = [
        'Рынок успокоился. Спрос вернулся в норму.',
        'Стабильный период — время для инвестиций.',
      ];
      final list = phase == 1 ? boom : (phase == 2 ? bust : calm);
      headline = list[_rng.nextInt(list.length)];
    }
    _supplyTimer += dt;
    if (_supplyTimer >= 5) {
      _supplyTimer = 0;
      supplyIdx += (1 - supplyIdx) * 0.06 + (_rng.nextDouble() - 0.5) * 0.08;
      supplyIdx = supplyIdx.clamp(0.75, 1.6).toDouble();
    }
  }

  void _bankrupt() {
    bankruptcies++;
    bankruptFlag = true;
    cash = 1500;
    debt = 0;
    bizList.clear();
    effects.clear();
    events.clear();
    profitRate = 0;
    history.clear();
    save();
  }

  // ---------- Действия игрока ----------

  void buzz() {
    if (haptics) HapticFeedback.selectionClick();
  }

  void showToast(String t) {
    toast = t;
    _toastTimer?.cancel();
    _toastTimer = Timer(const Duration(seconds: 5), () {
      toast = null;
      notifyListeners();
    });
    notifyListeners();
  }

  void setSpeed(int v) {
    speed = v;
    notifyListeners();
  }

  void setHaptics(bool v) {
    haptics = v;
    save();
    notifyListeners();
  }

  bool _spend(double c) {
    if (cash < c) return false;
    cash -= c;
    return true;
  }

  void _done() {
    buzz();
    notifyListeners();
  }

  bool canOpen(BusinessDef d) => bizOf(d.id) == null && cash >= d.openCost && netWorth >= d.unlockNetWorth;

  bool openBusiness(BusinessDef d) {
    if (!canOpen(d)) return false;
    cash -= d.openCost;
    bizList.add(Biz(d, invested: d.openCost));
    _done();
    return true;
  }

  double levelCost(Biz b) => b.def.openCost * 0.9 * pow(1.9, b.level - 1).toDouble();
  double qualityCost(Biz b) => b.def.openCost * 0.6 * pow(1.9, b.quality).toDouble();
  double marketingCost(Biz b) => b.def.openCost * 0.3 * pow(1.7, b.marketing).toDouble();
  double managerCost(Biz b) => b.def.openCost * 2;
  double hireCost(Biz b) => b.def.wage * 60;

  bool levelUp(Biz b) {
    if (b.level >= maxLevel) return false;
    final c = levelCost(b);
    if (!_spend(c)) return false;
    b.level++;
    b.invested += c;
    _done();
    return true;
  }

  bool upgradeQuality(Biz b) {
    if (b.quality >= maxQuality) return false;
    if (!_spend(qualityCost(b))) return false;
    b.quality++;
    _done();
    return true;
  }

  bool upgradeMarketing(Biz b) {
    if (b.marketing >= maxMarketing) return false;
    if (!_spend(marketingCost(b))) return false;
    b.marketing++;
    _done();
    return true;
  }

  bool hireManager(Biz b) {
    if (b.manager) return false;
    final c = managerCost(b);
    if (!_spend(c)) return false;
    b.manager = true;
    b.invested += c;
    b.mult = bestMult(b);
    _done();
    return true;
  }

  bool hire(Biz b) {
    if (b.staff >= b.slots) return false;
    if (!_spend(hireCost(b))) return false;
    b.staff++;
    _done();
    return true;
  }

  bool fire(Biz b) {
    if (b.staff <= 0) return false;
    b.staff--;
    _done();
    return true;
  }

  void setMult(Biz b, double v) {
    b.mult = v.clamp(0.6, 2.0).toDouble();
    notifyListeners();
  }

  double techCost(TechDef t) => t.baseCost * pow(t.growth, techLevel(t.id)).toDouble();

  bool buyTech(TechDef t) {
    if (techLevel(t.id) >= t.maxLevel) return false;
    if (!_spend(techCost(t))) return false;
    tech[t.id] = techLevel(t.id) + 1;
    _done();
    return true;
  }

  bool borrow(double amount) {
    final a = min(amount, creditAvailable);
    if (a <= 0) return false;
    debt += a;
    cash += a;
    everBorrowed = true;
    _done();
    return true;
  }

  bool repay(double amount) {
    final a = min(min(amount, debt), max(0.0, cash));
    if (a <= 0) return false;
    debt -= a;
    cash -= a;
    if (debt < 0.01) {
      debt = 0;
      if (everBorrowed) repaidLoan = true;
    }
    _done();
    return true;
  }

  bool missionDone(Mission m) => m.test(this);

  bool claim(Mission m) {
    if (claimed.contains(m.id) || !m.test(this)) return false;
    claimed.add(m.id);
    cash += m.reward;
    showToast('🎯 Цель выполнена: +${money(m.reward)}');
    buzz();
    return true;
  }

  bool prestige() {
    if (!canPrestige) return false;
    legacy += prestigePoints;
    prestiges++;
    cash = 1500 + 2000.0 * legacy;
    debt = 0;
    bizList.clear();
    tech.clear();
    effects.clear();
    events.clear();
    profitRate = 0;
    history.clear();
    save();
    notifyListeners();
    return true;
  }

  Future<void> resetAll() async {
    cash = 1500;
    debt = 0;
    lifetimeProfit = 0;
    playSeconds = 0;
    legacy = 0;
    prestiges = 0;
    bankruptcies = 0;
    everBorrowed = false;
    repaidLoan = false;
    bizList.clear();
    tech.clear();
    claimed.clear();
    effects.clear();
    events.clear();
    history.clear();
    profitRate = 0;
    phase = 0;
    supplyIdx = 1.0;
    offlineEarned = 0;
    seenIntro = false;
    await _prefs?.remove(_saveKey);
    notifyListeners();
  }

  // ---------- События ----------

  void _spawnEvent() {
    if (bizList.isEmpty || events.length >= 3) return;
    final rate = max(profitRate, 2.0);
    final b = bizList[_rng.nextInt(bizList.length)];
    final name = b.def.name;
    final base = max(150.0, rate * 45).roundToDouble();
    GameEvent e;
    switch (_rng.nextInt(7)) {
      case 0:
        e = GameEvent(
          id: _eventId++,
          type: 'inspection',
          emoji: '🕵️',
          title: 'Проверка: $name',
          body: 'Инспектор нашёл мелкие нарушения. Уладить сейчас за ${money(base)} или рискнуть: штраф может быть втрое больше.',
          optA: 'Уладить ${money(base)}',
          optB: 'Рискнуть',
          p: {'cost': base, 'biz': b.def.id},
        );
        break;
      case 1:
        e = GameEvent(
          id: _eventId++,
          type: 'blogger',
          emoji: '🎥',
          title: 'Блогер предлагает рекламу',
          body: 'Известный блогер снимет обзор на «$name». Спрос вырастет на 50% на 2,5 минуты.',
          optA: 'Заказать ${money(base)}',
          optB: 'Отказаться',
          p: {'cost': base, 'biz': b.def.id},
        );
        break;
      case 2:
        final supplierCost = (base * 1.5).roundToDouble();
        e = GameEvent(
          id: _eventId++,
          type: 'supplier',
          emoji: '📦',
          title: 'Выгодный контракт',
          body: 'Поставщик предлагает фиксированные цены: себестоимость −30% на 4 минуты во всех бизнесах.',
          optA: 'Подписать ${money(supplierCost)}',
          optB: 'Отказаться',
          p: {'cost': supplierCost},
        );
        break;
      case 3:
        e = GameEvent(
          id: _eventId++,
          type: 'competitor',
          emoji: '⚔️',
          title: 'Конкурент рядом с «$name»',
          body: 'Напротив открылся конкурент. Акция удержит клиентов, иначе спрос просядет на 20% на 3 минуты.',
          optA: 'Акция ${money(base)}',
          optB: 'Принять удар',
          p: {'cost': base, 'biz': b.def.id},
        );
        break;
      case 4:
        final raiseCost = max(100.0, b.def.wage * max(1, b.staff) * 90).roundToDouble();
        e = GameEvent(
          id: _eventId++,
          type: 'raise',
          emoji: '🙋',
          title: 'Сотрудники просят премию',
          body: 'Команда «$name» хочет премию. Выплатите — вырастет репутация. Откажете — кто-то может уволиться.',
          optA: 'Выплатить ${money(raiseCost)}',
          optB: 'Отказать',
          p: {'cost': raiseCost, 'biz': b.def.id},
        );
        break;
      case 5:
        final investorOffer = max(2000.0, netWorth * 0.08).roundToDouble();
        e = GameEvent(
          id: _eventId++,
          type: 'investor',
          emoji: '🤝',
          title: 'Предложение инвестора',
          body: 'Инвестор даёт ${money(investorOffer)} сразу, но заберёт 10% выручки на 6 минут.',
          optA: 'Взять ${money(investorOffer)}',
          optB: 'Отказаться',
          p: {'offer': investorOffer},
        );
        break;
      default:
        e = GameEvent(
          id: _eventId++,
          type: 'viral',
          emoji: '📱',
          title: 'Вирусный пост!',
          body: 'О «$name» написали в соцсетях. Спрос +60% на 2 минуты — бесплатно!',
          optA: 'Отлично!',
          p: {'biz': b.def.id},
        );
    }
    events.add(e);
    buzz();
  }

  void resolveEvent(GameEvent e, int choice, {bool auto = false}) {
    if (!events.contains(e)) return;
    final cost = (e.p['cost'] as double?) ?? 0.0;
    final b = bizOf((e.p['biz'] as String?) ?? '');
    const payTypes = ['inspection', 'blogger', 'supplier', 'competitor', 'raise'];
    var pick = choice;
    if (pick == 0 && payTypes.contains(e.type) && cash < cost) {
      if (!auto) {
        showToast('Не хватает денег: нужно ${money(cost)}');
        return;
      }
      pick = e.optB == null ? 0 : 1;
    }
    events.remove(e);

    switch (e.type) {
      case 'inspection':
        if (pick == 0) {
          cash -= cost;
          showToast('Проверка пройдена, штрафа нет.');
        } else if (_rng.nextDouble() < 0.5) {
          final fine = cost * 3;
          cash -= fine;
          if (b != null) b.rep = max(1.0, b.rep - 0.3);
          showToast('🚨 Штраф ${money(fine)}! Репутация пострадала.');
        } else {
          showToast('Повезло: проверка обошлась без штрафа.');
        }
        break;
      case 'blogger':
        if (pick == 0 && b != null) {
          cash -= cost;
          effects.add(Effect(EffectKind.demand, b.def.id, 1.5, 150));
          showToast('Реклама запущена: спрос растёт!');
        }
        break;
      case 'supplier':
        if (pick == 0) {
          cash -= cost;
          effects.add(Effect(EffectKind.supply, null, 0.7, 240));
          showToast('Контракт подписан: сырьё дешевле.');
        }
        break;
      case 'competitor':
        if (pick == 0) {
          cash -= cost;
          showToast('Акция удержала клиентов.');
        } else if (b != null) {
          effects.add(Effect(EffectKind.demand, b.def.id, 0.8, 180));
          showToast('Часть клиентов ушла к конкуренту.');
        }
        break;
      case 'raise':
        if (pick == 0) {
          cash -= cost;
          if (b != null) b.rep = min(5.0, b.rep + 0.3);
          showToast('Команда довольна. Репутация выросла.');
        } else if (b != null && b.staff > 1 && _rng.nextDouble() < 0.5) {
          b.staff--;
          showToast('Один сотрудник уволился.');
        } else {
          showToast('Все остались, но настроение так себе.');
        }
        break;
      case 'investor':
        if (pick == 0) {
          final offer = (e.p['offer'] as double?) ?? 0.0;
          cash += offer;
          effects.add(Effect(EffectKind.revenue, null, 0.9, 360));
          showToast('Инвестор вложил ${money(offer)}.');
        }
        break;
      case 'viral':
        if (b != null) {
          effects.add(Effect(EffectKind.demand, b.def.id, 1.6, 120));
          showToast('Спрос на «${b.def.name}» взлетел!');
        }
        break;
    }
    buzz();
    notifyListeners();
  }

  // ---------- Сохранение ----------

  Future<void> save() async {
    final data = <String, dynamic>{
      'cash': cash,
      'debt': debt,
      'lifetimeProfit': lifetimeProfit,
      'playSeconds': playSeconds,
      'legacy': legacy,
      'prestiges': prestiges,
      'bankruptcies': bankruptcies,
      'everBorrowed': everBorrowed,
      'repaidLoan': repaidLoan,
      'haptics': haptics,
      'seenIntro': seenIntro,
      'speed': speed,
      'biz': bizList.map((b) => b.toJson()).toList(),
      'tech': tech,
      'claimed': claimed.toList(),
      'phase': phase,
      'phaseLeft': phaseLeft,
      'supplyIdx': supplyIdx,
      'profitRate': profitRate,
      'lastSeen': DateTime.now().millisecondsSinceEpoch,
    };
    await _prefs?.setString(_saveKey, jsonEncode(data));
  }

  void _load() {
    final raw = _prefs?.getString(_saveKey);
    if (raw == null) return;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      cash = (m['cash'] as num?)?.toDouble() ?? 1500;
      debt = (m['debt'] as num?)?.toDouble() ?? 0;
      lifetimeProfit = (m['lifetimeProfit'] as num?)?.toDouble() ?? 0;
      playSeconds = (m['playSeconds'] as num?)?.toDouble() ?? 0;
      legacy = (m['legacy'] as num?)?.toInt() ?? 0;
      prestiges = (m['prestiges'] as num?)?.toInt() ?? 0;
      bankruptcies = (m['bankruptcies'] as num?)?.toInt() ?? 0;
      everBorrowed = m['everBorrowed'] as bool? ?? false;
      repaidLoan = m['repaidLoan'] as bool? ?? false;
      haptics = m['haptics'] as bool? ?? true;
      seenIntro = m['seenIntro'] as bool? ?? false;
      speed = (m['speed'] as num?)?.toInt() ?? 1;
      phase = (m['phase'] as num?)?.toInt() ?? 0;
      phaseLeft = (m['phaseLeft'] as num?)?.toDouble() ?? 150;
      supplyIdx = (m['supplyIdx'] as num?)?.toDouble() ?? 1.0;
      profitRate = (m['profitRate'] as num?)?.toDouble() ?? 0;

      bizList.clear();
      for (final j in (m['biz'] as List<dynamic>? ?? [])) {
        final b = Biz.fromJson(j as Map<String, dynamic>);
        if (b != null) bizList.add(b);
      }
      tech.clear();
      final t = m['tech'] as Map<String, dynamic>? ?? {};
      t.forEach((k, v) => tech[k] = (v as num).toInt());
      claimed
        ..clear()
        ..addAll((m['claimed'] as List<dynamic>? ?? []).map((e) => e as String));

      final last = m['lastSeen'] as int?;
      if (last != null) {
        _applyOffline(DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(last)));
      }
    } catch (_) {
      // Повреждённое сохранение — начинаем заново.
    }
  }
}
