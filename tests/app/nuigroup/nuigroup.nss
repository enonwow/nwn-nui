// =============================================================================
// nuigroup.nss
// Integration test: one window + one NuiGroup with vertical overflow.
// =============================================================================

#include "nw_inc_nui"

const string NUIGRP_WIN = "IT_NUIGRP_WIN";

json NuiGrpCentered(json jWidget)
{
    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    jRow = JsonArrayInsert(jRow, jWidget);
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    return NuiRow(jRow);
}

json NuiGrpContent()
{
    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiLabel(JsonString("Group line 01"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));
    jCol = JsonArrayInsert(jCol, NuiLabel(JsonString("Group line 02"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));
    jCol = JsonArrayInsert(jCol, NuiLabel(JsonString("Group line 03"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));
    jCol = JsonArrayInsert(jCol, NuiLabel(JsonString("Group line 04"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));
    jCol = JsonArrayInsert(jCol, NuiLabel(JsonString("Group line 05"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));
    jCol = JsonArrayInsert(jCol, NuiLabel(JsonString("Group line 06"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));
    jCol = JsonArrayInsert(jCol, NuiLabel(JsonString("Group line 07"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));
    jCol = JsonArrayInsert(jCol, NuiLabel(JsonString("Group line 08"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));
    jCol = JsonArrayInsert(jCol, NuiLabel(JsonString("Group line 09"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));
    jCol = JsonArrayInsert(jCol, NuiLabel(JsonString("Group line 10"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));
    return NuiCol(jCol);
}

void NuiGrpOpen(object oPC)
{
    if (!GetIsPC(oPC)) return;

    int nOld = NuiFindWindow(oPC, NUIGRP_WIN);
    if (nOld != 0) NuiDestroy(oPC, nOld);

    json jGroup = NuiGroup(NuiGrpContent(), TRUE, NUI_SCROLLBARS_Y);
    jGroup = NuiWidth(jGroup, 320.0);
    jGroup = NuiHeight(jGroup, 140.0);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));
    jCol = JsonArrayInsert(jCol, NuiGrpCentered(jGroup));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));

    json jWin = NuiWindow(
        NuiCol(jCol),
        JsonString("NuiGroup Test"),
        NuiRect(-1.0, -1.0, 440.0, 240.0),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE));

    int nToken = NuiCreate(oPC, jWin, NUIGRP_WIN, "");

    if (nToken == 0) return;

    NuiSetUserData(oPC, nToken, jWin);
}
