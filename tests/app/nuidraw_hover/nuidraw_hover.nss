// =============================================================================
// nuidraw_hover.nss
// Integration test: DrawList hover/press states + click event.
// =============================================================================

#include "nw_inc_nui"

const string NUIDRH_WIN = "IT_NUIDRH_WIN";
const string NUIDRH_EV  = "nuidraw_hover_ev";

const string NUIDRH_BTN  = "it_nuidrh_btn";
const string NUIDRH_CLOSE = "it_nuidrh_close";

json NuiDrhCentered(json jWidget)
{
    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    jRow = JsonArrayInsert(jRow, jWidget);
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    return NuiRow(jRow);
}

json NuiDrhInteractiveCard()
{
    float fW = 180.0;
    float fH = 90.0;

    json jBtn = NuiId(NuiButton(JsonString("")), NUIDRH_BTN);
    jBtn = NuiWidth(jBtn, fW);
    jBtn = NuiHeight(jBtn, fH);

    json jDraw = JsonArray();

    // Normal state (mouse off).
    jDraw = JsonArrayInsert(jDraw, NuiDrawListRect(
        JsonBool(TRUE), NuiColor(40, 90, 150, 220), JsonBool(TRUE), JsonFloat(1.0),
        NuiRect(-10.0, -8.0, fW + 20.0, fH + 16.0),
        NUI_DRAW_LIST_ITEM_ORDER_AFTER, NUI_DRAW_LIST_ITEM_RENDER_MOUSE_OFF));

    // Hover state (mouse over).
    jDraw = JsonArrayInsert(jDraw, NuiDrawListRect(
        JsonBool(TRUE), NuiColor(50, 140, 90, 230), JsonBool(TRUE), JsonFloat(1.0),
        NuiRect(-10.0, -8.0, fW + 20.0, fH + 16.0),
        NUI_DRAW_LIST_ITEM_ORDER_AFTER, NUI_DRAW_LIST_ITEM_RENDER_MOUSE_HOVER));

    // Pressed state (left mouse held).
    jDraw = JsonArrayInsert(jDraw, NuiDrawListRect(
        JsonBool(TRUE), NuiColor(180, 140, 60, 235), JsonBool(TRUE), JsonFloat(1.0),
        NuiRect(-10.0, -8.0, fW + 20.0, fH + 16.0),
        NUI_DRAW_LIST_ITEM_ORDER_AFTER, NUI_DRAW_LIST_ITEM_RENDER_MOUSE_LEFT));

    // Always-visible frame and caption.
    jDraw = JsonArrayInsert(jDraw, NuiDrawListRect(
        JsonBool(TRUE), NuiColor(245, 195, 110, 255), JsonBool(FALSE), JsonFloat(2.0),
        NuiRect(-10.0, -8.0, fW + 20.0, fH + 16.0)));
    jDraw = JsonArrayInsert(jDraw, NuiDrawListText(
        JsonBool(TRUE), NuiColor(250, 245, 235, 255),
        NuiRect(30.0, 34.0, 120.0, 24.0), JsonString("HOVER / CLICK")));

    return NuiDrawList(jBtn, JsonBool(FALSE), jDraw);
}

void NuiDrhOpen(object oPC)
{
    if (!GetIsPC(oPC)) return;

    int nOld = NuiFindWindow(oPC, NUIDRH_WIN);
    if (nOld != 0) NuiDestroy(oPC, nOld);

    json jClose = NuiId(NuiButton(JsonString("Close")), NUIDRH_CLOSE);
    jClose = NuiWidth(jClose, 92.0);
    jClose = NuiHeight(jClose, 30.0);

    json jHelp = NuiLabel(
        JsonString("Hover should change color, hold LMB for pressed state."),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE));
    jHelp = NuiHeight(jHelp, 24.0);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 8.0));
    jCol = JsonArrayInsert(jCol, NuiDrhCentered(jHelp));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 8.0));
    jCol = JsonArrayInsert(jCol, NuiDrhCentered(NuiDrhInteractiveCard()));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 14.0));
    jCol = JsonArrayInsert(jCol, NuiDrhCentered(jClose));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 8.0));

    json jWin = NuiWindow(
        NuiCol(jCol),
        JsonString("NuiDraw Hover Test"),
        NuiRect(-1.0, -1.0, 520.0, 270.0),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE));

    int nToken = NuiCreate(oPC, jWin, NUIDRH_WIN, NUIDRH_EV);

    if (nToken == 0) return;

    NuiSetUserData(oPC, nToken, jWin);
}

