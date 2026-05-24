// =============================================================================
// nuigeombind.nss
// Integration test: runtime geometry updates via NuiBind + NuiSetBind.
// =============================================================================

#include "nw_inc_nui"

const string NUIGEO_WIN       = "IT_NUIGEO_WIN";
const string NUIGEO_EV        = "nuigeombind_ev";
const string NUIGEO_RECT      = "it_nuigeo_rect";
const string NUIGEO_MSG       = "it_nuigeo_msg";
const string NUIGEO_BTN_MID   = "it_nuigeo_mid";
const string NUIGEO_BTN_SMALL = "it_nuigeo_sml";
const string NUIGEO_BTN_WIDE  = "it_nuigeo_wid";

json NuiGeoCentered(json jWidget)
{
    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    jRow = JsonArrayInsert(jRow, jWidget);
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    return NuiRow(jRow);
}

void NuiGeoOpen(object oPC)
{
    if (!GetIsPC(oPC)) return;

    int nOld = NuiFindWindow(oPC, NUIGEO_WIN);
    if (nOld != 0) NuiDestroy(oPC, nOld);

    json jMid = NuiId(NuiButton(JsonString("Centered")), NUIGEO_BTN_MID);
    jMid = NuiWidth(jMid, 120.0);
    jMid = NuiHeight(jMid, 32.0);

    json jSmall = NuiId(NuiButton(JsonString("Compact")), NUIGEO_BTN_SMALL);
    jSmall = NuiWidth(jSmall, 120.0);
    jSmall = NuiHeight(jSmall, 32.0);

    json jWide = NuiId(NuiButton(JsonString("Wide")), NUIGEO_BTN_WIDE);
    jWide = NuiWidth(jWide, 120.0);
    jWide = NuiHeight(jWide, 32.0);

    json jButtons = JsonArray();
    jButtons = JsonArrayInsert(jButtons, NuiSpacer());
    jButtons = JsonArrayInsert(jButtons, jMid);
    jButtons = JsonArrayInsert(jButtons, NuiWidth(NuiSpacer(), 8.0));
    jButtons = JsonArrayInsert(jButtons, jSmall);
    jButtons = JsonArrayInsert(jButtons, NuiWidth(NuiSpacer(), 8.0));
    jButtons = JsonArrayInsert(jButtons, jWide);
    jButtons = JsonArrayInsert(jButtons, NuiSpacer());
    jButtons = NuiRow(jButtons);

    json jHint = NuiLabel(
        JsonString("Buttons below change window geometry via bound rect."),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE));
    jHint = NuiHeight(jHint, 24.0);

    json jMsg = NuiLabel(NuiBind(NUIGEO_MSG), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jMsg = NuiHeight(jMsg, 24.0);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));
    jCol = JsonArrayInsert(jCol, NuiGeoCentered(jHint));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 8.0));
    jCol = JsonArrayInsert(jCol, jButtons);
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 8.0));
    jCol = JsonArrayInsert(jCol, NuiGeoCentered(jMsg));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));

    json jWin = NuiWindow(
        NuiCol(jCol),
        JsonString("NuiGeomBind Test"),
        NuiBind(NUIGEO_RECT),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE));

    int nToken = NuiCreate(oPC, jWin, NUIGEO_WIN, NUIGEO_EV);
    if (nToken == 0) return;

    NuiSetUserData(oPC, nToken, jWin);
    NuiSetBind(oPC, nToken, NUIGEO_RECT, NuiRect(-1.0, -1.0, 520.0, 210.0));
    NuiSetBind(oPC, nToken, NUIGEO_MSG, JsonString("Current: centered 520x210."));
}

