// =============================================================================
// nuitst_juiopn.nss
// JUI launcher opener (direct-run only).
// NUI events are handled in: nuitst_juev.nss
// =============================================================================

#include "nw_inc_nui"

const string NUITJUI_WIN      = "ITNWN_JUI_WIN";
const string NUITJUI_EVENT    = "nuitst_juev";
const string NUITJUI_LIST     = "itnwn_jui_list";
const string NUITJUI_SELECTED = "itnwn_jui_selected";
const string NUITJUI_OPEN_EN  = "itnwn_jui_open_en";
const string NUITJUI_BTN_OPEN = "itnwn_jui_open_btn";
const string NUITJUI_BTN_JSON = "itnwn_jui_json_btn";

const int NUITJUI_NONE        = 0;
const int NUITJUI_TLBL        = 1;
const int NUITJUI_TBTN        = 2;
const int NUITJUI_TOPT        = 3;
const int NUITJUI_TCHK        = 4;
const int NUITJUI_TSLD        = 5;
const int NUITJUI_TPRG        = 6;
const int NUITJUI_TTXE        = 7;
const int NUITJUI_TBIM        = 8;
const int NUITJUI_TBSE        = 9;
const int NUITJUI_TCLR        = 10;
const int NUITJUI_TCMB        = 11;
const int NUITJUI_TIMG        = 12;
const int NUITJUI_TSLF        = 13;
const int NUITJUI_TTXT        = 14;
const int NUITJUI_TTOG        = 15;
const int NUITJUI_TCHA        = 16;
const int NUITJUI_TDLA        = 17;
const int NUITJUI_TDLC        = 18;
const int NUITJUI_TDLV        = 19;
const int NUITJUI_TDLI        = 20;
const int NUITJUI_TDIR        = 21;
const int NUITJUI_TDLL        = 22;
const int NUITJUI_TDLP        = 23;
const int NUITJUI_TDLR        = 24;
const int NUITJUI_TDLT        = 25;

json NuiTJuiCentered(json jWidget)
{
    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    jRow = JsonArrayInsert(jRow, jWidget);
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    return NuiRow(jRow);
}

json NuiTJuiEntries()
{
    json jEntries = JsonArray();
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("-- Select JUI target --", NUITJUI_NONE));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("itjui_tlbl.jui -> ITJUI_TLBL", NUITJUI_TLBL));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("itjui_tbtn.jui -> ITJUI_TBTN", NUITJUI_TBTN));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("itjui_topt.jui -> ITJUI_TOPT", NUITJUI_TOPT));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("itjui_tchk.jui -> ITJUI_TCHK", NUITJUI_TCHK));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("itjui_tsld.jui -> ITJUI_TSLD", NUITJUI_TSLD));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("itjui_tprg.jui -> ITJUI_TPRG", NUITJUI_TPRG));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("itjui_ttxe.jui -> ITJUI_TTXE", NUITJUI_TTXE));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("itjui_tbim.jui -> ITJUI_TBIM", NUITJUI_TBIM));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("itjui_tbse.jui -> ITJUI_TBSE", NUITJUI_TBSE));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("itjui_tclr.jui -> ITJUI_TCLR", NUITJUI_TCLR));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("itjui_tcmb.jui -> ITJUI_TCMB", NUITJUI_TCMB));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("itjui_timg.jui -> ITJUI_TIMG", NUITJUI_TIMG));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("itjui_tslf.jui -> ITJUI_TSLF", NUITJUI_TSLF));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("itjui_ttxt.jui -> ITJUI_TTXT", NUITJUI_TTXT));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("itjui_ttog.jui -> ITJUI_TTOG", NUITJUI_TTOG));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("itjui_tcha.jui -> ITJUI_TCHA", NUITJUI_TCHA));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("itjui_tdla.jui -> ITJUI_TDLA", NUITJUI_TDLA));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("itjui_tdlc.jui -> ITJUI_TDLC", NUITJUI_TDLC));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("itjui_tdlv.jui -> ITJUI_TDLV", NUITJUI_TDLV));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("itjui_tdli.jui -> ITJUI_TDLI", NUITJUI_TDLI));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("itjui_tdir.jui -> ITJUI_TDIR", NUITJUI_TDIR));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("itjui_tdll.jui -> ITJUI_TDLL", NUITJUI_TDLL));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("itjui_tdlp.jui -> ITJUI_TDLP", NUITJUI_TDLP));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("itjui_tdlr.jui -> ITJUI_TDLR", NUITJUI_TDLR));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("itjui_tdlt.jui -> ITJUI_TDLT", NUITJUI_TDLT));
    return jEntries;
}

void NuiTJuiOpen(object oPC)
{
    if (!GetIsObjectValid(oPC) || !GetIsPC(oPC) || GetIsDM(oPC)) return;

    int nOld = NuiFindWindow(oPC, NUITJUI_WIN);
    if (nOld != 0) NuiDestroy(oPC, nOld);

    json jCombo = NuiCombo(NuiBind(NUITJUI_LIST), NuiBind(NUITJUI_SELECTED));
    jCombo = NuiWidth(jCombo, 260.0);
    jCombo = NuiHeight(jCombo, 32.0);

    json jOpen = NuiId(NuiButton(JsonString("Open")), NUITJUI_BTN_OPEN);
    jOpen = NuiWidth(jOpen, 84.0);
    jOpen = NuiHeight(jOpen, 32.0);
    jOpen = NuiEnabled(jOpen, NuiBind(NUITJUI_OPEN_EN));

    json jJson = NuiId(NuiButton(JsonString("JSON")), NUITJUI_BTN_JSON);
    jJson = NuiWidth(jJson, 84.0);
    jJson = NuiHeight(jJson, 32.0);
    jJson = NuiEnabled(jJson, NuiBind(NUITJUI_OPEN_EN));

    json jMainRow = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, jCombo);
    jMainRow = JsonArrayInsert(jMainRow, NuiWidth(NuiSpacer(), 12.0));
    jMainRow = JsonArrayInsert(jMainRow, jOpen);
    jMainRow = JsonArrayInsert(jMainRow, NuiWidth(NuiSpacer(), 8.0));
    jMainRow = JsonArrayInsert(jMainRow, jJson);
    jMainRow = NuiRow(jMainRow);

    json jHelp = NuiLabel(
        JsonString("JUI export: baseline components (all 600x600)."),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE));
    jHelp = NuiWidth(jHelp, 500.0);
    jHelp = NuiHeight(jHelp, 24.0);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));
    jCol = JsonArrayInsert(jCol, NuiTJuiCentered(jHelp));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 8.0));
    jCol = JsonArrayInsert(jCol, NuiTJuiCentered(jMainRow));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));

    json jWin = NuiWindow(
        NuiCol(jCol),
        JsonString("ITNWN JUI Export"),
        NuiRect(-1.0, -1.0, 560.0, 155.0),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE));

    int nToken = NuiCreate(oPC, jWin, NUITJUI_WIN, NUITJUI_EVENT);
    if (nToken == 0) return;

    NuiSetBind(oPC, nToken, NUITJUI_LIST, NuiTJuiEntries());
    NuiSetBind(oPC, nToken, NUITJUI_SELECTED, JsonInt(NUITJUI_NONE));
    NuiSetBind(oPC, nToken, NUITJUI_OPEN_EN, JsonBool(FALSE));
    NuiSetBindWatch(oPC, nToken, NUITJUI_SELECTED, TRUE);
}

void main()
{
    object oPC = GetLastUsedBy();
    if (!GetIsObjectValid(oPC) || !GetIsPC(oPC))
    {
        oPC = GetFirstPC();
    }
    NuiTJuiOpen(oPC);
}
