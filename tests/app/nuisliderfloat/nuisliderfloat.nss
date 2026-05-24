// =============================================================================
// nuisliderfloat.nss
// Integration test: one window + one NuiSliderFloat.
// =============================================================================

#include "nw_inc_nui"

const string NUISLF_WIN      = "IT_NUISLF_WIN";
const string NUISLF_VAL_BIND = "it_nuislf_val";
const string NUISLF_MIN_BIND = "it_nuislf_min";
const string NUISLF_MAX_BIND = "it_nuislf_max";
const string NUISLF_STP_BIND = "it_nuislf_stp";

json NuiSlfCentered(json jWidget)
{
    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    jRow = JsonArrayInsert(jRow, jWidget);
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    return NuiRow(jRow);
}

void NuiSlfOpen(object oPC)
{
    if (!GetIsPC(oPC)) return;

    int nOld = NuiFindWindow(oPC, NUISLF_WIN);
    if (nOld != 0) NuiDestroy(oPC, nOld);

    json jSlider = NuiSliderFloat(
        NuiBind(NUISLF_VAL_BIND),
        NuiBind(NUISLF_MIN_BIND),
        NuiBind(NUISLF_MAX_BIND),
        NuiBind(NUISLF_STP_BIND));
    jSlider = NuiWidth(jSlider, 280.0);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 14.0));
    jCol = JsonArrayInsert(jCol, NuiSlfCentered(jSlider));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 12.0));

    json jWin = NuiWindow(
        NuiCol(jCol),
        JsonString("NuiSliderFloat Test"),
        NuiRect(-1.0, -1.0, 420.0, 130.0),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE));

    int nToken = NuiCreate(oPC, jWin, NUISLF_WIN, "");
    if (nToken == 0) return;



    NuiSetUserData(oPC, nToken, jWin);
    NuiSetBind(oPC, nToken, NUISLF_VAL_BIND, JsonFloat(0.35));
    NuiSetBind(oPC, nToken, NUISLF_MIN_BIND, JsonFloat(0.0));
    NuiSetBind(oPC, nToken, NUISLF_MAX_BIND, JsonFloat(1.0));
    NuiSetBind(oPC, nToken, NUISLF_STP_BIND, JsonFloat(0.05));
}

