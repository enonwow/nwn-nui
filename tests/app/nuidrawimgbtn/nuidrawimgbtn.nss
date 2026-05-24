// =============================================================================
// nuidrawimgbtn.nss
// Complex test: NuiDrawListImage overlay on top of a clickable button.
// =============================================================================

#include "nw_inc_nui"

const string NUIDIB_WIN      = "IT_NUIDIB_WIN";
const string NUIDIB_EV       = "nuidrawimgbtn_ev";
const string NUIDIB_BTN_BASE = "it_nuidib_base";
const string NUIDIB_BTN_OVR  = "it_nuidib_ovr";
const string NUIDIB_MSG      = "it_nuidib_msg";
const string NUIDIB_RESREF   = "test_image";

json NuiDibCentered(json jWidget)
{
    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    jRow = JsonArrayInsert(jRow, jWidget);
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    return NuiRow(jRow);
}

json NuiDibOverlayButton()
{
    float fW = 184.0;
    float fH = 66.0;
    float fPadX = 18.0;
    float fPadY = 14.0;

    json jBtn = NuiId(NuiButton(JsonString("Overlay target")), NUIDIB_BTN_OVR);
    jBtn = NuiWidth(jBtn, fW);
    jBtn = NuiHeight(jBtn, fH);

    json jDraw = JsonArray();
    jDraw = JsonArrayInsert(jDraw, NuiDrawListImage(
        JsonBool(TRUE),
        JsonString(NUIDIB_RESREF),
        NuiRect(-fPadX, -fPadY, fW + (2.0 * fPadX), fH + (2.0 * fPadY)),
        JsonInt(NUI_ASPECT_FILL),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE),
        NUI_DRAW_LIST_ITEM_ORDER_AFTER,
        NUI_DRAW_LIST_ITEM_RENDER_ALWAYS));

    jDraw = JsonArrayInsert(jDraw, NuiDrawListRect(
        JsonBool(TRUE),
        NuiColor(245, 200, 120, 255),
        JsonBool(FALSE),
        JsonFloat(2.0),
        NuiRect(-4.0, -4.0, fW + 8.0, fH + 8.0),
        NUI_DRAW_LIST_ITEM_ORDER_AFTER,
        NUI_DRAW_LIST_ITEM_RENDER_ALWAYS));

    return NuiDrawList(jBtn, JsonBool(FALSE), jDraw);
}

void NuiDibOpen(object oPC)
{
    if (!GetIsPC(oPC)) return;

    int nOld = NuiFindWindow(oPC, NUIDIB_WIN);
    if (nOld != 0) NuiDestroy(oPC, nOld);

    json jLblA = NuiLabel(JsonString("BASE BUTTON"), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jLblA = NuiHeight(jLblA, 22.0);

    json jLblB = NuiLabel(JsonString("IMAGE OVERLAY"), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jLblB = NuiHeight(jLblB, 22.0);

    json jBase = NuiId(NuiButton(JsonString("Base target")), NUIDIB_BTN_BASE);
    jBase = NuiWidth(jBase, 184.0);
    jBase = NuiHeight(jBase, 66.0);

    json jColA = JsonArray();
    jColA = JsonArrayInsert(jColA, jLblA);
    jColA = JsonArrayInsert(jColA, NuiHeight(NuiSpacer(), 6.0));
    jColA = JsonArrayInsert(jColA, jBase);

    json jColB = JsonArray();
    jColB = JsonArrayInsert(jColB, jLblB);
    jColB = JsonArrayInsert(jColB, NuiHeight(NuiSpacer(), 6.0));
    jColB = JsonArrayInsert(jColB, NuiDibOverlayButton());

    json jCompare = JsonArray();
    jCompare = JsonArrayInsert(jCompare, NuiSpacer());
    jCompare = JsonArrayInsert(jCompare, NuiCol(jColA));
    jCompare = JsonArrayInsert(jCompare, NuiWidth(NuiSpacer(), 20.0));
    jCompare = JsonArrayInsert(jCompare, NuiCol(jColB));
    jCompare = JsonArrayInsert(jCompare, NuiSpacer());

    json jInfo = NuiLabel(
        JsonString("Right button is covered by DrawList image; click either button to verify events."),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE));
    jInfo = NuiHeight(jInfo, 24.0);

    json jMsg = NuiLabel(NuiBind(NUIDIB_MSG), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jMsg = NuiHeight(jMsg, 24.0);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 8.0));
    jCol = JsonArrayInsert(jCol, NuiDibCentered(jInfo));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));
    jCol = JsonArrayInsert(jCol, NuiRow(jCompare));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 8.0));
    jCol = JsonArrayInsert(jCol, NuiDibCentered(jMsg));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 8.0));

    json jWin = NuiWindow(
        NuiCol(jCol),
        JsonString("NuiDrawImage Btn Test"),
        NuiRect(-1.0, -1.0, 560.0, 250.0),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE));

    int nToken = NuiCreate(oPC, jWin, NUIDIB_WIN, NUIDIB_EV);
    if (nToken == 0) return;



    NuiSetUserData(oPC, nToken, jWin);
    NuiSetBind(oPC, nToken, NUIDIB_MSG, JsonString("Waiting for click..."));
}

