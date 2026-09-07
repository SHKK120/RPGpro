# SCENARIO-01 — Scenario Consistency Production Pipeline

## 현재 판정

과금 없는 로컬 생산 기반은 준비했다. 공식 Scenario MCP URL을 프로젝트 로컬 설정에 OAuth 방식으로 등록했고, 공식 Scenario Skill 11개와 RPGpro Director Skill, Reference Registry, Camera/Sprite/Quality/Cost 규칙을 저장소 범위에 만들었다. 다만 현재 실행 중인 Codex가 변경된 MCP 설정을 다시 읽지 않았고 관리형 PC가 `codex mcp` CLI 실행을 `EPERM`으로 차단하므로, OAuth·diagnostics·Team/Project·model discovery·asset tools의 **실제 연결 검증은 미완료**다.

## 생산 흐름

`Canonical Reference → Approved Asset ID → 3D/2.5D Proxy → live-schema Control → Canonical Baseline + Asset Delta → 기본 Candidate 1장 → Asset Analysis → Quality Gate → 기본 1회 Targeted Refine → Approved RGBA PNG → Godot Sprite3D → Collision/Nav Proxy → Gameplay Camera Validation`

승인 reference가 있을 때 bare prompt로 처음부터 다시 만들지 않는다. Scenario 결과는 visual만 담당하고 Godot의 walkable geometry, navigation, collision, trigger, input, combat, save를 결정하지 않는다.

## 설치·연결 상태

- MCP server: `https://mcp.scenario.com/mcp`
- 로컬 설정: `.codex/config.toml`의 `[mcp_servers.scenario]`; Git 제외 대상
- 인증 정책: OAuth 우선, 토큰/API key는 프로젝트에 기록하지 않음
- 공식 Skill upstream: `scenario-labs/skills`
- 설치 기준 commit: `168e6682d6cd9f2fd4b6196c1c904aa449048e1a`
- 당시 최신 release: `skills-v0.40.1` (2026-09-02)
- 설치일: 2026-09-07
- 설치 경로: `.agents/skills/<skill-name>/`
- 설치 목록: `scenario`, `scenario-image`, `scenario-image-editing`, `scenario-game-assets`, `scenario-consistency`, `scenario-identity-library`, `scenario-model-training`, `scenario-asset-analysis`, `scenario-quality-gate`, `scenario-refine-loop`, `scenario-sprite-animation`
- RPGpro Director: `.agents/skills/rpgpro-scenario-production/`

공식 Skill은 외부 플랫폼 사용법을 소유하고 Director는 RPGpro의 순서·판정·경계를 소유한다. 기존 `rpgpro-2d5d-asset`, `rpgpro-lowpoly-modeling`, `rpgpro-material-texture`, `rpgpro-visual-slice`를 덮어쓰지 않는다.

설치본 중 `scenario-identity-library`의 upstream frontmatter description에는 현재 validator가 금지하는 angle bracket 예시가 있어, 의미를 바꾸지 않고 `character name or prop name`으로 로컬 정규화했다. 나머지는 위 commit 원문이다. 요청된 11개 current environment pipeline sibling은 모두 있다. `scenario-sprite-animation`이 후속 animation lane에서 지시하는 `scenario-video`는 이번 설치 목록 밖이며 현재 캐릭터/animation 범위도 닫혀 있다. 해당 범위를 열 때 공식 sibling을 추가 설치하기 전에는 그 단계를 실행하지 않는다. 이미지 모델 family Skill은 live discovery에서 특정 family를 채택한 뒤 필요한 것만 추가하며 전부 설치하지 않는다.

## 실제 연결 재개 절차

1. 프로젝트 루트에서 새 Codex 작업을 열거나 앱/MCP 서버를 재시작해 `.codex/config.toml`을 다시 읽는다.
2. Scenario OAuth 인증 화면에서 사용자가 자신의 계정 접근을 승인한다.
3. Scenario diagnostics를 호출해 서버 응답과 인증을 확인한다.
4. Team 목록과 Project 목록을 조회한다. 각각 하나면 사용하고, 여러 개이며 RPGpro 대상이 불명확하면 사용자에게 한 번 확인한다.
5. full catalog를 상시 로드하지 않고 현재 단계에 필요한 lean tool discovery로 live image model과 asset/collection tools 노출을 확인한다.
6. live tool schema에서 reference/control/depth/edge와 pricing/dry-run 필드를 확인한다. 기억한 모델명이나 매개변수를 보내지 않는다.
7. Registry의 canonical reference를 올바른 Collection에 등록하고 실제 `asset_id`를 기록한다.

설정 파일의 존재는 연결 성공이 아니다. 위 여섯 실제 응답을 얻기 전에는 MCP 연결 완료로 표시하지 않는다.

현재 프로세스의 MCP resource/template 목록과 도구 catalog를 다시 조회했지만 Scenario server와 diagnostics/team/project/model/asset 도구는 노출되지 않았다. 따라서 이번 작업의 실제 연결 테스트 결과는 **미연결(재시작·OAuth 대기)**이며 Team/Project와 live model은 `미확인`이다.

## Camera Production Standard

현재 실제 prototype `Camera3D`는 perspective, 위치 `(0, 5.35, 10.8)`, 회전 `(-27, 0, 0)`도, FOV `52`다. 생산 batch 전에 활성 scene을 다시 읽어 변경 여부를 확인한다. 환경 Sprite는 이 시점 family, 한 방향 조명, 동일 palette/detail density를 유지하고 자산마다 높이·perspective·focal 느낌을 바꾸지 않는다. 캐릭터 4/8방향은 별도 후속 규격이며 현재 생성 범위가 아니다.

## Sprite Production Contract

- 환경 단일 물체, 전체 실루엣 표시, transparent RGBA PNG 우선
- no text, UI, logo, label, border, unrelated prop, baked environment floor
- bottom-centre ground contact와 filtering 여백
- 원본 aspect ratio 유지; X/Y 독립 늘이기 금지
- 고정 camera family, light direction, palette, material language, detail density
- 승인본만 `assets/art/2p5d/green_coast/{nature,rocks,ruins,buildings,props}/`로 반입
- pivot/scale/facing/filtering은 `rpgpro-2d5d-asset`, 최종 화면은 `rpgpro-visual-slice`가 판정

## Baseline / Delta / Consistency

Baseline은 Green Coast 공통 camera, coastal palette, stylized low-poly material, readable rounded silhouette, detail density, transparent output 규격이다. Delta는 `medium coastal oak, wider canopy, slight lean, no flowers`처럼 달라지는 내용만 적는다. 통과한 Tree A나 Goblin Raider가 있으면 그 asset ID와 family identity를 기준으로 variant/role delta를 만든다. 환경과 캐릭터 reference 및 향후 training dataset은 분리한다.

## Proxy / Control

Godot/Blender proxy는 scale, width/height, footprint, silhouette, orientation, collision intent, simple mass만 전달한다. 못생긴 proxy는 실패가 아니다. 실제 live schema가 지원할 때만 proxy render를 edge/depth/control 입력으로 사용한다. 우선 후보는 tree silhouette, cliff side, ruin arch, building facade, door, large rock이다.

## Quality Gate와 Refine Loop

각 asset은 자동 candidate 1장으로 시작한다. 첫 결과가 사용 가능하면 재생성하지 않는다. Candidate는 style, camera, silhouette, category, palette, detail density, ground contact, background, random prop, UI/text, perspective, Sprite3D suitability, approved-neighbour compatibility 13항목을 PASS/WARN/FAIL로 기록한다. FAIL이 하나라도 있으면 승인본으로 반입하지 않는다.

수정은 가장 큰 원인 1~2개만 골라 targeted edit/regeneration으로 진행하며 자동 Refine은 기본 1회다. 2회째는 남은 실패 원인이 명확하고 사전 합의한 Asset별 누적 CU 상한 안일 때만 허용한다. 좋은 master에서 배경·색·framing·장식·canopy 일부만 틀렸으면 full regeneration보다 image editing을 우선한다. 그 뒤에도 실패하면 prompt/reference/control/model 원인을 보고하고 멈춘다.

## Cost Safety Gate

이번 작업에서 Generation, Edit, Model Training을 실행하지 않았고 Scenario credit 사용은 0이다. 가능한 모든 credit-consuming 호출 전에 `dry_run`을 먼저 실행하고 예상 CU를 기록한다. 첫 호출 전에는 Asset별 누적 CU 상한과 예상 소비량을 사용자에게 보고해 승인을 받으며, 상한을 넘기기 전에 자동 중단한다. Model Training은 generation 승인과 별개로 명시적 승인이 필요하다. Credit add-on 구매·subscription upgrade·결제 페이지·자동 결제는 금지한다.

승인 후 첫 E2E는 Tree A, Medium Rock, Ruin Arch 세 종류 이하만 대상으로 한다. 세 자산이 Godot Gameplay Camera와 사람 확인을 통과하기 전에는 Terrain/Nature/Village 자산을 대량 생산하지 않는다.

## Godot 검증

PASS 이미지에 Sprite3D, 균일 scale, ground pivot, billboard/fixed-angle 규칙, 별도 Collision Proxy를 적용한다. 같은 scene과 실제 gameplay camera에서 perspective, scale, colour, light, ground contact, collage feeling, depth order, clipping, collision mismatch를 함께 본다. 목표는 서로 다른 생성 이미지가 아니라 같은 3D 게임에서 렌더된 자산처럼 보이는 것이다.

## Style Model은 후속 단계

먼저 Reference + Consistency + Control을 시험한다. 반복 결과의 palette/light/material language가 계속 흔들릴 때만 10~15개의 깨끗하고 일관된 environment crop으로 style model을 검토한다. UI·라벨·설명·과거 ART-01·character close-up·중복 이미지는 제외한다. live catalog와 training schema를 확인하고 사용자 승인 없이 train하거나 production default로 지정하지 않는다.
