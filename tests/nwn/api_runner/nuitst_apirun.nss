// =============================================================================
// nuitst_apirun.nss
// ITNWN API runner (MVP):
// - GET /nui-runner/tests-mini (bootstrap list)
// - local iterate over returned tests[]
// - open each script via ExecuteScript
// - verify window open status
// - POST /nui-runner/results
// - POST /nui-runner/finish
//
// Requirements:
// - NWNX HTTPClient plugin enabled
// - NWNX Events plugin enabled
// - API runner reachable over HTTPS/TLS (NWNX HTTPClient uses SSL client)
// - include files available in module compile env:
//      nwnx_httpclient.nss
//      nwnx_events.nss
// =============================================================================

#include "nwnx_httpclient"
#include "nwnx_events"

const string ITAPI_BUILD = "itapi_2026_05_23_r2";

const string ITAPI_WIN_ID_FALLBACK = "ITNWN_UNKNOWN";

const string ITAPI_HOST_DEFAULT = "host.docker.internal";
const string ITAPI_HOST_FALLBACK = "127.0.0.1";
const string ITAPI_HOST_FALLBACK_2 = "localhost";
const int    ITAPI_PORT_DEFAULT = 51871;
const string ITAPI_PATH_TESTS_MINI = "/nui-runner/tests-mini";
const string ITAPI_PATH_RESULTS = "/nui-runner/results";
const string ITAPI_PATH_FINISH = "/nui-runner/finish";

const int ITAPI_DEFAULT_DELAY_MS = 1200;
const int ITAPI_DEFAULT_GAP_MS   = 300;

const string ITAPI_TAG_FETCH_TESTS = "ITNWN_FETCH_TESTS";
const string ITAPI_TAG_POST_RESULT = "ITNWN_POST_RESULT";
const string ITAPI_TAG_FINISH_RUN = "ITNWN_FINISH_RUN";
const int ITAPI_ENABLE_FINISH_POST = FALSE;

const string ITAPI_REQ_KIND_PREFIX   = "itapi_req_kind_";
const string ITAPI_REQ_PLAYER_PREFIX = "itapi_req_player_";
const string ITAPI_CFG_HOST_KEY      = "itapi_cfg_host";
const string ITAPI_CFG_HOST_FALLBACK_KEY = "itapi_cfg_host_fallback";
const string ITAPI_CFG_HOST_FALLBACK_2_KEY = "itapi_cfg_host_fallback_2";
const string ITAPI_CFG_PORT_KEY      = "itapi_cfg_port";

const string ITAPI_LOCAL_TESTS_DUMP = "itapi_tests_dump";
const string ITAPI_LOCAL_INDEX      = "itapi_tests_index";
const string ITAPI_LOCAL_RUNNING    = "itapi_tests_running";

const string ITAPI_LOCAL_CUR_CASE_ID   = "itapi_cur_case_id";
const string ITAPI_LOCAL_CUR_SCRIPT    = "itapi_cur_script";
const string ITAPI_LOCAL_CUR_WINDOW_ID = "itapi_cur_window_id";
const string ITAPI_LOCAL_CUR_DELAY_MS  = "itapi_cur_delay_ms";
const string ITAPI_LOCAL_FETCH_RETRY   = "itapi_fetch_retry";

string ItApiResolveHost()
{
    string sHost = GetLocalString(GetModule(), ITAPI_CFG_HOST_KEY);
    if (sHost != "") return sHost;
    return ITAPI_HOST_DEFAULT;
}

int ItApiResolvePort()
{
    int nPort = GetLocalInt(GetModule(), ITAPI_CFG_PORT_KEY);
    if (nPort < 1 || nPort > 65535) return ITAPI_PORT_DEFAULT;
    return nPort;
}

string ItApiResolveFallbackHost()
{
    string sHost = GetLocalString(GetModule(), ITAPI_CFG_HOST_FALLBACK_KEY);
    if (sHost == ITAPI_HOST_FALLBACK_2)
    {
        // Guard against stale module locals where fallback1 and fallback2 were both localhost.
        return ITAPI_HOST_FALLBACK;
    }
    if (sHost != "") return sHost;
    return ITAPI_HOST_FALLBACK;
}

string ItApiResolveFallbackHost2()
{
    string sHost = GetLocalString(GetModule(), ITAPI_CFG_HOST_FALLBACK_2_KEY);
    if (sHost != "") return sHost;
    return ITAPI_HOST_FALLBACK_2;
}

string ItApiReqKindKey(int nRequestId)
{
    return ITAPI_REQ_KIND_PREFIX + IntToString(nRequestId);
}

string ItApiReqPlayerKey(int nRequestId)
{
    return ITAPI_REQ_PLAYER_PREFIX + IntToString(nRequestId);
}

void ItApiReqRemember(int nRequestId, string sKind, object oPC)
{
    object oMod = GetModule();
    SetLocalString(oMod, ItApiReqKindKey(nRequestId), sKind);
    SetLocalObject(oMod, ItApiReqPlayerKey(nRequestId), oPC);
}

string ItApiReqKindGet(int nRequestId)
{
    return GetLocalString(GetModule(), ItApiReqKindKey(nRequestId));
}

object ItApiReqPlayerGet(int nRequestId)
{
    return GetLocalObject(GetModule(), ItApiReqPlayerKey(nRequestId));
}

void ItApiReqForget(int nRequestId)
{
    object oMod = GetModule();
    DeleteLocalString(oMod, ItApiReqKindKey(nRequestId));
    DeleteLocalObject(oMod, ItApiReqPlayerKey(nRequestId));
}

void ItApiMsg(object oPC, string sMsg)
{
    if (!GetIsObjectValid(oPC)) return;
    SendMessageToPC(oPC, "[ITNWN API] " + sMsg);
}

int ItApiEnsureSubscriptions()
{
    object oMod = GetModule();
    if (GetLocalInt(oMod, "itapi_http_subscribed") == TRUE)
    {
        return TRUE;
    }

    // HTTPClient callbacks.
    NWNX_Events_SubscribeEvent("NWNX_ON_HTTPCLIENT_SUCCESS", "nuitst_apirun");
    NWNX_Events_SubscribeEvent("NWNX_ON_HTTPCLIENT_FAILED", "nuitst_apirun");

    SetLocalInt(oMod, "itapi_http_subscribed", TRUE);
    return TRUE;
}

int ItApiRequestPostResult(object oPC, json jResult)
{
    struct NWNX_HTTPClient_Request s;
    s.nRequestMethod = NWNX_HTTPCLIENT_REQUEST_METHOD_POST;
    s.sTag = ITAPI_TAG_POST_RESULT;
    s.sHost = ItApiResolveHost();
    s.nPort = ItApiResolvePort();
    s.sPath = ITAPI_PATH_RESULTS;
    s.sData = JsonDump(jResult);
    s.nContentType = NWNX_HTTPCLIENT_CONTENT_TYPE_JSON;
    s.nAuthType = NWNX_HTTPCLIENT_AUTH_TYPE_NONE;
    s.sAuthUserOrToken = "";
    s.sAuthPassword = "";
    s.sHeaders = "Accept: application/json|Content-Type: application/json";

    int nRequestId = NWNX_HTTPClient_SendRequest(s);
    if (nRequestId < 0) return nRequestId;
    ItApiReqRemember(nRequestId, "POST_RESULT", oPC);
    return nRequestId;
}

int ItApiRequestTestsMini(object oPC)
{
    struct NWNX_HTTPClient_Request s;
    s.nRequestMethod = NWNX_HTTPCLIENT_REQUEST_METHOD_GET;
    s.sTag = ITAPI_TAG_FETCH_TESTS;
    s.sHost = ItApiResolveHost();
    s.nPort = ItApiResolvePort();
    s.sPath = ITAPI_PATH_TESTS_MINI;
    s.sData = "";
    s.nContentType = NWNX_HTTPCLIENT_CONTENT_TYPE_JSON;
    s.nAuthType = NWNX_HTTPCLIENT_AUTH_TYPE_NONE;
    s.sAuthUserOrToken = "";
    s.sAuthPassword = "";
    s.sHeaders = "Accept: application/json";

    int nRequestId = NWNX_HTTPClient_SendRequest(s);
    if (nRequestId < 0) return nRequestId;
    ItApiReqRemember(nRequestId, "FETCH_TESTS", oPC);
    return nRequestId;
}

int ItApiRequestFinish(object oPC)
{
    struct NWNX_HTTPClient_Request s;
    s.nRequestMethod = NWNX_HTTPCLIENT_REQUEST_METHOD_POST;
    s.sTag = ITAPI_TAG_FINISH_RUN;
    s.sHost = ItApiResolveHost();
    s.nPort = ItApiResolvePort();
    s.sPath = ITAPI_PATH_FINISH;
    s.sData = "{}";
    s.nContentType = NWNX_HTTPCLIENT_CONTENT_TYPE_JSON;
    s.nAuthType = NWNX_HTTPCLIENT_AUTH_TYPE_NONE;
    s.sAuthUserOrToken = "";
    s.sAuthPassword = "";
    s.sHeaders = "Accept: application/json|Content-Type: application/json";

    int nRequestId = NWNX_HTTPClient_SendRequest(s);
    if (nRequestId < 0) return nRequestId;
    ItApiReqRemember(nRequestId, "FINISH_RUN", oPC);
    return nRequestId;
}

int ItApiTryFetchFallback(object oPC)
{
    if (!GetIsObjectValid(oPC) || !GetIsPC(oPC)) return FALSE;

    int nRetry = GetLocalInt(oPC, ITAPI_LOCAL_FETCH_RETRY);
    string sHost = ItApiResolveHost();
    int nReq = 0;

    if (nRetry <= 0 && sHost != ITAPI_HOST_DEFAULT)
    {
        SetLocalString(GetModule(), ITAPI_CFG_HOST_KEY, ITAPI_HOST_DEFAULT);
        SetLocalInt(oPC, ITAPI_LOCAL_FETCH_RETRY, 1);
        ItApiMsg(oPC, "Retry fetch with host=" + ITAPI_HOST_DEFAULT + ".");
        nReq = ItApiRequestTestsMini(oPC);
        if (nReq >= 0)
        {
            ItApiMsg(oPC, "Requested tests fetch from API. request_id=" + IntToString(nReq));
            return TRUE;
        }
    }

    sHost = ItApiResolveHost();
    string sFallback = ItApiResolveFallbackHost();
    if (nRetry <= 1 && sHost != sFallback)
    {
        SetLocalString(GetModule(), ITAPI_CFG_HOST_KEY, sFallback);
        SetLocalInt(oPC, ITAPI_LOCAL_FETCH_RETRY, 2);
        ItApiMsg(oPC, "Retry fetch with host=" + sFallback + ".");
        nReq = ItApiRequestTestsMini(oPC);
        if (nReq >= 0)
        {
            ItApiMsg(oPC, "Requested tests fetch from API. request_id=" + IntToString(nReq));
            return TRUE;
        }
    }

    sHost = ItApiResolveHost();
    string sFallback2 = ItApiResolveFallbackHost2();
    if (nRetry <= 2 && sHost != sFallback2)
    {
        SetLocalString(GetModule(), ITAPI_CFG_HOST_KEY, sFallback2);
        SetLocalInt(oPC, ITAPI_LOCAL_FETCH_RETRY, 3);
        ItApiMsg(oPC, "Retry fetch with host=" + sFallback2 + ".");
        nReq = ItApiRequestTestsMini(oPC);
        if (nReq >= 0)
        {
            ItApiMsg(oPC, "Requested tests fetch from API. request_id=" + IntToString(nReq));
            return TRUE;
        }
    }

    // Last-resort hard retry path: always try docker host if we still have not attempted it.
    sHost = ItApiResolveHost();
    if (nRetry <= 3 && sHost != ITAPI_HOST_FALLBACK)
    {
        SetLocalString(GetModule(), ITAPI_CFG_HOST_KEY, ITAPI_HOST_FALLBACK);
        SetLocalInt(oPC, ITAPI_LOCAL_FETCH_RETRY, 4);
        ItApiMsg(oPC, "Retry fetch with host=" + ITAPI_HOST_FALLBACK + ".");
        nReq = ItApiRequestTestsMini(oPC);
        if (nReq >= 0)
        {
            ItApiMsg(oPC, "Requested tests fetch from API. request_id=" + IntToString(nReq));
            return TRUE;
        }
    }

    return FALSE;
}

json ItApiGetTestsArrayFromResponse(string sResponse)
{
    json jParsed = JsonParse(sResponse);

    if (JsonGetType(jParsed) == JSON_TYPE_ARRAY)
    {
        return jParsed;
    }

    if (JsonGetType(jParsed) == JSON_TYPE_OBJECT)
    {
        json jTests = JsonObjectGet(jParsed, "tests");
        if (JsonGetType(jTests) == JSON_TYPE_ARRAY)
        {
            return jTests;
        }
    }

    return JSON_NULL;
}

int ItApiReadIntOrDefault(json jObj, string sKey, int nDefault)
{
    json jVal = JsonObjectGet(jObj, sKey);
    if (JsonGetType(jVal) == JSON_TYPE_INTEGER)
    {
        return JsonGetInt(jVal);
    }
    if (JsonGetType(jVal) == JSON_TYPE_FLOAT)
    {
        return FloatToInt(JsonGetFloat(jVal));
    }
    if (JsonGetType(jVal) == JSON_TYPE_STRING)
    {
        string s = JsonGetString(jVal);
        if (s != "") return StringToInt(s);
    }
    return nDefault;
}

string ItApiReadStringOrDefault(json jObj, string sKey, string sDefault)
{
    json jVal = JsonObjectGet(jObj, sKey);
    if (JsonGetType(jVal) == JSON_TYPE_STRING)
    {
        return JsonGetString(jVal);
    }
    return sDefault;
}

void ItApiStoreTests(object oPC, json jTests)
{
    SetLocalString(oPC, ITAPI_LOCAL_TESTS_DUMP, JsonDump(jTests));
    SetLocalInt(oPC, ITAPI_LOCAL_INDEX, 0);
}

json ItApiLoadTests(object oPC)
{
    string sDump = GetLocalString(oPC, ITAPI_LOCAL_TESTS_DUMP);
    if (sDump == "") return JSON_NULL;

    json jTests = JsonParse(sDump);
    if (JsonGetType(jTests) != JSON_TYPE_ARRAY) return JSON_NULL;
    return jTests;
}

json ItApiGetTestsArrayFromMiniResponse(string sResponse)
{
    json jParsed = JsonParse(sResponse);
    if (JsonGetType(jParsed) != JSON_TYPE_OBJECT) return JsonArray();

    json jTestsMini = JsonObjectGet(jParsed, "tests");
    if (JsonGetType(jTestsMini) != JSON_TYPE_ARRAY) return JsonArray();

    json jOut = JsonArray();
    int nLen = JsonGetLength(jTestsMini);
    int i = 0;
    while (i < nLen)
    {
        json jRow = JsonArrayGet(jTestsMini, i);
        if (JsonGetType(jRow) == JSON_TYPE_ARRAY && JsonGetLength(jRow) >= 5)
        {
            json jObj = JsonObject();
            jObj = JsonObjectSet(jObj, "case_id", JsonArrayGet(jRow, 0));
            jObj = JsonObjectSet(jObj, "script_resref", JsonArrayGet(jRow, 1));
            jObj = JsonObjectSet(jObj, "expected_window_id", JsonArrayGet(jRow, 2));
            jObj = JsonObjectSet(jObj, "delay_ms", JsonArrayGet(jRow, 3));
            jObj = JsonObjectSet(jObj, "capture_test", JsonArrayGet(jRow, 4));
            jOut = JsonArrayInsert(jOut, jObj);
        }
        i++;
    }

    return jOut;
}

void ItApiRunNextCase(object oPC);
void ItApiCollectAndSendCurrentCase(object oPC);

void ItApiRunNextCase(object oPC)
{
    if (!GetIsObjectValid(oPC) || !GetIsPC(oPC)) return;

    json jTests = ItApiLoadTests(oPC);
    if (JsonGetType(jTests) != JSON_TYPE_ARRAY)
    {
        SetLocalInt(oPC, ITAPI_LOCAL_RUNNING, FALSE);
        ItApiMsg(oPC, "No tests array loaded.");
        return;
    }

    int nIndex = GetLocalInt(oPC, ITAPI_LOCAL_INDEX);
    int nLen = JsonGetLength(jTests);

    if (nIndex < 0 || nIndex >= nLen)
    {
        SetLocalInt(oPC, ITAPI_LOCAL_RUNNING, FALSE);
        if (ITAPI_ENABLE_FINISH_POST)
        {
            int nFinishReq = ItApiRequestFinish(oPC);
            if (nFinishReq >= 0)
            {
                ItApiMsg(oPC, "Run complete. Cases: " + IntToString(nLen) + ". finish_request_id=" + IntToString(nFinishReq));
            }
            else
            {
                ItApiMsg(oPC, "Run complete. Cases: " + IntToString(nLen) + ". finish request failed.");
            }
        }
        else
        {
            ItApiMsg(oPC, "Run complete. Cases: " + IntToString(nLen) + ". (finish POST disabled)");
        }
        return;
    }

    json jCase = JsonArrayGet(jTests, nIndex);
    string sCaseId = ItApiReadStringOrDefault(jCase, "case_id", "case_" + IntToString(nIndex));
    string sScript = ItApiReadStringOrDefault(jCase, "script_resref", "");
    string sWindowId = ItApiReadStringOrDefault(jCase, "expected_window_id", ITAPI_WIN_ID_FALLBACK);
    int nDelayMs = ItApiReadIntOrDefault(jCase, "delay_ms", ITAPI_DEFAULT_DELAY_MS);

    if (sScript == "")
    {
        ItApiMsg(oPC, "Skip " + sCaseId + ": empty script_resref");
        SetLocalInt(oPC, ITAPI_LOCAL_INDEX, nIndex + 1);
        DelayCommand(IntToFloat(ITAPI_DEFAULT_GAP_MS) / 1000.0, ItApiRunNextCase(oPC));
        return;
    }

    SetLocalString(oPC, ITAPI_LOCAL_CUR_CASE_ID, sCaseId);
    SetLocalString(oPC, ITAPI_LOCAL_CUR_SCRIPT, sScript);
    SetLocalString(oPC, ITAPI_LOCAL_CUR_WINDOW_ID, sWindowId);
    SetLocalInt(oPC, ITAPI_LOCAL_CUR_DELAY_MS, nDelayMs);

    ExecuteScript(sScript, oPC);

    float fDelay = IntToFloat(nDelayMs) / 1000.0;
    if (fDelay < 0.1) fDelay = 0.1;
    DelayCommand(fDelay, ItApiCollectAndSendCurrentCase(oPC));
}

void ItApiCollectAndSendCurrentCase(object oPC)
{
    if (!GetIsObjectValid(oPC) || !GetIsPC(oPC)) return;

    string sCaseId = GetLocalString(oPC, ITAPI_LOCAL_CUR_CASE_ID);
    string sScript = GetLocalString(oPC, ITAPI_LOCAL_CUR_SCRIPT);
    string sExpectedWindowId = GetLocalString(oPC, ITAPI_LOCAL_CUR_WINDOW_ID);

    int nToken = 0;
    if (sExpectedWindowId != "")
    {
        nToken = NuiFindWindow(oPC, sExpectedWindowId);
    }

    int bOpened = (nToken != 0);
    string sFoundWindowId = "";
    if (bOpened)
    {
        sFoundWindowId = NuiGetWindowId(oPC, nToken);
    }

    int bWindowMatch = (bOpened && (sFoundWindowId == sExpectedWindowId));

    json jOpenAck = JSON_NULL;
    int bOpenAck = FALSE;
    if (bOpened)
    {
        jOpenAck = NuiGetBind(oPC, nToken, "__it_open_ack");
        if (JsonGetType(jOpenAck) == JSON_TYPE_INTEGER)
        {
            bOpenAck = (JsonGetInt(jOpenAck) != 0);
        }
        else if (JsonGetType(jOpenAck) == JSON_TYPE_STRING)
        {
            bOpenAck = (StringToInt(JsonGetString(jOpenAck)) != 0);
        }
    }

    json jUserData = JSON_NULL;
    if (bOpened)
    {
        jUserData = NuiGetUserData(oPC, nToken);
    }

    string sStatus = "PASS";
    if (!bOpened)
    {
        sStatus = "NOT_FOUND_AFTER_CREATE";
    }
    else if (!bWindowMatch)
    {
        sStatus = "WINDOW_ID_MISMATCH";
    }

    json jResult = JsonObject();
    jResult = JsonObjectSet(jResult, "case_id", JsonString(sCaseId));
    jResult = JsonObjectSet(jResult, "script_resref", JsonString(sScript));
    jResult = JsonObjectSet(jResult, "expected_window_id", JsonString(sExpectedWindowId));
    jResult = JsonObjectSet(jResult, "found_window_id", JsonString(sFoundWindowId));
    jResult = JsonObjectSet(jResult, "status", JsonString(sStatus));
    jResult = JsonObjectSet(jResult, "opened", JsonInt(bOpened));
    jResult = JsonObjectSet(jResult, "window_id_match", JsonInt(bWindowMatch));
    jResult = JsonObjectSet(jResult, "open_ack", JsonInt(bOpenAck));
    jResult = JsonObjectSet(jResult, "token", JsonInt(nToken));
    jResult = JsonObjectSet(jResult, "user_data_dump", JsonString(JsonDump(jUserData)));

    ItApiRequestPostResult(oPC, jResult);

    if (nToken != 0)
    {
        NuiDestroy(oPC, nToken);
    }

    int nIndex = GetLocalInt(oPC, ITAPI_LOCAL_INDEX);
    SetLocalInt(oPC, ITAPI_LOCAL_INDEX, nIndex + 1);

    DelayCommand(IntToFloat(ITAPI_DEFAULT_GAP_MS) / 1000.0, ItApiRunNextCase(oPC));
}

void ItApiHandleHttpSuccess()
{
    int nRequestId = StringToInt(NWNX_Events_GetEventData("REQUEST_ID"));
    string sResponse = NWNX_Events_GetEventData("RESPONSE");

    string sKind = ItApiReqKindGet(nRequestId);
    object oPC = ItApiReqPlayerGet(nRequestId);
    if (sKind == "")
    {
        return;
    }

    if (sKind == "FETCH_TESTS")
    {
        json jTestsMini = ItApiGetTestsArrayFromMiniResponse(sResponse);
        if (JsonGetType(jTestsMini) != JSON_TYPE_ARRAY || JsonGetLength(jTestsMini) <= 0)
        {
            ItApiMsg(oPC, "Tests list is empty or invalid.");
            SetLocalInt(oPC, ITAPI_LOCAL_RUNNING, FALSE);
            ItApiReqForget(nRequestId);
            return;
        }

        int nLen2 = JsonGetLength(jTestsMini);
        ItApiStoreTests(oPC, jTestsMini);
        ItApiMsg(oPC, "Loaded tests: " + IntToString(nLen2));
        SetLocalInt(oPC, ITAPI_LOCAL_RUNNING, TRUE);
        ItApiRunNextCase(oPC);
        ItApiReqForget(nRequestId);
        return;
    }

    if (sKind == "FINISH_RUN")
    {
        ItApiMsg(oPC, "Finish acknowledged by API.");
    }

    // POST_RESULT success: currently no-op beyond debug.
    ItApiReqForget(nRequestId);
}

void ItApiHandleHttpFailed()
{
    int nRequestId = StringToInt(NWNX_Events_GetEventData("REQUEST_ID"));
    string sResponse = NWNX_Events_GetEventData("RESPONSE");

    string sKind = ItApiReqKindGet(nRequestId);
    object oPC = ItApiReqPlayerGet(nRequestId);
    if (sKind == "")
    {
        return;
    }

    ItApiMsg(oPC,
        "HTTP failed kind=" + sKind +
        " request_id=" + IntToString(nRequestId) +
        " response=" + sResponse);

    if (sKind == "FETCH_TESTS")
    {
        if (ItApiTryFetchFallback(oPC))
        {
            ItApiReqForget(nRequestId);
            return;
        }
        SetLocalInt(oPC, ITAPI_LOCAL_RUNNING, FALSE);
    }

    ItApiReqForget(nRequestId);
}

void ItApiStart(object oPC)
{
    if (!GetIsObjectValid(oPC) || !GetIsPC(oPC) || GetIsDM(oPC))
    {
        SendMessageToPC(oPC, "[ITNWN API] Invalid runner target player.");
        return;
    }

    if (!ItApiEnsureSubscriptions())
    {
        ItApiMsg(oPC, "Cannot subscribe NWNX HTTP callbacks.");
        return;
    }

    ItApiMsg(
        oPC,
        "Build=" + ITAPI_BUILD + " " +
        "Runner config host=" + ItApiResolveHost() +
        " port=" + IntToString(ItApiResolvePort()) +
        " fallback1=" + ItApiResolveFallbackHost() +
        " fallback2=" + ItApiResolveFallbackHost2() +
        " (override via module locals: " + ITAPI_CFG_HOST_KEY + ", " + ITAPI_CFG_PORT_KEY + ")"
    );

    SetLocalInt(oPC, ITAPI_LOCAL_FETCH_RETRY, 0);
    int nReq = ItApiRequestTestsMini(oPC);
    if (nReq < 0)
    {
        if (!ItApiTryFetchFallback(oPC))
        {
            ItApiMsg(oPC, "Failed to send GET /nui-runner/tests-mini request.");
        }
        return;
    }

    ItApiMsg(oPC, "Requested tests list from API. request_id=" + IntToString(nReq));
}

void main()
{
    string sNwnxEvent = NWNX_Events_GetCurrentEvent();
    if (sNwnxEvent == "NWNX_ON_HTTPCLIENT_SUCCESS")
    {
        ItApiHandleHttpSuccess();
        return;
    }
    if (sNwnxEvent == "NWNX_ON_HTTPCLIENT_FAILED")
    {
        ItApiHandleHttpFailed();
        return;
    }

    // Direct launch path.
    object oPC = GetLastUsedBy();
    if (!GetIsObjectValid(oPC) || !GetIsPC(oPC))
    {
        oPC = GetFirstPC();
    }
    ItApiStart(oPC);
}

