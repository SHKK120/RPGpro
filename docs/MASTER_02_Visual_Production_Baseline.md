# MASTER-02 — 안정화·제작 Skill·Visual Production Baseline

> MASTER-02의 제작 체계는 유지하지만 최초 화면은 Production Blockout 판정이다. 현재 사람 확인 후보는 `MASTER_02R_Visual_Production_Baseline_Correction.md`와 두 MASTER-02R Reference view를 우선한다.

## 상태

**환경 Production Exemplar 구현·기술 검증 완료 / 실제 플레이·최종 시각 만족도 사람 확인 대기**

기존 M02~M04·MACRO-01·PLAYTEST-01의 구현 및 미확인 상태를 유지한다. 이번 묶음은 새 기능, 캐릭터·몬스터 디자인, Green Coast 전체 재구축이 아니다.

## 현재 시각 우선순위

1. 이번에 사용자가 제공한 최신 기준 이미지
2. 이 문서의 Production Baseline과 신규 환경 exemplar
3. 기존 M05·ART-01 구현 자료

ART-01의 64×64/Nearest Pixel 3D 결과는 삭제하지 않고 `[과거 기술 시험]`으로 보존한다. 새 자산은 **Bright & Warm Stylized Low-Poly Fantasy Adventure 3D**, 큰 형태, 명확한 실루엣, 제한된 색, Color Block, 단순한 공유 Material, 절제된 Texture를 현재 제작 방향으로 사용한다. Pixel influence는 보조이며 텍스처를 일부러 깨져 보이게 만들지 않는다.

## 기준 이미지 계층

1. **Gameplay Visual Target** — `art/reference/Gameplay Visual Target 1.png`: 실제 플레이 카메라에서 길, 절벽, 식생, 폐허, 울타리, 바다, 원경과 전투 정보가 함께 읽혀야 하는 최상위 화면 목표.
2. **Green Coast Layout Target** — `art/reference/Green Coast Layout Target 1.jpeg`: Village, Cliff Path, Ruins, Combat Area, Beach, Watchtower의 공간 관계와 큰 동선 참고. 현재 월드 구조를 그대로 이 이미지로 바꾸라는 명세가 아니다.
3. **Environment Master Asset Sheet** — 별도 단일 파일을 새로 가정하지 않는다. 아래 Terrain, Nature, Village & Ruins 세 모듈군과 공통 Material Family의 관계를 묶는 제작 계층이다.
4. **Modular Terrain Asset Sheet** — `Terrain Kit 1.jpeg`, `Terrain Kit 2.jpeg`.
5. **Nature Asset Sheet** — `Nature Kit 1.jpeg`, `Nature Kit 2.jpeg`.
6. **Modular Village & Ruins Asset Sheet** — `Village & Ruins Kit 1.jpeg`, `Village & Ruins Kit 2.jpeg`.
7. **Character Asset Sheet** — 이번 묶음에서는 주인공을 디자인·모델링하지 않는다. Gameplay Visual Target의 분위기만 향후 제작 요구에 참고한다.
8. **Monster Asset Sheet** — 해안 게, 고블린 Raider/Slinger/Shieldbearer/Watchcaptain, Ruin Bat, Mudflat Slime 시트는 향후 분위기·실루엣·상대 스케일 참고다. 이번 묶음에서 실제 몬스터 디자인이나 모델을 만들지 않는다.

`art/`는 `.gdignore`로 런타임 import에서 제외한다. 기준 이미지는 게임 Texture가 아니며 실행 장면에서 직접 참조하지 않는다.

## 세 제작 Skill의 책임

- `rpgpro-visual-slice`: 무엇이 실제 Godot 화면에서 통과하는가.
- `rpgpro-lowpoly-modeling`: 실루엣, 형태, 스케일, 피벗, 접지, 충돌, NavMesh 경계와 모듈 연결을 어떻게 만드는가.
- `rpgpro-material-texture`: Color Block, 공유 Material Family, 필요한 최소 Texture와 필터링을 어떻게 통일하는가.

세 Skill은 `.agents/skills/` 아래 프로젝트 정본이다. PC 절대경로, 비밀정보, 외부 런타임 캐시를 포함하지 않는다. 도구 설치와 프로젝트 전용 MCP 복구는 `01_환경복구.md`가 소유한다.

## Production Exemplar

경로: `res://scenes/art/green_coast_prod_v01/`

### Terrain — 5

- `playable_ground.tscn`
- `soil_path.tscn`
- `cliff_straight.tscn`
- `cliff_corner.tscn`
- `ramp_transition.tscn`

### Nature — 6

- `tree_base_a.tscn`
- `tree_base_b.tscn`
- `bush.tscn`
- `grass_cluster.tscn`
- `rock_small.tscn`
- `rock_medium.tscn`

### Village / Ruins — 7

- `fence_straight.tscn`
- `fence_corner.tscn`
- `ruin_wall.tscn`
- `ruin_arch.tscn`
- `building_wall.tscn`
- `door_wall.tscn`
- `roof_piece.tscn`

이번 exemplar는 Tier A Godot primitive와 결정적 생성 도구를 사용한다. 지형군은 4m 연결 폭, freestanding asset은 지면 중심 피벗과 local `Y=0` 접지를 시험한다. 이 수치는 새 모듈의 반복 연결을 위한 MASTER-02 시험값이며 전체 게임의 최종 grid 규칙으로 확정하지 않는다.

## Material Family

경로: `res://assets/art/green_coast_prod_v01/materials/`

신규 baseline은 Texture 없이 Color Block 중심의 공유 재질 14개로 시작한다.

- Grass family: `grass`, `grass_foliage_dark`, `grass_foliage_light`
- Soil / Path: `soil_path`
- Rock Cliff: `rock_cliff`, `rock_sunlit`
- Sand: `sand`
- Shallow Water: `shallow_water`
- Wood: `wood`, `wood_dark`
- Stone: `stone`
- Fabric: `fabric_blue`
- Metal: `metal`
- Accent: `accent_warm`

모든 자산별 unique texture를 만들지 않는다. Texture는 이후 실제 화면에서 큰 목재 방향, 넓은 석재 변화, 제한된 천 accent 등 필요성이 확인될 때만 추가하고 해상도와 filtering은 화면 결과로 정한다. 64×64와 Nearest는 새 기본값이 아니다.

## Reference Area

- 장면: `res://scenes/reference/master_02_production_baseline.tscn`
- 재생성: `C:\godot\godot.exe --headless --path <repo> --script res://tools/master_02_build.gd`
- 구성: playable ground/path, straight/corner cliff와 ramp, 두 tree base와 식생·바위, fence, ruin wall/arch, building wall/door/roof, sand, shallow water와 원경 rock.
- 기존 F5 Main Scene, 저장 ID, 입력, 전투, Collision, NavigationMesh에는 연결하지 않은 독립 검증 장면이다.

## 캐릭터·몬스터 향후 메모

이번 묶음에서는 디자인하지 않는다. 나중에 제작 조각이 승인되면 최신 시트의 밝고 따뜻한 저폴리 감각, 큰 실루엣, 단순 재질, 환경과 비슷한 detail density를 적용한다.

- 상대 스케일 표시는 참고값일 뿐 Collider·공격 범위·최종 게임 크기가 아니다.
- Goblin은 공통 Base에서 Raider, Slinger, Shieldbearer, Watchcaptain으로 파생하는 구조를 우선 검토한다.
- Character/Monster 조각에서 neutral multi-view, GLB scale·pivot, Blender cleanup, rig, animation, Godot import와 gameplay-camera 검증 요구를 먼저 닫는다.
- Meshy나 유료 외부 생성은 별도 사용자 승인 전 실행하지 않는다.

## 기술 검증

- Godot 4.7.2 headless editor import·파싱: 성공.
- 생성 도구: Material 14, Terrain 5, Nature 6, Village/Ruin 7, Reference Area 1 생성 성공.
- Reference Area headless scene load: 성공.
- 1280×720 Compatibility/ANGLE 렌더: 성공. Intel HD Graphics 530의 알려진 OpenGL 품질 경고로 ANGLE을 사용했다.
- 기존 F5 Main Scene 4프레임 headless smoke: 성공.
- 기존 F5 Main Scene 1280×720 Compatibility/ANGLE 일반 그래픽 시작: 시작 메뉴 표시까지 성공. 실제 메뉴 입력과 전체 루프는 미확인이다.
- 신규 자산은 독립 장면에만 있어 기존 M02/M03/M04/MACRO Save·입력·NavMesh를 변경하지 않는다.

## 사람 확인 대기

- 최신 Gameplay Visual Target으로 향하는 초기 production set으로 형태·색·재질 언어가 타당한가.
- path, cliff, vegetation, fence/ruin과 coast가 같은 세트로 읽히는가.
- 반복 자산의 단순함과 현재 화면 밀도가 이후 Green Coast 실제 적용에 충분한가.
- 실제 F5 전체 루프, Save/Quit/Continue, 전투 체감과 최종 시각 만족도는 이번 기술 검사만으로 통과 처리하지 않는다.

stage/commit/push하지 않은 로컬 상태다.
