// =============================================================================
// nuiprogress.nss
// Integration test: one window + one NuiProgress.
// =============================================================================

#include "nw_inc_nui"

const string NUIPRG_WIN  = "IT_NUIPRG_WIN";
const string NUIPRG_BIND = "it_nuiprg_bind";

json NuiPrgCentered(json jWidget)
{
    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    jRow = JsonArrayInsert(jRow, jWidget);
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    return NuiRow(jRow);
}

void NuiPrgOpen(object oPC)
{
    if (!GetIsPC(oPC)) return;

    int nOld = NuiFindWindow(oPC, NUIPRG_WIN);
    if (nOld != 0) NuiDestroy(oPC, nOld);

    json jProgress = NuiProgress(NuiBind(NUIPRG_BIND));
    jProgress = NuiWidth(jProgress, 260.0);
    jProgress = NuiHeight(jProgress, 26.0);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 14.0));
    jCol = JsonArrayInsert(jCol, NuiPrgCentered(jProgress));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 12.0));

    json jWin = NuiWindow(
        NuiCol(jCol),
        JsonString("NuiProgress Test"),
        NuiRect(-1.0, -1.0, 400.0, 140.0),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE));

    int nToken = NuiCreate(oPC, jWin, NUIPRG_WIN, "");
    if (nToken == 0) return;



    NuiSetUserData(oPC, nToken, jWin);
    NuiSetBind(oPC, nToken, NUIPRG_BIND, JsonFloat(0.65));
}

