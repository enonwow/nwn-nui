// =============================================================================
// nuilist.nss
// Integration test: one window + one NuiList (minimal single-column list).
// =============================================================================

#include "nw_inc_nui"

const string NUILST_WIN    = "IT_NUILST_WIN";
const string NUILST_LABELS = "it_nuilst_labels";
const string NUILST_COUNT  = "it_nuilst_count";

json NuiLstCentered(json jWidget)
{
    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    jRow = JsonArrayInsert(jRow, jWidget);
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    return NuiRow(jRow);
}

json NuiLstItems()
{
    json jItems = JsonArray();
    jItems = JsonArrayInsert(jItems, JsonString("Entry 01"));
    jItems = JsonArrayInsert(jItems, JsonString("Entry 02"));
    jItems = JsonArrayInsert(jItems, JsonString("Entry 03"));
    jItems = JsonArrayInsert(jItems, JsonString("Entry 04"));
    jItems = JsonArrayInsert(jItems, JsonString("Entry 05"));
    jItems = JsonArrayInsert(jItems, JsonString("Entry 06"));
    return jItems;
}

void NuiLstOpen(object oPC)
{
    if (!GetIsPC(oPC)) return;

    int nOld = NuiFindWindow(oPC, NUILST_WIN);
    if (nOld != 0) NuiDestroy(oPC, nOld);

    json jCell = NuiLabel(
        NuiBind(NUILST_LABELS),
        JsonInt(NUI_HALIGN_LEFT),
        JsonInt(NUI_VALIGN_MIDDLE));

    json jTemplate = JsonArray();
    jTemplate = JsonArrayInsert(jTemplate, NuiListTemplateCell(jCell, 0.0, TRUE));

    json jList = NuiList(jTemplate, NuiBind(NUILST_COUNT), 28.0, TRUE, NUI_SCROLLBARS_Y);
    jList = NuiWidth(jList, 280.0);
    jList = NuiHeight(jList, 180.0);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));
    jCol = JsonArrayInsert(jCol, NuiLstCentered(jList));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));

    json jWin = NuiWindow(
        NuiCol(jCol),
        JsonString("NuiList Test"),
        NuiRect(-1.0, -1.0, 430.0, 290.0),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE));

    int nToken = NuiCreate(oPC, jWin, NUILST_WIN, "");
    if (nToken == 0) return;



    NuiSetUserData(oPC, nToken, jWin);
    json jItems = NuiLstItems();
    NuiSetBind(oPC, nToken, NUILST_LABELS, jItems);
    NuiSetBind(oPC, nToken, NUILST_COUNT, JsonInt(JsonGetLength(jItems)));
}

