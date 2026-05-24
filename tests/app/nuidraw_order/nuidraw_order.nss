// =============================================================================
// nuidraw_order.nss
// Integration test: DrawList layering ORDER_BEFORE vs ORDER_AFTER.
// =============================================================================

#include "nw_inc_nui"

const string NUIDRO_WIN = "IT_NUIDRO_WIN";

json NuiDroSample(int nOrder, string sBaseLabel)
{
    json jBase = NuiButton(JsonString(sBaseLabel));
    jBase = NuiWidth(jBase, 190.0);
    jBase = NuiHeight(jBase, 88.0);

    json jDraw = JsonArray();

    // Same tint rectangle in both samples; only order changes.
    jDraw = JsonArrayInsert(jDraw, NuiDrawListRect(
        JsonBool(TRUE),
        NuiColor(70, 180, 120, 230),
        JsonBool(TRUE),
        JsonFloat(1.0),
        NuiRect(0.0, 0.0, 190.0, 88.0),
        nOrder));

    // Fixed outer frame to make widget bounds obvious.
    jDraw = JsonArrayInsert(jDraw, NuiDrawListRect(
        JsonBool(TRUE),
        NuiColor(245, 200, 120, 255),
        JsonBool(FALSE),
        JsonFloat(2.0),
        NuiRect(-8.0, -8.0, 206.0, 104.0),
        NUI_DRAW_LIST_ITEM_ORDER_AFTER));

    return NuiDrawList(jBase, JsonBool(FALSE), jDraw);
}

void NuiDroOpen(object oPC)
{
    if (!GetIsPC(oPC)) return;

    int nOld = NuiFindWindow(oPC, NUIDRO_WIN);
    if (nOld != 0) NuiDestroy(oPC, nOld);

    json jLblBefore = NuiLabel(JsonString("ORDER_BEFORE"), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jLblBefore = NuiHeight(jLblBefore, 24.0);

    json jLblAfter = NuiLabel(JsonString("ORDER_AFTER"), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jLblAfter = NuiHeight(jLblAfter, 24.0);

    json jColBefore = JsonArray();
    jColBefore = JsonArrayInsert(jColBefore, jLblBefore);
    jColBefore = JsonArrayInsert(jColBefore, NuiHeight(NuiSpacer(), 6.0));
    jColBefore = JsonArrayInsert(jColBefore, NuiDroSample(NUI_DRAW_LIST_ITEM_ORDER_BEFORE, "BASE"));

    json jColAfter = JsonArray();
    jColAfter = JsonArrayInsert(jColAfter, jLblAfter);
    jColAfter = JsonArrayInsert(jColAfter, NuiHeight(NuiSpacer(), 6.0));
    jColAfter = JsonArrayInsert(jColAfter, NuiDroSample(NUI_DRAW_LIST_ITEM_ORDER_AFTER, "BASE"));

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    jRow = JsonArrayInsert(jRow, NuiCol(jColBefore));
    jRow = JsonArrayInsert(jRow, NuiWidth(NuiSpacer(), 20.0));
    jRow = JsonArrayInsert(jRow, NuiCol(jColAfter));
    jRow = JsonArrayInsert(jRow, NuiSpacer());

    json jHint = NuiLabel(
        JsonString("Green fill is identical; only draw order changes."),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE));
    jHint = NuiHeight(jHint, 24.0);

    json jRoot = JsonArray();
    jRoot = JsonArrayInsert(jRoot, NuiHeight(NuiSpacer(), 8.0));
    jRoot = JsonArrayInsert(jRoot, jHint);
    jRoot = JsonArrayInsert(jRoot, NuiHeight(NuiSpacer(), 10.0));
    jRoot = JsonArrayInsert(jRoot, NuiRow(jRow));
    jRoot = JsonArrayInsert(jRoot, NuiHeight(NuiSpacer(), 8.0));

    json jWin = NuiWindow(
        NuiCol(jRoot),
        JsonString("NuiDraw Order Test"),
        NuiRect(-1.0, -1.0, 660.0, 280.0),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE));

    int nToken = NuiCreate(oPC, jWin, NUIDRO_WIN, "");

    if (nToken == 0) return;

    NuiSetUserData(oPC, nToken, jWin);
}

