// =============================================================================
// nuiimage.nss
// Integration test: one window + one NuiImage.
// =============================================================================

#include "nw_inc_nui"

const string NUIIMG_WIN = "IT_NUIIMG_WIN";

json NuiImgCentered(json jWidget)
{
    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    jRow = JsonArrayInsert(jRow, jWidget);
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    return NuiRow(jRow);
}

void NuiImgOpen(object oPC)
{
    if (!GetIsPC(oPC)) return;

    int nOld = NuiFindWindow(oPC, NUIIMG_WIN);
    if (nOld != 0) NuiDestroy(oPC, nOld);

    // Base-game icon resref, no custom HAK required.
    json jImg = NuiImage(
        JsonString("ir_follow"),
        JsonInt(NUI_ASPECT_FIT),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE));
    jImg = NuiWidth(jImg, 96.0);
    jImg = NuiHeight(jImg, 96.0);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));
    jCol = JsonArrayInsert(jCol, NuiImgCentered(jImg));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));

    json jWin = NuiWindow(
        NuiCol(jCol),
        JsonString("NuiImage Test"),
        NuiRect(-1.0, -1.0, 320.0, 190.0),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE));

    int nToken = NuiCreate(oPC, jWin, NUIIMG_WIN, "");

    if (nToken == 0) return;

    NuiSetUserData(oPC, nToken, jWin);
}

