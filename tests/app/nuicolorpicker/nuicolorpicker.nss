// =============================================================================
// nuicolorpicker.nss
// Integration test: one window + one NuiColorPicker.
// =============================================================================

#include "nw_inc_nui"

const string NUICLR_WIN  = "IT_NUICLR_WIN";
const string NUICLR_BIND = "it_nuiclr_bind";

json NuiClrCentered(json jWidget)
{
    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    jRow = JsonArrayInsert(jRow, jWidget);
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    return NuiRow(jRow);
}

void NuiClrOpen(object oPC)
{
    if (!GetIsPC(oPC)) return;

    int nOld = NuiFindWindow(oPC, NUICLR_WIN);
    if (nOld != 0) NuiDestroy(oPC, nOld);

    json jPicker = NuiColorPicker(NuiBind(NUICLR_BIND));
    jPicker = NuiWidth(jPicker, 220.0);
    jPicker = NuiHeight(jPicker, 180.0);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));
    jCol = JsonArrayInsert(jCol, NuiClrCentered(jPicker));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));

    json jWin = NuiWindow(
        NuiCol(jCol),
        JsonString("NuiColorPicker Test"),
        NuiRect(-1.0, -1.0, 420.0, 300.0),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE));

    int nToken = NuiCreate(oPC, jWin, NUICLR_WIN, "");
    if (nToken == 0) return;



    NuiSetUserData(oPC, nToken, jWin);
    NuiSetBind(oPC, nToken, NUICLR_BIND, NuiColor(96, 128, 255, 255));
}

