# Scenario Reference Registry

## 상태와 사용 규칙

- 기준일: 2026-09-07
- Scenario MCP asset/collection 등록: **대기**. 로컬 MCP 설정은 추가했지만 현재 Codex 프로세스에서 OAuth와 실제 도구 호출을 아직 확인하지 못했다.
- `Scenario asset_id`가 `미등록`인 항목은 로컬 파일만 존재한다. 임의 ID를 만들지 않는다.
- `Human approved`의 `기준 사용 승인`은 사용자가 최신 기준 이미지로 쓰라고 지시했다는 뜻이다. 개별 생산 PNG의 최종 승인을 뜻하지 않는다.
- 우선순위: Gameplay/Assembly/QA 최신 기준 > 최신 환경 Kit > Character identity sheet > 과거 ART-01.
- 원본 판넬의 제목, 라벨, UI, 로고, 설명 문장은 runtime sprite로 추출하지 않는다. 필요한 경우 무텍스트 clean crop을 별도 파일·별도 registry 항목으로 기록한다.

## Canonical 환경 기준

| Reference name | Category | Local path | Scenario asset_id | Role | Priority | Human approved | Kind | 사용 가능한 대상 | 사용 금지 대상 | Notes |
|---|---|---|---|---|---|---|---|---|---|---|
| Gameplay Visual Target | Gameplay | `art/reference/Gameplay Visual Target 1.png` | 미등록 | 최고 화면 스타일·실제 플레이 감각 | P0 | 기준 사용 승인 | Style / Camera / Layout | mood, palette, density, camera feeling, world relationship | isolated sprite geometry 직접 복제, UI·캐릭터 제작 | 캐릭터는 현재 제작 범위 밖 |
| Terrain Assembly Target | Terrain | `art/reference/Terrain Kit A.png` | 미등록 | 사용자 지정 조립 목표 | P0 | 기준 사용 승인 | Layout / Style | modular assembly, non-blocky landscape, transition 결과 관계 | 판넬 라벨·전체 이미지 runtime 사용 | 사용자가 보낸 첫 장 `test.png`의 저장소 보존본. 시트의 역할은 사용자 지정이 우선 |
| Terrain QA Sheet | Terrain | `art/reference/Green Coast Layout Target 2.png` | 미등록 | 사용자 지정 Material/Transition/Module 규격 | P0 | 기준 사용 승인 | Material / Module | plateau, path, stair, cliff, beach, shoreline module 규격과 연결 | 완성 장면의 직접 배경·판넬 텍스트 | 사용자가 보낸 두 번째 `test2.png`의 저장소 보존본. 역할은 사용자 지정이 우선 |
| Green Coast Layout Target | World | `art/reference/Green Coast Layout Target 1.jpeg` | 미등록 | 지역 관계와 조밀도 | P0 | 기준 사용 승인 | Layout / Style | Village, Cliff Path, Ruins, Combat, Beach, Watchtower 구성 | isolated sprite 입력, 라벨 | 실제 게임 구성을 위한 상위 관계 기준 |
| Terrain Kit Core | Terrain | `art/reference/Terrain Kit 2.jpeg` | 미등록 | 절벽·평지 module family | P1 | 기준 사용 승인 | Material / Module | cliff silhouette, plateau, ledge, path module | 제목·라벨·여러 모듈 통째 입력 | 5개 surface sample 추출 원본 |
| Terrain Kit Transition | Terrain | `art/reference/Terrain Kit 1.jpeg` | 미등록 | 경사·계단·해안 transition | P1 | 기준 사용 승인 | Material / Module | ramps, stairs, edge, coast transition | sheet 전체를 sprite로 사용 | 구조 및 seam 기준 |
| Nature Kit Trees | Nature | `art/reference/Nature Kit 2.jpeg` | 미등록 | 나무·관목 family | P1 | 기준 사용 승인 | Style / Module | tree silhouette, scale family, foliage language | 판넬 텍스트·여러 나무가 섞인 직접 입력 | Tree clean crop 후보 |
| Nature Kit Coastal | Nature | `art/reference/Nature Kit 1.jpeg` | 미등록 | 해안 식생·유목·채집물 family | P1 | 기준 사용 승인 | Style / Module | flora clusters, driftwood, ground scatter | 판넬 전체, 라벨 | 작은 자산은 단일 clean crop 우선 |
| Village & Ruins Building Kit | Village/Ruins | `art/reference/Village & Ruins Kit 2.jpeg` | 미등록 | 건물 shell과 roof module | P1 | 기준 사용 승인 | Style / Module | facade, roof, door, awning, porch | 조립 예시를 isolated sprite로 오인 | 지붕 방향·겹침 검증 기준 |
| Village & Ruins Prop Kit | Village/Ruins | `art/reference/Village & Ruins Kit 1.jpeg` | 미등록 | fence, ruin, prop, watchtower family | P1 | 기준 사용 승인 | Style / Module | ruin arch, fence, storage, coastal props | 판넬 전체, 로고·라벨 | Ruin Arch clean crop 후보 |

## Character identity 참고 — 현재 생산 금지

| Reference name | Category | Local path | Scenario asset_id | Role | Priority | Human approved | Kind | 사용 가능한 대상 | 사용 금지 대상 | Notes |
|---|---|---|---|---|---|---|---|---|---|---|
| Goblin Raider Sheet | Character | `art/reference/C37DF9C9-9ED6-4D66-88BE-124DCCBE8089.jpeg` | 미등록 | Goblin family base identity | P2 | 참고 보존 | Identity | 향후 명시 승인된 Goblin family | 현재 캐릭터 생성·runtime 판넬 사용 | Raider master 후보, 아직 승인 자산 아님 |
| Goblin Slinger Sheet | Character | `art/reference/A69DAC31-A7A7-4B90-AE6F-3CDF420DA78E.jpeg` | 미등록 | Goblin role delta | P2 | 참고 보존 | Identity | 향후 Slinger 장비·비율 | 현재 생성 | Raider family와 함께 사용 |
| Goblin Shieldbearer Sheet | Character | `art/reference/AFB30A40-3226-4DBF-94A8-6A4C45619E29.jpeg` | 미등록 | Goblin role delta | P2 | 참고 보존 | Identity | 향후 Shieldbearer 장비·비율 | 현재 생성 | 독립 bare prompt 금지 |
| Goblin Watchcaptain Sheet | Character | `art/reference/D63F8CCE-13BF-4B0E-8347-9E2EAFD3327F.jpeg` | 미등록 | Goblin boss/elite delta | P2 | 참고 보존 | Identity | 향후 Watchcaptain 장비·scale | 현재 생성 | 별도 명시 승인 필요 |
| Coastal Rock Crab Sheet | Creature | `art/reference/28651FD1-10BC-4DB8-A24E-945154E4EB8F.jpeg` | 미등록 | creature identity | P2 | 참고 보존 | Identity | 향후 creature identity | 현재 생성, environment style training | 캐릭터/환경 dataset 분리 |
| Ruin Bat Sheet | Creature | `art/reference/74053A6B-2F6F-4099-BAB5-DF98DF6056A8.jpeg` | 미등록 | creature identity | P2 | 참고 보존 | Identity | 향후 creature identity | 현재 생성, environment style training | 캐릭터/환경 dataset 분리 |
| Mudflat Slime Sheet | Creature | `art/reference/39E14BCE-3EEE-44BA-8574-72582148C9F5.jpeg` | 미등록 | creature identity | P2 | 참고 보존 | Identity | 향후 creature identity | 현재 생성, environment style training | 캐릭터/환경 dataset 분리 |

## Scenario Collection 계획

OAuth와 Team/Project 확인 뒤 다음 Collection을 만들되, 현재는 원격 상태를 생성했다고 기록하지 않는다.

- `RPGpro / Canonical / Gameplay`
- `RPGpro / Canonical / Terrain`
- `RPGpro / Canonical / Nature`
- `RPGpro / Canonical / Village_Ruins`
- `RPGpro / Canonical / Character`
- `RPGpro / Approved_Production`
- `RPGpro / Candidate`
- `RPGpro / Rejected`

Environment Style과 Character Identity를 섞지 않는다. 업로드나 crop 생성 뒤에는 원본 항목, 파생 항목, Scenario asset ID, 승인자, quality-gate 결과를 함께 갱신한다.
