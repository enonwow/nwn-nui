// =============================================================================
// nuicheck.nss
// Integration test: one window + one NuiCheck.
// =============================================================================

#include "nw_inc_nui"

const string NUICHK_WIN  = "IT_NUICHK_WIN";
const string NUICHK_BIND = "it_nuichk_bind";

json NuiChkCentered(json jWidget)
{
    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    jRow = JsonArrayInsert(jRow, jWidget);
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    return NuiRow(jRow);
}

void NuiChkOpen(object oPC)
{
    if (!GetIsPC(oPC)) return;

    int nOld = NuiFindWindow(oPC, NUICHK_WIN);
    if (nOld != 0) NuiDestroy(oPC, nOld);

    json jCheck = NuiCheck(JsonString("Enable Option"), NuiBind(NUICHK_BIND));
    jCheck = NuiWidth(jCheck, 220.0);
    jCheck = NuiHeight(jCheck, 32.0);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));
    jCol = JsonArrayInsert(jCol, NuiChkCentered(jCheck));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));

    json jWin = NuiWindow(
        NuiCol(jCol),
        JsonString("NuiCheck Test"),
        NuiRect(-1.0, -1.0, 360.0, 140.0),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE));

    int nToken = NuiCreate(oPC, jWin, NUICHK_WIN, "");
    if (nToken == 0) return;



    NuiSetUserData(oPC, nToken, jWin);
    NuiSetBind(oPC, nToken, NUICHK_BIND, JsonBool(FALSE));
}

