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
        'Welcome! 💸',
        'You start with \$1,500. Open a coffee shop in the Businesses tab, hire staff and set the right price.\n\n'
            'Watch demand, reputation and the market, make decisions in your Inbox, upgrade your businesses and build an empire.',
        'Let\'s go!',
      );
      return;
    }
    if (g.bankruptFlag) {
      g.bankruptFlag = false;
      _dialog(
        'Bankruptcy 💥',
        'Debts swallowed your business and everything had to close. You start over with \$1,500, but your upgrades and legacy remain. '
            'Keep an eye on expenses and avoid going deep into the red.',
        'Start over',
      );
      return;
    }
    if (g.offlineEarned > 0) {
      final amount = g.offlineEarned;
      g.clearOffline();
      _dialog('Welcome back! 👋', 'While you were away, your business earned\n+${money(amount)}', 'Collect');
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
          BottomNavigationBarItem(icon: Text('📊', style: TextStyle(fontSize: 22)), label: 'Overview'),
          BottomNavigationBarItem(icon: Text('🏢', style: TextStyle(fontSize: 22)), label: 'Businesses'),
          BottomNavigationBarItem(icon: Text('🔬', style: TextStyle(fontSize: 22)), label: 'Upgrades'),
          BottomNavigationBarItem(icon: Text('🏦', style: TextStyle(fontSize: 22)), label: 'Bank'),
          BottomNavigationBarItem(icon: Text('👤', style: TextStyle(fontSize: 22)), label: 'Profile'),
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
