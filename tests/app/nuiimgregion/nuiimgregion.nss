// =============================================================================
// nuiimgregion.nss
// Integration test: one window + NuiImageRegion cropping two atlas regions.
// =============================================================================

#include "nw_inc_nui"

const string NUIIMR_WIN = "IT_NUIIMR_WIN";

json NuiImrCentered(json jWidget)
{
    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    jRow = JsonArrayInsert(jRow, jWidget);
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    return NuiRow(jRow);
}

void NuiImrOpen(object oPC)
{
    if (!GetIsPC(oPC)) return;

    int nOld = NuiFindWindow(oPC, NUIIMR_WIN);
    if (nOld != 0) NuiDestroy(oPC, nOld);

    // Base-game icon used as source image; two different source sub-rectangles.
    json jImgA = NuiImage(
        JsonString("ir_follow"),
        JsonInt(NUI_ASPECT_FIT),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE));
    jImgA = NuiImageRegion(jImgA, NuiRect(0.0, 0.0, 32.0, 32.0));
    jImgA = NuiWidth(jImgA, 96.0);
    jImgA = NuiHeight(jImgA, 96.0);

    json jImgB = NuiImage(
        JsonString("ir_follow"),
        JsonInt(NUI_ASPECT_FIT),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE));
    jImgB = NuiImageRegion(jImgB, NuiRect(32.0, 32.0, 32.0, 32.0));
    jImgB = NuiWidth(jImgB, 96.0);
    jImgB = NuiHeight(jImgB, 96.0);

    json jImgs = JsonArray();
    jImgs = JsonArrayInsert(jImgs, jImgA);
    jImgs = JsonArrayInsert(jImgs, NuiWidth(NuiSpacer(), 16.0));
    jImgs = JsonArrayInsert(jImgs, jImgB);
    jImgs = NuiRow(jImgs);

    json jHint = NuiLabel(
        JsonString("Left: (0,0,32,32)   Right: (32,32,32,32)"),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE));
    jHint = NuiHeight(jHint, 24.0);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));
    jCol = JsonArrayInsert(jCol, NuiImrCentered(jHint));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 6.0));
    jCol = JsonArrayInsert(jCol, NuiImrCentered(jImgs));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));

    json jWin = NuiWindow(
        NuiCol(jCol),
        JsonString("NuiImageRegion Test"),
        NuiRect(-1.0, -1.0, 440.0, 230.0),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE));

    int nToken = NuiCreate(oPC, jWin, NUIIMR_WIN, "");

    if (nToken == 0) return;

    NuiSetUserData(oPC, nToken, jWin);
}
