// =============================================================================
// nuioptions.nss
// Integration test: one window + one NuiOptions.
// =============================================================================

#include "nw_inc_nui"

const string NUIOPT_WIN  = "IT_NUIOPT_WIN";
const string NUIOPT_SEL  = "it_nuiopt_sel";

json NuiOptCentered(json jWidget)
{
    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    jRow = JsonArrayInsert(jRow, jWidget);
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    return NuiRow(jRow);
}

json NuiOptEntries()
{
    json jEntries = JsonArray();
    jEntries = JsonArrayInsert(jEntries, JsonString("Option A"));
    jEntries = JsonArrayInsert(jEntries, JsonString("Option B"));
    jEntries = JsonArrayInsert(jEntries, JsonString("Option C"));
    return jEntries;
}

void NuiOptOpen(object oPC)
{
    if (!GetIsPC(oPC)) return;

    int nOld = NuiFindWindow(oPC, NUIOPT_WIN);
    if (nOld != 0) NuiDestroy(oPC, nOld);

    json jOptions = NuiOptions(
        NUI_DIRECTION_VERTICAL,
        NuiOptEntries(),
        NuiBind(NUIOPT_SEL));
    jOptions = NuiWidth(jOptions, 220.0);
    jOptions = NuiHeight(jOptions, 94.0);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));
    jCol = JsonArrayInsert(jCol, NuiOptCentered(jOptions));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));

    json jWin = NuiWindow(
        NuiCol(jCol),
        JsonString("NuiOptions Test"),
        NuiRect(-1.0, -1.0, 380.0, 210.0),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE));

    int nToken = NuiCreate(oPC, jWin, NUIOPT_WIN, "");
    if (nToken == 0) return;



    NuiSetUserData(oPC, nToken, jWin);
    NuiSetBind(oPC, nToken, NUIOPT_SEL, JsonInt(1));
}

