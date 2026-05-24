// =============================================================================
// nuitooltip.nss
// Modifier test: NuiTooltip().
// =============================================================================

#include "nw_inc_nui"

const string NUITIP_WIN = "IT_NUITIP_WIN";

json NuiTipCentered(json jWidget)
{
    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    jRow = JsonArrayInsert(jRow, jWidget);
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    return NuiRow(jRow);
}

void NuiTipOpen(object oPC)
{
    if (!GetIsPC(oPC)) return;

    int nOld = NuiFindWindow(oPC, NUITIP_WIN);
    if (nOld != 0) NuiDestroy(oPC, nOld);

    json jBtn = NuiButton(JsonString("Hover Me"));
    jBtn = NuiTooltip(jBtn, JsonString("Tooltip: standard button hover."));
    jBtn = NuiWidth(jBtn, 150.0);
    jBtn = NuiHeight(jBtn, 34.0);

    json jImgBtn = NuiButtonImage(JsonString("ir_follow"));
    jImgBtn = NuiTooltip(jImgBtn, JsonString("Tooltip: image button hover."));
    jImgBtn = NuiWidth(jImgBtn, 64.0);
    jImgBtn = NuiHeight(jImgBtn, 64.0);

    json jHelp = NuiLabel(
        JsonString("Hover controls to display tooltips."),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE));
    jHelp = NuiHeight(jHelp, 24.0);

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, jBtn);
    jRow = JsonArrayInsert(jRow, NuiWidth(NuiSpacer(), 16.0));
    jRow = JsonArrayInsert(jRow, jImgBtn);
    jRow = NuiRow(jRow);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));
    jCol = JsonArrayInsert(jCol, NuiTipCentered(jHelp));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 8.0));
    jCol = JsonArrayInsert(jCol, NuiTipCentered(jRow));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));

    json jWin = NuiWindow(
        NuiCol(jCol),
        JsonString("NuiTooltip Test"),
        NuiRect(-1.0, -1.0, 420.0, 210.0),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE));

    int nToken = NuiCreate(oPC, jWin, NUITIP_WIN, "");

    if (nToken == 0) return;

    NuiSetUserData(oPC, nToken, jWin);
}
