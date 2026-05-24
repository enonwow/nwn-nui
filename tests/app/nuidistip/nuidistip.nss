// =============================================================================
// nuidistip.nss
// Modifier test: NuiDisabledTooltip() on disabled widget.
// =============================================================================

#include "nw_inc_nui"

const string NUIDST_WIN = "IT_NUIDST_WIN";

json NuiDstCentered(json jWidget)
{
    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    jRow = JsonArrayInsert(jRow, jWidget);
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    return NuiRow(jRow);
}

void NuiDstOpen(object oPC)
{
    if (!GetIsPC(oPC)) return;

    int nOld = NuiFindWindow(oPC, NUIDST_WIN);
    if (nOld != 0) NuiDestroy(oPC, nOld);

    json jOn = NuiButton(JsonString("Enabled"));
    jOn = NuiTooltip(jOn, JsonString("Standard tooltip for enabled button."));
    jOn = NuiWidth(jOn, 140.0);
    jOn = NuiHeight(jOn, 34.0);

    json jOff = NuiButton(JsonString("Disabled"));
    jOff = NuiEnabled(jOff, JsonBool(FALSE));
    jOff = NuiDisabledTooltip(jOff, JsonString("Disabled tooltip is shown here."));
    jOff = NuiWidth(jOff, 140.0);
    jOff = NuiHeight(jOff, 34.0);

    json jHelp = NuiLabel(
        JsonString("Hover both buttons; second is disabled + has disabled tooltip."),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE));
    jHelp = NuiHeight(jHelp, 24.0);

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, jOn);
    jRow = JsonArrayInsert(jRow, NuiWidth(NuiSpacer(), 16.0));
    jRow = JsonArrayInsert(jRow, jOff);
    jRow = NuiRow(jRow);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));
    jCol = JsonArrayInsert(jCol, NuiDstCentered(jHelp));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 8.0));
    jCol = JsonArrayInsert(jCol, NuiDstCentered(jRow));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));

    json jWin = NuiWindow(
        NuiCol(jCol),
        JsonString("NuiDisabledTooltip Test"),
        NuiRect(-1.0, -1.0, 460.0, 210.0),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE));

    int nToken = NuiCreate(oPC, jWin, NUIDST_WIN, "");

    if (nToken == 0) return;

    NuiSetUserData(oPC, nToken, jWin);
}
