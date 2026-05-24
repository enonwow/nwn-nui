// =============================================================================
// nuiswaplay.nss
// Complex test: swap group layout in-place via NuiSetGroupLayout().
// =============================================================================

#include "nw_inc_nui"

const string NUISWP_WIN   = "IT_NUISWP_WIN";
const string NUISWP_EV    = "nuiswaplay_ev";
const string NUISWP_GRP   = "it_nuiswp_grp";
const string NUISWP_BTN_A = "it_nuiswp_a";
const string NUISWP_BTN_B = "it_nuiswp_b";
const string NUISWP_ENC_A = "it_nuiswp_ae";
const string NUISWP_ENC_B = "it_nuiswp_be";

json NuiSwpCentered(json jWidget)
{
    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    jRow = JsonArrayInsert(jRow, jWidget);
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    return NuiRow(jRow);
}

json NuiSwpViewA()
{
    json jHead = NuiLabel(JsonString("VIEW A"), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jHead = NuiHeight(jHead, 28.0);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jHead);
    jCol = JsonArrayInsert(jCol, NuiLabel(JsonString("Layout A focuses on vertical stack."), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));
    jCol = JsonArrayInsert(jCol, NuiLabel(JsonString("Item 01"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));
    jCol = JsonArrayInsert(jCol, NuiLabel(JsonString("Item 02"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));
    jCol = JsonArrayInsert(jCol, NuiLabel(JsonString("Item 03"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));
    return NuiCol(jCol);
}

json NuiSwpViewB()
{
    json jHead = NuiLabel(JsonString("VIEW B"), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jHead = NuiHeight(jHead, 28.0);

    json jBtn = NuiButtonImage(JsonString("ir_follow"));
    jBtn = NuiWidth(jBtn, 64.0);
    jBtn = NuiHeight(jBtn, 64.0);

    json jPrg = NuiProgress(JsonFloat(0.70));
    jPrg = NuiWidth(jPrg, 210.0);
    jPrg = NuiHeight(jPrg, 24.0);

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, jBtn);
    jRow = JsonArrayInsert(jRow, NuiWidth(NuiSpacer(), 12.0));
    jRow = JsonArrayInsert(jRow, NuiCol(JsonArrayInsert(JsonArray(), jPrg)));
    jRow = NuiRow(jRow);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jHead);
    jCol = JsonArrayInsert(jCol, NuiLabel(JsonString("Layout B uses mixed widgets in a row."), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 8.0));
    jCol = JsonArrayInsert(jCol, jRow);
    return NuiCol(jCol);
}

void NuiSwpOpen(object oPC)
{
    if (!GetIsPC(oPC)) return;

    int nOld = NuiFindWindow(oPC, NUISWP_WIN);
    if (nOld != 0) NuiDestroy(oPC, nOld);

    json jA = NuiId(NuiButton(JsonString("Show View A")), NUISWP_BTN_A);
    jA = NuiEncouraged(jA, NuiBind(NUISWP_ENC_A));
    jA = NuiWidth(jA, 130.0);
    jA = NuiHeight(jA, 34.0);

    json jB = NuiId(NuiButton(JsonString("Show View B")), NUISWP_BTN_B);
    jB = NuiEncouraged(jB, NuiBind(NUISWP_ENC_B));
    jB = NuiWidth(jB, 130.0);
    jB = NuiHeight(jB, 34.0);

    json jTop = JsonArray();
    jTop = JsonArrayInsert(jTop, jA);
    jTop = JsonArrayInsert(jTop, NuiWidth(NuiSpacer(), 12.0));
    jTop = JsonArrayInsert(jTop, jB);
    jTop = NuiRow(jTop);

    json jSwap = NuiId(NuiGroup(NuiSwpViewA(), TRUE, NUI_SCROLLBARS_AUTO), NUISWP_GRP);
    jSwap = NuiWidth(jSwap, 470.0);
    jSwap = NuiHeight(jSwap, 180.0);

    json jHelp = NuiLabel(
        JsonString("Click buttons to swap layout inside one group (no window recreate)."),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE));
    jHelp = NuiHeight(jHelp, 24.0);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 8.0));
    jCol = JsonArrayInsert(jCol, NuiSwpCentered(jHelp));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 6.0));
    jCol = JsonArrayInsert(jCol, NuiSwpCentered(jTop));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 8.0));
    jCol = JsonArrayInsert(jCol, NuiSwpCentered(jSwap));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 8.0));

    json jWin = NuiWindow(
        NuiCol(jCol),
        JsonString("NuiSwapLayout Test"),
        NuiRect(-1.0, -1.0, 560.0, 330.0),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE));

    int nToken = NuiCreate(oPC, jWin, NUISWP_WIN, NUISWP_EV);
    if (nToken == 0) return;



    NuiSetUserData(oPC, nToken, jWin);
    NuiSetBind(oPC, nToken, NUISWP_ENC_A, JsonBool(TRUE));
    NuiSetBind(oPC, nToken, NUISWP_ENC_B, JsonBool(FALSE));
}
