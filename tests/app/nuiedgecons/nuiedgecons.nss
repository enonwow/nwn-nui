// =============================================================================
// nuiedgecons.nss
// Integration test: NuiWindow edge constraint (screen margins).
// =============================================================================

#include "nw_inc_nui"

const string NUIEDG_WIN = "IT_NUIEDG_WIN";

json NuiEdgCentered(json jWidget)
{
    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    jRow = JsonArrayInsert(jRow, jWidget);
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    return NuiRow(jRow);
}

void NuiEdgOpen(object oPC)
{
    if (!GetIsPC(oPC)) return;

    int nOld = NuiFindWindow(oPC, NUIEDG_WIN);
    if (nOld != 0) NuiDestroy(oPC, nOld);

    json jL1 = NuiLabel(
        JsonString("Window tries to open at top-left (0,0)."),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE));
    jL1 = NuiHeight(jL1, 24.0);

    json jL2 = NuiLabel(
        JsonString("Edge constraint enforces 40px margins on all sides."),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE));
    jL2 = NuiHeight(jL2, 24.0);

    json jBox = NuiGroup(
        NuiLabel(JsonString("Observe final clamped placement."), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)),
        TRUE,
        NUI_SCROLLBARS_NONE);
    jBox = NuiWidth(jBox, 280.0);
    jBox = NuiHeight(jBox, 90.0);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));
    jCol = JsonArrayInsert(jCol, NuiEdgCentered(jL1));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 4.0));
    jCol = JsonArrayInsert(jCol, NuiEdgCentered(jL2));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));
    jCol = JsonArrayInsert(jCol, NuiEdgCentered(jBox));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));

    json jWin = NuiWindow(
        NuiCol(jCol),
        JsonString("NuiEdgeConstraint Test"),
        NuiRect(0.0, 0.0, 430.0, 220.0),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(TRUE),
        JSON_NULL,
        NuiRect(40.0, 40.0, 40.0, 40.0));

    int nToken = NuiCreate(oPC, jWin, NUIEDG_WIN, "");
    if (nToken == 0) return;

    NuiSetUserData(oPC, nToken, jWin);
}

