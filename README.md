# Knot

Knot은 하루 5개 루틴을 7일 동안 완료해 35개 점의 형상을 완성하는 Flutter 모바일 앱입니다.

## 실행

```powershell
flutter pub get
flutter run
```

웹 렌더링으로 빠르게 확인하려면 다음을 사용합니다.

```powershell
flutter run -d chrome
```

## Firebase 연결

Firebase 패키지, 익명 인증, Realtime Database, Analytics가 연결되어 있습니다. 제공된 `knot-de1a1` Web 설정은 [lib/firebase_options.dart](lib/firebase_options.dart)에 등록되어 있으며, 앱은 시작 시 익명 세션을 만들고 루틴 claim과 집계 이벤트를 기록합니다.

1. Firebase Console에서 `knot-de1a1` 프로젝트의 Anonymous Authentication을 활성화합니다.
2. FlutterFire CLI가 필요하면 설치합니다.

```powershell
dart pub global activate flutterfire_cli
```

3. 다른 Firebase 프로젝트로 교체할 경우 프로젝트 루트에서 앱을 등록합니다.

```powershell
flutterfire configure
```

4. Realtime Database를 만들고 `users/{uid}/claims/{routineId}/{dateKey}` 쓰기 규칙을 trusted backend 기준으로 설정합니다.
5. `flutter run`으로 익명 세션과 claim 기록을 확인합니다.

Web Google 로그인은 `localhost`를 Firebase Authentication의 승인된 도메인에 추가하면 바로 사용할 수 있습니다. Android Google 로그인은 Firebase Console에서 Android 앱을 등록하고 `google-services.json`을 받은 뒤 `flutterfire configure`로 네이티브 설정을 생성해야 합니다. 지금 저장소에 포함된 설정값은 제공받은 Web 앱 설정입니다.

Firebase 초기화와 claim 제출 경계는 [lib/firebase_service.dart](lib/firebase_service.dart)에 있습니다. 서버 멱등성, 중복 claim 방지, 매칭 함수는 다음 단계에서 Cloud Functions로 이동해야 합니다.

## 검증

```powershell
flutter analyze
flutter test
flutter build web
```
