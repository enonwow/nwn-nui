// =============================================================================
// nuipadding.nss
// Modifier test: NuiPadding() spacing inside element.
// =============================================================================

#include "nw_inc_nui"

const string NUIPAD_WIN = "IT_NUIPAD_WIN";

json NuiPadCentered(json jWidget)
{
    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    jRow = JsonArrayInsert(jRow, jWidget);
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    return NuiRow(jRow);
}

json NuiPadCell(string sTitle, json jPanel)
{
    json jLbl = NuiLabel(JsonString(sTitle), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jLbl = NuiHeight(jLbl, 24.0);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jLbl);
    jCol = JsonArrayInsert(jCol, jPanel);
    return NuiCol(jCol);
}

void NuiPadOpen(object oPC)
{
    if (!GetIsPC(oPC)) return;

    int nOld = NuiFindWindow(oPC, NUIPAD_WIN);
    if (nOld != 0) NuiDestroy(oPC, nOld);

    json jPlain = NuiGroup(
        NuiLabel(JsonString("content"), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)),
        TRUE,
        NUI_SCROLLBARS_NONE);
    jPlain = NuiWidth(jPlain, 120.0);
    jPlain = NuiHeight(jPlain, 54.0);

    json jPadded = NuiGroup(
        NuiLabel(JsonString("content"), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)),
        TRUE,
        NUI_SCROLLBARS_NONE);
    jPadded = NuiPadding(jPadded, 12.0);
    jPadded = NuiWidth(jPadded, 120.0);
    jPadded = NuiHeight(jPadded, 54.0);

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiPadCell("No padding", jPlain));
    jRow = JsonArrayInsert(jRow, NuiWidth(NuiSpacer(), 20.0));
    jRow = JsonArrayInsert(jRow, NuiPadCell("Padding 12", jPadded));
    jRow = NuiRow(jRow);

    json jHelp = NuiLabel(
        JsonString("Right panel has NuiPadding(12.0)."),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE));
    jHelp = NuiHeight(jHelp, 24.0);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));
    jCol = JsonArrayInsert(jCol, NuiPadCentered(jHelp));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 8.0));
    jCol = JsonArrayInsert(jCol, NuiPadCentered(jRow));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));

    json jWin = NuiWindow(
        NuiCol(jCol),
        JsonString("NuiPadding Test"),
        NuiRect(-1.0, -1.0, 460.0, 230.0),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE));

    int nToken = NuiCreate(oPC, jWin, NUIPAD_WIN, "");

    if (nToken == 0) return;

    NuiSetUserData(oPC, nToken, jWin);
}
