// =============================================================================
// nuilstenc.nss
// Complex test: clickable list with row-level encouraged state.
// =============================================================================

#include "nw_inc_nui"

const string NUILSE_WIN    = "IT_NUILSE_WIN";
const string NUILSE_EV     = "nuilstenc_ev";
const string NUILSE_BTN    = "it_nuilse_btn";
const string NUILSE_NAMES  = "it_nuilse_names";
const string NUILSE_ENC    = "it_nuilse_enc";
const string NUILSE_COUNT  = "it_nuilse_count";
const string NUILSE_STATUS = "it_nuilse_status";

json NuiLseCentered(json jWidget)
{
    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    jRow = JsonArrayInsert(jRow, jWidget);
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    return NuiRow(jRow);
}

json NuiLseNames()
{
    json j = JsonArray();
    j = JsonArrayInsert(j, JsonString("Entry 01"));
    j = JsonArrayInsert(j, JsonString("Entry 02"));
    j = JsonArrayInsert(j, JsonString("Entry 03"));
    j = JsonArrayInsert(j, JsonString("Entry 04"));
    j = JsonArrayInsert(j, JsonString("Entry 05"));
    j = JsonArrayInsert(j, JsonString("Entry 06"));
    return j;
}

json NuiLseEncArray(int nSelected, int nCount)
{
    json j = JsonArray();
    int i;
    for (i = 0; i < nCount; i++)
    {
        j = JsonArrayInsert(j, JsonBool(i == nSelected));
    }
    return j;
}

void NuiLseSync(object oPC, int nToken, int nSelected)
{
    json jNames = NuiLseNames();
    int nCount = JsonGetLength(jNames);

    NuiSetBind(oPC, nToken, NUILSE_NAMES, jNames);
    NuiSetBind(oPC, nToken, NUILSE_COUNT, JsonInt(nCount));
    NuiSetBind(oPC, nToken, NUILSE_ENC, NuiLseEncArray(nSelected, nCount));

    if (nSelected >= 0 && nSelected < nCount)
    {
        string sSel = JsonGetString(JsonArrayGet(jNames, nSelected));
        NuiSetBind(oPC, nToken, NUILSE_STATUS, JsonString("Selected: " + sSel));
    }
    else
    {
        NuiSetBind(oPC, nToken, NUILSE_STATUS, JsonString("Selected: none"));
    }
}

void NuiLseOpen(object oPC)
{
    if (!GetIsPC(oPC)) return;

    int nOld = NuiFindWindow(oPC, NUILSE_WIN);
    if (nOld != 0) NuiDestroy(oPC, nOld);

    json jName = NuiLabel(NuiBind(NUILSE_NAMES), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));

    json jBtn = NuiId(NuiButton(JsonString("Select")), NUILSE_BTN);
    jBtn = NuiEncouraged(jBtn, NuiBind(NUILSE_ENC));
    jBtn = NuiWidth(jBtn, 92.0);
    jBtn = NuiHeight(jBtn, 26.0);

    json jTemplate = JsonArray();
    jTemplate = JsonArrayInsert(jTemplate, NuiListTemplateCell(jName, 0.0, TRUE));
    jTemplate = JsonArrayInsert(jTemplate, NuiListTemplateCell(jBtn, 98.0, FALSE));

    json jList = NuiList(jTemplate, NuiBind(NUILSE_COUNT), 30.0, TRUE, NUI_SCROLLBARS_Y);
    jList = NuiWidth(jList, 360.0);
    jList = NuiHeight(jList, 190.0);

    json jStatus = NuiLabel(NuiBind(NUILSE_STATUS), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jStatus = NuiHeight(jStatus, 24.0);

    json jHelp = NuiLabel(
        JsonString("Click Select in any row; selected row button becomes encouraged."),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE));
    jHelp = NuiHeight(jHelp, 24.0);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 8.0));
    jCol = JsonArrayInsert(jCol, NuiLseCentered(jHelp));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 6.0));
    jCol = JsonArrayInsert(jCol, NuiLseCentered(jList));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 6.0));
    jCol = JsonArrayInsert(jCol, NuiLseCentered(jStatus));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 8.0));

    json jWin = NuiWindow(
        NuiCol(jCol),
        JsonString("NuiListEncouraged Test"),
        NuiRect(-1.0, -1.0, 500.0, 340.0),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE));

    int nToken = NuiCreate(oPC, jWin, NUILSE_WIN, NUILSE_EV);
    if (nToken == 0) return;



    NuiSetUserData(oPC, nToken, jWin);
    NuiLseSync(oPC, nToken, -1);
}
