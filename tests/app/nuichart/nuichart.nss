// =============================================================================
// nuichart.nss
// Integration test: one window + one NuiChart (single line slot).
// =============================================================================

#include "nw_inc_nui"

const string NUICHT_WIN  = "IT_NUICHT_WIN";
const string NUICHT_DATA = "it_nuicht_data";

json NuiChtCentered(json jWidget)
{
    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    jRow = JsonArrayInsert(jRow, jWidget);
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    return NuiRow(jRow);
}

json NuiChtData()
{
    json jData = JsonArray();
    jData = JsonArrayInsert(jData, JsonFloat(0.10));
    jData = JsonArrayInsert(jData, JsonFloat(0.30));
    jData = JsonArrayInsert(jData, JsonFloat(0.20));
    jData = JsonArrayInsert(jData, JsonFloat(0.60));
    jData = JsonArrayInsert(jData, JsonFloat(0.45));
    jData = JsonArrayInsert(jData, JsonFloat(0.80));
    return jData;
}

json NuiChtSlots()
{
    json jSlots = JsonArray();
    json jSlot = NuiChartSlot(
        NUI_CHART_TYPE_LINES,
        JsonString("Series A"),
        NuiColor(90, 180, 255, 255),
        NuiBind(NUICHT_DATA));
    jSlots = JsonArrayInsert(jSlots, jSlot);
    return jSlots;
}

void NuiChtOpen(object oPC)
{
    if (!GetIsPC(oPC)) return;

    int nOld = NuiFindWindow(oPC, NUICHT_WIN);
    if (nOld != 0) NuiDestroy(oPC, nOld);

    json jChart = NuiChart(NuiChtSlots());
    jChart = NuiWidth(jChart, 320.0);
    jChart = NuiHeight(jChart, 180.0);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));
    jCol = JsonArrayInsert(jCol, NuiChtCentered(jChart));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));

    json jWin = NuiWindow(
        NuiCol(jCol),
        JsonString("NuiChart Test"),
        NuiRect(-1.0, -1.0, 470.0, 290.0),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE));

    int nToken = NuiCreate(oPC, jWin, NUICHT_WIN, "");
    if (nToken == 0) return;



    NuiSetUserData(oPC, nToken, jWin);
    NuiSetBind(oPC, nToken, NUICHT_DATA, NuiChtData());
}

