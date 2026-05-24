// =============================================================================
// nuiimage_hak.nss
// Integration test: custom HAK image via NuiImage (resref: test_image).
// =============================================================================

#include "nw_inc_nui"

const string NUIHKI_WIN = "IT_NUIHKI_WIN";

json NuiHkiCentered(json jWidget)
{
    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    jRow = JsonArrayInsert(jRow, jWidget);
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    return NuiRow(jRow);
}

void NuiHkiOpen(object oPC)
{
    if (!GetIsPC(oPC)) return;

    int nOld = NuiFindWindow(oPC, NUIHKI_WIN);
    if (nOld != 0) NuiDestroy(oPC, nOld);

    // Expects client-visible resource named "test_image" in HAK/override/nwsync.
    json jImg = NuiImage(
        JsonString("test_image"),
        JsonInt(NUI_ASPECT_FIT),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE));
    jImg = NuiWidth(jImg, 192.0);
    jImg = NuiHeight(jImg, 192.0);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));
    jCol = JsonArrayInsert(jCol, NuiHkiCentered(jImg));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));

    json jWin = NuiWindow(
        NuiCol(jCol),
        JsonString("NuiImage HAK Test"),
        NuiRect(-1.0, -1.0, 430.0, 290.0),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE));

    int nToken = NuiCreate(oPC, jWin, NUIHKI_WIN, "");

    if (nToken == 0) return;

    NuiSetUserData(oPC, nToken, jWin);
}

