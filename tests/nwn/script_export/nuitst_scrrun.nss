// =============================================================================
// nuitst_scrrun.nss
// Script-export launcher opener (direct-run only).
// NUI events are handled in: nuitst_screv.nss
// =============================================================================

#include "nw_inc_nui"

const string NUITSCR_WIN      = "ITNWN_SCR_WIN";
const string NUITSCR_EVENT    = "nuitst_screv";
const string NUITSCR_LIST     = "itnwn_scr_list";
const string NUITSCR_SELECTED = "itnwn_scr_selected";
const string NUITSCR_OPEN_EN  = "itnwn_scr_open_en";
const string NUITSCR_BTN_OPEN = "itnwn_scr_open_btn";
const string NUITSCR_BTN_JSON = "itnwn_scr_json_btn";

const int NUITSCR_NONE        = 0;
const int NUITSCR_TLBL        = 1;
const int NUITSCR_TBTN        = 2;
const int NUITSCR_TOPT        = 3;
const int NUITSCR_TCHK        = 4;
const int NUITSCR_TSLD        = 5;
const int NUITSCR_TPRG        = 6;
const int NUITSCR_TTXE        = 7;
const int NUITSCR_TBIM        = 8;
const int NUITSCR_TBSE        = 9;
const int NUITSCR_TCLR        = 10;
const int NUITSCR_TCMB        = 11;
const int NUITSCR_TIMG        = 12;
const int NUITSCR_TSLF        = 13;
const int NUITSCR_TTXT        = 14;
const int NUITSCR_TTOG        = 15;
const int NUITSCR_TCHA        = 16;
const int NUITSCR_TDLA        = 17;
const int NUITSCR_TDLC        = 18;
const int NUITSCR_TDLV        = 19;
const int NUITSCR_TDLI        = 20;
const int NUITSCR_TDIR        = 21;
const int NUITSCR_TDLL        = 22;
const int NUITSCR_TDLP        = 23;
const int NUITSCR_TDLR        = 24;
const int NUITSCR_TDLT        = 25;

json NuiTScrCentered(json jWidget)
{
    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    jRow = JsonArrayInsert(jRow, jWidget);
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    return NuiRow(jRow);
}

json NuiTScrEntries()
{
    json jEntries = JsonArray();
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("-- Select script-export target --", NUITSCR_NONE));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("itnwn_scrxp -> Build_itnwn_tlbl() [Label]", NUITSCR_TLBL));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("itnwn_scrxp -> Build_itnwn_tbtn() [Button]", NUITSCR_TBTN));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("itnwn_scrxp -> Build_itnwn_topt() [Options]", NUITSCR_TOPT));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("itnwn_scrxp -> Build_itnwn_tchk() [Check]", NUITSCR_TCHK));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("itnwn_scrxp -> Build_itnwn_tsld() [Slider]", NUITSCR_TSLD));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("itnwn_scrxp -> Build_itnwn_tprg() [Progress]", NUITSCR_TPRG));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("itnwn_scrxp -> Build_itnwn_ttxe() [TextEdit]", NUITSCR_TTXE));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("itnwn_scrxp -> Build_itnwn_tbim() [ButtonImage]", NUITSCR_TBIM));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("itnwn_scrxp -> Build_itnwn_tbse() [ButtonSelect]", NUITSCR_TBSE));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("itnwn_scrxp -> Build_itnwn_tclr() [ColorPicker]", NUITSCR_TCLR));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("itnwn_scrxp -> Build_itnwn_tcmb() [Combo]", NUITSCR_TCMB));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("itnwn_scrxp -> Build_itnwn_timg() [Image]", NUITSCR_TIMG));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("itnwn_scrxp -> Build_itnwn_tslf() [SliderFloat]", NUITSCR_TSLF));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("itnwn_scrxp -> Build_itnwn_ttxt() [Text]", NUITSCR_TTXT));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("itnwn_scrxp -> Build_itnwn_ttog() [Toggles]", NUITSCR_TTOG));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("itnwn_scrxp -> Build_itnwn_tcha() [Chart]", NUITSCR_TCHA));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("itnwn_scrxp -> Build_itnwn_tdla() [DrawArc]", NUITSCR_TDLA));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("itnwn_scrxp -> Build_itnwn_tdlc() [DrawCircle]", NUITSCR_TDLC));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("itnwn_scrxp -> Build_itnwn_tdlv() [DrawCurve]", NUITSCR_TDLV));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("itnwn_scrxp -> Build_itnwn_tdli() [DrawImage]", NUITSCR_TDLI));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("itnwn_scrxp -> Build_itnwn_tdir() [DrawImgRegion]", NUITSCR_TDIR));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("itnwn_scrxp -> Build_itnwn_tdll() [DrawLine]", NUITSCR_TDLL));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("itnwn_scrxp -> Build_itnwn_tdlp() [DrawPolyLine]", NUITSCR_TDLP));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("itnwn_scrxp -> Build_itnwn_tdlr() [DrawRect]", NUITSCR_TDLR));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("itnwn_scrxp -> Build_itnwn_tdlt() [DrawText]", NUITSCR_TDLT));
    return jEntries;
}

void NuiTScrOpen(object oPC)
{
    if (!GetIsObjectValid(oPC) || !GetIsPC(oPC) || GetIsDM(oPC)) return;

    int nOld = NuiFindWindow(oPC, NUITSCR_WIN);
    if (nOld != 0) NuiDestroy(oPC, nOld);

    json jCombo = NuiCombo(NuiBind(NUITSCR_LIST), NuiBind(NUITSCR_SELECTED));
    jCombo = NuiWidth(jCombo, 260.0);
    jCombo = NuiHeight(jCombo, 32.0);

    json jOpen = NuiId(NuiButton(JsonString("Open")), NUITSCR_BTN_OPEN);
    jOpen = NuiWidth(jOpen, 84.0);
    jOpen = NuiHeight(jOpen, 32.0);
    jOpen = NuiEnabled(jOpen, NuiBind(NUITSCR_OPEN_EN));

    json jJson = NuiId(NuiButton(JsonString("JSON")), NUITSCR_BTN_JSON);
    jJson = NuiWidth(jJson, 84.0);
    jJson = NuiHeight(jJson, 32.0);
    jJson = NuiEnabled(jJson, NuiBind(NUITSCR_OPEN_EN));

    json jMainRow = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, jCombo);
    jMainRow = JsonArrayInsert(jMainRow, NuiWidth(NuiSpacer(), 12.0));
    jMainRow = JsonArrayInsert(jMainRow, jOpen);
    jMainRow = JsonArrayInsert(jMainRow, NuiWidth(NuiSpacer(), 8.0));
    jMainRow = JsonArrayInsert(jMainRow, jJson);
    jMainRow = NuiRow(jMainRow);

    json jHelp = NuiLabel(
        JsonString("Script export: baseline components (all 600x600)."),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE));
    jHelp = NuiWidth(jHelp, 500.0);
    jHelp = NuiHeight(jHelp, 24.0);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));
    jCol = JsonArrayInsert(jCol, NuiTScrCentered(jHelp));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 8.0));
    jCol = JsonArrayInsert(jCol, NuiTScrCentered(jMainRow));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));

    json jWin = NuiWindow(
        NuiCol(jCol),
        JsonString("ITNWN Script Export"),
        NuiRect(-1.0, -1.0, 560.0, 155.0),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE));

    int nToken = NuiCreate(oPC, jWin, NUITSCR_WIN, NUITSCR_EVENT);
    if (nToken == 0) return;

    NuiSetBind(oPC, nToken, NUITSCR_LIST, NuiTScrEntries());
    NuiSetBind(oPC, nToken, NUITSCR_SELECTED, JsonInt(NUITSCR_NONE));
    NuiSetBind(oPC, nToken, NUITSCR_OPEN_EN, JsonBool(FALSE));
    NuiSetBindWatch(oPC, nToken, NUITSCR_SELECTED, TRUE);
}

void main()
{
    object oPC = GetLastUsedBy();
    if (!GetIsObjectValid(oPC) || !GetIsPC(oPC))
    {
        oPC = GetFirstPC();
    }
    NuiTScrOpen(oPC);
}
