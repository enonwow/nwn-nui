// =============================================================================
// nuiaspmod.nss
// Modifier test: NuiAspect() on fixed-width elements.
// =============================================================================

#include "nw_inc_nui"

const string NUIASM_WIN = "IT_NUIASM_WIN";

json NuiAsmCentered(json jWidget)
{
    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    jRow = JsonArrayInsert(jRow, jWidget);
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    return NuiRow(jRow);
}

json NuiAsmCell(string sTitle, float fAspect)
{
    json jBox = NuiGroup(NuiSpacer(), TRUE, NUI_SCROLLBARS_NONE);
    jBox = NuiWidth(jBox, 120.0);
    jBox = NuiAspect(jBox, fAspect);

    json jLbl = NuiLabel(JsonString(sTitle), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jLbl = NuiHeight(jLbl, 24.0);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jLbl);
    jCol = JsonArrayInsert(jCol, jBox);
    return NuiCol(jCol);
}

void NuiAsmOpen(object oPC)
{
    if (!GetIsPC(oPC)) return;

    int nOld = NuiFindWindow(oPC, NUIASM_WIN);
    if (nOld != 0) NuiDestroy(oPC, nOld);

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiAsmCell("Aspect 1.0", 1.0));
    jRow = JsonArrayInsert(jRow, NuiWidth(NuiSpacer(), 18.0));
    jRow = JsonArrayInsert(jRow, NuiAsmCell("Aspect 2.0", 2.0));
    jRow = NuiRow(jRow);

    json jHint = NuiLabel(
        JsonString("Both boxes have width 120; height is from NuiAspect."),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE));
    jHint = NuiHeight(jHint, 24.0);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));
    jCol = JsonArrayInsert(jCol, NuiAsmCentered(jHint));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 8.0));
    jCol = JsonArrayInsert(jCol, NuiAsmCentered(jRow));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));

    json jWin = NuiWindow(
        NuiCol(jCol),
        JsonString("NuiAspectMod Test"),
        NuiRect(-1.0, -1.0, 420.0, 260.0),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE));

    int nToken = NuiCreate(oPC, jWin, NUIASM_WIN, "");

    if (nToken == 0) return;

    NuiSetUserData(oPC, nToken, jWin);
}
