// =============================================================================
// nuitoggles.nss
// Integration test: one window + one NuiToggles.
// =============================================================================

#include "nw_inc_nui"

const string NUITOG_WIN  = "IT_NUITOG_WIN";
const string NUITOG_SEL  = "it_nuitog_sel";

json NuiTogCentered(json jWidget)
{
    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    jRow = JsonArrayInsert(jRow, jWidget);
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    return NuiRow(jRow);
}

json NuiTogLabels()
{
    json jTabs = JsonArray();
    jTabs = JsonArrayInsert(jTabs, JsonString("Tab A"));
    jTabs = JsonArrayInsert(jTabs, JsonString("Tab B"));
    jTabs = JsonArrayInsert(jTabs, JsonString("Tab C"));
    return jTabs;
}

void NuiTogOpen(object oPC)
{
    if (!GetIsPC(oPC)) return;

    int nOld = NuiFindWindow(oPC, NUITOG_WIN);
    if (nOld != 0) NuiDestroy(oPC, nOld);

    json jToggles = NuiToggles(
        NUI_DIRECTION_HORIZONTAL,
        NuiTogLabels(),
        NuiBind(NUITOG_SEL));
    // Tabbar uses wide built-in tab style; keep enough width to avoid horizontal overflow.
    jToggles = NuiWidth(jToggles, 480.0);
    jToggles = NuiHeight(jToggles, 35.0);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 12.0));
    jCol = JsonArrayInsert(jCol, NuiTogCentered(jToggles));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 12.0));

    json jWin = NuiWindow(
        NuiCol(jCol),
        JsonString("NuiToggles Test"),
        NuiRect(-1.0, -1.0, 620.0, 150.0),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE));

    int nToken = NuiCreate(oPC, jWin, NUITOG_WIN, "");
    if (nToken == 0) return;



    NuiSetUserData(oPC, nToken, jWin);
    NuiSetBind(oPC, nToken, NUITOG_SEL, JsonInt(1));
}

