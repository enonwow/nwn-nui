// =============================================================================
// nuislider.nss
// Integration test: one window + one NuiSlider (int).
// =============================================================================

#include "nw_inc_nui"

const string NUISLD_WIN      = "IT_NUISLD_WIN";
const string NUISLD_VAL_BIND = "it_nuisld_val";
const string NUISLD_MIN_BIND = "it_nuisld_min";
const string NUISLD_MAX_BIND = "it_nuisld_max";
const string NUISLD_STP_BIND = "it_nuisld_stp";

json NuiSldCentered(json jWidget)
{
    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    jRow = JsonArrayInsert(jRow, jWidget);
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    return NuiRow(jRow);
}

void NuiSldOpen(object oPC)
{
    if (!GetIsPC(oPC)) return;

    int nOld = NuiFindWindow(oPC, NUISLD_WIN);
    if (nOld != 0) NuiDestroy(oPC, nOld);

    json jSlider = NuiSlider(
        NuiBind(NUISLD_VAL_BIND),
        NuiBind(NUISLD_MIN_BIND),
        NuiBind(NUISLD_MAX_BIND),
        NuiBind(NUISLD_STP_BIND));
    jSlider = NuiWidth(jSlider, 260.0);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 14.0));
    jCol = JsonArrayInsert(jCol, NuiSldCentered(jSlider));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 12.0));

    json jWin = NuiWindow(
        NuiCol(jCol),
        JsonString("NuiSlider Test"),
        NuiRect(-1.0, -1.0, 400.0, 130.0),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE));

    int nToken = NuiCreate(oPC, jWin, NUISLD_WIN, "");
    if (nToken == 0) return;



    NuiSetUserData(oPC, nToken, jWin);
    NuiSetBind(oPC, nToken, NUISLD_VAL_BIND, JsonInt(35));
    NuiSetBind(oPC, nToken, NUISLD_MIN_BIND, JsonInt(0));
    NuiSetBind(oPC, nToken, NUISLD_MAX_BIND, JsonInt(100));
    NuiSetBind(oPC, nToken, NUISLD_STP_BIND, JsonInt(5));
}

