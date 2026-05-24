// =============================================================================
// nuiprogcolor.nss
// Integration test: three NuiProgress bars with foreground style colors.
// =============================================================================

#include "nw_inc_nui"

const string NUIPC_WIN = "IT_NUIPC_WIN";

json NuiPcCentered(json jWidget)
{
    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    jRow = JsonArrayInsert(jRow, jWidget);
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    return NuiRow(jRow);
}

json NuiPcRow(string sLabel, float fValue, json jColor)
{
    json jTxt = NuiLabel(JsonString(sLabel), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTxt = NuiWidth(jTxt, 56.0);

    json jProg = NuiProgress(JsonFloat(fValue));
    jProg = NuiStyleForegroundColor(jProg, jColor);
    jProg = NuiWidth(jProg, 230.0);
    jProg = NuiHeight(jProg, 24.0);

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, jTxt);
    jRow = JsonArrayInsert(jRow, NuiWidth(NuiSpacer(), 8.0));
    jRow = JsonArrayInsert(jRow, jProg);
    return NuiRow(jRow);
}

void NuiPcOpen(object oPC)
{
    if (!GetIsPC(oPC)) return;

    int nOld = NuiFindWindow(oPC, NUIPC_WIN);
    if (nOld != 0) NuiDestroy(oPC, nOld);

    json jColRows = JsonArray();
    jColRows = JsonArrayInsert(jColRows, NuiPcRow("Low", 0.25, NuiColor(185, 70, 60, 255)));
    jColRows = JsonArrayInsert(jColRows, NuiHeight(NuiSpacer(), 6.0));
    jColRows = JsonArrayInsert(jColRows, NuiPcRow("Mid", 0.55, NuiColor(210, 165, 70, 255)));
    jColRows = JsonArrayInsert(jColRows, NuiHeight(NuiSpacer(), 6.0));
    jColRows = JsonArrayInsert(jColRows, NuiPcRow("High", 0.85, NuiColor(70, 165, 90, 255)));
    jColRows = NuiCol(jColRows);

    json jHint = NuiLabel(
        JsonString("Color via NuiStyleForegroundColor on NuiProgress."),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE));
    jHint = NuiHeight(jHint, 24.0);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));
    jCol = JsonArrayInsert(jCol, NuiPcCentered(jHint));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 8.0));
    jCol = JsonArrayInsert(jCol, NuiPcCentered(jColRows));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));

    json jWin = NuiWindow(
        NuiCol(jCol),
        JsonString("NuiProgressColor Test"),
        NuiRect(-1.0, -1.0, 430.0, 240.0),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE));

    int nToken = NuiCreate(oPC, jWin, NUIPC_WIN, "");

    if (nToken == 0) return;

    NuiSetUserData(oPC, nToken, jWin);
}
