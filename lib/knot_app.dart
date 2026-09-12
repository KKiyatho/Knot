import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'firebase_service.dart';

const paper = Color(0xFFF6F0E6);
const paperDeep = Color(0xFFEEE6DA);
const ink = Color(0xFF1D1C1A);
const muted = Color(0xFF777067);
const quiet = Color(0xFFCBC1B5);
const accent = Color(0xFFAE5C35);
const hairline = Color(0x211D1C1A);

class KnotApp extends StatelessWidget {
  const KnotApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Knot',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      scaffoldBackgroundColor: paper,
      colorScheme: ColorScheme.fromSeed(seedColor: accent),
      fontFamily: 'Trebuchet MS',
      useMaterial3: true,
    ),
    home: const KnotHome(),
  );
}

class ShapeDefinition {
  const ShapeDefinition(
    this.name,
    this.english,
    this.description,
    this.nodes,
    this.links,
  );
  final String name;
  final String english;
  final String description;
  final List<Offset> nodes;
  final List<List<int>> links;
}

List<Offset> _nodes(String kind) {
  if (kind == 'fish') {
    return [
      Offset(8, 50),
      Offset(18, 35),
      Offset(34, 24),
      Offset(55, 24),
      Offset(72, 36),
      Offset(82, 50),
      Offset(72, 64),
      Offset(55, 76),
      Offset(34, 76),
      Offset(18, 65),
      Offset(31, 50),
      Offset(50, 50),
      Offset(68, 50),
      Offset(88, 24),
      Offset(96, 12),
      Offset(88, 76),
      Offset(96, 88),
      Offset(82, 50),
      Offset(44, 38),
      Offset(44, 62),
      Offset(61, 38),
      Offset(61, 62),
      Offset(20, 50),
      Offset(76, 43),
      Offset(76, 57),
      Offset(89, 36),
      Offset(89, 64),
      Offset(13, 50),
      Offset(39, 50),
      Offset(58, 50),
      Offset(27, 50),
      Offset(51, 25),
      Offset(51, 75),
      Offset(72, 38),
      Offset(72, 62),
    ];
  }
  if (kind == 'house') {
    return [
      Offset(12, 78),
      Offset(12, 45),
      Offset(50, 12),
      Offset(88, 45),
      Offset(88, 78),
      Offset(32, 78),
      Offset(32, 52),
      Offset(50, 38),
      Offset(68, 52),
      Offset(68, 78),
      Offset(50, 12),
      Offset(50, 78),
      Offset(42, 78),
      Offset(58, 78),
      Offset(42, 60),
      Offset(58, 60),
      Offset(24, 35),
      Offset(76, 35),
      Offset(24, 61),
      Offset(76, 61),
      Offset(32, 45),
      Offset(68, 45),
      Offset(32, 68),
      Offset(68, 68),
      Offset(50, 28),
      Offset(50, 48),
      Offset(22, 78),
      Offset(78, 78),
      Offset(22, 55),
      Offset(78, 55),
      Offset(39, 52),
      Offset(61, 52),
      Offset(39, 68),
      Offset(61, 68),
      Offset(50, 70),
    ];
  }
  if (kind == 'leaf') {
    return [
      Offset(50, 90),
      Offset(40, 78),
      Offset(28, 64),
      Offset(20, 48),
      Offset(24, 32),
      Offset(38, 18),
      Offset(54, 10),
      Offset(70, 20),
      Offset(82, 36),
      Offset(80, 52),
      Offset(70, 68),
      Offset(58, 80),
      Offset(50, 90),
      Offset(50, 50),
      Offset(50, 24),
      Offset(34, 38),
      Offset(66, 38),
      Offset(30, 52),
      Offset(70, 52),
      Offset(36, 65),
      Offset(64, 65),
      Offset(42, 78),
      Offset(58, 78),
      Offset(42, 50),
      Offset(58, 50),
      Offset(32, 28),
      Offset(68, 30),
      Offset(24, 43),
      Offset(76, 43),
      Offset(38, 22),
      Offset(62, 24),
      Offset(28, 62),
      Offset(72, 60),
      Offset(44, 36),
      Offset(56, 68),
    ];
  }
  if (kind == 'moon') {
    return [
      Offset(72, 12),
      Offset(54, 10),
      Offset(38, 18),
      Offset(25, 32),
      Offset(18, 50),
      Offset(23, 68),
      Offset(36, 82),
      Offset(52, 90),
      Offset(70, 86),
      Offset(82, 74),
      Offset(70, 70),
      Offset(58, 60),
      Offset(52, 48),
      Offset(54, 34),
      Offset(64, 22),
      Offset(43, 28),
      Offset(35, 44),
      Offset(36, 62),
      Offset(48, 76),
      Offset(61, 32),
      Offset(62, 48),
      Offset(60, 64),
      Offset(30, 50),
      Offset(46, 18),
      Offset(27, 38),
      Offset(28, 66),
      Offset(48, 84),
      Offset(70, 28),
      Offset(72, 48),
      Offset(68, 68),
      Offset(44, 40),
      Offset(46, 58),
      Offset(54, 74),
      Offset(22, 50),
      Offset(78, 50),
    ];
  }
  return [
    Offset(8, 82),
    Offset(20, 64),
    Offset(32, 45),
    Offset(44, 24),
    Offset(52, 8),
    Offset(62, 25),
    Offset(74, 46),
    Offset(86, 65),
    Offset(96, 82),
    Offset(18, 82),
    Offset(30, 72),
    Offset(42, 62),
    Offset(54, 72),
    Offset(68, 82),
    Offset(28, 54),
    Offset(40, 45),
    Offset(52, 54),
    Offset(64, 44),
    Offset(78, 55),
    Offset(38, 30),
    Offset(52, 32),
    Offset(66, 30),
    Offset(44, 18),
    Offset(60, 18),
    Offset(52, 42),
    Offset(24, 73),
    Offset(80, 73),
    Offset(34, 62),
    Offset(70, 62),
    Offset(30, 82),
    Offset(74, 82),
    Offset(52, 68),
    Offset(52, 80),
    Offset(46, 50),
    Offset(58, 50),
  ];
}

List<List<int>> _links(String kind) {
  if (kind == 'house') {
    return [
      [0, 1, 2, 3, 4, 0],
      [0, 5, 9, 4],
      [5, 6, 7, 8, 9],
      [2, 10, 3],
      [10, 11],
      [6, 14, 15, 8],
      [1, 16, 17, 3],
      [5, 18, 19, 9],
      [1, 20, 21, 3],
      [5, 22, 23, 9],
      [7, 24, 11],
      [0, 26, 27, 4],
      [1, 28, 29, 3],
      [6, 30, 31, 8],
      [6, 32, 33, 8],
      [11, 34],
    ];
  }
  if (kind == 'leaf') {
    return [
      [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
      [0, 13, 14, 6],
      [13, 15, 16, 8],
      [13, 17, 18, 10],
      [13, 19, 20, 11],
      [0, 21, 22],
      [3, 23, 24, 9],
      [5, 25, 26, 7],
      [4, 27, 28, 9],
      [5, 29, 30, 8],
      [2, 31, 32, 10],
      [13, 33, 34],
    ];
  }
  if (kind == 'moon') {
    return [
      [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
      [1, 13, 12, 11, 10, 9],
      [12, 14, 15, 16, 17, 10],
      [12, 18, 19, 20, 10],
      [3, 21, 4],
      [2, 22, 1],
      [3, 23, 2],
      [5, 24, 6],
      [7, 25, 8],
      [0, 26, 13],
      [4, 32, 21],
      [11, 29, 30, 16],
      [10, 31, 17],
      [1, 33, 12],
      [0, 34, 8],
    ];
  }
  if (kind == 'mountain') {
    return [
      [0, 1, 2, 3, 4, 5, 6, 7, 8],
      [0, 9, 13, 8],
      [1, 10, 11, 12, 7],
      [2, 14, 15, 16, 18, 6],
      [3, 19, 20, 21, 22, 5],
      [4, 23, 24, 25],
      [16, 26, 27, 20],
      [11, 28, 29, 12],
      [0, 30, 31, 8],
      [4, 32, 33, 34, 16],
    ];
  }
  return [
    [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0],
    [0, 10, 11, 12, 5],
    [11, 18, 3],
    [11, 19, 7],
    [10, 20, 2],
    [10, 21, 8],
    [12, 23, 13, 14],
    [12, 24, 15, 16],
    [10, 22, 27],
    [11, 28, 29],
    [3, 31, 18],
    [7, 32, 19],
    [5, 33, 13],
    [6, 34, 15],
  ];
}

final shapes = [
  ShapeDefinition(
    '물고기',
    'FISH',
    '몸통과 꼬리로 이어지는 유려한 흐름형',
    _nodes('fish'),
    _links('fish'),
  ),
  ShapeDefinition(
    '집',
    'HOUSE',
    '지붕, 벽, 문, 창이 완성되는 안정형',
    _nodes('house'),
    _links('house'),
  ),
  ShapeDefinition(
    '잎',
    'LEAF',
    '줄기와 잎맥이 피어나는 자연형',
    _nodes('leaf'),
    _links('leaf'),
  ),
  ShapeDefinition(
    '달',
    'MOON',
    '초승달 윤곽과 내부 점이 채워지는 야간형',
    _nodes('moon'),
    _links('moon'),
  ),
  ShapeDefinition(
    '산',
    'MOUNTAIN',
    '능선과 봉우리가 이어지는 풍경형',
    _nodes('mountain'),
    _links('mountain'),
  ),
];

class KnotHome extends StatefulWidget {
  const KnotHome({super.key});
  @override
  State<KnotHome> createState() => _KnotHomeState();
}

class _KnotHomeState extends State<KnotHome> {
  final completedNodes = <int>{};
  final todayCompleted = <int>{};
  static const routines = [
    ('기상', '07:00'),
    ('물 마시기', '500ml'),
    ('식사', '온전한 한 끼'),
    ('움직이기', '산책 30분'),
    ('잠들기', '23:30 이전'),
  ];
  static const routineIds = ['wake', 'water', 'meal', 'move', 'sleep'];
  int selectedRoutine = 0;
  int selectedShape = 0;
  int tab = 0;
  Timer? timer;
  Stopwatch? watch;
  Duration held = Duration.zero;
  bool holding = false;
  bool signingIn = false;
  bool claimsLoaded = false;

  int get currentDayIndex {
    final today = DateTime.now();
    final monday = today.subtract(
      Duration(days: today.weekday - DateTime.monday),
    );
    return today
        .difference(DateTime(monday.year, monday.month, monday.day))
        .inDays;
  }

  int get currentNode => currentDayIndex * routines.length + selectedRoutine;

  DateTime get weekStart {
    final today = DateTime.now();
    final monday = today.subtract(
      Duration(days: today.weekday - DateTime.monday),
    );
    return DateTime(monday.year, monday.month, monday.day);
  }

  String get weekdayName =>
      const ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'][currentDayIndex];

  String get weekLabel =>
      '${weekStart.year}년 ${weekStart.month}월 ${weekStart.day}일 주';

  ShapeDefinition get shape => shapes[selectedShape];
  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _restoreClaims();
  }

  Future<void> _restoreClaims() async {
    final keys = await KnotFirebaseService.instance.loadClaimKeys();
    if (!mounted) return;
    setState(() {
      for (var day = 0; day < 7; day++) {
        final dateKey = weekStart
            .add(Duration(days: day))
            .toIso8601String()
            .substring(0, 10);
        for (var routine = 0; routine < routineIds.length; routine++) {
          if (keys.contains('${routineIds[routine]}|$dateKey')) {
            completedNodes.add(day * routines.length + routine);
            if (day == currentDayIndex) todayCompleted.add(routine);
          }
        }
      }
      selectedRoutine = List.generate(
        routines.length,
        (i) => i,
      ).firstWhere((i) => !todayCompleted.contains(i), orElse: () => 0);
      claimsLoaded = true;
    });
  }

  void startHold() {
    if (todayCompleted.contains(selectedRoutine) || holding) return;
    setState(() {
      holding = true;
      held = Duration.zero;
      watch = Stopwatch()..start();
    });
    timer = Timer.periodic(const Duration(milliseconds: 40), (_) {
      if ((watch?.elapsed ?? Duration.zero) >= const Duration(seconds: 2)) {
        completeRoutine();
      } else if (mounted) {
        setState(() => held = watch?.elapsed ?? Duration.zero);
      }
    });
  }

  void cancelHold() {
    if (!holding) return;
    timer?.cancel();
    watch?.stop();
    setState(() {
      holding = false;
      held = Duration.zero;
    });
  }

  void completeRoutine() {
    final completedRoutine = selectedRoutine;
    timer?.cancel();
    watch?.stop();
    setState(() {
      todayCompleted.add(selectedRoutine);
      completedNodes.add(currentNode);
      holding = false;
      held = const Duration(seconds: 2);
      selectedRoutine = List.generate(
        routines.length,
        (i) => i,
      ).firstWhere((i) => !todayCompleted.contains(i), orElse: () => 0);
    });
    unawaited(
      KnotFirebaseService.instance.submitClaim(
        routineId: routineIds[completedRoutine],
        eventId: 'local-${DateTime.now().microsecondsSinceEpoch}',
        dateKey: DateTime.now().toUtc().toIso8601String().substring(0, 10),
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    setState(() => signingIn = true);
    final credential = await KnotFirebaseService.instance.signInWithGoogle();
    if (!mounted) return;
    setState(() => signingIn = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          credential == null ? 'Google 로그인에 실패했습니다.' : 'Google 계정으로 연결되었습니다.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      bottom: false,
      child: IndexedStack(
        index: tab,
        children: [_home(), _constellation(), _settings()],
      ),
    ),
    bottomNavigationBar: NavigationBar(
      backgroundColor: paper,
      elevation: 0,
      selectedIndex: tab,
      onDestinationSelected: (i) => setState(() => tab = i),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.scatter_plot_outlined),
          selectedIcon: Icon(Icons.scatter_plot),
          label: '매듭',
        ),
        NavigationDestination(
          icon: Icon(Icons.checklist_outlined),
          selectedIcon: Icon(Icons.checklist),
          label: '루틴',
        ),
        NavigationDestination(
          icon: Icon(Icons.tune),
          selectedIcon: Icon(Icons.tune),
          label: '설정',
        ),
      ],
    ),
  );

  Widget _top() => Padding(
    padding: const EdgeInsets.fromLTRB(24, 18, 24, 14),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Text(
              'KNOT',
              style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 2),
            ),
            const SizedBox(width: 12),
            Text('주간 기록', style: _caption()),
          ],
        ),
        IconButton(
          tooltip: KnotFirebaseService.instance.isGoogleLinked
              ? 'Google 로그인됨'
              : 'Google로 로그인',
          onPressed: signingIn ? null : _signInWithGoogle,
          style: IconButton.styleFrom(
            backgroundColor: ink,
            foregroundColor: paper,
          ),
          icon: signingIn
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: paper,
                  ),
                )
              : const Icon(Icons.person_outline),
        ),
      ],
    ),
  );
  Widget _home() => CustomScrollView(
    slivers: [
      SliverToBoxAdapter(child: _top()),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        sliver: SliverToBoxAdapter(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text("THIS WEEK'S WORK", style: _eyebrow()),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Routine\nDrawer', style: _display(44)),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('매일의 작은 행동을 하나의 선으로 이어 보세요.', style: _body()),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('이번 주의 형상은 당신의 속도로 완성됩니다.', style: _body()),
              ),
              const SizedBox(height: 18),
              _canvas(280),
              Text(
                '$weekLabel  ·  ${shape.name} 형상  ·  ${completedNodes.length}/35',
                style: _caption(),
              ),
            ],
          ),
        ),
      ),
      SliverToBoxAdapter(child: _drawer()),
    ],
  );
  Widget _constellation() => CustomScrollView(
    slivers: [
      SliverToBoxAdapter(child: _top()),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 70),
        sliver: SliverToBoxAdapter(
          child: Column(
            children: [
              Text('WEEKLY CONSTELLATION', style: _eyebrow()),
              const SizedBox(height: 14),
              Text(weekdayName, style: _display(48)),
              const SizedBox(height: 8),
              Text(
                '${completedNodes.length} / 35 매듭 · 형상: ${shape.name} (${shape.english})',
                style: _caption(),
              ),
              const SizedBox(height: 20),
              _canvas(390),
              const SizedBox(height: 14),
              Text('중앙의 점을 2초간 길게 누르면 매듭이 채워집니다', style: _body()),
              const SizedBox(height: 18),
              _weekRule(),
              const SizedBox(height: 28),
              _currentCard(),
            ],
          ),
        ),
      ),
    ],
  );
  Widget _settings() => CustomScrollView(
    slivers: [
      SliverToBoxAdapter(child: _top()),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 70),
        sliver: SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('QUIET SETTINGS', style: _eyebrow()),
              const SizedBox(height: 14),
              Text('설정', style: _display(48)),
              const SizedBox(height: 22),
              _setting(
                '소리',
                '인증과 매칭의 짧은 소리',
                Switch(value: true, onChanged: (_) {}),
              ),
              _setting(
                '햅틱',
                '점이 채워질 때의 진동',
                Switch(value: true, onChanged: (_) {}),
              ),
              _setting(
                '이번 주의 형상',
                '${shape.name} · ${completedNodes.length}/35',
                TextButton(
                  onPressed: _showShapeSelection,
                  child: const Text('다음 주에 바꾸기 →'),
                ),
              ),
              _setting(
                '개인정보와 데이터',
                '짧은 보존과 익명 기록',
                TextButton(onPressed: () {}, child: const Text('읽어보기 →')),
              ),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _canvas(double height) => GestureDetector(
    onLongPressStart: (_) => startHold(),
    onLongPressEnd: (_) => cancelHold(),
    onLongPressCancel: cancelHold,
    child: Semantics(
      label: '${shape.name} 주간 형상, ${completedNodes.length}개 중 35개 완료',
      button: true,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: KnotPainter(shape, completedNodes, currentNode, holding),
        ),
      ),
    ),
  );
  Widget _drawer() => Container(
    color: const Color(0x66FFFDF9),
    padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('오늘의 5개 매듭', style: _display(23)),
            Text(
              '${selectedRoutine + 1}번째 순서',
              style: const TextStyle(color: accent, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...List.generate(5, _routineRow),
        const SizedBox(height: 18),
        Text(
          todayCompleted.contains(selectedRoutine)
              ? '완료한 루틴은 오늘 다시 인증할 수 없습니다.'
              : '${routines[selectedRoutine].$1} 루틴을 중앙의 점에 2초간 길게 눌러 인증하세요.',
          style: _caption(),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onLongPressStart: (_) => startHold(),
          onLongPressEnd: (_) => cancelHold(),
          onLongPressCancel: cancelHold,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15),
            color: todayCompleted.contains(selectedRoutine)
                ? quiet
                : holding
                ? accent
                : ink,
            child: Center(
              child: Text(
                todayCompleted.contains(selectedRoutine)
                    ? '완료된 루틴'
                    : holding
                    ? '채우는 중 · ${(held.inMilliseconds / 1000).toStringAsFixed(1)}s'
                    : '점 길게 누르기',
                style: const TextStyle(
                  color: paper,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
  Widget _routineRow(int i) {
    final done = todayCompleted.contains(i);
    return GestureDetector(
      onTap: done ? null : () => setState(() => selectedRoutine = i),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: selectedRoutine == i ? paperDeep : Colors.transparent,
          border: const Border(bottom: BorderSide(color: hairline)),
        ),
        child: Row(
          children: [
            Text('0${i + 1}', style: _caption()),
            const SizedBox(width: 12),
            Icon(
              done ? Icons.circle : Icons.circle_outlined,
              size: 12,
              color: done ? ink : quiet,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(routines[i].$1, style: _display(20))),
            Text(routines[i].$2, style: _caption()),
            const SizedBox(width: 10),
            Text(
              done
                  ? '완료됨'
                  : selectedRoutine == i
                  ? '인증 대기'
                  : '대기 중',
              style: TextStyle(
                fontSize: 11,
                color: selectedRoutine == i ? accent : muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _weekRule() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: List.generate(
      7,
      (i) => Container(
        width: 34,
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        color: i < completedNodes.length ~/ 5
            ? ink
            : i == completedNodes.length ~/ 5
            ? accent
            : quiet,
      ),
    ),
  );
  Widget _currentCard() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(border: Border.all(color: hairline)),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$weekdayName 제 ${selectedRoutine + 1}의 궤적',
              style: _caption(),
            ),
            const SizedBox(height: 6),
            Text(routines[selectedRoutine].$1, style: _display(23)),
          ],
        ),
        Text('${todayCompleted.length}/5 완료', style: _caption()),
      ],
    ),
  );
  Widget _setting(String title, String detail, Widget trailing) => Container(
    padding: const EdgeInsets.symmetric(vertical: 18),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: hairline)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: _display(19)),
              const SizedBox(height: 4),
              Text(detail, style: _caption()),
            ],
          ),
        ),
        trailing,
      ],
    ),
  );
  void _showShapeSelection() => showModalBottomSheet<void>(
    context: context,
    backgroundColor: paper,
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: RadioGroup<int>(
          groupValue: selectedShape,
          onChanged: (value) {
            if (value != null) setState(() => selectedShape = value);
            Navigator.pop(context);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('새로운 한 주의 매듭', style: _display(25)),
              const SizedBox(height: 12),
              ...List.generate(
                shapes.length,
                (i) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('${shapes[i].name}  ${shapes[i].english}'),
                  subtitle: Text(shapes[i].description, style: _caption()),
                  trailing: Radio<int>(value: i),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  TextStyle _display(double size) => TextStyle(
    fontFamily: 'Georgia',
    fontSize: size,
    height: 1.08,
    color: ink,
  );
  TextStyle _body() => const TextStyle(color: muted, fontSize: 13, height: 1.5);
  TextStyle _caption() =>
      const TextStyle(color: muted, fontSize: 12, letterSpacing: .3);
  TextStyle _eyebrow() => const TextStyle(
    color: accent,
    fontSize: 11,
    letterSpacing: 2.1,
    fontWeight: FontWeight.w600,
  );
}

class KnotPainter extends CustomPainter {
  const KnotPainter(this.shape, this.completed, this.current, this.holding);
  final ShapeDefinition shape;
  final Set<int> completed;
  final int current;
  final bool holding;
  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width, size.height) / 100;
    final origin = Offset(
      (size.width - 100 * scale) / 2,
      (size.height - 100 * scale) / 2,
    );
    Offset p(Offset v) => origin + Offset(v.dx * scale, v.dy * scale);
    final template = Paint()
      ..color = quiet
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final done = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.3
      ..strokeCap = StrokeCap.round;
    for (final link in shape.links) {
      final path = Path();
      for (var i = 0; i < link.length; i++) {
        final point = p(shape.nodes[link[i]]);
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      canvas.drawPath(path, template);
      for (var i = 0; i < link.length - 1; i++) {
        if (completed.contains(link[i]) && completed.contains(link[i + 1])) {
          canvas.drawLine(
            p(shape.nodes[link[i]]),
            p(shape.nodes[link[i + 1]]),
            done,
          );
        }
      }
    }
    for (var i = 0; i < shape.nodes.length; i++) {
      final point = p(shape.nodes[i]);
      final isDone = completed.contains(i);
      final isCurrent = i == current && !isDone;
      final radius = isCurrent ? 5.5 : 3.2;
      final paint = Paint()
        ..color = isDone
            ? ink
            : isCurrent
            ? accent
            : paper;
      canvas.drawCircle(point, radius, paint);
      if (!isDone && !isCurrent) {
        final outline = Paint()
          ..color = quiet
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;
        canvas.drawCircle(point, radius, outline);
      }
      if (isCurrent && holding) {
        final ring = Paint()
          ..color = accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawCircle(point, radius + 9, ring);
      }
    }
  }

  @override
  bool shouldRepaint(covariant KnotPainter old) =>
      old.shape != shape ||
      old.completed != completed ||
      old.current != current ||
      old.holding != holding;
}
