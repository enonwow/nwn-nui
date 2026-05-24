// =============================================================================
// nuimargin.nss
// Modifier test: NuiMargin() spacing outside element.
// =============================================================================

#include "nw_inc_nui"

const string NUIMGN_WIN = "IT_NUIMGN_WIN";

json NuiMgnCentered(json jWidget)
{
    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    jRow = JsonArrayInsert(jRow, jWidget);
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    return NuiRow(jRow);
}

void NuiMgnOpen(object oPC)
{
    if (!GetIsPC(oPC)) return;

    int nOld = NuiFindWindow(oPC, NUIMGN_WIN);
    if (nOld != 0) NuiDestroy(oPC, nOld);

    json jA = NuiButton(JsonString("A"));
    jA = NuiWidth(jA, 90.0);
    jA = NuiHeight(jA, 34.0);

    json jB = NuiButton(JsonString("B + margin"));
    jB = NuiMargin(jB, 12.0);
    jB = NuiWidth(jB, 90.0);
    jB = NuiHeight(jB, 34.0);

    json jC = NuiButton(JsonString("C"));
    jC = NuiWidth(jC, 90.0);
    jC = NuiHeight(jC, 34.0);

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, jA);
    jRow = JsonArrayInsert(jRow, jB);
    jRow = JsonArrayInsert(jRow, jC);
    jRow = NuiRow(jRow);

    json jFrame = NuiGroup(jRow, TRUE, NUI_SCROLLBARS_NONE);
    jFrame = NuiWidth(jFrame, 360.0);
    jFrame = NuiHeight(jFrame, 72.0);

    json jHelp = NuiLabel(
        JsonString("Middle button has NuiMargin(12.0)."),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE));
    jHelp = NuiHeight(jHelp, 24.0);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));
    jCol = JsonArrayInsert(jCol, NuiMgnCentered(jHelp));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 8.0));
    jCol = JsonArrayInsert(jCol, NuiMgnCentered(jFrame));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));

    json jWin = NuiWindow(
        NuiCol(jCol),
        JsonString("NuiMargin Test"),
        NuiRect(-1.0, -1.0, 500.0, 220.0),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE));

    int nToken = NuiCreate(oPC, jWin, NUIMGN_WIN, "");

    if (nToken == 0) return;

    NuiSetUserData(oPC, nToken, jWin);
}
