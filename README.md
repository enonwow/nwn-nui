# NWN NUI Builder

Build, preview, export, and validate **Neverwinter Nights: Enhanced Edition (NWN:EE)** NUI layouts with a browser-based editor, then verify runtime behavior with automated NWN-side integration tooling.

This repository combines:
- a React/Vite NUI builder app (`nui-builder`)
- curated fixture/test cases (`tests/app`)
- NWN runtime export/API runner tooling (`tests/nwn`)

---

## Table of Contents

1. [Project Goals](#project-goals)
2. [Repository Layout](#repository-layout)
3. [Core Capabilities](#core-capabilities)
4. [Quick Start (UI Builder)](#quick-start-ui-builder)
5. [Docker Quick Start](#docker-quick-start)
6. [Testing Strategy](#testing-strategy)
7. [NWN Runtime Integration Flow](#nwn-runtime-integration-flow)
8. [API Runner Contract (Summary)](#api-runner-contract-summary)
9. [Conventions and Constraints](#conventions-and-constraints)
10. [CI and GitHub Usage](#ci-and-github-usage)
11. [Troubleshooting](#troubleshooting)
12. [Roadmap](#roadmap)
13. [Contributing](#contributing)

---

## Project Goals

This project exists to reduce NUI authoring friction and tighten the loop between:
- **visual authoring** in a modern browser UI,
- **script/JUI generation** for NWN:EE,
- **runtime verification** against real NWN behavior.

Design philosophy:
- Aurora/NWN runtime rules come first.
- Custom helpers are wrappers/extensions, never replacements for engine semantics.
- Test coverage should guard both export correctness and runtime parity.

---

## Repository Layout

```text
.
|-- .github/
|   `-- workflows/
|       `-- nui-builder-ci.yml
|-- nui-builder/
|   |-- public/
|   |-- src/
|   |   |-- custom-components/
|   |   |-- data/
|   |   |-- demo/
|   |   |-- demo-assets/
|   |   `-- lib/
|   |-- tools/
|   `-- package.json
`-- tests/
    |-- app/
    |   |-- <fixture-cases>/
    |   `-- _tools/
    `-- nwn/
        |-- api_runner/
        |-- jui_export/
        |-- menu/
        |-- script_export/
        |-- _artifacts/
        `-- _tools/
```

Additional docs:
- `tests/README.md`
- `tests/app/README.md`
- `tests/nwn/README.md`
- `tests/nwn/api_runner/README_API_RUNNER.md`

---

## Core Capabilities

### 1) Visual NUI authoring
- Build layout trees from NWN components/modifiers/values.
- Live canvas preview with structure/property panels.
- Demo/Test loaders for curated scenarios.

### 2) Export pipeline
- Generate:
  - `.jui`
  - `.nss` layout/script output
  - event-script scaffolds
  - optional helper library (`lib_nui` usage paths)

### 3) Validation-aware workflow
- Property validation for common NWN constraints (including float style in many fields).
- Feedback in output/validation UX to catch invalid graph state before export.

### 4) Runtime-oriented test coverage
- App-level fixtures and integration cases (`tests/app`).
- NWN-side integration runner (`tests/nwn/api_runner`) for in-engine checks.
- JSON/JUI result capture and compare flow for parity tracking.

---

## Quick Start (UI Builder)

### Requirements
- Node.js 20+
- npm 10+ (or compatible)

### Install

```powershell
cd nui-builder
npm ci
```

### Run local dev server

```powershell
npm run dev
```

Default Vite local URL:
- `http://127.0.0.1:5180/`

### Build

```powershell
npm run build
```

### Typecheck

```powershell
npm run typecheck
```

---

## Docker Quick Start

If you do not want to install Node/Python locally, you can run the project via Docker.

### Prerequisites
- Docker Desktop
- Docker Compose v2

### Start UI builder (recommended default)

```powershell
docker compose up --build ui
```

Open:
- `http://127.0.0.1:5180/`

### Stop services

```powershell
docker compose down
```

### Optional: run preview image (production-like)

```powershell
docker compose --profile preview up --build ui-preview
```

Open:
- `http://127.0.0.1:4173/`

### Optional: run API runner container

```powershell
docker compose --profile nwn up --build api-runner
```

Notes:
- This profile starts API runner in safe container mode (`--skip-nss-sync`, `--skip-runner-compile`, `--disable-app-capture`).
- For real NWN integration, provide host paths for `temp0` and `NWScript` using `.env.docker`.

### Docker env template

Copy:
- `.env.docker.example` -> `.env.docker`

Then adjust ports/paths as needed.

---

## Testing Strategy

Testing is split between **app-side** and **NWN runtime-side**.

### App-side checks

From `nui-builder`:

```powershell
npm run test
npm run test:contracts
```

Optional visual/image helpers:

```powershell
npm run image:capture:app
npm run image:compare
npm run image:compare:set
npm run image:compare:e2e
```

### Fixture corpus (`tests/app`)

`tests/app` contains canonical feature fixtures (component families, drawlist, list behavior, encourage/sync scenarios, etc.) used by:
- import/export checks
- runtime runner scripts
- parity diagnostics

See:
- `tests/app/README.md`
- `tests/app/TEST_RESULTS.md`

### NWN-side suite (`tests/nwn`)

Main domains:
- `jui_export`
- `script_export`
- `menu`
- `api_runner`

See:
- `tests/nwn/README.md`
- `tests/nwn/TEST_RESULTS.md`

---

## NWN Runtime Integration Flow

The API runner enables a practical E2E pass:
1. Start local API runner (HTTPS/TLS).
2. Provide test list to NWN runner script.
3. NWN executes scripted cases.
4. Runtime status + dumped data are POSTed back.
5. Finish endpoint returns run summary.

Primary references:
- `tests/nwn/api_runner/README_API_RUNNER.md`
- `tests/nwn/api_runner/itnwn_api_server.py`
- `tests/nwn/api_runner/nuitst_apirun.nss`
- `tests/nwn/api_runner/nuitst_apicfg.nss`

### Typical local runner start

```powershell
powershell -ExecutionPolicy Bypass -File tests/nwn/api_runner/start_api_runner.ps1
```

### Deploy scripts to module `temp0` (manual utility)

```powershell
python tests/nwn/_tools/itnwn_deploy_all_nss.py --dry-run
python tests/nwn/_tools/itnwn_deploy_all_nss.py --force-replace
```

---

## API Runner Contract (Summary)

Endpoints:
- `POST /nui-runner/start`
- `POST /nui-runner/results`
- `POST /nui-runner/finish`

Returned/transported entities include:
- case identifiers
- script resrefs
- expected/found window ids
- open/match status
- runtime dumps for comparison

For full payload schema and examples, use:
- `tests/nwn/api_runner/README_API_RUNNER.md`

---

## Conventions and Constraints

### NWScript and NWN constraints
- Respect NWScript naming/resref limits where required (commonly 16-char constraints in practical flows).
- Keep runtime compatibility first; app abstractions must not violate Aurora behavior.

### Numeric formatting
- Where floating values are required, use explicit dot notation (for example `180.0`).

### UI design guidance
- Default design intent is **1:1 scale** for layout authoring.
- Use preview scaling as inspection aid, not as canonical layout target.

### Test artifact hygiene
- Runtime artifacts are generated under `tests/nwn/_artifacts`.
- Temporary logs/caches should stay out of git history.

---

## CI and GitHub Usage

Current workflow:
- `.github/workflows/nui-builder-ci.yml`

It verifies:
- dependency install (`npm ci`)
- TypeScript typecheck
- tests
- production build

Trigger scope:
- changes under `nui-builder/**`
- CI workflow file updates

If you want GitHub Pages hosting, either:
- add a dedicated Pages workflow that builds `nui-builder` and deploys `nui-builder/dist`, or
- publish `dist` through your existing release/deploy pipeline.

---

## Troubleshooting

### Blank page on `127.0.0.1:5180`
- Check browser console for runtime errors.
- Reinstall dependencies:
  - `cd nui-builder`
  - `npm ci`
- Restart dev server.

### NWN HTTPClient cannot connect
- Confirm API runner is running and reachable on configured host/port.
- Ensure TLS/certificate setup matches NWNX HTTPClient expectations.
- Verify host fallback settings in `nuitst_apicfg` / runner config.
- Confirm module path and script sync succeeded (`temp0` present, scripts compiled).

### Missing NWNX includes
- Ensure `nwnx_events.nss` and `nwnx_httpclient.nss` are available in include source.
- Use deployment tools/scripts described in `tests/nwn/README.md`.

### Script compiles but runtime mismatch exists
- Compare exported JUI/JSON output with expected fixtures.
- Inspect `_artifacts` run logs and payload snapshots.
- Validate component constraints (single-child wrappers, value types, bind initialization).

---

## Roadmap

Planned/high-value directions:
- stronger visual parity checks between builder and NWN runtime
- improved list/drawlist edge-case diagnostics
- richer automation for screenshot + JUI parity runs
- expanded lexicon/knowledge UX around components and engine behavior

---

## Contributing

Recommended contribution flow:
1. Keep changes scoped (builder vs tests vs runner).
2. Add/adjust fixtures in `tests/app` when behavior changes.
3. Run local checks:
   - `npm run typecheck`
   - `npm run test`
   - `npm run build`
4. For runtime-sensitive changes, run relevant `tests/nwn` flow.
5. Update docs when behavior/contracts/workflow changed.

When in doubt, choose engine parity over UI convenience.

---

If you are onboarding from scratch, start with:
- `tests/README.md`
- `tests/nwn/api_runner/README_API_RUNNER.md`
- `nui-builder/src` (data + lib + custom-components)
