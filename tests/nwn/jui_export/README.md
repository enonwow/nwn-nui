# JUI Export Cases

This folder contains NWN-side JUI export verification fixtures.

## Purpose
- open generated windows in NWN
- compare runtime/exported JUI payloads against expected `.jui` files
- verify parity for component-level exports

## Typical contents
- `itjui_*.jui` expected payloads
- `nuitst_juiopn.nss` open/launcher helper
- `nuitst_juev.nss` event-side helper
- optional `app_*.png` screenshots and compare summaries
