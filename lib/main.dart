import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'date_screen.dart';
import 'ratio_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // One small read so the last values are on screen in the first frame.
  final prefs = await SharedPreferences.getInstance();
  runApp(CoffeeCalcApp(prefs: prefs));
}

class CoffeeCalcApp extends StatelessWidget {
  final SharedPreferences prefs;
  const CoffeeCalcApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    ThemeData theme(Brightness b) => ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF8B5A2B),
            brightness: b,
          ),
        );
    return MaterialApp(
      title: 'CoffeeCalc',
      debugShowCheckedModeBanner: false,
      theme: theme(Brightness.light),
      darkTheme: theme(Brightness.dark),
      themeMode: ThemeMode.dark,
      home: HomePager(prefs: prefs),
    );
  }
}

/// The two screens side by side; swipe to switch.
class HomePager extends StatefulWidget {
  final SharedPreferences prefs;
  const HomePager({super.key, required this.prefs});

  @override
  State<HomePager> createState() => _HomePagerState();
}

class _HomePagerState extends State<HomePager> {
  static const _pageKey = 'page';
  late final PageController _controller;
  late int _page;

  @override
  void initState() {
    super.initState();
    _page = widget.prefs.getInt(_pageKey) ?? 0;
    _controller = PageController(initialPage: _page);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (p) {
                  setState(() => _page = p);
                  widget.prefs.setInt(_pageKey, p);
                },
                children: [
                  DateScreen(prefs: widget.prefs),
                  RatioScreen(prefs: widget.prefs),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12, top: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < 2; i++)
                    GestureDetector(
                      onTap: () => _controller.animateToPage(i,
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _page == i ? 20 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _page == i ? cs.primary : cs.outlineVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
