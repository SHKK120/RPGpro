# MASTER-03 Green Coast Production Build + Full Playtest

> 이 결과는 삭제·rollback하지 않고 보존한다. 다만 2026-09-07 이후 환경 시각 제작의 우선 구조는 `MASTER_03R_2D5D_Visual_Architecture.md`의 3D Gameplay + 2.5D Visual이며, 이 문서의 모든 환경물을 최종 3D mesh로 완성한다는 목표는 더 이상 우선하지 않는다.

## 상태

**환경 Production Kit 확장·실제 Green Coast 통합·자동 전체 흐름 검증 완료 / 사람 시각·실조작 확인 대기**

이번 묶음은 MASTER-02R의 작은 Reference Area를 실제 F5 Green Coast로 확장한 첫 Production Build다. 주인공·몬스터 디자인, Rig/Animation, 외부 AI 3D, Region 2 Production Art는 범위 밖이다. 기존 M02→M03→M04→MACRO-01 기능과 Save ID를 보존했다. stage/commit/push하지 않았다.

## Production Standard

실제 플레이어 Capsule 높이 2.0m·반지름 0.55m와 M02 NavMesh agent 높이 2.0m·반지름 0.75m를 기준으로 삼았다. 연결 모듈은 MASTER-02R의 4m 기준면을 유지한다.

| 항목 | MASTER-03 기준 |
|---|---|
| 문 | 약 1.34m × 2.10m |
| 창 | 약 1.30m × 1.18m |
| 계단 | 폭 1.75~2.80m, 완만한 대체 경사 Collision |
| 목책 | 4m 연결, 높이 약 1.5m |
| 길 | 좁음 1.55m / 기본 2.25m / 넓음 3.0m |
| 전투 바닥 | 기본 10m × 8m |
| 절벽 | 4m 연결면, 약 4m 낙차 표현 |
| 경사로 | 폭 2.0m 또는 3.4m, 길이 약 4.3m |
| 나무 | 몸통 약 3.3m, 수관 포함 약 4~5m |
| 관목·바위 | 플레이어 무릎~가슴 높이의 소·중·대 실루엣 |
| 유적 아치 | 4m 모듈, 두 기둥 사이 약 1.8m 이상 |
| 건물 벽 | 4m × 2.7~2.9m |
| Watchtower | 약 6.5m landmark 실루엣 |

Freestanding 자산은 local Y=0 접지, 지형은 4m 연결면 중심 pivot을 사용한다. 재사용 asset scene에는 단순 Collision을 포함하지만 실제 Green Coast 통합 layer에서는 기존 검증 Collision/NavMesh가 정본이므로 인스턴스 Collision을 끄고 시각만 교체한다.

## 기존 18개 A/B/C Audit

- A — 현재 구조 유지·실제 월드 재사용: Soil Path, Tree A/B, Rock Small/Medium, Fence Straight/Corner, Ruin Wall/Arch, Building Wall, Door Wall, Roof Piece 12개.
- B — 실제 보강 후 재생성: Playable Ground, Cliff Straight, Cliff Corner, Ramp Transition, Bush, Grass Cluster 6개. edge variation, shoulder/foot rock, 비대칭 foliage mass와 추가 blade를 보강했다.
- C — 전면 폐기: 0개. MASTER-02R에서 primitive-only 형태를 이미 제거했기 때문에 이번에는 검증된 형태 언어를 확장했다.

## Production Kit 결과

- Material Family 22개: 기존 14개에 wet sand, building plaster, roof terracotta, white/yellow/purple flower, rope, water foam을 추가했다. 첫 라이브 렌더 뒤 roof/accent를 `#94482f`로 낮췄다.
- Terrain 35 scenes: large/medium/small ground, transition, combat ground, straight/corner/T/wide/narrow/irregular path, cliff inner/outer/end/ledge/plateau/transition, wide/narrow ramp, natural/stone/small steps, sand/rocky beach/beach/cliff/water/shore transition, large rock, sea stack 등을 포함한다.
- Nature 18 scenes: Tree A/B/C, bush small/medium, grass와 3색 flower, coastal plant/reed, long/short log, stump, driftwood, rock family를 포함한다.
- Village/Ruins 29 scenes: wall/door/window/corner/roof/gable/porch/stair/foundation, fence straight/corner/gate/end/broken, ruin wall/corner/arch/column/broken/rubble, sign/lantern/banner/crate/barrel/rope/fishing rack/dock/watchtower를 포함한다.
- 총 82 reusable scenes, 공유 Material 22개, scene 내부 StaticBody3D 49개, missing `res://` reference 0개다.

생성 정본은 `res://tools/master_03_build.gd`, 출력은 기존 `green_coast_prod_v01` 경로를 확장한다. MASTER-02R 자산을 별도 버전으로 복제하지 않아 동일 family의 중복 정본을 만들지 않았다.

## 실제 Green Coast 통합

F5 장면 root가 `master_03_green_coast.gd`를 사용하고 이 스크립트가 기존 `macro_01_game.gd`를 상속한다. 기존 기능 코드는 수정하지 않고 다음 영역을 실제 gameplay scene에 조립했다.

- Home/Village: 기존 Hut Collision에 맞춘 cottage shell·roof·porch·stairs, yard fence/gate, crate/barrel, sign/lantern/banner, stateful bench/display/trophy/Region gate.
- Cliff Path: 기존 loop와 shortcut 위에 irregular path family를 반복하고 북·서 경계에 grass cap과 faceted cliff face를 연결했다.
- Nature/Forest: 기존 여섯 tree collision 위치를 Tree A/B/C로 교체하고 edge trees, bush, grass/flower, log/stump를 보강했다.
- Ruins/Secret: 기존 wall collision과 souvenir 위치에 arch, wall, corner, broken column, rubble, overgrowth를 배치했다.
- Combat: 기존 적 위치와 공격 로직을 유지하고 path와 ruin landmark로 공간을 구분했다.
- Beach/Coast: sand/wet band/shallow water/foam, shore rocks, sea stack, driftwood, reed, dock/fishing rack/rope를 구성했다.
- Vista/Landmark: 북쪽 절벽 자동 Vista와 바다·sea stack, 동북 watchtower가 같은 화면에서 읽히게 했다.
- Boss Area: 기존 Arena/NavMesh/입구 barrier를 유지하고 wide combat ground, ruin arch/walls/columns로 외곽을 다시 읽히게 했다.

기존 Green Coast의 main loop와 좁은 return shortcut, Ruin secret, Vista, 동쪽 Boss route를 유지해 Handcrafted Connected Open-Zone의 한 바퀴를 보존했다. Region 2는 흐름과 고산 prototype만 유지하고 Production Art를 적용하지 않았다.

## Material, Lighting, Water

- Grass/soil/rock/building stone/sand/wet shore/water/wood-dark wood/blue fabric/light-dark vegetation을 공유 family로 유지했다.
- Texture를 새로 만들지 않고 Color Block과 geometry separation을 먼저 사용했다.
- 실제 F5에서는 background `#6fa7c3`, ambient 0.42, warm sun 0.78, cool fill 0.14를 사용한다.
- 물은 Compatibility shader의 작은 vertex motion과 얇은 shallow/foam band만 사용하며 반사·dense foam·고비용 post effect를 넣지 않았다.

## Collision과 Navigation

- 실제 gameplay는 기존 `m02_navigation_mesh.tres`, M04 runtime NavigationRegion, Region 2 NavigationRegion을 유지한다.
- Production asset Collision은 scene inspection과 이후 재사용을 위한 단순형이다. 실제 world layer에서는 중복 충돌을 비활성화했다.
- 지면·Hut·tree trunk·ruin wall·arena collision과 상태/저장 root는 삭제하거나 이름을 바꾸지 않았다.
- 자동 검사에서 Home→Ruin 경로가 2점 이상으로 연결되고 destination 수락과 WASD 이동을 확인했다.

## Full Playtest 결과

`res://tools/master_03_verify.gd`가 격리 Save를 사용해 32개 검사를 통과했다.

1. New Game와 Production layer 생성
2. WASD 이동, 우클릭 목적지 수락, Green Coast 연결 경로
3. 목재 5·돌 3, Ruin 기념품, Vista 진입·복귀
4. Bench 설치와 기념품 전시
5. 고정 적 5기 격파, Monster Core 획득, Blade +1
6. Boss 진입, 치명 사망 뒤 Scene 유지·HP/Phase 초기화·재시도
7. Boss 격파, Tide reward, Trophy 전시, Blade +2, Green Coast 완료
8. Region 2 진입, Ore·Homestead·제작, Home 귀환
9. Save, 새 scene에서 Continue, 진행·무기·Trophy·귀환 지역 복원
10. M02 필수키만 있는 version 1 구세이브 형식 허용

이는 엔진 입력/action과 메서드 기반 자동 검증이다. 사람이 실제 F5에서 마우스 감각, 장시간 전투 난이도·재미, 화면 만족도를 확인하기 전 최종 통과로 표시하지 않는다.

## 실제 Gameplay Capture

`res://tools/master_03_capture.gd`는 실제 `green_coast_m02.tscn`을 열고 Home, Cliff, Ruins, Beach, Vista, Boss, Overview 카메라를 재현한다. 1280×720 Compatibility/ANGLE에서 실제 frame을 생성했다. 첫 live render 뒤 roof/accent 과포화를 낮추고 다시 렌더했다. 결과 PNG는 `.godot/`의 사람 확인용 로컬 산출물이며 Git 정본이 아니다.

## 사람 확인 대기

- Green Coast가 이후 구조 재작업 없이 콘텐츠 밀도와 자산을 추가할 수 있는 Production Base인가.
- 같은 4m 연결·scale/pivot/collision/material family 규칙을 이후 Region에 재사용해도 되는가.
- 실제 F5에서 길/shortcut/secret/boss 입구와 상호작용이 충분히 읽히는가.
- 장시간 화면, 실제 키·마우스 체감, 전투 난이도·재미와 최종 캐릭터/몬스터 시각은 미확인이다.

사용자 승인 전 시각·재미·디자인을 통과 처리하지 않는다.
