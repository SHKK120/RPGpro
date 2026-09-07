# MASTER-03R 2.5D Visual Architecture

## 상태

**구조 전환 기반·소형 Green Coast 검증 구간·자동 기술 검증 완료 / 실제 Green Coast 전면 적용과 사람 시각 확인 대기**

MASTER-03 결과를 reset·clean·rollback하지 않고 현재 상태 위에 추가한 전환안이다. 기존 전체 흐름, 저장, 전투, 입력, 카메라, NavMesh, Collision과 3D Terrain 기반은 보존한다. 기존 저품질 환경 Visual Mesh는 삭제하지 않고 2.5D 교체 후보로 분류한다. stage/commit/push하지 않았다.

## SCENARIO-01 생산 레이어

MASTER-03R 구조는 그대로 유지하고, 2.5D visual의 외부 생산 순서만 `rpgpro-scenario-production` Director로 고정한다. 최신 reference와 승인 asset ID를 재사용하고 Godot/Blender proxy를 live schema가 지원하는 control로 전달한 뒤, Scenario consistency·asset analysis·quality gate·최대 2회 refine을 거친 PASS PNG만 `rpgpro-2d5d-asset`으로 반입한다.

현재 공식 Skill·Registry·Camera/Sprite/Quality/Cost 계약은 준비됐지만 Scenario OAuth와 실제 MCP diagnostics/Team/Project/model/tool discovery는 새 Codex 작업에서 확인해야 한다. credit-consuming generation과 model training은 실행하지 않았다. 상세 상태는 `SCENARIO_01_Production_Pipeline.md`를 따른다.

## 구조 전환 이유

- 최신 Green Coast 기준은 선명한 실루엣, 풍부한 표면 정보, 높은 소품 밀도와 읽기 쉬운 해안 단차가 핵심이다.
- 현재 MASTER-03의 기능·물리 구조는 재사용 가치가 높지만, 모든 환경물을 즉시 최종 저폴리 3D로 완성하는 방식은 기준 이미지와의 시각 격차가 크다.
- 게임 규칙과 공간은 3D가 소유하고, 화면 품질에 직접 보이는 환경물은 2.5D 이미지 레이어로 교체 가능한 구조를 우선한다.

## 기준 이미지 사용 규칙

우선순위는 최신 첨부 이미지가 과거 ART-01보다 높다.

- `Gameplay Visual Target 1.png`: 실제 플레이 화면의 밝기, 실루엣, 깊이와 가독성 기준
- `Green Coast Layout Target 1.jpeg`: 해안·절벽·길·거점·유적의 큰 배치 기준
- Terrain/Nature/Village & Ruins Kit: 에셋 family와 재질 언어 기준
- `test.png`: 사용자 지정 **조립 목표**
- `test2.png`: 사용자 지정 **Material / Transition / Module 규격 기준**

판넬 전체, 라벨, 로고, 설명 텍스트를 Sprite나 배경으로 게임에 넣지 않는다. 시트는 판단·규격 자료이며, 런타임에는 독립 투명 에셋, 독립 표면 Material과 독립 3D module만 연결한다.

## 보존·교체 분류

| 분류 | 처리 |
|---|---|
| 3D Gameplay Foundation | Ground, Cliff collision, Ramp, Stairs, 높이, NavMesh, 이동 가능면을 유지 |
| Gameplay Systems | 우클릭 이동, WASD, 전투, Trigger, Camera, Save/Load와 진행 ID를 유지 |
| 2.5D Visual Layer | 나무, 관목, 바위 군집, 집, 소형 건물, 유적, 소품을 Sprite3D/AnimatedSprite3D로 교체 가능 |
| Hybrid | 큰 절벽·건물·유적은 단순 3D 몸체·Collision과 2.5D 전면/장식 레이어를 결합 |
| 교체 후보 | 억지로 완성한 저품질 3D environment visual mesh. 삭제하지 않고 후보로 기록 |
| 현 단계 제외 | 최종 주인공·몬스터 디자인, 최종 방향별 프레임, Region 2 전면 아트 |

## 2.5D 자산 규격

- Alpha가 있는 독립 이미지이며 판넬 텍스트·로고·워터마크가 없어야 한다.
- 비율은 이미지 원본 비율과 `pixel_size × uniform_scale`만 사용한다. X/Y 비균일 Scale을 금지한다.
- `ground_pivot`으로 접지를 정의하고, 시각 크기와 Collision 크기를 분리한다.
- 식생·소형 소품은 Y Billboard, 카메라 각도가 고정된 구조물은 고정 yaw, 캐릭터는 4/8방향 AnimatedSprite3D를 사용한다.
- Actor Scene은 외부 CharacterBody3D가 Collision을 소유한다. 시각 자식에 StaticBody를 중복하지 않는다.
- 환경 시각 프록시는 물리 layer 2를 사용한다. 실제 Terrain과 생산 Actor는 필요한 mask를 명시적으로 조합한다.
- 선택적 바닥 그림자는 투명 radial texture를 사용하며 불투명 사각 plane을 만들지 않는다.

## Material / Transition / Module

레퍼런스 시트의 실제 Grass, Soil/Path, Rock Cliff, Sand, Shallow Water 샘플이 있음을 확인했다. `tools/master_03r_extract_surface_samples.py`는 각 샘플의 내부 정사각 영역만 잘라 좌우·상하 mirror tile로 만든다. 출력은 모두 256×256이며 비율 변형이 없다.

- `surface_samples/grass.png`: Ground cap 시험
- `surface_samples/soil_path.png`: Path module 시험
- `surface_samples/rock_cliff.png`: Cliff side·stone step 시험
- `surface_samples/sand.png`: Beach 시험
- `surface_samples/shallow_water.png`: 움직이는 Water shader의 albedo 기준

이 샘플은 재질 시험용이다. 판넬 전체를 붙이지 않는다. 넓은 바닥과 긴 암벽은 이미지를 확대해 늘이지 않고, 표면 종류별 월드 타일 크기를 고정해 Mesh 실제 폭·깊이 또는 폭·높이에서 UV 반복 횟수를 계산한다. `texture_repeat`를 명시하고 두 축을 별도로 반복하며 한 축 장축 늘이기를 금지한다. Grass→Path, Path→Cliff, Cliff→Beach, Sand→Water 경계는 독립 module 조립으로 확인한다.

## 재사용 Base

- `AssetConfig2D5D`: 유형, facing, texture/frames, pixel size, 균일 scale, pivot, Collision, shadow와 navigation metadata
- `SpriteProp3D`: Billboard 환경 에셋과 독립 CollisionProxy 연결
- `StructureVisual3D`: 고정 카메라 각도의 집·유적·대형 시각 레이어
- `DirectionalSpriteActor3D`: 최종 디자인 없이 4/8방향 이름·fallback을 검증
- `CollisionProxy3D`: Box/Capsule/Cylinder 단순 proxy와 별도 물리 layer

## 검증 씬

### Assembly Validation

`res://scenes/reference/master_03r_assembly_validation.tscn`

실제 3D Ground·Cliff·Beach·Water, 단차 두 곳, 길 세 조각, 해안 계단 다섯 단 위에 Cottage·Broadleaf Tree·Ruin Arch·Rock/Flower visual을 조립한다. 설명 판넬을 배경으로 사용하지 않는다.

### Gameplay Validation

`res://scenes/reference/master_03r_gameplay_validation.tscn`

같은 공간에서 최종 캐릭터 디자인 대신 방향 표시용 기술 marker로 우클릭 이동, 4방향 결정, Visual/Collision 분리와 Cottage proxy 차단·미끄러짐을 확인한다.

## 현재 시험 에셋

환경 4종만 시험 제작했다: Cottage, Broadleaf Tree, Ruin Arch, Rock/Flower Cluster. 주인공과 몬스터는 디자인하지 않았다. `directional_marker.svg`는 방향·이동 코드용 기술 표식이며 최종 캐릭터가 아니다.

생성 원본과 투명 PNG를 분리해 보존하고, `tools/master_03r_prepare_sprites.py`로 Alpha trim, 모서리 투명도, magenta fringe, 원본/출력 비율을 검사한다.

## 기술 검증

- Godot 4.7.2 headless editor import와 script class 등록
- MASTER-03R 자동 검사 48항목: 필수 resource, config, 5종 256×256 표면, Sprite/Collision 분리, 3D foundation, Ground/Cliff world-scale tile 반복, 한글 source text, 4방향, 이동, proxy 반응
- Compatibility / ANGLE 실제 1280×720 렌더 캡처
- 기존 MASTER-03 전체 흐름과 메인 씬은 별도 회귀 검사 대상으로 유지

기계 검증은 사람이 느끼는 최종 시각 품질, 장시간 플레이 가독성, 재미를 승인하지 않는다.

## 최신 화면 비교 결과

- 첫 캡처의 과노출 Grass, 한 축으로 늘어난 Path UV, 사각형 그림자와 평면 slab 인상을 불합격으로 보고 수정했다.
- 현재 캡처는 실제 3D 단차·절벽·해안·계단·수면과 독립 2.5D 환경물이 함께 보이며, 한글이 깨지지 않고 Sprite 원본 비율을 유지한다.
- 최신 목표 이미지보다 vegetation/shoreline module 밀도, 자연스러운 비직선 cliff transition, 물가 foam과 route framing은 아직 부족하다. 현재 결과는 전환 구조 검증이며 최종 Green Coast 아트 합격이 아니다.

## 다음 적용 경계

승인되면 기존 `green_coast_m02.tscn`의 gameplay/collision/nav hierarchy는 유지하고 Visual child만 구역별로 교체한다. Home/Village 한 화면 → Cliff/Path → Ruins → Beach/Vista 순서로 고정 프레임을 비교한다. 각 구역은 교체 전후 기능 회귀와 사람 화면 판정을 분리한다.
