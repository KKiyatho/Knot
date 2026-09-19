import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'firebase_service.dart';

const paper = Color(0xFFF6F0E6);
const paperDeep = Color(0xFFEEE6DA);
const ink = Color(0xFF1D1C1A);
const muted = Color(0xFF777067);
const quiet = Color(0xFFCBC1B5);
const accent = Color(0xFFAE5C35);
const hairline = Color(0x211D1C1A);
const weekdayShortNames = ['월', '화', '수', '목', '금', '토', '일'];
const _mobileFrameWidth = 430.0;

class KnotApp extends StatelessWidget {
  const KnotApp({super.key, this.requireGoogle = true});
  final bool requireGoogle;
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
    // 웹에서 넓은 창으로 열어도 모바일 화면 비율만 가운데에 보여준다.
    builder: (context, child) {
      if (!kIsWeb || child == null) return child ?? const SizedBox.shrink();
      final media = MediaQuery.of(context);
      if (media.size.width <= _mobileFrameWidth) return child;
      return ColoredBox(
        color: const Color(0xFF15130F),
        child: Center(
          child: SizedBox(
            width: _mobileFrameWidth,
            child: MediaQuery(
              data: media.copyWith(size: Size(_mobileFrameWidth, media.size.height)),
              child: ClipRect(child: child),
            ),
          ),
        ),
      );
    },
    home: requireGoogle ? const KnotAuthGate() : const KnotHome(),
  );
}

class KnotAuthGate extends StatefulWidget {
  const KnotAuthGate({super.key});
  @override
  State<KnotAuthGate> createState() => _KnotAuthGateState();
}

class _KnotAuthGateState extends State<KnotAuthGate> {
  bool signingIn = false;
  String? error;

  Future<void> _signIn() async {
    setState(() { signingIn = true; error = null; });
    final credential = await KnotFirebaseService.instance.signInWithGoogle();
    if (!mounted) return;
    if (credential == null) {
      setState(() { signingIn = false; error = 'Google 로그인에 실패했습니다. 다시 시도해 주세요.'; });
    } else {
      setState(() => signingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = KnotFirebaseService.instance.user;
    if (user != null && KnotFirebaseService.instance.isGoogleLinked) {
      return const KnotHome();
    }
    return Scaffold(
      backgroundColor: paper,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('KNOT', style: TextStyle(letterSpacing: 4, fontWeight: FontWeight.w700, color: ink)),
                  const SizedBox(height: 28),
                  Text('당신의 루틴을\n하나의 선으로.', style: const TextStyle(fontFamily: 'Georgia', fontSize: 44, height: 1.05, color: ink)),
                  const SizedBox(height: 16),
                  const Text('Google 계정으로 시작하면 루틴과 주간 매듭이 안전하게 이어집니다.', style: TextStyle(color: muted, height: 1.5)),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: signingIn ? null : _signIn,
                      icon: signingIn ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.login),
                      label: Text(signingIn ? '로그인 중...' : 'Google로 시작하기'),
                      style: FilledButton.styleFrom(backgroundColor: ink, foregroundColor: paper, padding: const EdgeInsets.symmetric(vertical: 18)),
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 16),
                    Text(error!, style: const TextStyle(color: Colors.redAccent)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RoutineItem {
  RoutineItem(
    this.id,
    this.name,
    this.detail, {
    List<bool>? activeDays,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
  }) : activeDays = activeDays ?? List<bool>.filled(7, true),
       startTime = startTime ?? const TimeOfDay(hour: 7, minute: 0),
       endTime = endTime ?? startTime ?? const TimeOfDay(hour: 7, minute: 0);
  final String id;
  String name;
  String detail;
  /// 월(0)~일(6) 중 이 루틴을 반복할 요일. 기본값은 매일.
  List<bool> activeDays;
  TimeOfDay startTime;
  /// 시작 시간과 같으면 기간이 아니라 "그 시각에 딱" 하는 루틴이다.
  TimeOfDay endTime;
  bool get isDaily => activeDays.every((d) => d);
  bool get isPointInTime => startTime.hour == endTime.hour && startTime.minute == endTime.minute;
  String get timeLabel {
    String two(int v) => v.toString().padLeft(2, '0');
    final start = '${two(startTime.hour)}:${two(startTime.minute)}';
    if (isPointInTime) return start;
    return '$start~${two(endTime.hour)}:${two(endTime.minute)}';
  }
  String get cycleLabel {
    if (isDaily) return '매일';
    if (!activeDays.any((d) => d)) return '반복 없음';
    const names = ['월', '화', '수', '목', '금', '토', '일'];
    return [for (var i = 0; i < 7; i++) if (activeDays[i]) names[i]].join(' · ');
  }
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

/// 다각형 정점 목록을 닫힌 윤곽선으로 보고, 둘레를 따라 등간격으로 [count]개의 점을 뽑는다.
/// 정점 순서만 올바르면 선으로 이었을 때 항상 의도한 실루엣이 나온다.
List<Offset> _outline(List<Offset> control, int count) {
  final closed = [...control, control.first];
  final segLengths = <double>[];
  var total = 0.0;
  for (var i = 0; i < closed.length - 1; i++) {
    final d = (closed[i + 1] - closed[i]).distance;
    segLengths.add(d);
    total += d;
  }
  final points = <Offset>[];
  for (var i = 0; i < count; i++) {
    final target = total * i / count;
    var acc = 0.0;
    for (var s = 0; s < segLengths.length; s++) {
      final segLength = segLengths[s];
      if (acc + segLength >= target || s == segLengths.length - 1) {
        final localT = segLength <= 0 ? 0.0 : ((target - acc) / segLength).clamp(0.0, 1.0);
        points.add(Offset.lerp(closed[s], closed[s + 1], localT)!);
        break;
      }
      acc += segLength;
    }
  }
  return points;
}

const _shapeResolution = 56;

/// 형상별 실루엣 정점. 순서대로 이으면 바로 물고기/집/잎/달/산 모양이 되도록
/// 둘레를 따라 시계 방향으로 배치한다.
List<Offset> _nodes(String kind) {
  switch (kind) {
    case 'fish':
      return _outline(const [
        Offset(10, 50), // 주둥이
        Offset(16, 38),
        Offset(26, 28),
        Offset(40, 22),
        Offset(56, 22),
        Offset(68, 28),
        Offset(74, 38),
        Offset(76, 48), // 꼬리 이음 위
        Offset(92, 26), // 꼬리 위쪽 끝
        Offset(80, 50), // 꼬리 갈래 (오목)
        Offset(92, 74), // 꼬리 아래쪽 끝
        Offset(76, 52), // 꼬리 이음 아래
        Offset(74, 62),
        Offset(68, 72),
        Offset(56, 78),
        Offset(40, 78),
        Offset(26, 72),
        Offset(16, 62),
      ], _shapeResolution);
    case 'house':
      return _outline(const [
        Offset(18, 86), // 왼쪽 아래
        Offset(18, 46), // 왼쪽 처마
        Offset(50, 16), // 지붕 꼭짓점
        Offset(82, 46), // 오른쪽 처마
        Offset(82, 86), // 오른쪽 아래
      ], _shapeResolution);
    case 'leaf':
      return _outline(const [
        Offset(50, 8), // 잎 끝
        Offset(62, 18),
        Offset(72, 30),
        Offset(78, 44),
        Offset(78, 56),
        Offset(72, 70),
        Offset(62, 82),
        Offset(50, 92), // 잎자루 쪽 끝
        Offset(38, 82),
        Offset(28, 70),
        Offset(22, 56),
        Offset(22, 44),
        Offset(28, 30),
        Offset(38, 18),
      ], _shapeResolution);
    case 'moon':
      return _outline(const [
        Offset(58, 8), // 위쪽 뿔
        Offset(72, 14),
        Offset(82, 24),
        Offset(88, 38),
        Offset(90, 50),
        Offset(88, 62),
        Offset(82, 76),
        Offset(72, 86),
        Offset(58, 92), // 아래쪽 뿔
        Offset(66, 80), // 안쪽(오목) 곡선 시작
        Offset(60, 68),
        Offset(58, 56),
        Offset(58, 44),
        Offset(60, 32),
        Offset(66, 20),
      ], _shapeResolution);
    case 'mountain':
      return _outline(const [
        Offset(4, 90), // 왼쪽 아래
        Offset(4, 60),
        Offset(20, 30), // 첫째 봉우리
        Offset(34, 52),
        Offset(48, 18), // 가장 높은 봉우리
        Offset(60, 46),
        Offset(74, 24), // 셋째 봉우리
        Offset(86, 54),
        Offset(96, 60),
        Offset(96, 90), // 오른쪽 아래
      ], _shapeResolution);
  }
  return _outline(const [Offset(50, 10), Offset(90, 50), Offset(50, 90), Offset(10, 50)], _shapeResolution);
}

/// 순서대로 이은 뒤 처음 점으로 돌아오는 하나의 닫힌 윤곽선.
List<List<int>> _links(String kind) {
  final n = _nodes(kind).length;
  return [List<int>.generate(n + 1, (i) => i % n)];
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

ShapeDefinition shapeForRoutineCount(ShapeDefinition base, int routineCount) {
  final total = math.max(3, routineCount * 7);
  // base.nodes는 이미 닫힌 윤곽선이므로 마지막 점 다음에는 다시 첫 점이 온다고 보고 감싸서 리샘플한다.
  final baseCount = base.nodes.length;
  final nodes = List<Offset>.generate(total, (index) {
    final position = index * baseCount / total;
    final start = position.floor() % baseCount;
    final fraction = position - position.floor();
    final from = base.nodes[start];
    final to = base.nodes[(start + 1) % baseCount];
    return Offset(
      from.dx + (to.dx - from.dx) * fraction,
      from.dy + (to.dy - from.dy) * fraction,
    );
  });
  return ShapeDefinition(
    base.name,
    base.english,
    base.description,
    nodes,
    [List<int>.generate(total + 1, (index) => index % total)],
  );
}

class KnotHome extends StatefulWidget {
  const KnotHome({super.key});
  @override
  State<KnotHome> createState() => _KnotHomeState();
}

class _KnotHomeState extends State<KnotHome> with SingleTickerProviderStateMixin {
  final completedNodes = <int>{};
  final todayCompleted = <int>{};
  final routines = <RoutineItem>[
    RoutineItem('wake', '기상', '', startTime: const TimeOfDay(hour: 7, minute: 0)),
    RoutineItem('water', '물 마시기', '500ml', startTime: const TimeOfDay(hour: 9, minute: 0)),
    RoutineItem(
      'meal',
      '식사',
      '온전한 한 끼',
      startTime: const TimeOfDay(hour: 12, minute: 0),
      endTime: const TimeOfDay(hour: 13, minute: 0),
    ),
    RoutineItem(
      'move',
      '움직이기',
      '산책 30분',
      startTime: const TimeOfDay(hour: 18, minute: 0),
      endTime: const TimeOfDay(hour: 18, minute: 30),
    ),
    RoutineItem('sleep', '잠들기', '', startTime: const TimeOfDay(hour: 23, minute: 30)),
  ];
  int selectedRoutine = 0;
  int selectedShape = 0;
  int themeIndex = 0;
  int tab = 0;
  Timer? timer;
  Stopwatch? watch;
  Duration held = Duration.zero;
  bool holding = false;
  bool signingIn = false;
  bool claimsLoaded = false;
  int? tyingNode;
  late final AnimationController tieController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  );

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

  ShapeDefinition get shape => shapeForRoutineCount(shapes[selectedShape], routines.length);
  int get totalNodes => routines.length * 7;
  @override
  void dispose() {
    timer?.cancel();
    tieController.dispose();
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
        for (var routine = 0; routine < routines.length; routine++) {
          if (keys.contains('${routines[routine].id}|$dateKey')) {
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
    if (todayCompleted.contains(selectedRoutine) || holding || tyingNode != null) return;
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
    final nodeToTie = currentNode;
    timer?.cancel();
    watch?.stop();
    setState(() {
      holding = false;
      held = const Duration(seconds: 2);
      tyingNode = nodeToTie;
    });
    // 점이 즉시 채워지는 대신, 실이 매듭으로 조여지는 짧은 애니메이션을 먼저 재생한다.
    tieController
      ..reset()
      ..forward().whenComplete(() {
        if (!mounted) return;
        setState(() {
          todayCompleted.add(completedRoutine);
          completedNodes.add(nodeToTie);
          tyingNode = null;
          selectedRoutine = List.generate(
            routines.length,
            (i) => i,
          ).firstWhere((i) => !todayCompleted.contains(i), orElse: () => 0);
        });
      });
    unawaited(
      KnotFirebaseService.instance.submitClaim(
        routineId: routines[completedRoutine].id,
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

  Color get themeBackground => const [paper, Color(0xFFF0E7D6), Color(0xFFE4F0EC)][themeIndex];
  Color get themeAccent => const [accent, Color(0xFF7B5A3E), Color(0xFF2D756B)][themeIndex];

  @override
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(
      scaffoldBackgroundColor: themeBackground,
      colorScheme: ColorScheme.fromSeed(seedColor: themeAccent, brightness: Brightness.light),
    ),
    child: Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: tab,
          children: [_home(), _constellation(), _settings()],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: themeBackground,
        elevation: 0,
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.scatter_plot_outlined), selectedIcon: Icon(Icons.scatter_plot), label: '매듭'),
          NavigationDestination(icon: Icon(Icons.checklist_outlined), selectedIcon: Icon(Icons.checklist), label: '루틴'),
          NavigationDestination(icon: Icon(Icons.tune), selectedIcon: Icon(Icons.tune), label: '설정'),
        ],
      ),
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
                '$weekLabel  ·  ${shape.name} 형상  ·  ${completedNodes.length}/$totalNodes',
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
                '${completedNodes.length} / $totalNodes 매듭 · 형상: ${shape.name} (${shape.english})',
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
                '테마',
                const ['종이', '모래', '세이지'][themeIndex],
                DropdownButton<int>(
                  value: themeIndex,
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('종이')),
                    DropdownMenuItem(value: 1, child: Text('모래')),
                    DropdownMenuItem(value: 2, child: Text('세이지')),
                  ],
                  onChanged: (value) => setState(() => themeIndex = value ?? 0),
                ),
              ),
              _setting(
                '이번 주의 형상',
                '${shape.name} · ${completedNodes.length}/$totalNodes',
                TextButton(
                  onPressed: _showShapeSelection,
                  child: const Text('다음 주에 바꾸기 →'),
                ),
              ),
              _setting(
                '나의 루틴',
                '${routines.length}개 · 도형 점 $totalNodes개',
                TextButton(
                  onPressed: _showRoutineEditor,
                  child: const Text('편집 →'),
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
      label: '${shape.name} 주간 형상, ${completedNodes.length}개 중 $totalNodes개 완료',
      button: true,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: AnimatedBuilder(
          animation: tieController,
          builder: (context, _) => CustomPaint(
            painter: KnotPainter(
              shape,
              completedNodes,
              currentNode,
              holding,
              background: themeBackground,
              foreground: Theme.of(context).colorScheme.onSurface,
              accentColor: themeAccent,
              tyingNode: tyingNode,
              tyingProgress: tieController.value,
            ),
          ),
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
            Text('오늘의 ${routines.length}개 매듭', style: _display(23)),
            Text(
              '${selectedRoutine + 1}번째 순서',
              style: const TextStyle(color: accent, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          todayCompleted.contains(selectedRoutine)
              ? '완료한 루틴은 오늘 다시 인증할 수 없습니다.'
              : '${routines[selectedRoutine].name} 루틴을 중앙의 점에 2초간 길게 눌러 인증하세요.',
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
        const SizedBox(height: 18),
        ...List.generate(routines.length, _routineRow),
        _addRoutineRow(),
      ],
    ),
  );
  Widget _addRoutineRow() => GestureDetector(
    onTap: () => _editRoutineDialog(null),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: hairline))),
      child: Row(
        children: [
          const Icon(Icons.add, size: 16, color: accent),
          const SizedBox(width: 10),
          Text('루틴 추가', style: _display(20).copyWith(color: accent)),
        ],
      ),
    ),
  );
  Widget _routineRow(int i) {
    final done = todayCompleted.contains(i);
    return GestureDetector(
      onTap: done ? null : () => setState(() => selectedRoutine = i),
      onSecondaryTapDown: (details) => _showRoutineDeleteMenu(details.globalPosition, i),
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
            Expanded(child: Text(routines[i].name, style: _display(20))),
            Text(
              routines[i].detail.isEmpty ? routines[i].timeLabel : '${routines[i].timeLabel} · ${routines[i].detail}',
              style: _caption(),
            ),
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

  /// 루틴 행을 우클릭하면 삭제 버튼이 있는 작은 메뉴를 그 위치에 띄운다.
  Future<void> _showRoutineDeleteMenu(Offset position, int index) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final canDelete = routines.length > 1;
    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(position & const Size(1, 1), Offset.zero & overlay.size),
      items: [
        PopupMenuItem<String>(
          value: 'delete',
          enabled: canDelete,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
              const SizedBox(width: 8),
              Text(canDelete ? '${routines[index].name} 삭제' : '마지막 루틴은 삭제할 수 없음'),
            ],
          ),
        ),
      ],
    );
    if (selected == 'delete') {
      setState(() {
        routines.removeAt(index);
        completedNodes.clear();
        todayCompleted.clear();
        selectedRoutine = 0;
      });
    }
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
            Text(routines[selectedRoutine].name, style: _display(23)),
          ],
        ),
        Text('${todayCompleted.length}/${routines.length} 완료', style: _caption()),
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

  Future<void> _showRoutineEditor() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: paper,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('나의 루틴', style: _display(26)),
                const SizedBox(height: 6),
                Text('손잡이를 끌어 순서를 바꾸고, 항목을 눌러 이름·시간·반복 요일을 편집하세요.', style: _caption()),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * .5),
                  child: ReorderableListView.builder(
                    shrinkWrap: true,
                    buildDefaultDragHandles: false,
                    physics: const ClampingScrollPhysics(),
                    itemCount: routines.length,
                    onReorderItem: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) newIndex -= 1;
                        final item = routines.removeAt(oldIndex);
                        routines.insert(newIndex, item);
                        completedNodes.clear();
                        todayCompleted.clear();
                        selectedRoutine = 0;
                      });
                      setSheetState(() {});
                    },
                    itemBuilder: (context, index) {
                      final item = routines[index];
                      return ListTile(
                        key: ValueKey(item.id),
                        contentPadding: EdgeInsets.zero,
                        leading: ReorderableDragStartListener(
                          index: index,
                          child: const Icon(Icons.drag_indicator, color: muted),
                        ),
                        title: Text(item.name),
                        subtitle: Text('${item.timeLabel} · ${item.cycleLabel}', style: _caption()),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: '루틴 편집',
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () async {
                                await _editRoutineDialog(item);
                                setSheetState(() {});
                              },
                            ),
                            IconButton(
                              tooltip: '루틴 삭제',
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: routines.length <= 1 ? null : () {
                                setState(() {
                                  routines.removeAt(index);
                                  completedNodes.clear();
                                  todayCompleted.clear();
                                  selectedRoutine = 0;
                                });
                                setSheetState(() {});
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    await _editRoutineDialog(null);
                    setSheetState(() {});
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('루틴 추가'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// [item]이 null이면 새 루틴을 그 자리에서 이름·주기와 함께 만들고, 아니면 기존 루틴을 편집한다.
  Future<void> _editRoutineDialog(RoutineItem? item) async {
    final isNew = item == null;
    final workingItem = item ?? RoutineItem('custom-${DateTime.now().microsecondsSinceEpoch}', '새 루틴', '');
    final nameController = TextEditingController(text: workingItem.name);
    final detailController = TextEditingController(text: workingItem.detail);
    final days = List<bool>.from(workingItem.activeDays);
    var startTime = workingItem.startTime;
    var endTime = workingItem.endTime;
    // 기존 루틴이 이미 기간으로 설정돼 있었다면 뒤 시간을 건드린 것으로 본다.
    var endTouched = !workingItem.isPointInTime;
    String two(int v) => v.toString().padLeft(2, '0');
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(isNew ? '루틴 추가' : '루틴 편집'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: '루틴 이름'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: detailController,
                  decoration: const InputDecoration(labelText: '메모 · 목표 (예: 500ml)'),
                ),
                const SizedBox(height: 16),
                Text('시간', style: _caption()),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: dialogContext,
                            initialTime: startTime,
                            initialEntryMode: TimePickerEntryMode.input,
                            helpText: '시작 시간',
                          );
                          if (picked == null) return;
                          setDialogState(() {
                            startTime = picked;
                            // 뒤 시간을 아직 따로 바꾼 적이 없으면 앞 시간을 따라간다 (그 시각에 딱).
                            if (!endTouched) endTime = picked;
                          });
                        },
                        child: Text('시작 ${two(startTime.hour)}:${two(startTime.minute)}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: dialogContext,
                            initialTime: endTime,
                            initialEntryMode: TimePickerEntryMode.input,
                            helpText: '종료 시간',
                          );
                          if (picked == null) return;
                          setDialogState(() {
                            endTime = picked;
                            endTouched = true;
                          });
                        },
                        child: Text('종료 ${two(endTime.hour)}:${two(endTime.minute)}'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  endTouched
                      ? '${two(startTime.hour)}:${two(startTime.minute)}~${two(endTime.hour)}:${two(endTime.minute)} 기간 동안'
                      : '${two(startTime.hour)}:${two(startTime.minute)}에 딱 · 종료 시간을 바꾸면 기간이 됩니다.',
                  style: _caption(),
                ),
                const SizedBox(height: 16),
                Text('반복 주기', style: _caption()),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: List.generate(
                    7,
                    (i) => FilterChip(
                      label: Text(weekdayShortNames[i]),
                      selected: days[i],
                      onSelected: (value) => setDialogState(() => days[i] = value),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () => setDialogState(() {
                    for (var i = 0; i < 7; i++) {
                      days[i] = true;
                    }
                  }),
                  child: const Text('매일로 설정'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('취소')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(isNew ? '추가' : '저장')),
          ],
        ),
      ),
    );
    if (result == true) {
      setState(() {
        workingItem.name = nameController.text.trim().isEmpty ? workingItem.name : nameController.text.trim();
        workingItem.detail = detailController.text.trim();
        workingItem.activeDays = days;
        workingItem.startTime = startTime;
        workingItem.endTime = endTouched ? endTime : startTime;
        if (isNew) routines.add(workingItem);
      });
    }
    nameController.dispose();
    detailController.dispose();
  }

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
  const KnotPainter(
    this.shape,
    this.completed,
    this.current,
    this.holding, {
    required this.background,
    required this.foreground,
    required this.accentColor,
    this.tyingNode,
    this.tyingProgress = 0,
  });
  final ShapeDefinition shape;
  final Set<int> completed;
  final int current;
  final bool holding;
  final Color background;
  final Color foreground;
  final Color accentColor;
  /// 매듭이 지어지는 중인 노드 인덱스(없으면 null).
  final int? tyingNode;
  /// 0(고리가 느슨함) 에서 1(매듭이 완전히 조임)까지의 진행률.
  final double tyingProgress;
  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width, size.height) / 100;
    final origin = Offset(
      (size.width - 100 * scale) / 2,
      (size.height - 100 * scale) / 2,
    );
    Offset p(Offset v) => origin + Offset(v.dx * scale, v.dy * scale);
    final template = Paint()
      ..color = Color.lerp(background, foreground, .28)!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    final templateShadow = Paint()
      ..color = const Color(0x14000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.2
      ..strokeCap = StrokeCap.round;
    final done = Paint()
      ..color = foreground
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round;
    final doneHighlight = Paint()
      ..color = Colors.white.withValues(alpha: .24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .8
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
      canvas.drawPath(path, templateShadow);
      canvas.drawPath(path, template);
      for (var i = 0; i < link.length - 1; i++) {
        if (completed.contains(link[i]) && completed.contains(link[i + 1])) {
          final from = p(shape.nodes[link[i]]);
          final to = p(shape.nodes[link[i + 1]]);
          canvas.drawLine(from, to, templateShadow..color = const Color(0x28000000));
          canvas.drawLine(
            from,
            to,
            done,
          );
          canvas.drawLine(from.translate(0, -.5), to.translate(0, -.5), doneHighlight);
        }
      }
    }
    for (var i = 0; i < shape.nodes.length; i++) {
      final point = p(shape.nodes[i]);
      if (i == tyingNode) {
        _paintTyingKnot(canvas, point, tyingProgress, accentColor, foreground);
        continue;
      }
      final isDone = completed.contains(i);
      final isCurrent = i == current && !isDone;
      final radius = isCurrent ? 5.5 : 3.2;
      final paint = Paint()
        ..color = isDone
          ? foreground
            : isCurrent
            ? accentColor
            : background;
      canvas.drawCircle(point, radius, paint);
      if (!isDone && !isCurrent) {
        final outline = Paint()
          ..color = Color.lerp(background, foreground, .28)!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;
        canvas.drawCircle(point, radius, outline);
      }
      if (isCurrent && holding) {
        final ring = Paint()
          ..color = accentColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawCircle(point, radius + 9, ring);
      }
    }
  }

  /// 매듭이 실제로 조여지는 장면: 두 개의 고리가 회전하며 조여지다가 하나의 점으로 그치었다.
  void _paintTyingKnot(Canvas canvas, Offset center, double t, Color loopColor, Color dotColor) {
    final ease = Curves.easeInOut.transform(t.clamp(0.0, 1.0));
    final loopSize = 13 + (2 - 13) * ease;
    final loopPaint = Paint()
      ..color = loopColor.withValues(alpha: (1 - ease) * .9 + .1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6 + (1.2 - 2.6) * ease
      ..strokeCap = StrokeCap.round;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(ease * math.pi * 1.5);
    final loops = Path()
      ..addOval(Rect.fromCircle(center: Offset(-loopSize * .42, 0), radius: loopSize))
      ..addOval(Rect.fromCircle(center: Offset(loopSize * .42, 0), radius: loopSize));
    canvas.drawPath(loops, loopPaint);
    canvas.restore();
    final dotRadius = 1 + (5.5 - 1) * ease;
    canvas.drawCircle(center, dotRadius, Paint()..color = dotColor.withValues(alpha: ease));
  }

  @override
  bool shouldRepaint(covariant KnotPainter old) =>
      old.shape != shape ||
      old.completed.length != completed.length ||
      old.completed.difference(completed).isNotEmpty ||
      old.current != current ||
      old.holding != holding ||
      old.tyingNode != tyingNode ||
      old.tyingProgress != tyingProgress;
}
