// =============================================================================
// nuichartcol.nss
// Integration test: NuiChart with column/bar slot type.
// =============================================================================

#include "nw_inc_nui"

const string NUICC_WIN  = "IT_NUICC_WIN";
const string NUICC_DATA = "it_nuicc_data";

json NuiCclCentered(json jWidget)
{
    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    jRow = JsonArrayInsert(jRow, jWidget);
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    return NuiRow(jRow);
}

json NuiCclData()
{
    json jData = JsonArray();
    jData = JsonArrayInsert(jData, JsonFloat(0.20));
    jData = JsonArrayInsert(jData, JsonFloat(0.55));
    jData = JsonArrayInsert(jData, JsonFloat(0.35));
    jData = JsonArrayInsert(jData, JsonFloat(0.80));
    jData = JsonArrayInsert(jData, JsonFloat(0.48));
    return jData;
}

json NuiCclSlots()
{
    json jSlots = JsonArray();
    json jSlot = NuiChartSlot(
        NUI_CHART_TYPE_COLUMN,
        JsonString(""),
        NuiColor(245, 170, 90, 255),
        NuiBind(NUICC_DATA));
    jSlots = JsonArrayInsert(jSlots, jSlot);
    return jSlots;
}

void NuiCclOpen(object oPC)
{
    if (!GetIsPC(oPC)) return;

    int nOld = NuiFindWindow(oPC, NUICC_WIN);
    if (nOld != 0) NuiDestroy(oPC, nOld);

    json jChart = NuiChart(NuiCclSlots());
    jChart = NuiWidth(jChart, 320.0);
    jChart = NuiHeight(jChart, 180.0);

    json jHint = NuiLabel(
        JsonString("NUI_CHART_TYPE_COLUMN visual check."),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE));
    jHint = NuiHeight(jHint, 20.0);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));
    jCol = JsonArrayInsert(jCol, NuiCclCentered(jChart));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 6.0));
    jCol = JsonArrayInsert(jCol, NuiCclCentered(jHint));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));

    json jWin = NuiWindow(
        NuiCol(jCol),
        JsonString("NuiChart Column Test"),
        NuiRect(-1.0, -1.0, 470.0, 300.0),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE));

    int nToken = NuiCreate(oPC, jWin, NUICC_WIN, "");
    if (nToken == 0) return;

    NuiSetUserData(oPC, nToken, jWin);
    NuiSetBind(oPC, nToken, NUICC_DATA, NuiCclData());
}
