// =============================================================================
// nuicombo.nss
// Integration test: one window + one NuiCombo.
// =============================================================================

#include "nw_inc_nui"

const string NUICMB_WIN  = "IT_NUICMB_WIN";
const string NUICMB_LIST = "it_nuicmb_list";
const string NUICMB_SEL  = "it_nuicmb_sel";

json NuiCmbCentered(json jWidget)
{
    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    jRow = JsonArrayInsert(jRow, jWidget);
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    return NuiRow(jRow);
}

json NuiCmbEntries()
{
    json jEntries = JsonArray();
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("Option A", 100));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("Option B", 200));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("Option C", 300));
    return jEntries;
}

void NuiCmbOpen(object oPC)
{
    if (!GetIsPC(oPC)) return;

    int nOld = NuiFindWindow(oPC, NUICMB_WIN);
    if (nOld != 0) NuiDestroy(oPC, nOld);

    json jCombo = NuiCombo(NuiBind(NUICMB_LIST), NuiBind(NUICMB_SEL));
    jCombo = NuiWidth(jCombo, 220.0);
    jCombo = NuiHeight(jCombo, 32.0);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 12.0));
    jCol = JsonArrayInsert(jCol, NuiCmbCentered(jCombo));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 12.0));

    json jWin = NuiWindow(
        NuiCol(jCol),
        JsonString("NuiCombo Test"),
        NuiRect(-1.0, -1.0, 380.0, 140.0),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE));

    int nToken = NuiCreate(oPC, jWin, NUICMB_WIN, "");
    if (nToken == 0) return;



    NuiSetUserData(oPC, nToken, jWin);
    NuiSetBind(oPC, nToken, NUICMB_LIST, NuiCmbEntries());
    NuiSetBind(oPC, nToken, NUICMB_SEL, JsonInt(1));
}

