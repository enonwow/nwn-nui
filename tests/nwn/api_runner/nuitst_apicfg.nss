// ============================================================================
// nuitst_apicfg.nss
// Helper: set API host/port for ITNWN API runner without touching runner code.
// Run once in module, then run `nuitst_apirun`.
// ============================================================================

const string ITAPI_CFG_HOST_KEY = "itapi_cfg_host";
const string ITAPI_CFG_HOST_FALLBACK_KEY = "itapi_cfg_host_fallback";
const string ITAPI_CFG_HOST_FALLBACK_2_KEY = "itapi_cfg_host_fallback_2";
const string ITAPI_CFG_PORT_KEY = "itapi_cfg_port";

// Change these two values when needed.
const string ITAPI_SET_HOST = "host.docker.internal";
const string ITAPI_SET_HOST_FALLBACK = "127.0.0.1";
const string ITAPI_SET_HOST_FALLBACK_2 = "localhost";
const int    ITAPI_SET_PORT = 51871;

void main()
{
    object oPC = GetLastUsedBy();
    if (!GetIsObjectValid(oPC) || !GetIsPC(oPC))
    {
        oPC = GetFirstPC();
    }

    SetLocalString(GetModule(), ITAPI_CFG_HOST_KEY, ITAPI_SET_HOST);
    SetLocalString(GetModule(), ITAPI_CFG_HOST_FALLBACK_KEY, ITAPI_SET_HOST_FALLBACK);
    SetLocalString(GetModule(), ITAPI_CFG_HOST_FALLBACK_2_KEY, ITAPI_SET_HOST_FALLBACK_2);
    SetLocalInt(GetModule(), ITAPI_CFG_PORT_KEY, ITAPI_SET_PORT);

    if (GetIsObjectValid(oPC))
    {
        SendMessageToPC(
            oPC,
            "[ITNWN API] Config set: host=" + ITAPI_SET_HOST +
            " port=" + IntToString(ITAPI_SET_PORT) +
            " fallback1=" + ITAPI_SET_HOST_FALLBACK +
            " fallback2=" + ITAPI_SET_HOST_FALLBACK_2
        );
    }
}

