# tests/nwn

NWN-oriented suite:
- `jui_export`
- `script_export`
- `menu`
- `api_runner`

Use these fixtures when validating JUI/script export paths in Aurora.

## Tools

- Deploy all `.nss` scripts to module `temp0`:
  - `python tests/nwn/_tools/itnwn_deploy_all_nss.py --dry-run`
  - `python tests/nwn/_tools/itnwn_deploy_all_nss.py --force-replace`
  - script also auto-adds missing NWNX includes from `~/Documents/NWScript`:
    - `nwnx_events.nss`
    - `nwnx_httpclient.nss`
  - custom include source: `--nwnscript-dir "C:\Users\you\Documents\NWScript"`

- Start API runner server (default `https://127.0.0.1:51871`):
  - `python tests/nwn/api_runner/itnwn_api_server.py`
  - custom port: `python tests/nwn/api_runner/itnwn_api_server.py --port 51901`
  - startup preflight checks `temp0` exists and auto-syncs:
    - all `.nss` from `tests/app`
    - runner scripts from `tests/nwn/api_runner` (`nuitst_apirun`, `nuitst_apicfg`)
    - missing NWNX includes (`nwnx_events`, `nwnx_httpclient`)
    - generated launcher wrappers for library-style tests
  - no overwrite by default (`--force-replace-nss` to force)
  - NWNX HTTPClient uses TLS/SSL client mode, so API runner should be HTTPS
  - optional cleanup of legacy artifacts:
    - `powershell -ExecutionPolicy Bypass -File tests/nwn/api_runner/start_api_runner.ps1 -CleanupLegacyArtifacts`
