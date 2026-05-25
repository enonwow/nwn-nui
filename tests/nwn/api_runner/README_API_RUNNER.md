# ITNWN API Runner (`nuitst_apirun.nss`)

Purpose: automate a smoke run of NUI tests returned by API.

## What the script does
- downloads test list: `GET /nui-runner/tests-mini` (bootstrap)
- iterates tests on NWN side
- launches each test via `ExecuteScript(script_resref, oPC)`
- after short delay checks whether window opened (`NuiFindWindow`)
- sends result: `POST /nui-runner/results`
- saves runtime `user_data_dump` as `.jui` into run artifacts
- compares runtime `.jui` with expected `.jui` from `tests/app/<case>/` (when uniquely resolvable)
- closes run: `POST /nui-runner/finish`
- API server (default mode) triggers app capture using `capture_test`
- closes window and continues

## Python API server (new)

Server script:
- `tests/nwn/api_runner/itnwn_api_server.py`

On startup server performs preflight:
- verifies `temp0` module path exists
- auto-copies all `.nss` from `tests/app` to `temp0`
- auto-copies runner scripts from `tests/nwn/api_runner` to `temp0`:
  - `nuitst_apirun.nss`
  - `nuitst_apicfg.nss`
- auto-compiles runner scripts to fresh `.ncs` in `temp0` via `nwnsc.exe`:
  - `nuitst_apirun.ncs`
  - `nuitst_apicfg.ncs`
- maintains static launcher scripts (`itap_...`, max 16 chars) inside each `tests/app/<case>/` folder and reuses them across runs
- auto-copies required NWNX include scripts to `temp0` when missing:
  - `nwnx_events.nss`
  - `nwnx_httpclient.nss`
- in `safe` mode unchanged files are skipped; changed collisions fail fast (no silent overwrite)

Default bind:
- host: `127.0.0.1` (or `0.0.0.0` for cross-namespace access)
- port: `51871` (not `8080`)
- scheme: `https` (TLS required by NWNX HTTPClient)

Run:

```powershell
python tests/nwn/api_runner/itnwn_api_server.py
```

PowerShell helper (recommended):

```powershell
powershell -ExecutionPolicy Bypass -File tests/nwn/api_runner/start_api_runner.ps1 -Port 51901
```

`start_api_runner.ps1` does extra automation:
- syncs host/port defaults in:
  - `tests/nwn/api_runner/nuitst_apicfg.nss`
  - `tests/nwn/api_runner/nuitst_apirun.nss`
- auto-generates local TLS cert/key (if missing), and regenerates when SAN host list is incomplete:
  - `tests/nwn/api_runner/certs/itnwn_api_localhost.crt`
  - `tests/nwn/api_runner/certs/itnwn_api_localhost.key`
- trusts that cert in `CurrentUser\Root` (for local machine testing)
- API server also uses single-instance lock per port (`_server_lock_<port>.json`) to prevent multiple overlapping runners on the same host/port.

Optional cleanup of old runner artifacts before start:

```powershell
powershell -ExecutionPolicy Bypass -File tests/nwn/api_runner/start_api_runner.ps1 `
  -CleanupLegacyArtifacts
```

Optional standalone cleanup (keeps 2 newest API runs by default):

```powershell
powershell -ExecutionPolicy Bypass -File tests/nwn/api_runner/cleanup_api_runner_artifacts.ps1
```

If you see TLS handshake errors in NWN/NWNX, verify that:
- runner host in `nuitst_apirun` / `nuitst_apicfg` equals API host,
- cert is trusted in current user root store,
- API is running on the same host/port shown by startup logs.

Custom host + port:

```powershell
powershell -ExecutionPolicy Bypass -File tests/nwn/api_runner/start_api_runner.ps1 -ApiHost localhost -Port 51901
```

Custom NWScript include dir (source for `nwnx_events.nss` + `nwnx_httpclient.nss`):

```powershell
powershell -ExecutionPolicy Bypass -File tests/nwn/api_runner/start_api_runner.ps1 `
  -NwscriptDir "C:\Users\enonw\Documents\NWScript"
```

Custom TLS files:

```powershell
powershell -ExecutionPolicy Bypass -File tests/nwn/api_runner/start_api_runner.ps1 `
  -ApiHost localhost `
  -Port 51901 `
  -TlsCertPath "C:\path\server.crt" `
  -TlsKeyPath "C:\path\server.key"
```

Skip TLS auto-generation:

```powershell
powershell -ExecutionPolicy Bypass -File tests/nwn/api_runner/start_api_runner.ps1 `
  -ApiHost localhost `
  -Port 51901 `
  -SkipTlsCertEnsure
```

Set overwrite mode in starter script call:

```powershell
# force overwrite changed .nss in temp0
powershell -ExecutionPolicy Bypass -File tests/nwn/api_runner/start_api_runner.ps1 -Port 51901 -NssOverwriteMode force

# safe mode (skip unchanged, block changed collisions)
powershell -ExecutionPolicy Bypass -File tests/nwn/api_runner/start_api_runner.ps1 -Port 51901 -NssOverwriteMode safe

# skip temp0 sync entirely (use when files are already deployed and locked by active process)
powershell -ExecutionPolicy Bypass -File tests/nwn/api_runner/start_api_runner.ps1 -Port 51901 -SkipNssSync

# explicit fallback hosts for NWN runner network tries
powershell -ExecutionPolicy Bypass -File tests/nwn/api_runner/start_api_runner.ps1 `
  -ApiHost host.docker.internal `
  -ApiHostFallback 127.0.0.1 `
  -ApiHostFallback2 localhost
```

Custom port:

```powershell
python tests/nwn/api_runner/itnwn_api_server.py --port 51901 --tls-cert "C:\path\server.crt" --tls-key "C:\path\server.key"
```

## Docker option (optional)

From repository root:

```powershell
docker compose --profile nwn up --build api-runner
```

By default this profile runs in safe mode (no temp0 sync / no compile / no capture).  
For real NWN runtime integration, configure `.env.docker` with host paths and run the server directly or adjust container command.

Or via env:

```powershell
$env:ITNWN_API_PORT = "51901"
$env:ITNWN_TLS_CERT = "C:\path\server.crt"
$env:ITNWN_TLS_KEY = "C:\path\server.key"
python tests/nwn/api_runner/itnwn_api_server.py
```

Custom module path (`temp0`):

```powershell
python tests/nwn/api_runner/itnwn_api_server.py --module-path "C:\Users\you\Documents\Neverwinter Nights\modules\temp0"
```

Custom NWScript include dir:

```powershell
python tests/nwn/api_runner/itnwn_api_server.py --nwnscript-dir "C:\Users\you\Documents\NWScript"
```

Env for module path:

```powershell
$env:ITNWN_MODULE_PATH = "C:\Users\you\Documents\Neverwinter Nights\modules\temp0"
$env:ITNWN_NWSCRIPT_DIR = "C:\Users\you\Documents\NWScript"
python tests/nwn/api_runner/itnwn_api_server.py
```

If you intentionally want overwrite during startup sync:

```powershell
python tests/nwn/api_runner/itnwn_api_server.py --force-replace-nss
```

## Module requirements
- NWNX HTTPClient plugin
- NWNX Events plugin
- includes available in compile environment:
  - `nwnx_httpclient.nss`
  - `nwnx_events.nss`

## NWN runner host/port override

`nuitst_apirun` reads module locals:
- `itapi_cfg_host`
- `itapi_cfg_port`

Use helper script:
- `nuitst_apicfg.nss`

Edit constants in that file (`ITAPI_SET_HOST`, `ITAPI_SET_PORT`) and run it once before `nuitst_apirun`.
When you start via `start_api_runner.ps1`, these constants are synced automatically to the same host/port.

## API contract

### `POST /nui-runner/start`
Returns tests list for this run.

Example response:

```json
{
  "ok": true,
  "run_id": "run_20260523_120000",
  "tests_count": 3,
  "tests": [
    {
      "case_id": "nuibutton",
      "script_resref": "itap_ab12cd34ef5",
      "expected_window_id": "IT_NUIBTN_WIN",
      "capture_test": "nuibutton",
      "delay_ms": 1200
    }
  ]
}
```

Fields:
- `case_id` (string)
- `script_resref` (string, NWScript to ExecuteScript)
- `expected_window_id` (string)
- `capture_test` (string, folder under `tests/app`)
- `delay_ms` (int)

### `POST /nui-runner/results`
Payload per test:

```json
{
  "case_id": "itjui_tbtn",
  "script_resref": "nuitst_juiopn",
  "expected_window_id": "ITJUI_TBTN",
  "found_window_id": "ITJUI_TBTN",
  "status": "PASS",
  "opened": 1,
  "window_id_match": 1,
  "open_ack": 0,
  "token": 123,
  "user_data_dump": "{...}"
}
```

API enriches each stored result row with:
- `runtime_jui_file` (relative path under run dir)
- `expected_jui_file` (relative path under repo, when found)
- `jui_compare_status`:
  - `MATCH`
  - `DIFF`
  - `MISSING_EXPECTED`
  - `AMBIGUOUS_EXPECTED`
  - `RUNTIME_NULL`
  - `RUNTIME_INVALID`
  - `MISSING_RUNTIME`
  - `EXPECTED_INVALID`
- `jui_compare_note` (diagnostic text)

Statuses:
- `PASS`
- `NOT_FOUND_AFTER_CREATE`
- `WINDOW_ID_MISMATCH`

## Run
1. Start API (default `127.0.0.1:51871`) or your custom host/port.
2. Run script `nuitst_apirun` in NWN.
3. (Optional) run `nuitst_apicfg` first if you changed host/port.
4. Script subscribes automatically:
   - `NWNX_ON_HTTPCLIENT_SUCCESS`
   - `NWNX_ON_HTTPCLIENT_FAILED`
5. Runner calls `GET /nui-runner/tests-mini`, iterates tests, posts results to `POST /nui-runner/results`, then calls `POST /nui-runner/finish`.
6. `POST /nui-runner/finish` waits for queued app captures to finish before returning summary status.

## Manifest

Default test manifest:
- `tests/nwn/api_runner/tests_manifest.json`

You can replace it or pass a custom file:

```powershell
python tests/nwn/api_runner/itnwn_api_server.py --manifest "C:\path\to\manifest.json"
```

## Current test locations
- integration source tests: `tests/app`
- runner/runtime tools: `tests/nwn`

