// =============================================================================
// nuibuttonimage.nss
// Integration test: one window + one NuiButtonImage.
// =============================================================================

#include "nw_inc_nui"

const string NUIBTNIMG_WIN = "IT_NUIBTNIMG_WIN";

json NuiBtnImgCentered(json jWidget)
{
    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    jRow = JsonArrayInsert(jRow, jWidget);
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    return NuiRow(jRow);
}

void NuiBtnImgOpen(object oPC)
{
    if (!GetIsPC(oPC)) return;

    int nOld = NuiFindWindow(oPC, NUIBTNIMG_WIN);
    if (nOld != 0) NuiDestroy(oPC, nOld);

    // Base-game icon resref, should work without custom HAK.
    json jBtn = NuiButtonImage(JsonString("ir_follow"));
    jBtn = NuiWidth(jBtn, 96.0);
    jBtn = NuiHeight(jBtn, 96.0);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));
    jCol = JsonArrayInsert(jCol, NuiBtnImgCentered(jBtn));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));

    json jWin = NuiWindow(
        NuiCol(jCol),
        JsonString("NuiButtonImage Test"),
        NuiRect(-1.0, -1.0, 320.0, 190.0),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE));

    int nToken = NuiCreate(oPC, jWin, NUIBTNIMG_WIN, "");

    if (nToken == 0) return;

    NuiSetUserData(oPC, nToken, jWin);
}

