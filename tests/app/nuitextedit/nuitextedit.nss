// =============================================================================
// nuitextedit.nss
// Integration test: one window + one NuiTextEdit.
// =============================================================================

#include "nw_inc_nui"

const string NUITXT_WIN  = "IT_NUITXT_WIN";
const string NUITXT_BIND = "it_nuitxt_bind";

json NuiTxtCentered(json jWidget)
{
    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    jRow = JsonArrayInsert(jRow, jWidget);
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    return NuiRow(jRow);
}

void NuiTxtOpen(object oPC)
{
    if (!GetIsPC(oPC)) return;

    int nOld = NuiFindWindow(oPC, NUITXT_WIN);
    if (nOld != 0) NuiDestroy(oPC, nOld);

    json jInput = NuiTextEdit(JsonString("Type here..."), NuiBind(NUITXT_BIND), 64, FALSE);
    jInput = NuiWidth(jInput, 220.0);
    jInput = NuiHeight(jInput, 32.0);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));
    jCol = JsonArrayInsert(jCol, NuiTxtCentered(jInput));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));

    json jWin = NuiWindow(
        NuiCol(jCol),
        JsonString("NuiTextEdit Test"),
        NuiRect(-1.0, -1.0, 360.0, 140.0),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE));

    int nToken = NuiCreate(oPC, jWin, NUITXT_WIN, "");
    if (nToken == 0) return;



    NuiSetUserData(oPC, nToken, jWin);
    NuiSetBind(oPC, nToken, NUITXT_BIND, JsonString(""));
}

