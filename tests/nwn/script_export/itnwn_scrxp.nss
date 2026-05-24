// =============================================================================
// itnwn_scrxp.nss
// Script-export baseline targets for tests/nwn.
// Fixed geometry for all targets: 600x600.
// =============================================================================

#include "nw_inc_nui"

const string ITNWSCR_TGT_EV   = "nuitst_screv";
const string ITNWSCR_CHART_B  = "itnwn_chart_data";

const string ITNWSCR_WIN_LBL  = "ITNWN_TLBL";
const string ITNWSCR_WIN_BTN  = "ITNWN_TBTN";
const string ITNWSCR_WIN_OPT  = "ITNWN_TOPT";
const string ITNWSCR_WIN_CHK  = "ITNWN_TCHK";
const string ITNWSCR_WIN_SLD  = "ITNWN_TSLD";
const string ITNWSCR_WIN_PRG  = "ITNWN_TPRG";
const string ITNWSCR_WIN_TXE  = "ITNWN_TTXE";
const string ITNWSCR_WIN_BIM  = "ITNWN_TBIM";
const string ITNWSCR_WIN_BSE  = "ITNWN_TBSE";
const string ITNWSCR_WIN_CLR  = "ITNWN_TCLR";
const string ITNWSCR_WIN_CMB  = "ITNWN_TCMB";
const string ITNWSCR_WIN_IMG  = "ITNWN_TIMG";
const string ITNWSCR_WIN_SLF  = "ITNWN_TSLF";
const string ITNWSCR_WIN_TXT  = "ITNWN_TTXT";
const string ITNWSCR_WIN_TOG  = "ITNWN_TTOG";
const string ITNWSCR_WIN_CHA  = "ITNWN_TCHA";
const string ITNWSCR_WIN_DLA  = "ITNWN_TDLA";
const string ITNWSCR_WIN_DLC  = "ITNWN_TDLC";
const string ITNWSCR_WIN_DLV  = "ITNWN_TDLV";
const string ITNWSCR_WIN_DLI  = "ITNWN_TDLI";
const string ITNWSCR_WIN_DIR  = "ITNWN_TDIR";
const string ITNWSCR_WIN_DLL  = "ITNWN_TDLL";
const string ITNWSCR_WIN_DLP  = "ITNWN_TDLP";
const string ITNWSCR_WIN_DLR  = "ITNWN_TDLR";
const string ITNWSCR_WIN_DLT  = "ITNWN_TDLT";

void ItnwScrDestroyTarget(object oPC, string sWindowId)
{
    int nOld = NuiFindWindow(oPC, sWindowId);
    if (nOld != 0) NuiDestroy(oPC, nOld);
}

int ItnwScrOpenTarget(object oPC, string sWindowId, string sTitle, json jWidget)
{
    if (!GetIsObjectValid(oPC) || !GetIsPC(oPC)) return 0;

    ItnwScrDestroyTarget(oPC, sWindowId);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jWidget);

    json jWin = NuiWindow(
        NuiCol(jCol),
        JsonString(sTitle),
        NuiRect(-1.0, -1.0, 600.0, 600.0),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE));

    int nToken = NuiCreate(oPC, jWin, sWindowId, ITNWSCR_TGT_EV);
    if (nToken == 0) return 0;

    NuiSetUserData(oPC, nToken, jWin);
    return nToken;
}

json ItnwScrElements123()
{
    json jElements = JsonArray();
    jElements = JsonArrayInsert(jElements, JsonString("Label 1"));
    jElements = JsonArrayInsert(jElements, JsonString("Label 2"));
    jElements = JsonArrayInsert(jElements, JsonString("Label 3"));
    return jElements;
}

json ItnwScrComboEntriesABC()
{
    json jEntries = JsonArray();
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("Option A", 100));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("Option B", 200));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("Option C", 300));
    return jEntries;
}

json ItnwScrChartData()
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

json ItnwScrChartSlots()
{
    json jSlots = JsonArray();
    json jSlot = NuiChartSlot(
        NUI_CHART_TYPE_LINES,
        JsonString("Series A"),
        NuiColor(90, 180, 255, 255),
        NuiBind(ITNWSCR_CHART_B));
    jSlots = JsonArrayInsert(jSlots, jSlot);
    return jSlots;
}

json ItnwScrPolyPoints()
{
    json jPoints = JsonArray();
    jPoints = JsonArrayInsert(jPoints, JsonFloat(170.0));
    jPoints = JsonArrayInsert(jPoints, JsonFloat(300.0));
    jPoints = JsonArrayInsert(jPoints, JsonFloat(250.0));
    jPoints = JsonArrayInsert(jPoints, JsonFloat(230.0));
    jPoints = JsonArrayInsert(jPoints, JsonFloat(330.0));
    jPoints = JsonArrayInsert(jPoints, JsonFloat(270.0));
    jPoints = JsonArrayInsert(jPoints, JsonFloat(420.0));
    jPoints = JsonArrayInsert(jPoints, JsonFloat(210.0));
    return jPoints;
}

json ItnwScrDrawCanvas(json jDrawItem)
{
    json jDraw = JsonArray();
    jDraw = JsonArrayInsert(jDraw, jDrawItem);

    json jCanvasBase = NuiGroup(NuiSpacer(), TRUE, NUI_SCROLLBARS_NONE);
    jCanvasBase = NuiWidth(jCanvasBase, 520.0);
    jCanvasBase = NuiHeight(jCanvasBase, 420.0);
    return NuiDrawList(jCanvasBase, JsonBool(TRUE), jDraw);
}

void Build_itnwn_tlbl(object oPC)
{
    json jLabel = NuiLabel(
        JsonString("Baseline Label"),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE));
    ItnwScrOpenTarget(oPC, ITNWSCR_WIN_LBL, "ITNWN Label Target", jLabel);
}

void Build_itnwn_tbtn(object oPC)
{
    json jButton = NuiButton(JsonString("Baseline Button"));
    ItnwScrOpenTarget(oPC, ITNWSCR_WIN_BTN, "ITNWN Button Target", jButton);
}

void Build_itnwn_topt(object oPC)
{
    json jOptions = NuiOptions(
        NUI_DIRECTION_HORIZONTAL,
        ItnwScrElements123(),
        JsonInt(1));
    ItnwScrOpenTarget(oPC, ITNWSCR_WIN_OPT, "ITNWN Options Target", jOptions);
}

void Build_itnwn_tchk(object oPC)
{
    json jCheck = NuiCheck(
        JsonString("Baseline Check"),
        JsonBool(TRUE));
    ItnwScrOpenTarget(oPC, ITNWSCR_WIN_CHK, "ITNWN Check Target", jCheck);
}

void Build_itnwn_tsld(object oPC)
{
    json jSlider = NuiSlider(
        JsonInt(40),
        JsonInt(0),
        JsonInt(100),
        JsonInt(5));
    ItnwScrOpenTarget(oPC, ITNWSCR_WIN_SLD, "ITNWN Slider Target", jSlider);
}

void Build_itnwn_tprg(object oPC)
{
    json jProgress = NuiProgress(JsonFloat(0.6));
    ItnwScrOpenTarget(oPC, ITNWSCR_WIN_PRG, "ITNWN Progress Target", jProgress);
}

void Build_itnwn_ttxe(object oPC)
{
    json jTextEdit = NuiTextEdit(
        JsonString("Type here..."),
        JsonString(""),
        64,
        FALSE);
    ItnwScrOpenTarget(oPC, ITNWSCR_WIN_TXE, "ITNWN TextEdit Target", jTextEdit);
}

void Build_itnwn_tbim(object oPC)
{
    json jButtonImage = NuiButtonImage(JsonString("ir_follow"));
    ItnwScrOpenTarget(oPC, ITNWSCR_WIN_BIM, "ITNWN ButtonImage Target", jButtonImage);
}

void Build_itnwn_tbse(object oPC)
{
    json jButtonSelect = NuiButtonSelect(JsonString("Toggle Option"), JsonBool(TRUE));
    ItnwScrOpenTarget(oPC, ITNWSCR_WIN_BSE, "ITNWN ButtonSelect Target", jButtonSelect);
}

void Build_itnwn_tclr(object oPC)
{
    json jColorPicker = NuiColorPicker(NuiColor(96, 128, 255, 255));
    ItnwScrOpenTarget(oPC, ITNWSCR_WIN_CLR, "ITNWN ColorPicker Target", jColorPicker);
}

void Build_itnwn_tcmb(object oPC)
{
    json jCombo = NuiCombo(ItnwScrComboEntriesABC(), JsonInt(1));
    ItnwScrOpenTarget(oPC, ITNWSCR_WIN_CMB, "ITNWN Combo Target", jCombo);
}

void Build_itnwn_timg(object oPC)
{
    json jImage = NuiImage(
        JsonString("ir_follow"),
        JsonInt(NUI_ASPECT_FIT),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE));
    ItnwScrOpenTarget(oPC, ITNWSCR_WIN_IMG, "ITNWN Image Target", jImage);
}

void Build_itnwn_tslf(object oPC)
{
    json jSliderFloat = NuiSliderFloat(
        JsonFloat(0.35),
        JsonFloat(0.0),
        JsonFloat(1.0),
        JsonFloat(0.05));
    ItnwScrOpenTarget(oPC, ITNWSCR_WIN_SLF, "ITNWN SliderFloat Target", jSliderFloat);
}

void Build_itnwn_ttxt(object oPC)
{
    json jText = NuiText(JsonString("Line 1\nLine 2\nLine 3"), TRUE, NUI_SCROLLBARS_AUTO);
    ItnwScrOpenTarget(oPC, ITNWSCR_WIN_TXT, "ITNWN Text Target", jText);
}

void Build_itnwn_ttog(object oPC)
{
    json jToggles = NuiToggles(
        NUI_DIRECTION_HORIZONTAL,
        ItnwScrElements123(),
        JsonInt(1));
    ItnwScrOpenTarget(oPC, ITNWSCR_WIN_TOG, "ITNWN Toggles Target", jToggles);
}

void Build_itnwn_tcha(object oPC)
{
    json jChart = NuiChart(ItnwScrChartSlots());
    int nToken = ItnwScrOpenTarget(oPC, ITNWSCR_WIN_CHA, "ITNWN Chart Target", jChart);
    if (nToken == 0) return;
    NuiSetBind(oPC, nToken, ITNWSCR_CHART_B, ItnwScrChartData());
}

void Build_itnwn_tdla(object oPC)
{
    json jItem = NuiDrawListArc(
        JsonBool(TRUE),
        NuiColor(255, 220, 120, 255),
        JsonBool(FALSE),
        JsonFloat(4.0),
        NuiVec(260.0, 220.0),
        JsonFloat(120.0),
        JsonFloat(0.0),
        JsonFloat(3.14));
    ItnwScrOpenTarget(oPC, ITNWSCR_WIN_DLA, "ITNWN Draw Arc Target", ItnwScrDrawCanvas(jItem));
}

void Build_itnwn_tdlc(object oPC)
{
    json jItem = NuiDrawListCircle(
        JsonBool(TRUE),
        NuiColor(120, 220, 170, 255),
        JsonBool(FALSE),
        JsonFloat(3.0),
        NuiRect(160.0, 120.0, 200.0, 200.0));
    ItnwScrOpenTarget(oPC, ITNWSCR_WIN_DLC, "ITNWN Draw Circle Target", ItnwScrDrawCanvas(jItem));
}

void Build_itnwn_tdlv(object oPC)
{
    json jItem = NuiDrawListCurve(
        JsonBool(TRUE),
        NuiColor(150, 210, 255, 255),
        JsonFloat(3.0),
        NuiVec(120.0, 300.0),
        NuiVec(420.0, 300.0),
        NuiVec(190.0, 130.0),
        NuiVec(350.0, 370.0));
    ItnwScrOpenTarget(oPC, ITNWSCR_WIN_DLV, "ITNWN Draw Curve Target", ItnwScrDrawCanvas(jItem));
}

void Build_itnwn_tdli(object oPC)
{
    json jItem = NuiDrawListImage(
        JsonBool(TRUE),
        JsonString("ir_follow"),
        NuiRect(220.0, 150.0, 120.0, 120.0),
        JsonInt(NUI_ASPECT_FIT),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE));
    ItnwScrOpenTarget(oPC, ITNWSCR_WIN_DLI, "ITNWN Draw Image Target", ItnwScrDrawCanvas(jItem));
}

void Build_itnwn_tdir(object oPC)
{
    json jImage = NuiDrawListImage(
        JsonBool(TRUE),
        JsonString("ir_follow"),
        NuiRect(220.0, 150.0, 120.0, 120.0),
        JsonInt(NUI_ASPECT_FIT),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE));
    json jItem = NuiDrawListImageRegion(jImage, NuiRect(0.0, 0.0, 32.0, 32.0));
    ItnwScrOpenTarget(oPC, ITNWSCR_WIN_DIR, "ITNWN Draw ImgRegion Target", ItnwScrDrawCanvas(jItem));
}

void Build_itnwn_tdll(object oPC)
{
    json jItem = NuiDrawListLine(
        JsonBool(TRUE),
        NuiColor(235, 180, 80, 255),
        JsonFloat(4.0),
        NuiVec(110.0, 210.0),
        NuiVec(410.0, 210.0));
    ItnwScrOpenTarget(oPC, ITNWSCR_WIN_DLL, "ITNWN Draw Line Target", ItnwScrDrawCanvas(jItem));
}

void Build_itnwn_tdlp(object oPC)
{
    json jItem = NuiDrawListPolyLine(
        JsonBool(TRUE),
        NuiColor(170, 255, 140, 255),
        JsonBool(FALSE),
        JsonFloat(3.0),
        ItnwScrPolyPoints());
    ItnwScrOpenTarget(oPC, ITNWSCR_WIN_DLP, "ITNWN Draw PolyLine Target", ItnwScrDrawCanvas(jItem));
}

void Build_itnwn_tdlr(object oPC)
{
    json jItem = NuiDrawListRect(
        JsonBool(TRUE),
        NuiColor(240, 180, 90, 255),
        JsonBool(FALSE),
        JsonFloat(3.0),
        NuiRect(150.0, 120.0, 220.0, 160.0));
    ItnwScrOpenTarget(oPC, ITNWSCR_WIN_DLR, "ITNWN Draw Rect Target", ItnwScrDrawCanvas(jItem));
}

void Build_itnwn_tdlt(object oPC)
{
    json jItem = NuiDrawListText(
        JsonBool(TRUE),
        NuiColor(120, 200, 255, 255),
        NuiRect(120.0, 180.0, 300.0, 60.0),
        JsonString("DrawList Text"));
    ItnwScrOpenTarget(oPC, ITNWSCR_WIN_DLT, "ITNWN Draw Text Target", ItnwScrDrawCanvas(jItem));
}

// Backward compatibility shim for older launchers.
void Build_itnwn_scrxp(object oPC)
{
    Build_itnwn_tlbl(oPC);
}
