// =============================================================================
// nuivisible.nss
// Modifier test: NuiVisible(FALSE) keeps layout space.
// =============================================================================

#include "nw_inc_nui"

const string NUIVIS_WIN = "IT_NUIVIS_WIN";

json NuiVisCentered(json jWidget)
{
    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    jRow = JsonArrayInsert(jRow, jWidget);
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    return NuiRow(jRow);
}

void NuiVisOpen(object oPC)
{
    if (!GetIsPC(oPC)) return;

    int nOld = NuiFindWindow(oPC, NUIVIS_WIN);
    if (nOld != 0) NuiDestroy(oPC, nOld);

    json jA = NuiButton(JsonString("A"));
    jA = NuiWidth(jA, 90.0);
    jA = NuiHeight(jA, 34.0);

    json jHidden = NuiButton(JsonString("B"));
    jHidden = NuiWidth(jHidden, 90.0);
    jHidden = NuiHeight(jHidden, 34.0);
    jHidden = NuiVisible(jHidden, JsonBool(FALSE));

    json jC = NuiButton(JsonString("C"));
    jC = NuiWidth(jC, 90.0);
    jC = NuiHeight(jC, 34.0);

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, jA);
    jRow = JsonArrayInsert(jRow, NuiWidth(NuiSpacer(), 10.0));
    jRow = JsonArrayInsert(jRow, jHidden);
    jRow = JsonArrayInsert(jRow, NuiWidth(NuiSpacer(), 10.0));
    jRow = JsonArrayInsert(jRow, jC);
    jRow = NuiRow(jRow);

    json jFrame = NuiGroup(jRow, TRUE, NUI_SCROLLBARS_NONE);
    jFrame = NuiWidth(jFrame, 330.0);
    jFrame = NuiHeight(jFrame, 56.0);

    json jHelp = NuiLabel(
        JsonString("Middle widget is invisible, but its layout gap should remain."),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE));
    jHelp = NuiHeight(jHelp, 24.0);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));
    jCol = JsonArrayInsert(jCol, NuiVisCentered(jHelp));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 8.0));
    jCol = JsonArrayInsert(jCol, NuiVisCentered(jFrame));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));

    json jWin = NuiWindow(
        NuiCol(jCol),
        JsonString("NuiVisible Test"),
        NuiRect(-1.0, -1.0, 470.0, 210.0),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE));

    int nToken = NuiCreate(oPC, jWin, NUIVIS_WIN, "");

    if (nToken == 0) return;

    NuiSetUserData(oPC, nToken, jWin);
}
