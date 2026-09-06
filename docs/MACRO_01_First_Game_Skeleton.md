# MACRO-01 — First Game Skeleton

## 상태

**PHASE B 구현중·기술 실행 확인 대기**

M05 Visual Baseline을 유지한 채 기존 `green_coast_m02.tscn`의 상속 구조 위에 전체 게임 골격을 얇게 연결했다. 명칭·수치·지역 테마는 `[MACRO-01 시험 선택]`이며 최종 디자인이 아니다.

## 실행

- F5 메인 장면: `res://scenes/prototype/green_coast_m02.tscn`
- 시작 흐름: New Game / Continue → Home·Green Coast
- Region 1 완료 조건은 기존 M04의 Green Coast 완결 상태를 재사용한다.

## 구현 범위

- 검 메시와 함께 회전하는 `Area3D`에 실제로 접촉한 적만 한 휘두르기당 1회 피해를 받는다.
- Home: Rest·기존 강화, Storage, Trophy, Region Progress, Basic/Coastal 테마, Region Gate, Region 2 제작 슬롯.
- Region 2 Prototype: 별도 NavigationRegion, Entry·Main Path·Highland Ore 4개·강한 적 1체·Broken Beacon Landmark·자동 Vista·두 번째 집터·봉인된 Future Boss 공간·귀환 통로.
- Region 2에서 Ore 3개를 가져오면 Home에서 고정 `Highland Lamp`를 제작한다.
- 기존 save_v1을 확장해 지역, 자원, 집터, Storage, 테마, 제작 결과를 저장한다. 새 키가 없는 M02~M04 저장은 안전한 기본값으로 읽는다.

## 이번 시험 선택

- Region 2 작업 테마는 바람 부는 고지대이며 정식 지역명은 정하지 않는다.
- `Highland Ore`, `Highland Sentinel`, `Broken Beacon`, `Highland Lamp`는 구조 검증용 시험명이다.
- 자유 인벤토리·자유 가구 배치·집 전체 이전·Region 2 보스·범용 퀘스트는 만들지 않는다.

## 기술 확인 상태

- 정적 확인: 신규 리소스 참조 존재, 괄호 구조 균형, 메인 씬의 MACRO 컨트롤러 연결, 기존 거리·전방 단일 대상 공격 판정 제거.
- 미확인: Godot 명령 실행기가 `Access Denied`로 프로세스 실행을 차단해 파싱·일반 그래픽 실행·F5 전체 루프는 아직 통과 처리하지 않는다.

## 사람 확인 예정

1. New Game → Home → Green Coast 완료 → Home → Region 2 → Home 흐름.
2. Region 2의 새 자원·강한 적·Landmark·Vista·집터와 Home 제작 결과.
3. 저장 후 Continue에서 Region 진행·Storage·Theme·Trophy·Region 2·집터·제작 결과 유지.

stage/commit/push하지 않은 로컬 상태다.
