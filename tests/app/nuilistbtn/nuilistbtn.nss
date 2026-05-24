// =============================================================================
// nuilistbtn.nss
// Integration test: NuiList with two template cells (label + button).
// =============================================================================

#include "nw_inc_nui"

const string NUILBT_WIN    = "IT_NUILBT_WIN";
const string NUILBT_LABELS = "it_nuilbt_labels";
const string NUILBT_COUNT  = "it_nuilbt_count";

json NuiLbtCentered(json jWidget)
{
    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    jRow = JsonArrayInsert(jRow, jWidget);
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    return NuiRow(jRow);
}

json NuiLbtItems()
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

void NuiLbtOpen(object oPC)
{
    if (!GetIsPC(oPC)) return;

    int nOld = NuiFindWindow(oPC, NUILBT_WIN);
    if (nOld != 0) NuiDestroy(oPC, nOld);

    json jLabel = NuiLabel(
        NuiBind(NUILBT_LABELS),
        JsonInt(NUI_HALIGN_LEFT),
        JsonInt(NUI_VALIGN_MIDDLE));

    json jBtn = NuiButton(JsonString("Run"));
    jBtn = NuiWidth(jBtn, 66.0);
    jBtn = NuiHeight(jBtn, 24.0);

    json jTemplate = JsonArray();
    jTemplate = JsonArrayInsert(jTemplate, NuiListTemplateCell(jLabel, 0.0, TRUE));
    jTemplate = JsonArrayInsert(jTemplate, NuiListTemplateCell(jBtn, 72.0, FALSE));

    json jList = NuiList(jTemplate, NuiBind(NUILBT_COUNT), 30.0, TRUE, NUI_SCROLLBARS_Y);
    jList = NuiWidth(jList, 320.0);
    jList = NuiHeight(jList, 190.0);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));
    jCol = JsonArrayInsert(jCol, NuiLbtCentered(jList));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));

    json jWin = NuiWindow(
        NuiCol(jCol),
        JsonString("NuiListButton Test"),
        NuiRect(-1.0, -1.0, 470.0, 300.0),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE));

    int nToken = NuiCreate(oPC, jWin, NUILBT_WIN, "");
    if (nToken == 0) return;



    NuiSetUserData(oPC, nToken, jWin);
    json jItems = NuiLbtItems();
    NuiSetBind(oPC, nToken, NUILBT_LABELS, jItems);
    NuiSetBind(oPC, nToken, NUILBT_COUNT, JsonInt(JsonGetLength(jItems)));
}
