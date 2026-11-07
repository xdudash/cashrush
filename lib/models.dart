/// Тип бизнеса. Каждый тип можно открыть один раз, дальше его растят уровнями.
class BusinessDef {
  final String id;
  final String name;
  final String emoji;
  final String desc;
  final double openCost; // цена открытия
  final double unlockNetWorth; // нужный капитал для открытия
  final double price; // «справедливая» цена за клиента
  final double costRatio; // себестоимость клиента как доля цены
  final double demand; // базовый спрос, клиентов в секунду (ур. 1)
  final double wage; // зарплата одного сотрудника, $/с
  final double rent; // аренда за уровень, $/с
  final double marketingCost; // стоимость одного уровня рекламы, $/с
  final double elasticity; // насколько спрос чувствителен к цене

  const BusinessDef({
    required this.id,
    required this.name,
    required this.emoji,
    required this.desc,
    required this.openCost,
    required this.unlockNetWorth,
    required this.price,
    required this.costRatio,
    required this.demand,
    required this.wage,
    required this.rent,
    required this.marketingCost,
    required this.elasticity,
  });
}

const businessDefs = <BusinessDef>[
  BusinessDef(
    id: 'coffee', name: 'Кофейня', emoji: '☕',
    desc: 'Точка у метро. Дешёвый старт, быстрая окупаемость.',
    openCost: 300, unlockNetWorth: 0,
    price: 4, costRatio: 0.30, demand: 0.9,
    wage: 0.12, rent: 0.10, marketingCost: 0.05, elasticity: 1.6,
  ),
  BusinessDef(
    id: 'bakery', name: 'Пекарня', emoji: '🥐',
    desc: 'Свежая выпечка и постоянные клиенты по утрам.',
    openCost: 3000, unlockNetWorth: 2500,
    price: 10, costRatio: 0.35, demand: 2.0,
    wage: 0.4, rent: 0.8, marketingCost: 0.35, elasticity: 1.5,
  ),
  BusinessDef(
    id: 'burger', name: 'Бургерная', emoji: '🍔',
    desc: 'Большой поток, но дорогое сырьё и много персонала.',
    openCost: 20000, unlockNetWorth: 15000,
    price: 16, costRatio: 0.40, demand: 6.5,
    wage: 1.2, rent: 3, marketingCost: 1.8, elasticity: 1.5,
  ),
  BusinessDef(
    id: 'gym', name: 'Фитнес-клуб', emoji: '🏋️',
    desc: 'Почти нет сырья, зато высокая аренда и зарплаты.',
    openCost: 120000, unlockNetWorth: 90000,
    price: 40, costRatio: 0.15, demand: 11,
    wage: 5, rent: 25, marketingCost: 10, elasticity: 1.4,
  ),
  BusinessDef(
    id: 'shop', name: 'Интернет-магазин', emoji: '📦',
    desc: 'Огромный спрос, тонкая маржа. Любит оптовые закупки.',
    openCost: 800000, unlockNetWorth: 600000,
    price: 60, costRatio: 0.50, demand: 70,
    wage: 20, rent: 60, marketingCost: 60, elasticity: 1.6,
  ),
  BusinessDef(
    id: 'hotel', name: 'Отель', emoji: '🏨',
    desc: 'Дорогой, но очень доходный. Клиенты ценят качество.',
    openCost: 5000000, unlockNetWorth: 4000000,
    price: 250, costRatio: 0.25, demand: 62,
    wage: 40, rent: 400, marketingCost: 330, elasticity: 1.3,
  ),
  BusinessDef(
    id: 'it', name: 'IT-студия', emoji: '💻',
    desc: 'Мало заказов, но каждый стоит десятки тысяч.',
    openCost: 40000000, unlockNetWorth: 30000000,
    price: 20000, costRatio: 0.10, demand: 4.5,
    wage: 300, rent: 300, marketingCost: 2400, elasticity: 1.2,
  ),
  BusinessDef(
    id: 'space', name: 'Космотуризм', emoji: '🚀',
    desc: 'Вершина империи. Билет на орбиту — не для всех.',
    openCost: 500000000, unlockNetWorth: 400000000,
    price: 250000, costRatio: 0.20, demand: 4.2,
    wage: 3000, rent: 4000, marketingCost: 25000, elasticity: 1.3,
  ),
];

BusinessDef? defById(String id) {
  for (final d in businessDefs) {
    if (d.id == id) return d;
  }
  return null;
}

/// Глобальное улучшение («Развитие»).
class TechDef {
  final String id;
  final String name;
  final String emoji;
  final String desc;
  final double baseCost;
  final double growth;
  final int maxLevel;
  final String Function(int level) effect;

  TechDef({
    required this.id,
    required this.name,
    required this.emoji,
    required this.desc,
    required this.baseCost,
    required this.growth,
    required this.maxLevel,
    required this.effect,
  });
}

final techDefs = <TechDef>[
  TechDef(
    id: 'wholesale', name: 'Оптовые закупки', emoji: '🛒',
    desc: 'Договоры с поставщиками снижают себестоимость.',
    baseCost: 800, growth: 3.2, maxLevel: 8,
    effect: (l) => 'Себестоимость −${l * 5}%',
  ),
  TechDef(
    id: 'loyalty', name: 'Программа лояльности', emoji: '💌',
    desc: 'Клиенты возвращаются чаще, спрос растёт.',
    baseCost: 1500, growth: 3.2, maxLevel: 8,
    effect: (l) => 'Спрос +${l * 6}%',
  ),
  TechDef(
    id: 'automation', name: 'Автоматизация', emoji: '🤖',
    desc: 'Меньше ручной работы — ниже зарплатный фонд.',
    baseCost: 1200, growth: 3.2, maxLevel: 8,
    effect: (l) => 'Зарплаты −${l * 5}%',
  ),
  TechDef(
    id: 'logistics', name: 'Логистика', emoji: '🚚',
    desc: 'Быстрее обслуживаем клиентов — выше мощность.',
    baseCost: 2000, growth: 3.2, maxLevel: 8,
    effect: (l) => 'Мощность +${l * 7}%',
  ),
  TechDef(
    id: 'brand', name: 'Бренд', emoji: '🏷️',
    desc: 'Узнаваемая марка повышает репутацию всех бизнесов.',
    baseCost: 3000, growth: 3.6, maxLevel: 5,
    effect: (l) => 'Репутация +${(l * 0.2).toStringAsFixed(1)}★',
  ),
  TechDef(
    id: 'credit', name: 'Кредитный рейтинг', emoji: '💳',
    desc: 'Банк доверяет больше и даёт крупнее кредиты.',
    baseCost: 2500, growth: 3.4, maxLevel: 6,
    effect: (l) => 'Кредитный лимит +${l * 30}%',
  ),
];

TechDef? techById(String id) {
  for (final t in techDefs) {
    if (t.id == id) return t;
  }
  return null;
}
