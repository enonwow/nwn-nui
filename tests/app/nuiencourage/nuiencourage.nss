// =============================================================================
// nuiencourage.nss
// Modifier test: NuiEncouraged().
// =============================================================================

#include "nw_inc_nui"

const string NUIENC_WIN = "IT_NUIENC_WIN";

json NuiEncCentered(json jWidget)
{
    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    jRow = JsonArrayInsert(jRow, jWidget);
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    return NuiRow(jRow);
}

void NuiEncOpen(object oPC)
{
    if (!GetIsPC(oPC)) return;

    int nOld = NuiFindWindow(oPC, NUIENC_WIN);
    if (nOld != 0) NuiDestroy(oPC, nOld);

    json jNormal = NuiButton(JsonString("Normal"));
    jNormal = NuiWidth(jNormal, 140.0);
    jNormal = NuiHeight(jNormal, 34.0);

    json jEnc = NuiButton(JsonString("Encouraged"));
    jEnc = NuiEncouraged(jEnc, JsonBool(TRUE));
    jEnc = NuiWidth(jEnc, 140.0);
    jEnc = NuiHeight(jEnc, 34.0);

    json jHelp = NuiLabel(
        JsonString("Right button should have breathing glow."),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE));
    jHelp = NuiHeight(jHelp, 24.0);

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, jNormal);
    jRow = JsonArrayInsert(jRow, NuiWidth(NuiSpacer(), 16.0));
    jRow = JsonArrayInsert(jRow, jEnc);
    jRow = NuiRow(jRow);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));
    jCol = JsonArrayInsert(jCol, NuiEncCentered(jHelp));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 8.0));
    jCol = JsonArrayInsert(jCol, NuiEncCentered(jRow));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));

    json jWin = NuiWindow(
        NuiCol(jCol),
        JsonString("NuiEncouraged Test"),
        NuiRect(-1.0, -1.0, 440.0, 210.0),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE));

    int nToken = NuiCreate(oPC, jWin, NUIENC_WIN, "");

    if (nToken == 0) return;

    NuiSetUserData(oPC, nToken, jWin);
}
