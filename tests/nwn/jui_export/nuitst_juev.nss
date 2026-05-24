// =============================================================================
// nuitst_juev.nss
// NUI event handler for JUI launcher.
// Baseline targets: full component/drawlist set (all 600x600).
// =============================================================================

#include "nw_inc_nui"

const string NUITJUI_WIN       = "ITNWN_JUI_WIN";
const string NUITJUI_EVENT     = "nuitst_juev";
const string NUITJUI_LIST      = "itnwn_jui_list";
const string NUITJUI_SELECTED  = "itnwn_jui_selected";
const string NUITJUI_OPEN_EN   = "itnwn_jui_open_en";
const string NUITJUI_BTN_OPEN  = "itnwn_jui_open_btn";
const string NUITJUI_BTN_JSON  = "itnwn_jui_json_btn";
const string NUITJUI_JSN_WIN   = "ITNWN_JUI_JSN";
const string NUITJUI_JSN_CAP   = "itnwn_jui_jsn_cap";
const string NUITJUI_JSN_WID   = "itnwn_jui_jsn_wid";
const string NUITJUI_JSN_TXT   = "itnwn_jui_jsn_txt";

const int NUITJUI_NONE         = 0;
const int NUITJUI_TLBL         = 1;
const int NUITJUI_TBTN         = 2;
const int NUITJUI_TOPT         = 3;
const int NUITJUI_TCHK         = 4;
const int NUITJUI_TSLD         = 5;
const int NUITJUI_TPRG         = 6;
const int NUITJUI_TTXE         = 7;
const int NUITJUI_TBIM         = 8;
const int NUITJUI_TBSE         = 9;
const int NUITJUI_TCLR         = 10;
const int NUITJUI_TCMB         = 11;
const int NUITJUI_TIMG         = 12;
const int NUITJUI_TSLF         = 13;
const int NUITJUI_TTXT         = 14;
const int NUITJUI_TTOG         = 15;
const int NUITJUI_TCHA         = 16;
const int NUITJUI_TDLA         = 17;
const int NUITJUI_TDLC         = 18;
const int NUITJUI_TDLV         = 19;
const int NUITJUI_TDLI         = 20;
const int NUITJUI_TDIR         = 21;
const int NUITJUI_TDLL         = 22;
const int NUITJUI_TDLP         = 23;
const int NUITJUI_TDLR         = 24;
const int NUITJUI_TDLT         = 25;

const string NUITJUI_RES_TLBL  = "itjui_tlbl";
const string NUITJUI_RES_TBTN  = "itjui_tbtn";
const string NUITJUI_RES_TOPT  = "itjui_topt";
const string NUITJUI_RES_TCHK  = "itjui_tchk";
const string NUITJUI_RES_TSLD  = "itjui_tsld";
const string NUITJUI_RES_TPRG  = "itjui_tprg";
const string NUITJUI_RES_TTXE  = "itjui_ttxe";
const string NUITJUI_RES_TBIM  = "itjui_tbim";
const string NUITJUI_RES_TBSE  = "itjui_tbse";
const string NUITJUI_RES_TCLR  = "itjui_tclr";
const string NUITJUI_RES_TCMB  = "itjui_tcmb";
const string NUITJUI_RES_TIMG  = "itjui_timg";
const string NUITJUI_RES_TSLF  = "itjui_tslf";
const string NUITJUI_RES_TTXT  = "itjui_ttxt";
const string NUITJUI_RES_TTOG  = "itjui_ttog";
const string NUITJUI_RES_TCHA  = "itjui_tcha";
const string NUITJUI_RES_TDLA  = "itjui_tdla";
const string NUITJUI_RES_TDLC  = "itjui_tdlc";
const string NUITJUI_RES_TDLV  = "itjui_tdlv";
const string NUITJUI_RES_TDLI  = "itjui_tdli";
const string NUITJUI_RES_TDIR  = "itjui_tdir";
const string NUITJUI_RES_TDLL  = "itjui_tdll";
const string NUITJUI_RES_TDLP  = "itjui_tdlp";
const string NUITJUI_RES_TDLR  = "itjui_tdlr";
const string NUITJUI_RES_TDLT  = "itjui_tdlt";
const string NUITJUI_WIN_TLBL  = "ITJUI_TLBL";
const string NUITJUI_WIN_TBTN  = "ITJUI_TBTN";
const string NUITJUI_WIN_TOPT  = "ITJUI_TOPT";
const string NUITJUI_WIN_TCHK  = "ITJUI_TCHK";
const string NUITJUI_WIN_TSLD  = "ITJUI_TSLD";
const string NUITJUI_WIN_TPRG  = "ITJUI_TPRG";
const string NUITJUI_WIN_TTXE  = "ITJUI_TTXE";
const string NUITJUI_WIN_TBIM  = "ITJUI_TBIM";
const string NUITJUI_WIN_TBSE  = "ITJUI_TBSE";
const string NUITJUI_WIN_TCLR  = "ITJUI_TCLR";
const string NUITJUI_WIN_TCMB  = "ITJUI_TCMB";
const string NUITJUI_WIN_TIMG  = "ITJUI_TIMG";
const string NUITJUI_WIN_TSLF  = "ITJUI_TSLF";
const string NUITJUI_WIN_TTXT  = "ITJUI_TTXT";
const string NUITJUI_WIN_TTOG  = "ITJUI_TTOG";
const string NUITJUI_WIN_TCHA  = "ITJUI_TCHA";
const string NUITJUI_WIN_TDLA  = "ITJUI_TDLA";
const string NUITJUI_WIN_TDLC  = "ITJUI_TDLC";
const string NUITJUI_WIN_TDLV  = "ITJUI_TDLV";
const string NUITJUI_WIN_TDLI  = "ITJUI_TDLI";
const string NUITJUI_WIN_TDIR  = "ITJUI_TDIR";
const string NUITJUI_WIN_TDLL  = "ITJUI_TDLL";
const string NUITJUI_WIN_TDLP  = "ITJUI_TDLP";
const string NUITJUI_WIN_TDLR  = "ITJUI_TDLR";
const string NUITJUI_WIN_TDLT  = "ITJUI_TDLT";

json NuiTJuiCentered(json jWidget)
{
    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    jRow = JsonArrayInsert(jRow, jWidget);
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    return NuiRow(jRow);
}

void NuiTJuiSyncEnabled(object oPC, int nToken)
{
    int nSelected = JsonGetInt(NuiGetBind(oPC, nToken, NUITJUI_SELECTED));
    NuiSetBind(oPC, nToken, NUITJUI_OPEN_EN, JsonBool(nSelected > NUITJUI_NONE));
}

string NuiTJuiLimitJsonText(string sText)
{
    int nMax = 65000;
    if (GetStringLength(sText) <= nMax) return sText;
    return GetSubString(sText, 0, nMax) + "\n\n[TRUNCATED to 65000 chars]";
}

string NuiTJuiResrefForSelection(int nSelected)
{
    if (nSelected == NUITJUI_TLBL) return NUITJUI_RES_TLBL;
    if (nSelected == NUITJUI_TBTN) return NUITJUI_RES_TBTN;
    if (nSelected == NUITJUI_TOPT) return NUITJUI_RES_TOPT;
    if (nSelected == NUITJUI_TCHK) return NUITJUI_RES_TCHK;
    if (nSelected == NUITJUI_TSLD) return NUITJUI_RES_TSLD;
    if (nSelected == NUITJUI_TPRG) return NUITJUI_RES_TPRG;
    if (nSelected == NUITJUI_TTXE) return NUITJUI_RES_TTXE;
    if (nSelected == NUITJUI_TBIM) return NUITJUI_RES_TBIM;
    if (nSelected == NUITJUI_TBSE) return NUITJUI_RES_TBSE;
    if (nSelected == NUITJUI_TCLR) return NUITJUI_RES_TCLR;
    if (nSelected == NUITJUI_TCMB) return NUITJUI_RES_TCMB;
    if (nSelected == NUITJUI_TIMG) return NUITJUI_RES_TIMG;
    if (nSelected == NUITJUI_TSLF) return NUITJUI_RES_TSLF;
    if (nSelected == NUITJUI_TTXT) return NUITJUI_RES_TTXT;
    if (nSelected == NUITJUI_TTOG) return NUITJUI_RES_TTOG;
    if (nSelected == NUITJUI_TCHA) return NUITJUI_RES_TCHA;
    if (nSelected == NUITJUI_TDLA) return NUITJUI_RES_TDLA;
    if (nSelected == NUITJUI_TDLC) return NUITJUI_RES_TDLC;
    if (nSelected == NUITJUI_TDLV) return NUITJUI_RES_TDLV;
    if (nSelected == NUITJUI_TDLI) return NUITJUI_RES_TDLI;
    if (nSelected == NUITJUI_TDIR) return NUITJUI_RES_TDIR;
    if (nSelected == NUITJUI_TDLL) return NUITJUI_RES_TDLL;
    if (nSelected == NUITJUI_TDLP) return NUITJUI_RES_TDLP;
    if (nSelected == NUITJUI_TDLR) return NUITJUI_RES_TDLR;
    if (nSelected == NUITJUI_TDLT) return NUITJUI_RES_TDLT;
    return "";
}

string NuiTJuiWindowIdForSelection(int nSelected)
{
    if (nSelected == NUITJUI_TLBL) return NUITJUI_WIN_TLBL;
    if (nSelected == NUITJUI_TBTN) return NUITJUI_WIN_TBTN;
    if (nSelected == NUITJUI_TOPT) return NUITJUI_WIN_TOPT;
    if (nSelected == NUITJUI_TCHK) return NUITJUI_WIN_TCHK;
    if (nSelected == NUITJUI_TSLD) return NUITJUI_WIN_TSLD;
    if (nSelected == NUITJUI_TPRG) return NUITJUI_WIN_TPRG;
    if (nSelected == NUITJUI_TTXE) return NUITJUI_WIN_TTXE;
    if (nSelected == NUITJUI_TBIM) return NUITJUI_WIN_TBIM;
    if (nSelected == NUITJUI_TBSE) return NUITJUI_WIN_TBSE;
    if (nSelected == NUITJUI_TCLR) return NUITJUI_WIN_TCLR;
    if (nSelected == NUITJUI_TCMB) return NUITJUI_WIN_TCMB;
    if (nSelected == NUITJUI_TIMG) return NUITJUI_WIN_TIMG;
    if (nSelected == NUITJUI_TSLF) return NUITJUI_WIN_TSLF;
    if (nSelected == NUITJUI_TTXT) return NUITJUI_WIN_TTXT;
    if (nSelected == NUITJUI_TTOG) return NUITJUI_WIN_TTOG;
    if (nSelected == NUITJUI_TCHA) return NUITJUI_WIN_TCHA;
    if (nSelected == NUITJUI_TDLA) return NUITJUI_WIN_TDLA;
    if (nSelected == NUITJUI_TDLC) return NUITJUI_WIN_TDLC;
    if (nSelected == NUITJUI_TDLV) return NUITJUI_WIN_TDLV;
    if (nSelected == NUITJUI_TDLI) return NUITJUI_WIN_TDLI;
    if (nSelected == NUITJUI_TDIR) return NUITJUI_WIN_TDIR;
    if (nSelected == NUITJUI_TDLL) return NUITJUI_WIN_TDLL;
    if (nSelected == NUITJUI_TDLP) return NUITJUI_WIN_TDLP;
    if (nSelected == NUITJUI_TDLR) return NUITJUI_WIN_TDLR;
    if (nSelected == NUITJUI_TDLT) return NUITJUI_WIN_TDLT;
    return "";
}

string NuiTJuiSourceJuiText(int nSelected)
{
    if (nSelected == NUITJUI_TLBL)
    {
        return "{\n"
            + "  \"version\": 1,\n"
            + "  \"title\": \"ITNWN Label Target\",\n"
            + "  \"root\": {\n"
            + "    \"type\": \"col\",\n"
            + "    \"label\": null,\n"
            + "    \"value\": null,\n"
            + "    \"children\": [\n"
            + "      {\n"
            + "        \"type\": \"label\",\n"
            + "        \"value\": \"Baseline Label\",\n"
            + "        \"id\": \"lbl_baseline\"\n"
            + "      }\n"
            + "    ]\n"
            + "  },\n"
            + "  \"geometry\": {\n"
            + "    \"x\": -1,\n"
            + "    \"y\": -1,\n"
            + "    \"w\": 600,\n"
            + "    \"h\": 600\n"
            + "  },\n"
            + "  \"resizable\": false,\n"
            + "  \"collapsed\": false,\n"
            + "  \"closable\": true,\n"
            + "  \"transparent\": false,\n"
            + "  \"border\": true,\n"
            + "  \"accepts_input\": true,\n"
            + "  \"size_constraint\": null,\n"
            + "  \"edge_constraint\": null,\n"
            + "  \"font\": \"\"\n"
            + "}";
    }

    if (nSelected == NUITJUI_TBTN)
    {
        return "{\n"
            + "  \"version\": 1,\n"
            + "  \"title\": \"ITNWN Button Target\",\n"
            + "  \"root\": {\n"
            + "    \"type\": \"col\",\n"
            + "    \"label\": null,\n"
            + "    \"value\": null,\n"
            + "    \"children\": [\n"
            + "      {\n"
            + "        \"type\": \"button\",\n"
            + "        \"label\": \"Baseline Button\",\n"
            + "        \"id\": \"btn_baseline\"\n"
            + "      }\n"
            + "    ]\n"
            + "  },\n"
            + "  \"geometry\": {\n"
            + "    \"x\": -1,\n"
            + "    \"y\": -1,\n"
            + "    \"w\": 600,\n"
            + "    \"h\": 600\n"
            + "  },\n"
            + "  \"resizable\": false,\n"
            + "  \"collapsed\": false,\n"
            + "  \"closable\": true,\n"
            + "  \"transparent\": false,\n"
            + "  \"border\": true,\n"
            + "  \"accepts_input\": true,\n"
            + "  \"size_constraint\": null,\n"
            + "  \"edge_constraint\": null,\n"
            + "  \"font\": \"\"\n"
            + "}";
    }

    if (nSelected == NUITJUI_TOPT)
    {
        return "{\n"
            + "  \"version\": 1,\n"
            + "  \"title\": \"ITNWN Options Target\",\n"
            + "  \"root\": {\n"
            + "    \"type\": \"col\",\n"
            + "    \"label\": null,\n"
            + "    \"value\": null,\n"
            + "    \"children\": [\n"
            + "      {\n"
            + "        \"type\": \"options\",\n"
            + "        \"label\": null,\n"
            + "        \"value\": 1,\n"
            + "        \"direction\": 0,\n"
            + "        \"elements\": [\"Label 1\", \"Label 2\", \"Label 3\"],\n"
            + "        \"id\": \"opt_baseline\"\n"
            + "      }\n"
            + "    ]\n"
            + "  },\n"
            + "  \"geometry\": {\n"
            + "    \"x\": -1,\n"
            + "    \"y\": -1,\n"
            + "    \"w\": 600,\n"
            + "    \"h\": 600\n"
            + "  },\n"
            + "  \"resizable\": false,\n"
            + "  \"collapsed\": false,\n"
            + "  \"closable\": true,\n"
            + "  \"transparent\": false,\n"
            + "  \"border\": true,\n"
            + "  \"accepts_input\": true,\n"
            + "  \"size_constraint\": null,\n"
            + "  \"edge_constraint\": null,\n"
            + "  \"font\": \"\"\n"
            + "}";
    }

    if (nSelected == NUITJUI_TCHK)
    {
        return "{\n"
            + "  \"version\": 1,\n"
            + "  \"title\": \"ITNWN Check Target\",\n"
            + "  \"root\": {\n"
            + "    \"type\": \"col\",\n"
            + "    \"label\": null,\n"
            + "    \"value\": null,\n"
            + "    \"children\": [\n"
            + "      {\n"
            + "        \"type\": \"check\",\n"
            + "        \"label\": \"Baseline Check\",\n"
            + "        \"value\": true,\n"
            + "        \"id\": \"chk_baseline\"\n"
            + "      }\n"
            + "    ]\n"
            + "  },\n"
            + "  \"geometry\": {\n"
            + "    \"x\": -1,\n"
            + "    \"y\": -1,\n"
            + "    \"w\": 600,\n"
            + "    \"h\": 600\n"
            + "  },\n"
            + "  \"resizable\": false,\n"
            + "  \"collapsed\": false,\n"
            + "  \"closable\": true,\n"
            + "  \"transparent\": false,\n"
            + "  \"border\": true,\n"
            + "  \"accepts_input\": true,\n"
            + "  \"size_constraint\": null,\n"
            + "  \"edge_constraint\": null,\n"
            + "  \"font\": \"\"\n"
            + "}";
    }

    if (nSelected == NUITJUI_TSLD)
    {
        return "{\n"
            + "  \"version\": 1,\n"
            + "  \"title\": \"ITNWN Slider Target\",\n"
            + "  \"root\": {\n"
            + "    \"type\": \"col\",\n"
            + "    \"label\": null,\n"
            + "    \"value\": null,\n"
            + "    \"children\": [\n"
            + "      {\n"
            + "        \"type\": \"slider\",\n"
            + "        \"label\": null,\n"
            + "        \"value\": 40,\n"
            + "        \"min\": 0,\n"
            + "        \"max\": 100,\n"
            + "        \"step\": 5,\n"
            + "        \"id\": \"sld_baseline\"\n"
            + "      }\n"
            + "    ]\n"
            + "  },\n"
            + "  \"geometry\": {\n"
            + "    \"x\": -1,\n"
            + "    \"y\": -1,\n"
            + "    \"w\": 600,\n"
            + "    \"h\": 600\n"
            + "  },\n"
            + "  \"resizable\": false,\n"
            + "  \"collapsed\": false,\n"
            + "  \"closable\": true,\n"
            + "  \"transparent\": false,\n"
            + "  \"border\": true,\n"
            + "  \"accepts_input\": true,\n"
            + "  \"size_constraint\": null,\n"
            + "  \"edge_constraint\": null,\n"
            + "  \"font\": \"\"\n"
            + "}";
    }

    if (nSelected == NUITJUI_TPRG)
    {
        return "{\n"
            + "  \"version\": 1,\n"
            + "  \"title\": \"ITNWN Progress Target\",\n"
            + "  \"root\": {\n"
            + "    \"type\": \"col\",\n"
            + "    \"label\": null,\n"
            + "    \"value\": null,\n"
            + "    \"children\": [\n"
            + "      {\n"
            + "        \"type\": \"progress\",\n"
            + "        \"label\": null,\n"
            + "        \"value\": 0.6,\n"
            + "        \"id\": \"prg_baseline\"\n"
            + "      }\n"
            + "    ]\n"
            + "  },\n"
            + "  \"geometry\": {\n"
            + "    \"x\": -1,\n"
            + "    \"y\": -1,\n"
            + "    \"w\": 600,\n"
            + "    \"h\": 600\n"
            + "  },\n"
            + "  \"resizable\": false,\n"
            + "  \"collapsed\": false,\n"
            + "  \"closable\": true,\n"
            + "  \"transparent\": false,\n"
            + "  \"border\": true,\n"
            + "  \"accepts_input\": true,\n"
            + "  \"size_constraint\": null,\n"
            + "  \"edge_constraint\": null,\n"
            + "  \"font\": \"\"\n"
            + "}";
    }

    if (nSelected == NUITJUI_TTXE)
    {
        return "{\n"
            + "  \"version\": 1,\n"
            + "  \"title\": \"ITNWN TextEdit Target\",\n"
            + "  \"root\": {\n"
            + "    \"type\": \"col\",\n"
            + "    \"label\": null,\n"
            + "    \"value\": null,\n"
            + "    \"children\": [\n"
            + "      {\n"
            + "        \"type\": \"textedit\",\n"
            + "        \"label\": \"Type here...\",\n"
            + "        \"value\": \"\",\n"
            + "        \"max\": 64,\n"
            + "        \"multiline\": false,\n"
            + "        \"wordwrap\": true,\n"
            + "        \"id\": \"txe_baseline\"\n"
            + "      }\n"
            + "    ]\n"
            + "  },\n"
            + "  \"geometry\": {\n"
            + "    \"x\": -1,\n"
            + "    \"y\": -1,\n"
            + "    \"w\": 600,\n"
            + "    \"h\": 600\n"
            + "  },\n"
            + "  \"resizable\": false,\n"
            + "  \"collapsed\": false,\n"
            + "  \"closable\": true,\n"
            + "  \"transparent\": false,\n"
            + "  \"border\": true,\n"
            + "  \"accepts_input\": true,\n"
            + "  \"size_constraint\": null,\n"
            + "  \"edge_constraint\": null,\n"
            + "  \"font\": \"\"\n"
            + "}";
    }

    string sResRef = NuiTJuiResrefForSelection(nSelected);
    string sWinId = NuiTJuiWindowIdForSelection(nSelected);
    if (sResRef != "" && sWinId != "")
    {
        return "{\n"
            + "  \"version\": 1,\n"
            + "  \"source_resref\": \"" + sResRef + ".jui\",\n"
            + "  \"window_id\": \"" + sWinId + "\",\n"
            + "  \"note\": \"Use source file from tests/nwn/jui_export/.\"\n"
            + "}";
    }
    return "{}";
}

void NuiTJuiOpenJsonViewer(object oPC, string sWindowId, string sCaption, string sJsonText)
{
    int nExisting = NuiFindWindow(oPC, NUITJUI_JSN_WIN);
    if (nExisting != 0)
    {
        NuiSetBind(oPC, nExisting, NUITJUI_JSN_WID, JsonString(sWindowId));
        NuiSetBind(oPC, nExisting, NUITJUI_JSN_CAP, JsonString(sCaption));
        NuiSetBind(oPC, nExisting, NUITJUI_JSN_TXT, JsonString(NuiTJuiLimitJsonText(sJsonText)));
        return;
    }

    json jWidLabel = NuiLabel(JsonString("Window ID:"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jWidLabel = NuiWidth(jWidLabel, 110.0);
    jWidLabel = NuiHeight(jWidLabel, 24.0);

    json jWid = NuiTextEdit(JsonString(""), NuiBind(NUITJUI_JSN_WID), 64, FALSE);
    jWid = NuiWidth(jWid, 260.0);
    jWid = NuiHeight(jWid, 30.0);

    json jWidRow = JsonArray();
    jWidRow = JsonArrayInsert(jWidRow, NuiSpacer());
    jWidRow = JsonArrayInsert(jWidRow, jWidLabel);
    jWidRow = JsonArrayInsert(jWidRow, NuiWidth(NuiSpacer(), 8.0));
    jWidRow = JsonArrayInsert(jWidRow, jWid);
    jWidRow = JsonArrayInsert(jWidRow, NuiSpacer());
    jWidRow = NuiRow(jWidRow);

    json jCap = NuiLabel(NuiBind(NUITJUI_JSN_CAP), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jCap = NuiHeight(jCap, 24.0);

    json jText = NuiTextEdit(JsonString(""), NuiBind(NUITJUI_JSN_TXT), 65535, TRUE);
    jText = NuiWidth(jText, 730.0);
    jText = NuiHeight(jText, 410.0);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 8.0));
    jCol = JsonArrayInsert(jCol, jWidRow);
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 6.0));
    jCol = JsonArrayInsert(jCol, jCap);
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 6.0));
    jCol = JsonArrayInsert(jCol, NuiTJuiCentered(jText));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 8.0));

    json jWin = NuiWindow(
        NuiCol(jCol),
        JsonString("JUI Export JSON"),
        NuiRect(-1.0, -1.0, 790.0, 530.0),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE));

    int nToken = NuiCreate(oPC, jWin, NUITJUI_JSN_WIN, NUITJUI_EVENT);
    if (nToken == 0) return;

    NuiSetBind(oPC, nToken, NUITJUI_JSN_WID, JsonString(sWindowId));
    NuiSetBind(oPC, nToken, NUITJUI_JSN_CAP, JsonString(sCaption));
    NuiSetBind(oPC, nToken, NUITJUI_JSN_TXT, JsonString(NuiTJuiLimitJsonText(sJsonText)));
}

void NuiTJuiOpenSelected(object oPC, int nSelected)
{
    string sResRef = NuiTJuiResrefForSelection(nSelected);
    string sWinId = NuiTJuiWindowIdForSelection(nSelected);

    if (sResRef == "" || sWinId == "")
    {
        SendMessageToPC(oPC, "JUI-export: invalid selection.");
        return;
    }

    int nOld = NuiFindWindow(oPC, sWinId);
    if (nOld != 0) NuiDestroy(oPC, nOld);

    int nToken = NuiCreateFromResRef(oPC, sResRef, sWinId, NUITJUI_EVENT);
    if (nToken == 0)
    {
        SendMessageToPC(oPC, "JUI open failed: ensure " + sResRef + ".jui is client-visible.");
        return;
    }
}

void NuiTJuiExportSelectedJson(object oPC, int nSelected)
{
    if (nSelected <= NUITJUI_NONE)
    {
        NuiTJuiOpenJsonViewer(oPC, "", "No Selection", "Select JUI target first.");
        return;
    }

    string sWinId = NuiTJuiWindowIdForSelection(nSelected);
    if (sWinId == "")
    {
        NuiTJuiOpenJsonViewer(oPC, "", "No Selection", "Select JUI target first.");
        return;
    }

    int nTarget = NuiFindWindow(oPC, sWinId);
    if (nTarget == 0)
    {
        NuiTJuiOpenJsonViewer(oPC, sWinId, "Window Not Open", "Click Open first.");
        return;
    }

    NuiTJuiOpenJsonViewer(
        oPC,
        sWinId,
        "Copy .jui JSON below.",
        NuiTJuiSourceJuiText(nSelected));
}

void main()
{
    string sEvent = NuiGetEventType();
    if (sEvent == "") return;

    object oPC = NuiGetEventPlayer();
    int nToken = NuiGetEventWindow();
    string sWindowId = NuiGetWindowId(oPC, nToken);
    string sElement = NuiGetEventElement();
    if (!GetIsObjectValid(oPC) || !GetIsPC(oPC)) return;

    if (sWindowId != NUITJUI_WIN && sWindowId != NUITJUI_JSN_WIN) return;

    if (sEvent == "open")
    {
        NuiTJuiSyncEnabled(oPC, nToken);
        return;
    }

    if (sEvent == "watch" && sElement == NUITJUI_SELECTED)
    {
        NuiTJuiSyncEnabled(oPC, nToken);
        return;
    }

    if (sEvent == "click" && sElement == NUITJUI_BTN_OPEN)
    {
        int nSelected = JsonGetInt(NuiGetBind(oPC, nToken, NUITJUI_SELECTED));
        NuiTJuiOpenSelected(oPC, nSelected);
        return;
    }

    if (sEvent == "click" && sElement == NUITJUI_BTN_JSON)
    {
        int nSelected = JsonGetInt(NuiGetBind(oPC, nToken, NUITJUI_SELECTED));
        NuiTJuiExportSelectedJson(oPC, nSelected);
        return;
    }
}
