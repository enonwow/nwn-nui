// =============================================================================
// nuisizecons.nss
// Integration test: NuiWindow size constraint (min/max width and height).
// =============================================================================

#include "nw_inc_nui"

const string NUISIZ_WIN = "IT_NUISIZ_WIN";

json NuiSizCentered(json jWidget)
{
    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    jRow = JsonArrayInsert(jRow, jWidget);
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    return NuiRow(jRow);
}

void NuiSizOpen(object oPC)
{
    if (!GetIsPC(oPC)) return;

    int nOld = NuiFindWindow(oPC, NUISIZ_WIN);
    if (nOld != 0) NuiDestroy(oPC, nOld);

    json jL1 = NuiLabel(
        JsonString("Resize this window. Constraints: min 420x220, max 620x340."),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE));
    jL1 = NuiHeight(jL1, 24.0);

    json jL2 = NuiLabel(
        JsonString("When either max <= min, axis is effectively locked."),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE));
    jL2 = NuiHeight(jL2, 24.0);

    json jBox = NuiGroup(
        NuiLabel(JsonString("Constraint demo area"), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)),
        TRUE,
        NUI_SCROLLBARS_NONE);
    jBox = NuiWidth(jBox, 300.0);
    jBox = NuiHeight(jBox, 110.0);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));
    jCol = JsonArrayInsert(jCol, NuiSizCentered(jL1));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 4.0));
    jCol = JsonArrayInsert(jCol, NuiSizCentered(jL2));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));
    jCol = JsonArrayInsert(jCol, NuiSizCentered(jBox));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));

    json jWin = NuiWindow(
        NuiCol(jCol),
        JsonString("NuiSizeConstraint Test"),
        NuiRect(-1.0, -1.0, 500.0, 260.0),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(TRUE),
        NuiRect(420.0, 220.0, 620.0, 340.0));

    int nToken = NuiCreate(oPC, jWin, NUISIZ_WIN, "");
    if (nToken == 0) return;

    NuiSetUserData(oPC, nToken, jWin);
}

