// =============================================================================
// nuitst_screv.nss
// NUI event handler for script-export launcher.
// =============================================================================

#include "nw_inc_nui"
#include "itnwn_scrxp"

const string NUITSCR_WIN      = "ITNWN_SCR_WIN";
const string NUITSCR_EVENT    = "nuitst_screv";
const string NUITSCR_LIST     = "itnwn_scr_list";
const string NUITSCR_SELECTED = "itnwn_scr_selected";
const string NUITSCR_OPEN_EN  = "itnwn_scr_open_en";
const string NUITSCR_BTN_OPEN = "itnwn_scr_open_btn";
const string NUITSCR_BTN_JSON = "itnwn_scr_json_btn";
const string NUITSCR_JSN_WIN  = "ITNWN_SCR_JSN";
const string NUITSCR_JSN_CAP  = "itnwn_scr_jsn_cap";
const string NUITSCR_JSN_WID  = "itnwn_scr_jsn_wid";
const string NUITSCR_JSN_TXT  = "itnwn_scr_jsn_txt";

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

const string NUITSCR_WIN_TLBL = "ITNWN_TLBL";
const string NUITSCR_WIN_TBTN = "ITNWN_TBTN";
const string NUITSCR_WIN_TOPT = "ITNWN_TOPT";
const string NUITSCR_WIN_TCHK = "ITNWN_TCHK";
const string NUITSCR_WIN_TSLD = "ITNWN_TSLD";
const string NUITSCR_WIN_TPRG = "ITNWN_TPRG";
const string NUITSCR_WIN_TTXE = "ITNWN_TTXE";
const string NUITSCR_WIN_TBIM = "ITNWN_TBIM";
const string NUITSCR_WIN_TBSE = "ITNWN_TBSE";
const string NUITSCR_WIN_TCLR = "ITNWN_TCLR";
const string NUITSCR_WIN_TCMB = "ITNWN_TCMB";
const string NUITSCR_WIN_TIMG = "ITNWN_TIMG";
const string NUITSCR_WIN_TSLF = "ITNWN_TSLF";
const string NUITSCR_WIN_TTXT = "ITNWN_TTXT";
const string NUITSCR_WIN_TTOG = "ITNWN_TTOG";
const string NUITSCR_WIN_TCHA = "ITNWN_TCHA";
const string NUITSCR_WIN_TDLA = "ITNWN_TDLA";
const string NUITSCR_WIN_TDLC = "ITNWN_TDLC";
const string NUITSCR_WIN_TDLV = "ITNWN_TDLV";
const string NUITSCR_WIN_TDLI = "ITNWN_TDLI";
const string NUITSCR_WIN_TDIR = "ITNWN_TDIR";
const string NUITSCR_WIN_TDLL = "ITNWN_TDLL";
const string NUITSCR_WIN_TDLP = "ITNWN_TDLP";
const string NUITSCR_WIN_TDLR = "ITNWN_TDLR";
const string NUITSCR_WIN_TDLT = "ITNWN_TDLT";

json NuiTScrCentered(json jWidget)
{
    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    jRow = JsonArrayInsert(jRow, jWidget);
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    return NuiRow(jRow);
}

void NuiTScrSyncEnabled(object oPC, int nToken)
{
    int nSelected = JsonGetInt(NuiGetBind(oPC, nToken, NUITSCR_SELECTED));
    NuiSetBind(oPC, nToken, NUITSCR_OPEN_EN, JsonBool(nSelected > NUITSCR_NONE));
}

string NuiTScrLimitJsonText(string sText)
{
    int nMax = 65000;
    if (GetStringLength(sText) <= nMax) return sText;
    return GetSubString(sText, 0, nMax) + "\n\n[TRUNCATED to 65000 chars]";
}

void NuiTScrOpenJsonViewer(object oPC, string sWindowId, string sCaption, string sJsonText)
{
    int nExisting = NuiFindWindow(oPC, NUITSCR_JSN_WIN);
    if (nExisting != 0)
    {
        NuiSetBind(oPC, nExisting, NUITSCR_JSN_WID, JsonString(sWindowId));
        NuiSetBind(oPC, nExisting, NUITSCR_JSN_CAP, JsonString(sCaption));
        NuiSetBind(oPC, nExisting, NUITSCR_JSN_TXT, JsonString(NuiTScrLimitJsonText(sJsonText)));
        return;
    }

    json jWidLabel = NuiLabel(JsonString("Window ID:"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jWidLabel = NuiWidth(jWidLabel, 110.0);
    jWidLabel = NuiHeight(jWidLabel, 24.0);

    json jWid = NuiTextEdit(JsonString(""), NuiBind(NUITSCR_JSN_WID), 64, FALSE);
    jWid = NuiWidth(jWid, 260.0);
    jWid = NuiHeight(jWid, 30.0);

    json jWidRow = JsonArray();
    jWidRow = JsonArrayInsert(jWidRow, NuiSpacer());
    jWidRow = JsonArrayInsert(jWidRow, jWidLabel);
    jWidRow = JsonArrayInsert(jWidRow, NuiWidth(NuiSpacer(), 8.0));
    jWidRow = JsonArrayInsert(jWidRow, jWid);
    jWidRow = JsonArrayInsert(jWidRow, NuiSpacer());
    jWidRow = NuiRow(jWidRow);

    json jCap = NuiLabel(NuiBind(NUITSCR_JSN_CAP), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jCap = NuiHeight(jCap, 24.0);

    json jText = NuiTextEdit(JsonString(""), NuiBind(NUITSCR_JSN_TXT), 65535, TRUE);
    jText = NuiWidth(jText, 730.0);
    jText = NuiHeight(jText, 410.0);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 8.0));
    jCol = JsonArrayInsert(jCol, jWidRow);
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 6.0));
    jCol = JsonArrayInsert(jCol, jCap);
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 6.0));
    jCol = JsonArrayInsert(jCol, NuiTScrCentered(jText));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 8.0));

    json jWin = NuiWindow(
        NuiCol(jCol),
        JsonString("Script Export JSON"),
        NuiRect(-1.0, -1.0, 790.0, 530.0),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE));

    int nToken = NuiCreate(oPC, jWin, NUITSCR_JSN_WIN, NUITSCR_EVENT);
    if (nToken == 0) return;

    NuiSetBind(oPC, nToken, NUITSCR_JSN_WID, JsonString(sWindowId));
    NuiSetBind(oPC, nToken, NUITSCR_JSN_CAP, JsonString(sCaption));
    NuiSetBind(oPC, nToken, NUITSCR_JSN_TXT, JsonString(NuiTScrLimitJsonText(sJsonText)));
}

string NuiTScrTargetWindowId(int nSelected)
{
    if (nSelected == NUITSCR_TLBL) return NUITSCR_WIN_TLBL;
    if (nSelected == NUITSCR_TBTN) return NUITSCR_WIN_TBTN;
    if (nSelected == NUITSCR_TOPT) return NUITSCR_WIN_TOPT;
    if (nSelected == NUITSCR_TCHK) return NUITSCR_WIN_TCHK;
    if (nSelected == NUITSCR_TSLD) return NUITSCR_WIN_TSLD;
    if (nSelected == NUITSCR_TPRG) return NUITSCR_WIN_TPRG;
    if (nSelected == NUITSCR_TTXE) return NUITSCR_WIN_TTXE;
    if (nSelected == NUITSCR_TBIM) return NUITSCR_WIN_TBIM;
    if (nSelected == NUITSCR_TBSE) return NUITSCR_WIN_TBSE;
    if (nSelected == NUITSCR_TCLR) return NUITSCR_WIN_TCLR;
    if (nSelected == NUITSCR_TCMB) return NUITSCR_WIN_TCMB;
    if (nSelected == NUITSCR_TIMG) return NUITSCR_WIN_TIMG;
    if (nSelected == NUITSCR_TSLF) return NUITSCR_WIN_TSLF;
    if (nSelected == NUITSCR_TTXT) return NUITSCR_WIN_TTXT;
    if (nSelected == NUITSCR_TTOG) return NUITSCR_WIN_TTOG;
    if (nSelected == NUITSCR_TCHA) return NUITSCR_WIN_TCHA;
    if (nSelected == NUITSCR_TDLA) return NUITSCR_WIN_TDLA;
    if (nSelected == NUITSCR_TDLC) return NUITSCR_WIN_TDLC;
    if (nSelected == NUITSCR_TDLV) return NUITSCR_WIN_TDLV;
    if (nSelected == NUITSCR_TDLI) return NUITSCR_WIN_TDLI;
    if (nSelected == NUITSCR_TDIR) return NUITSCR_WIN_TDIR;
    if (nSelected == NUITSCR_TDLL) return NUITSCR_WIN_TDLL;
    if (nSelected == NUITSCR_TDLP) return NUITSCR_WIN_TDLP;
    if (nSelected == NUITSCR_TDLR) return NUITSCR_WIN_TDLR;
    if (nSelected == NUITSCR_TDLT) return NUITSCR_WIN_TDLT;
    return "";
}

void NuiTScrOpenSelected(object oPC, int nSelected)
{
    if (nSelected == NUITSCR_TLBL)
    {
        Build_itnwn_tlbl(oPC);
        return;
    }

    if (nSelected == NUITSCR_TBTN)
    {
        Build_itnwn_tbtn(oPC);
        return;
    }

    if (nSelected == NUITSCR_TOPT)
    {
        Build_itnwn_topt(oPC);
        return;
    }

    if (nSelected == NUITSCR_TCHK)
    {
        Build_itnwn_tchk(oPC);
        return;
    }

    if (nSelected == NUITSCR_TSLD)
    {
        Build_itnwn_tsld(oPC);
        return;
    }

    if (nSelected == NUITSCR_TPRG)
    {
        Build_itnwn_tprg(oPC);
        return;
    }

    if (nSelected == NUITSCR_TTXE)
    {
        Build_itnwn_ttxe(oPC);
        return;
    }

    if (nSelected == NUITSCR_TBIM)
    {
        Build_itnwn_tbim(oPC);
        return;
    }

    if (nSelected == NUITSCR_TBSE)
    {
        Build_itnwn_tbse(oPC);
        return;
    }

    if (nSelected == NUITSCR_TCLR)
    {
        Build_itnwn_tclr(oPC);
        return;
    }

    if (nSelected == NUITSCR_TCMB)
    {
        Build_itnwn_tcmb(oPC);
        return;
    }

    if (nSelected == NUITSCR_TIMG)
    {
        Build_itnwn_timg(oPC);
        return;
    }

    if (nSelected == NUITSCR_TSLF)
    {
        Build_itnwn_tslf(oPC);
        return;
    }

    if (nSelected == NUITSCR_TTXT)
    {
        Build_itnwn_ttxt(oPC);
        return;
    }

    if (nSelected == NUITSCR_TTOG)
    {
        Build_itnwn_ttog(oPC);
        return;
    }

    if (nSelected == NUITSCR_TCHA)
    {
        Build_itnwn_tcha(oPC);
        return;
    }

    if (nSelected == NUITSCR_TDLA)
    {
        Build_itnwn_tdla(oPC);
        return;
    }

    if (nSelected == NUITSCR_TDLC)
    {
        Build_itnwn_tdlc(oPC);
        return;
    }

    if (nSelected == NUITSCR_TDLV)
    {
        Build_itnwn_tdlv(oPC);
        return;
    }

    if (nSelected == NUITSCR_TDLI)
    {
        Build_itnwn_tdli(oPC);
        return;
    }

    if (nSelected == NUITSCR_TDIR)
    {
        Build_itnwn_tdir(oPC);
        return;
    }

    if (nSelected == NUITSCR_TDLL)
    {
        Build_itnwn_tdll(oPC);
        return;
    }

    if (nSelected == NUITSCR_TDLP)
    {
        Build_itnwn_tdlp(oPC);
        return;
    }

    if (nSelected == NUITSCR_TDLR)
    {
        Build_itnwn_tdlr(oPC);
        return;
    }

    if (nSelected == NUITSCR_TDLT)
    {
        Build_itnwn_tdlt(oPC);
        return;
    }

    SendMessageToPC(oPC, "Script-export: invalid selection value " + IntToString(nSelected) + ".");
}

void NuiTScrExportSelectedJson(object oPC, int nSelected)
{
    if (nSelected <= NUITSCR_NONE)
    {
        NuiTScrOpenJsonViewer(oPC, "", "No Selection", "Select script target first.");
        return;
    }

    string sWinId = NuiTScrTargetWindowId(nSelected);
    if (sWinId == "")
    {
        NuiTScrOpenJsonViewer(oPC, "", "No Selection", "Select script target first.");
        return;
    }

    int nTarget = NuiFindWindow(oPC, sWinId);
    if (nTarget == 0)
    {
        NuiTScrOpenJsonViewer(oPC, sWinId, "Window Not Open", "Click Open first.");
        return;
    }

    json jUserData = NuiGetUserData(oPC, nTarget);
    if (JsonGetType(jUserData) == JSON_TYPE_NULL)
    {
        NuiTScrOpenJsonViewer(oPC, sWinId, "No JSON Captured", "Window userdata is JSON null.");
        return;
    }

    NuiTScrOpenJsonViewer(oPC, sWinId, "Copy JSON below.", JsonDump(jUserData));
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

    if (sWindowId != NUITSCR_WIN && sWindowId != NUITSCR_JSN_WIN) return;

    if (sEvent == "open")
    {
        NuiTScrSyncEnabled(oPC, nToken);
        return;
    }

    if (sEvent == "watch" && sElement == NUITSCR_SELECTED)
    {
        NuiTScrSyncEnabled(oPC, nToken);
        return;
    }

    if (sEvent == "click" && sElement == NUITSCR_BTN_OPEN)
    {
        int nSelected = JsonGetInt(NuiGetBind(oPC, nToken, NUITSCR_SELECTED));
        NuiTScrOpenSelected(oPC, nSelected);
        return;
    }

    if (sEvent == "click" && sElement == NUITSCR_BTN_JSON)
    {
        int nSelected = JsonGetInt(NuiGetBind(oPC, nToken, NUITSCR_SELECTED));
        NuiTScrExportSelectedJson(oPC, nSelected);
        return;
    }
}
