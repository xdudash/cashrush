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
    id: 'coffee', name: 'Coffee Shop', emoji: '☕',
    desc: 'A spot by the subway. Cheap start, fast payback.',
    openCost: 300, unlockNetWorth: 0,
    price: 4, costRatio: 0.30, demand: 0.9,
    wage: 0.12, rent: 0.10, marketingCost: 0.05, elasticity: 1.6,
  ),
  BusinessDef(
    id: 'bakery', name: 'Bakery', emoji: '🥐',
    desc: 'Fresh pastries and regular customers every morning.',
    openCost: 3000, unlockNetWorth: 2500,
    price: 10, costRatio: 0.35, demand: 2.0,
    wage: 0.4, rent: 0.8, marketingCost: 0.35, elasticity: 1.5,
  ),
  BusinessDef(
    id: 'burger', name: 'Burger Joint', emoji: '🍔',
    desc: 'Big crowds, but pricey ingredients and lots of staff.',
    openCost: 20000, unlockNetWorth: 15000,
    price: 16, costRatio: 0.40, demand: 6.5,
    wage: 1.2, rent: 3, marketingCost: 1.8, elasticity: 1.5,
  ),
  BusinessDef(
    id: 'gym', name: 'Fitness Club', emoji: '🏋️',
    desc: 'Hardly any supplies, but high rent and wages.',
    openCost: 120000, unlockNetWorth: 90000,
    price: 40, costRatio: 0.15, demand: 11,
    wage: 5, rent: 25, marketingCost: 10, elasticity: 1.4,
  ),
  BusinessDef(
    id: 'shop', name: 'Online Store', emoji: '📦',
    desc: 'Huge demand, thin margins. Loves wholesale buying.',
    openCost: 800000, unlockNetWorth: 600000,
    price: 60, costRatio: 0.50, demand: 70,
    wage: 20, rent: 60, marketingCost: 60, elasticity: 1.6,
  ),
  BusinessDef(
    id: 'hotel', name: 'Hotel', emoji: '🏨',
    desc: 'Expensive but very profitable. Guests value quality.',
    openCost: 5000000, unlockNetWorth: 4000000,
    price: 250, costRatio: 0.25, demand: 62,
    wage: 40, rent: 400, marketingCost: 330, elasticity: 1.3,
  ),
  BusinessDef(
    id: 'it', name: 'IT Studio', emoji: '💻',
    desc: 'Few orders, but each is worth tens of thousands.',
    openCost: 40000000, unlockNetWorth: 30000000,
    price: 20000, costRatio: 0.10, demand: 4.5,
    wage: 300, rent: 300, marketingCost: 2400, elasticity: 1.2,
  ),
  BusinessDef(
    id: 'space', name: 'Space Tourism', emoji: '🚀',
    desc: 'The peak of your empire. A ticket to orbit is not for everyone.',
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
    id: 'wholesale', name: 'Wholesale Deals', emoji: '🛒',
    desc: 'Supplier contracts lower your costs.',
    baseCost: 800, growth: 3.2, maxLevel: 8,
    effect: (l) => 'Costs −${l * 5}%',
  ),
  TechDef(
    id: 'loyalty', name: 'Loyalty Program', emoji: '💌',
    desc: 'Customers come back more often, demand grows.',
    baseCost: 1500, growth: 3.2, maxLevel: 8,
    effect: (l) => 'Demand +${l * 6}%',
  ),
  TechDef(
    id: 'automation', name: 'Automation', emoji: '🤖',
    desc: 'Less manual work means a lower payroll.',
    baseCost: 1200, growth: 3.2, maxLevel: 8,
    effect: (l) => 'Wages −${l * 5}%',
  ),
  TechDef(
    id: 'logistics', name: 'Logistics', emoji: '🚚',
    desc: 'Customers are served faster, so capacity is higher.',
    baseCost: 2000, growth: 3.2, maxLevel: 8,
    effect: (l) => 'Capacity +${l * 7}%',
  ),
  TechDef(
    id: 'brand', name: 'Brand', emoji: '🏷️',
    desc: 'A recognizable brand boosts the reputation of all your businesses.',
    baseCost: 3000, growth: 3.6, maxLevel: 5,
    effect: (l) => 'Reputation +${(l * 0.2).toStringAsFixed(1)}★',
  ),
  TechDef(
    id: 'credit', name: 'Credit Rating', emoji: '💳',
    desc: 'The bank trusts you more and offers bigger loans.',
    baseCost: 2500, growth: 3.4, maxLevel: 6,
    effect: (l) => 'Credit limit +${l * 30}%',
  ),
];

TechDef? techById(String id) {
  for (final t in techDefs) {
    if (t.id == id) return t;
  }
  return null;
}
