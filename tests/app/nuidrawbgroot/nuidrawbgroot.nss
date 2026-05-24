// =============================================================================
// nuidrawbgroot.nss
// Complex test: NuiDrawListImage as root background with hidden window chrome.
// =============================================================================

#include "nw_inc_nui"

const string NUIDBR_WIN       = "IT_NUIDBR_WIN";
const string NUIDBR_EV        = "nuidrawbgroot_ev";
const string NUIDBR_BTN_PING  = "it_nuidbr_ping";
const string NUIDBR_BTN_CLOSE = "it_nuidbr_close";
const string NUIDBR_MSG       = "it_nuidbr_msg";
const string NUIDBR_BG_RESREF = "test_image";

json NuiDbrBgLayer(float fW, float fH)
{
    json jBg = JsonArray();

    jBg = JsonArrayInsert(jBg, NuiDrawListImage(
        JsonBool(TRUE),
        JsonString(NUIDBR_BG_RESREF),
        NuiRect(0.0, 0.0, fW, fH),
        JsonInt(NUI_ASPECT_FILL),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE),
        NUI_DRAW_LIST_ITEM_ORDER_BEFORE,
        NUI_DRAW_LIST_ITEM_RENDER_ALWAYS));

    // Darken image slightly for text readability while keeping full transparency mode.
    jBg = JsonArrayInsert(jBg, NuiDrawListRect(
        JsonBool(TRUE),
        NuiColor(0, 0, 0, 150),
        JsonBool(TRUE),
        JsonFloat(1.0),
        NuiRect(0.0, 0.0, fW, fH),
        NUI_DRAW_LIST_ITEM_ORDER_BEFORE,
        NUI_DRAW_LIST_ITEM_RENDER_ALWAYS));

    jBg = JsonArrayInsert(jBg, NuiDrawListRect(
        JsonBool(TRUE),
        NuiColor(245, 200, 120, 255),
        JsonBool(FALSE),
        JsonFloat(2.0),
        NuiRect(0.0, 0.0, fW, fH),
        NUI_DRAW_LIST_ITEM_ORDER_BEFORE,
        NUI_DRAW_LIST_ITEM_RENDER_ALWAYS));

    return jBg;
}

void NuiDbrOpen(object oPC)
{
    if (!GetIsPC(oPC)) return;

    int nOld = NuiFindWindow(oPC, NUIDBR_WIN);
    if (nOld != 0) NuiDestroy(oPC, nOld);

    float fW = 540.0;
    float fH = 280.0;

    json jTitle = NuiLabel(JsonString("NuiDraw root background (header OFF / transparent ON)"),
                           JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jTitle = NuiHeight(jTitle, 24.0);

    json jMsg = NuiLabel(NuiBind(NUIDBR_MSG), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jMsg = NuiHeight(jMsg, 24.0);

    json jPing = NuiId(NuiButton(JsonString("Ping")), NUIDBR_BTN_PING);
    jPing = NuiWidth(jPing, 120.0);
    jPing = NuiHeight(jPing, 34.0);

    json jClose = NuiId(NuiButton(JsonString("Close")), NUIDBR_BTN_CLOSE);
    jClose = NuiWidth(jClose, 120.0);
    jClose = NuiHeight(jClose, 34.0);

    json jButtons = JsonArray();
    jButtons = JsonArrayInsert(jButtons, NuiSpacer());
    jButtons = JsonArrayInsert(jButtons, jPing);
    jButtons = JsonArrayInsert(jButtons, NuiWidth(NuiSpacer(), 14.0));
    jButtons = JsonArrayInsert(jButtons, jClose);
    jButtons = JsonArrayInsert(jButtons, NuiSpacer());

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 14.0));
    jCol = JsonArrayInsert(jCol, jTitle);
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));
    jCol = JsonArrayInsert(jCol, jMsg);
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 16.0));
    jCol = JsonArrayInsert(jCol, NuiRow(jButtons));
    jCol = JsonArrayInsert(jCol, NuiSpacer());

    json jRoot = NuiDrawList(NuiCol(jCol), JsonBool(FALSE), NuiDbrBgLayer(fW, fH));

    // Title/header hidden, transparent root, border hidden: full custom shell.
    json jWin = NuiWindow(
        jRoot,
        JsonBool(FALSE),
        NuiRect(-1.0, -1.0, fW, fH),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE));

    int nToken = NuiCreate(oPC, jWin, NUIDBR_WIN, NUIDBR_EV);
    if (nToken == 0) return;



    NuiSetUserData(oPC, nToken, jWin);
    NuiSetBind(oPC, nToken, NUIDBR_MSG, JsonString("Background image should fill entire root area."));
}

