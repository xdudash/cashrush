import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import 'format.dart';
import 'game.dart';
import 'ui/bank_tab.dart';
import 'ui/business_tab.dart';
import 'ui/common.dart';
import 'ui/overview_tab.dart';
import 'ui/profile_tab.dart';
import 'ui/research_tab.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final game = GameState();
  await game.init();
  runApp(TycoonApp(game: game));
}

class TycoonApp extends StatefulWidget {
  final GameState game;
  const TycoonApp({super.key, required this.game});

  @override
  State<TycoonApp> createState() => _TycoonAppState();
}

class _TycoonAppState extends State<TycoonApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      widget.game.onPaused();
    } else if (state == AppLifecycleState.resumed) {
      widget.game.onResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'Cash Rush',
      debugShowCheckedModeBanner: false,
      theme: const CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: kAccent,
        scaffoldBackgroundColor: kBg,
      ),
      home: HomeScreen(game: widget.game),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final GameState game;
  const HomeScreen({super.key, required this.game});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    widget.game.addListener(_check);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void dispose() {
    widget.game.removeListener(_check);
    super.dispose();
  }

  void _dialog(String title, String text, String button) {
    _busy = true;
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(text),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(button),
          ),
        ],
      ),
    ).then((_) {
      _busy = false;
      _check();
    });
  }

  void _check() {
    if (!mounted || _busy) return;
    final g = widget.game;
    if (!g.seenIntro) {
      g.seenIntro = true;
      g.save();
      _dialog(
        'Добро пожаловать! 💸',
        'Вы начинаете с \$1 500. Откройте кофейню во вкладке «Бизнесы», наймите сотрудников и подберите цену.\n\n'
            'Следите за спросом, репутацией и рынком, принимайте решения во «Входящих», развивайте бизнесы и стройте империю.',
        'Поехали!',
      );
      return;
    }
    if (g.bankruptFlag) {
      g.bankruptFlag = false;
      _dialog(
        'Банкротство 💥',
        'Долги съели бизнес, и всё пришлось закрыть. Вы начинаете заново с \$1 500, но улучшения и наследие остались. '
            'Следите за расходами и не уходите глубоко в минус.',
        'Начать заново',
      );
      return;
    }
    if (g.offlineEarned > 0) {
      final amount = g.offlineEarned;
      g.clearOffline();
      _dialog('С возвращением! 👋', 'Пока вас не было, бизнес заработал\n+${money(amount)}', 'Забрать');
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    return CupertinoTabScaffold(
      backgroundColor: kBg,
      tabBar: CupertinoTabBar(
        backgroundColor: kPanel,
        items: const [
          BottomNavigationBarItem(icon: Text('📊', style: TextStyle(fontSize: 22)), label: 'Обзор'),
          BottomNavigationBarItem(icon: Text('🏢', style: TextStyle(fontSize: 22)), label: 'Бизнесы'),
          BottomNavigationBarItem(icon: Text('🔬', style: TextStyle(fontSize: 22)), label: 'Развитие'),
          BottomNavigationBarItem(icon: Text('🏦', style: TextStyle(fontSize: 22)), label: 'Банк'),
          BottomNavigationBarItem(icon: Text('👤', style: TextStyle(fontSize: 22)), label: 'Профиль'),
        ],
      ),
      tabBuilder: (context, index) {
        switch (index) {
          case 0:
            return OverviewTab(game: game);
          case 1:
            return BusinessTab(game: game);
          case 2:
            return ResearchTab(game: game);
          case 3:
            return BankTab(game: game);
          default:
            return ProfileTab(game: game);
        }
      },
    );
  }
}
