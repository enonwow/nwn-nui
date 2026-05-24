// =============================================================================
// nuitst_menu2.nss
// tests/nwn launcher menu:
// - Script Export test path
// - JUI Export test path
// =============================================================================

#include "nw_inc_nui"

const string NUITM2_WIN    = "ITNWN_MENU2_WIN";
const string NUITM2_EV     = "nuitst_menu2";
const string NUITM2_BTN_S  = "itnwn_btn_scr";
const string NUITM2_BTN_J  = "itnwn_btn_jui";

json NuiTm2Centered(json jWidget)
{
    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    jRow = JsonArrayInsert(jRow, jWidget);
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    return NuiRow(jRow);
}

void NuiTm2Open(object oPC)
{
    if (!GetIsObjectValid(oPC) || !GetIsPC(oPC) || GetIsDM(oPC)) return;

    int nOld = NuiFindWindow(oPC, NUITM2_WIN);
    if (nOld != 0) NuiDestroy(oPC, nOld);

    json jTitle = NuiLabel(
        JsonString("tests/nwn launcher"),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE));
    jTitle = NuiHeight(jTitle, 24.0);

    json jInfo = NuiLabel(
        JsonString("Script/JUI baseline tests: Label, Button, Options (all 600x600)."),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE));
    jInfo = NuiHeight(jInfo, 22.0);

    json jBtnScript = NuiId(NuiButton(JsonString("Script Export Test")), NUITM2_BTN_S);
    jBtnScript = NuiWidth(jBtnScript, 190.0);
    jBtnScript = NuiHeight(jBtnScript, 34.0);

    json jBtnJui = NuiId(NuiButton(JsonString("JUI Export Test")), NUITM2_BTN_J);
    jBtnJui = NuiWidth(jBtnJui, 190.0);
    jBtnJui = NuiHeight(jBtnJui, 34.0);

    json jBtnRow = JsonArray();
    jBtnRow = JsonArrayInsert(jBtnRow, jBtnScript);
    jBtnRow = JsonArrayInsert(jBtnRow, NuiWidth(NuiSpacer(), 12.0));
    jBtnRow = JsonArrayInsert(jBtnRow, jBtnJui);
    jBtnRow = NuiRow(jBtnRow);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));
    jCol = JsonArrayInsert(jCol, NuiTm2Centered(jTitle));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 6.0));
    jCol = JsonArrayInsert(jCol, NuiTm2Centered(jInfo));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));
    jCol = JsonArrayInsert(jCol, NuiTm2Centered(jBtnRow));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));

    json jWin = NuiWindow(
        NuiCol(jCol),
        JsonString("ITNWN Menu"),
        NuiRect(-1.0, -1.0, 500.0, 160.0),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE));

    NuiCreate(oPC, jWin, NUITM2_WIN, NUITM2_EV);
}

void main()
{
    string sEvent = NuiGetEventType();

    if (sEvent == "")
    {
        object oPC = GetLastUsedBy();
        if (!GetIsObjectValid(oPC) || !GetIsPC(oPC))
        {
            oPC = GetFirstPC();
        }
        NuiTm2Open(oPC);
        return;
    }

    object oPC = NuiGetEventPlayer();
    string sElement = NuiGetEventElement();
    if (!GetIsObjectValid(oPC) || !GetIsPC(oPC)) return;

    if (sEvent == "click" && sElement == NUITM2_BTN_S)
    {
        ExecuteScript("nuitst_scrrun", oPC);
        return;
    }
    if (sEvent == "click" && sElement == NUITM2_BTN_J)
    {
        ExecuteScript("nuitst_juiopn", oPC);
        return;
    }
}
