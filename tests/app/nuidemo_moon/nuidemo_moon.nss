// =============================================================================
// nuidemo_moon.nss
// Integration test: demo moon background using NuiDrawList over
// NuiWidth -> NuiHeight -> NuiCol host chain.
// =============================================================================

#include "nw_inc_nui"

const string NUIDMO_WIN      = "IT_NUIDMO_WIN";
const string NUIDMO_BG_RESRF = "dm_moon_bg";

json NuiDmoBgLayer(float fW, float fH)
{
    json jBg = JsonArray();

    jBg = JsonArrayInsert(jBg, NuiDrawListImage(
        JsonBool(TRUE),
        JsonString(NUIDMO_BG_RESRF),
        NuiRect(0.0, 0.0, fW, fH),
        JsonInt(NUI_ASPECT_FILL),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE),
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

void NuiDmoOpen(object oPC)
{
    if (!GetIsPC(oPC)) return;

    int nOld = NuiFindWindow(oPC, NUIDMO_WIN);
    if (nOld != 0) NuiDestroy(oPC, nOld);

    float fW = 480.0;
    float fH = 320.0;

    json jTitle = NuiLabel(
        JsonString("Moon Demo (DrawList + Width/Height host)"),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE));
    jTitle = NuiHeight(jTitle, 24.0);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));
    jCol = JsonArrayInsert(jCol, jTitle);
    jCol = JsonArrayInsert(jCol, NuiSpacer());

    // Important chain for this test:
    // NuiDrawList -> NuiWidth -> NuiHeight -> NuiCol(root)
    json jSizedRoot = NuiWidth(NuiHeight(NuiCol(jCol), fH), fW);
    json jRoot = NuiDrawList(jSizedRoot, JsonBool(FALSE), NuiDmoBgLayer(fW, fH));

    json jWin = NuiWindow(
        jRoot,
        JsonBool(FALSE),
        NuiRect(-1.0, -1.0, fW, fH),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE));

    int nToken = NuiCreate(oPC, jWin, NUIDMO_WIN, "");
    if (nToken == 0) return;

    NuiSetUserData(oPC, nToken, jWin);
}
