// =============================================================================
// nuilabel.nss
// Integration test: one window + one NuiLabel.
// =============================================================================

#include "nw_inc_nui"

const string NUILBL_WIN  = "IT_NUILBL_WIN";
const string NUILBL_BIND = "it_nuilbl_bind";

json NuiLblCentered(json jWidget)
{
    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    jRow = JsonArrayInsert(jRow, jWidget);
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    return NuiRow(jRow);
}

void NuiLblOpen(object oPC)
{
    if (!GetIsPC(oPC)) return;

    int nOld = NuiFindWindow(oPC, NUILBL_WIN);
    if (nOld != 0) NuiDestroy(oPC, nOld);

    json jLabel = NuiLabel(
        NuiBind(NUILBL_BIND),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE));
    jLabel = NuiWidth(jLabel, 220.0);
    jLabel = NuiHeight(jLabel, 30.0);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 12.0));
    jCol = JsonArrayInsert(jCol, NuiLblCentered(jLabel));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 12.0));

    json jWin = NuiWindow(
        NuiCol(jCol),
        JsonString("NuiLabel Test"),
        NuiRect(-1.0, -1.0, 380.0, 140.0),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE));

    int nToken = NuiCreate(oPC, jWin, NUILBL_WIN, "");
    if (nToken == 0) return;



    NuiSetUserData(oPC, nToken, jWin);
    NuiSetBind(oPC, nToken, NUILBL_BIND, JsonString("Sample Label"));
}

