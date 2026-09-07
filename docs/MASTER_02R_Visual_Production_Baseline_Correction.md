# MASTER-02R Visual Production Baseline Correction

> 이 문서의 독립 Reference Area는 제작 언어 보정 근거로 보존한다. 실제 F5 Green Coast Production 적용과 최신 사람 확인 대상은 `MASTER_03_Green_Coast_Production_Build.md`가 우선한다.

## 상태

- **환경 제작 체계 보정·Godot 기술 검증 완료 / 사람 시각 확인 대기**
- 이번 결과는 최종 합격이 아니라 사람 판정용 Visual Production Baseline 후보다.
- 최종 질문은 "이 기준으로 Green Coast 전체와 이후 Region의 환경을 생산해도 되는가?"다.

## 범위와 보존

- MASTER-02의 Terrain 5, Nature 6, Village/Ruins 7, 공유 Material 14개 구조를 유지했다.
- 캐릭터·몬스터·Rig·Animation·Meshy·전체 월드·게임 기능은 범위 밖이다.
- 기존 F5 Main Scene, Save, combat, player, input, Region progression, Boss와 M02/M03/M04/MACRO-01 코드는 수정하지 않았다.
- 최초 실행이므로 stage/commit/push하지 않는다.

## 적용한 프로젝트 Skill

- `rpgpro-lowpoly-modeling`: primitive를 입력으로 쓸 수는 있지만 기본 실루엣이 남으면 production으로 승인하지 않는 규칙을 추가했다. 나무·바위·절벽·폐허·지붕·목책의 큰 형태를 보정했다.
- `rpgpro-material-texture`: 팔레트를 조명과 함께 비교하고 형광·pure cyan·clipped white·crushed black을 거부하는 관계형 보정을 추가했다.
- `rpgpro-visual-slice`: Production Overview와 Gameplay Validation 카메라를 분리하고 첫 성공 렌더 뒤 최소 한 번 실제 보정하는 규칙을 추가했다.

## 실제 보정

### Terrain

- Playable Ground: 지면 상단과 기초 면의 겹침을 제거하고 정확한 4m 연결 면과 단순 보행 충돌을 유지했다.
- Soil Path: 노란 직사각형 판 대신 폭과 중심이 변하는 muted soil ribbon과 소수의 박힌 돌을 사용했다.
- Cliff Straight / Corner: 평평한 Box 측면 대신 큰 삼각 면 변화가 있는 연속 암벽 면, Grass cap, 보조 shoulder rock을 사용했다.
- Ramp / Transition: Soil 표면과 암벽 덩어리, 양측 shoulder rock을 분리하고 단순 경사 충돌을 유지했다.

### Nature

- Tree Base A: taper trunk, 양방향 가지, 서로 다른 크기와 값의 비대칭 faceted canopy 4개로 변경했다.
- Tree Base B: 휜 하단 줄기, 상승 줄기, 긴 해안 방향 가지와 한쪽으로 뻗는 canopy 3개로 A와 다른 실루엣을 만들었다.
- Bush: 단일 구 대신 4개의 비대칭 foliage mass를 사용했다.
- Rock Small / Medium: SphereMesh를 제거하고 flat base, 비대칭 상단, 큰 polygon plane을 가진 별도 boulder 구조를 사용했다. Medium은 scale-up이 아니라 main/shoulder 두 덩어리다.
- Grass: 적은 수의 넓은 low-poly blade cluster로 유지했다.

### Village / Ruins

- Building / Door Wall: 두꺼운 timber frame, stone base, brace, door plank 분할이 큰 카메라 거리에서 읽히도록 했다.
- Roof: overhang과 eave가 읽히는 warm terracotta 계열 지붕으로 바꿨다.
- Ruin Wall: 같은 Box 반복 대신 높이·기울기·상단이 다른 큰 irregular stone block mass로 변경했다.
- Ruin Arch: 독립 lintel이 아니라 두꺼운 pillar와 7개 voussoir, broken crown으로 실제 아치 개구부와 붕괴 실루엣을 만들었다.
- Fence: post가 rail보다 명확히 크고, 약한 taper/skew와 stone foot을 가지도록 했다.

## Palette, Material, Lighting, Water

- Grass는 warm muted green, foliage는 dark/light green family로 낮췄다.
- Path는 orange/yellow에서 muted brown soil로 내렸다.
- Cliff와 masonry는 gray-beige 안에서 역할이 갈리도록 rock cliff, sunlit rock, stone 값을 분리했다.
- Sand는 path보다 밝고 덜 붉은 natural tan으로 유지했다.
- Water는 pure cyan에서 어두운 coastal blue-turquoise로 낮췄다.
- Roof는 warm terracotta, fabric accent는 restrained blue로 분리했다.
- 배경은 안정적인 coastal blue 단색, ambient 0.30, warm sun 0.62, cool fill 0.16으로 구성했다. 첫 렌더에서 발생한 white clipping과 거친 대비를 실제 렌더 뒤 낮췄다.
- Sea는 저비용 Color Block 두 면, 작은 저진폭 vertex motion, 얇은 restrained shoreline band, sand shelf와 sea stack으로 구분했다. 고비용 반사·PBR·dense foam은 사용하지 않았다.

## Reference Area

- 재사용 가능한 실제 환경은 `res://scenes/reference/master_02r_green_coast_area.tscn`이다.
- 작은 전시판에서 House fragment → connected path → nature → ruin arch/wall → cliff → sand/sea가 이어지는 작은 Green Coast 게임 구간으로 재조립했다.
- 모든 18개 모듈을 한 화면에 전시하지 않고 게임 구간의 읽힘을 우선했다.
- Production Overview: `res://scenes/reference/master_02r_production_overview.tscn`
- Gameplay Validation: `res://scenes/reference/master_02r_gameplay_validation.tscn`
- 생성 정본: `res://tools/master_02r_build.gd`

## 내부 렌더 반복

1. 첫 렌더: 조명과 pale material이 과노출되고 Grass/Water가 형광에 가까웠으며 지면 상단이 겹쳤다.
2. 두 번째 렌더: 색과 접지는 안정됐지만 넓은 빈 전시판과 약한 해안 연결이 남았다.
3. 최종 후보: 연속 지면, 측면/전면 절벽, L자 해안, 추가 자연물, 가까운 3/4 Gameplay 카메라로 보정했다.

## 기술 확인

- Godot 4.7.2 headless 생성 성공: Material 14, Terrain 5, Nature 6, Village/Ruin 7, Reference view 2.
- 18개 재사용 asset scene, 공유 Material 14개, Reference scene 4개를 확인했다.
- 생성 asset/reference의 missing `res://` resource 0, `Texture2D` 참조 0을 확인했다.
- 시각 geometry와 분리된 `StaticBody3D` 17개를 확인했다. 장식 foliage/grass에는 불필요한 충돌을 넣지 않았다.
- 두 Reference view의 headless 4-frame scene load가 종료 코드 0이었다.
- 두 Reference view의 실제 1280×720 Compatibility/ANGLE 렌더가 성공했다.
- 기존 `green_coast_m02.tscn`의 headless 및 Compatibility 4-frame smoke가 종료 코드 0이었다.
- 세 프로젝트 Skill은 UTF-8 환경에서 공식 `quick_validate.py`를 통과했고, 6개 Skill 파일에서 사용자 PC 절대경로와 secret 패턴을 찾지 못했다.

## 사람 확인

- Production Overview에서 모듈 연결, 지형 연결과 asset family를 본다.
- Gameplay Validation을 최신 Gameplay Visual Target과 직접 비교한다.
- 형태·밀도·팔레트·조명·해안 분위기가 이후 Region 생산 기준으로 충분한지는 사람이 결정한다.
- 실제 플레이 이동, 장시간 화면, 재미와 최종 디자인은 이번 기술 확인으로 통과 처리하지 않는다.
