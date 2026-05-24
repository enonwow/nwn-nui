// =============================================================================
// nuitext.nss
// Integration test: one window + one NuiText.
// =============================================================================

#include "nw_inc_nui"

const string NUITXTW_WIN = "IT_NUITEXT_WIN";

json NuiTxtwCentered(json jWidget)
{
    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    jRow = JsonArrayInsert(jRow, jWidget);
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    return NuiRow(jRow);
}

void NuiTxtwOpen(object oPC)
{
    if (!GetIsPC(oPC)) return;

    int nOld = NuiFindWindow(oPC, NUITXTW_WIN);
    if (nOld != 0) NuiDestroy(oPC, nOld);

    json jText = NuiText(JsonString("Line 1\nLine 2\nLine 3"), TRUE, NUI_SCROLLBARS_AUTO);
    jText = NuiWidth(jText, 260.0);
    jText = NuiHeight(jText, 90.0);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));
    jCol = JsonArrayInsert(jCol, NuiTxtwCentered(jText));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));

    json jWin = NuiWindow(
        NuiCol(jCol),
        JsonString("NuiText Test"),
        NuiRect(-1.0, -1.0, 400.0, 210.0),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE));

    int nToken = NuiCreate(oPC, jWin, NUITXTW_WIN, "");

    if (nToken == 0) return;

    NuiSetUserData(oPC, nToken, jWin);
}

