# Knot 🪢

> **"하루 다섯 개의 작은 행동이, 일주일 뒤 하나의 형상이 됩니다."**
> 기록이 아니라 행위로 완성하는 미니멀 주간 루틴 앱

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](pubspec.yaml)
[![Flutter](https://img.shields.io/badge/Flutter-3.44-02569B?logo=flutter)](https://flutter.dev)

---

## 📱 앱 소개

**Knot(매듭)**은 하루 5개의 루틴을 7일 동안 완료해 35개의 점을 잇는 미니멀 주간 루틴 앱입니다. 통계, 스트릭, 랭킹, 소셜 피드처럼 관리 부담을 만드는 요소를 걷어내고, 화면에는 오직 **오늘의 루틴 상태와 완성되어 가는 도형**만 남깁니다.

### 🎯 핵심 가치
- **기록보다 행위**: 입력은 없고, 점을 2초간 길게 누르는 행동 하나로 인증이 끝난다.
- **여백을 기능으로**: 카드, 배지, 그림자 없이 도형·점·선만으로 진행 상황을 보여준다.
- **조용한 실패 허용**: 네트워크가 끊겨도 루틴 인증은 로컬에서 계속 진행된다.
- **나만의 주기**: 루틴마다 이름·시간(또는 시간대)·반복 요일을 직접 정할 수 있다.

---

## ✨ 핵심 기능

### 1️⃣ 홈 — 이번 주의 매듭
```
중앙의 도형 틀 위에서 오늘의 루틴을 인증한다
├─ 점을 2초간 길게 누르면 매듭이 지어지는 애니메이션과 함께 완료
├─ 완료된 점은 인접한 점과 선으로 이어져 형상이 자라난다
└─ 매듭 짓기 버튼은 루틴 목록 바로 위, 엄지 닿는 자리에 배치
```

### 2️⃣ 루틴 편집 — 나만의 주기 설정
```
홈에서 바로 이름 · 시간 · 반복 요일을 정한다
├─ "루틴 추가"를 누르면 그 자리에서 바로 설정 다이얼로그가 열림
├─ 시작/종료 시간은 디지털 입력형 시계로 선택 (예: 10:00~11:00)
├─ 종료 시간을 건드리지 않으면 "그 시각에 딱" 한 점으로, 바꾸면 기간으로 동작
├─ 월~일 요일 칩으로 반복 주기를 선택 ("매일로 설정" 단축 지원)
├─ 드래그로 순서 변경, 우클릭으로 빠른 삭제
```

### 3️⃣ 주간 형상 — 물고기 · 집 · 잎 · 달 · 산
```
5가지 형상 중 하나를 골라 한 주의 캔버스로 삼는다
├─ 각 형상은 35개(하루 5개 × 7일) 노드를 가진 닫힌 윤곽선으로 정의
├─ 루틴 개수가 바뀌어도 윤곽선을 따라 점 밀도가 자동으로 다시 배치됨
└─ 도형 변경은 기본적으로 다음 주에만 가능 (진행 중 기록 보호)
```

### 4️⃣ 익명 계정 — Google 로그인 + Firebase
```
Firebase Anonymous → Google 계정 연결
├─ 루틴 claim은 Realtime Database에 날짜·루틴 단위로 기록
├─ 세션 간 진행 상황 복원 (loadClaimKeys)
└─ 개인 식별 정보 없이 최소 데이터만 저장
```

---

## 🛠️ 기술 스택

| 계층 | 기술 |
|------|------|
| **Frontend** | Flutter 3.44 (Dart 3.12) |
| **인증** | Firebase Authentication (Anonymous + Google) |
| **실시간 데이터** | Firebase Realtime Database |
| **분석** | Firebase Analytics |
| **렌더링** | `CustomPainter` 기반 도형/매듭 애니메이션 |
| **배포** | Azure Storage 정적 웹사이트 호스팅 (Azure CLI) |

---

## 🎨 UI/UX 특징

### 디자인 철학
- **스위스 타이포그래피 기반**의 강한 정렬과 넓은 여백
- 카드 · 그림자 · 그라데이션 · 장식 아이콘을 쓰지 않는다
- 시각 계층은 루틴명 → 도형 → 점의 순서로만 제한
- 색상만으로 완료 여부를 전달하지 않는다 (채움·윤곽·라벨을 함께 사용)

### 화면 구성
- 상단: 요일과 진행 상태
- 중앙: 이번 주 도형과 현재 노드
- 하단: 매듭 짓기 버튼 + 오늘의 루틴 목록 + 루틴 추가
- 자세한 화면 계약은 [UI.md](UI.md) 참고

---

## 💡 주요 구현 사항

### 1. 형상 윤곽선 리샘플링
- 5개 형상을 손으로 배치한 정점(닫힌 다각형)으로 정의하고, 둘레를 따라 등간격으로 리샘플링
- 루틴 개수(하루 노드 수)가 바뀌어도 같은 윤곽선을 유지한 채 점 개수만 다시 계산

### 2. 매듭 짓는 애니메이션
- 롱프레스 완료 시 점이 즉시 채워지지 않고, 두 개의 고리가 회전하며 조여지는 짧은 애니메이션 후 노드가 확정됨
- `AnimationController` + `AnimatedBuilder`로 프레임마다 `CustomPainter`에 진행률 전달

### 3. 시간 설정 UX
- 시작/종료 시간을 각각 디지털 입력형 `showTimePicker`로 선택
- 종료 시간을 건드리지 않으면 시작 시간을 따라가 "그 시각에 딱" 의미가 되고, 한 번 바꾸면 기간으로 고정

### 4. 웹에서도 모바일 비율
- `MaterialApp.builder`에서 `kIsWeb` + 430px 프레임으로 넓은 브라우저 창에서도 모바일 화면 비율만 중앙에 표시

---

## 🚀 배포 현황

### 웹
- **운영 URL**: https://knotwebh8pfmn.z12.web.core.windows.net/
- **배포 방식**: Azure Storage 정적 웹사이트 호스팅 (Azure CLI, `az storage blob upload-batch`)
- **비용**: Standard_LRS + Cool 티어로 월 최소 비용만 발생

### 모바일 (예정)
- Android / iOS 네이티브 빌드는 아직 스토어에 제출하지 않음

---

## 🎯 향후 계획 (PRD 기준)

### Phase 2 — 하이브리드 매칭
- [ ] Tier 1(±2초) / Tier 2(1분) / Tier 3(1시간) 익명 이벤트 매칭
- [ ] 매칭 결과의 순차 재생과 자동 초기화

### Phase 3 — 베타 검증
- [ ] 실동시성 부하 테스트, 매칭 지연·빈 화면률 확인
- [ ] Firebase Security Rules 자동 테스트

자세한 로드맵과 미결정 사항은 [PRD.md](PRD.md)를 참고하세요.

---

## 🔧 로컬 설치 및 실행

### 요구사항
- Flutter 3.44+
- Dart 3.12+
- Firebase CLI (Realtime Database 규칙 배포 시)

### 설치 및 실행
```powershell
flutter pub get
flutter run
```

웹 렌더링으로 빠르게 확인하려면:
```powershell
flutter run -d chrome
```

### 검증
```powershell
flutter analyze
flutter test
flutter build web
```

### 웹 빌드 & 배포
```powershell
flutter build web --release
az storage blob upload-batch -s build/web -d '$web' --account-name <storage-account> --overwrite
```

Firebase 연결, Google 로그인 설정, Realtime Database 규칙 등 상세 절차는 [SETUP.md](SETUP.md)를 참고하세요.

---

## 📚 프로젝트 문서

| 파일 | 내용 |
|------|------|
| [PRD.md](PRD.md) | 제품 요구사항 정의서 (MVP 범위, 로드맵, 미결정 사항) |
| [UI.md](UI.md) | 화면·상태별 UI 계약과 접근성 기준 |
| [Agent.md](Agent.md) | AI 어시스턴트 개발 지침 |
| [SETUP.md](SETUP.md) | 로컬 실행 · Firebase 연결 상세 가이드 |

---

## 🙏 인용

- **제품 원칙**: [PRD.md](PRD.md)의 "기록보다 행위, 연결하되 노출하지 않기" 원칙
- **기술 지원**: Flutter, Firebase 커뮤니티
