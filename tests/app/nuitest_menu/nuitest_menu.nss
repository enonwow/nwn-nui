// =============================================================================
// nuitest_menu.nss
// Integration test launcher: choose test from combo, then click Show.
// =============================================================================

#include "nw_inc_nui"

// Include all test scripts as include-style libraries (no main()).
#include "nuibutton"
#include "nuibuttonimage"
#include "nuiimage"
#include "nuitextedit"
#include "nuicheck"
#include "nuislider"
#include "nuiprogress"
#include "nuicombo"
#include "nuibuttonselect"
#include "nuilabel"
#include "nuitext"
#include "nuitoggles"
#include "nuioptions"
#include "nuicolorpicker"
#include "nuisliderfloat"
#include "nuichart"
#include "nuilist"
#include "nuiimage_hak"
#include "nuidraw_primitiv"
#include "nuidraw_hover"
#include "nuidraw_order"
#include "nuigroup"
#include "nuiimgregion"
#include "nuiaspect"
#include "nuilistbtn"
#include "nuiprogcolor"
#include "nuiaspmod"
#include "nuitooltip"
#include "nuidistip"
#include "nuivisible"
#include "nuiencourage"
#include "nuimargin"
#include "nuipadding"
#include "nuiswaplay"
#include "nuilstenc"
#include "nuidrawimgbtn"
#include "nuidrawbgroot"
#include "nuiaccinput"
#include "nuigeombind"
#include "nuisizecons"
#include "nuiedgecons"
#include "nuichartcol"
#include "nuidemo_moon"
#include "itduel_sw"

const string NUITST_WIN      = "IT_NUITST_WIN";
const string NUITST_EVENT    = "nuitest_menu";
const string NUITST_LIST     = "it_nuitst_list";
const string NUITST_SELECTED = "it_nuitst_selected";
const string NUITST_SHOW_EN  = "it_nuitst_show_en";
const string NUITST_SHOW_BTN = "it_nuitst_show_btn";
const string NUITST_JSON_BTN = "it_nuitst_json_btn";
const string NUITST_JSN_WIN  = "IT_NUITST_JSN";
const string NUITST_JSN_CAP  = "it_nuitst_jsn_cap";
const string NUITST_JSN_WID  = "it_nuitst_jsn_wid";
const string NUITST_JSN_TXT  = "it_nuitst_jsn_txt";

const int NUITST_NONE              = 0;
const int NUITST_NUIBUTTON         = 1;
const int NUITST_NUIBUTTONIMAGE    = 2;
const int NUITST_NUIIMAGE          = 3;
const int NUITST_NUITEXTEDIT       = 4;
const int NUITST_NUICHECK          = 5;
const int NUITST_NUISLIDER         = 6;
const int NUITST_NUIPROGRESS       = 7;
const int NUITST_NUICOMBO          = 8;
const int NUITST_NUIBUTTONSELECT   = 9;
const int NUITST_NUILABEL          = 10;
const int NUITST_NUITEXT           = 11;
const int NUITST_NUITOGGLES        = 12;
const int NUITST_NUIOPTIONS        = 13;
const int NUITST_NUICOLORPICKER    = 14;
const int NUITST_NUISLIDERFLOAT    = 15;
const int NUITST_NUICHART          = 16;
const int NUITST_NUILIST           = 17;
const int NUITST_NUIIMAGE_HAK      = 18;
const int NUITST_NUIDRAW_PRIMITIV  = 19;
const int NUITST_NUIDRAW_HOVER     = 20;
const int NUITST_NUIDRAW_ORDER     = 21;
const int NUITST_NUIGROUP          = 22;
const int NUITST_NUIIMGREGION      = 23;
const int NUITST_NUIASPECT         = 24;
const int NUITST_NUILISTBTN        = 25;
const int NUITST_NUIPROGCOLOR      = 26;
const int NUITST_NUIASPMOD         = 27;
const int NUITST_NUITOOLTIP        = 28;
const int NUITST_NUIDISTIP         = 29;
const int NUITST_NUIVISIBLE        = 30;
const int NUITST_NUIENCOURAGE      = 31;
const int NUITST_NUIMARGIN         = 32;
const int NUITST_NUIPADDING        = 33;
const int NUITST_NUISWAPLAY        = 34;
const int NUITST_NUILSTENC         = 35;
const int NUITST_NUIDRAWIMGBTN     = 36;
const int NUITST_NUIDRAWBGROOT     = 37;
const int NUITST_NUIACCINPUT       = 38;
const int NUITST_NUIGEOMBIND       = 39;
const int NUITST_NUISIZECONS       = 40;
const int NUITST_NUIEDGECONS       = 41;
const int NUITST_NUICHARTCOL       = 42;
const int NUITST_NUIDEMO_MOON      = 43;
const int NUITST_NUIDUELUI         = 44;

json NuiTstCentered(json jWidget)
{
    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    jRow = JsonArrayInsert(jRow, jWidget);
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    return NuiRow(jRow);
}

json NuiTstEntries()
{
    json jEntries = JsonArray();
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("-- Select test --", NUITST_NONE));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("nuibutton", NUITST_NUIBUTTON));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("nuibuttonimage", NUITST_NUIBUTTONIMAGE));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("nuiimage", NUITST_NUIIMAGE));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("nuitextedit", NUITST_NUITEXTEDIT));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("nuicheck", NUITST_NUICHECK));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("nuislider", NUITST_NUISLIDER));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("nuiprogress", NUITST_NUIPROGRESS));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("nuicombo", NUITST_NUICOMBO));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("nuibuttonselect", NUITST_NUIBUTTONSELECT));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("nuilabel", NUITST_NUILABEL));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("nuitext", NUITST_NUITEXT));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("nuitoggles", NUITST_NUITOGGLES));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("nuioptions", NUITST_NUIOPTIONS));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("nuicolorpicker", NUITST_NUICOLORPICKER));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("nuisliderfloat", NUITST_NUISLIDERFLOAT));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("nuichart", NUITST_NUICHART));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("nuilist", NUITST_NUILIST));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("nuiimage_hak", NUITST_NUIIMAGE_HAK));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("nuidraw_primitives", NUITST_NUIDRAW_PRIMITIV));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("nuidraw_hover", NUITST_NUIDRAW_HOVER));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("nuidraw_order", NUITST_NUIDRAW_ORDER));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("nuigroup", NUITST_NUIGROUP));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("nuiimgregion", NUITST_NUIIMGREGION));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("nuiaspect", NUITST_NUIASPECT));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("nuilistbtn", NUITST_NUILISTBTN));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("nuiprogcolor", NUITST_NUIPROGCOLOR));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("nuiaspmod", NUITST_NUIASPMOD));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("nuitooltip", NUITST_NUITOOLTIP));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("nuidistip", NUITST_NUIDISTIP));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("nuivisible", NUITST_NUIVISIBLE));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("nuiencourage", NUITST_NUIENCOURAGE));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("nuimargin", NUITST_NUIMARGIN));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("nuipadding", NUITST_NUIPADDING));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("nuiswaplay", NUITST_NUISWAPLAY));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("nuilstenc", NUITST_NUILSTENC));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("nuidrawimgbtn", NUITST_NUIDRAWIMGBTN));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("nuidrawbgroot", NUITST_NUIDRAWBGROOT));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("nuiaccinput", NUITST_NUIACCINPUT));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("nuigeombind", NUITST_NUIGEOMBIND));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("nuisizecons", NUITST_NUISIZECONS));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("nuiedgecons", NUITST_NUIEDGECONS));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("nuichartcol", NUITST_NUICHARTCOL));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("nuidemo_moon", NUITST_NUIDEMO_MOON));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("nuiduelui", NUITST_NUIDUELUI));
    return jEntries;
}

void NuiTstSyncShowEnabled(object oPC, int nToken)
{
    int nSelected = JsonGetInt(NuiGetBind(oPC, nToken, NUITST_SELECTED));
    NuiSetBind(oPC, nToken, NUITST_SHOW_EN, JsonBool(nSelected > NUITST_NONE));
}

string NuiTstWindowIdFromSelected(int nSelected)
{
    if (nSelected == NUITST_NUIBUTTON)        return NUIBTN_WIN;
    if (nSelected == NUITST_NUIBUTTONIMAGE)   return NUIBTNIMG_WIN;
    if (nSelected == NUITST_NUIIMAGE)         return NUIIMG_WIN;
    if (nSelected == NUITST_NUITEXTEDIT)      return NUITXT_WIN;
    if (nSelected == NUITST_NUICHECK)         return NUICHK_WIN;
    if (nSelected == NUITST_NUISLIDER)        return NUISLD_WIN;
    if (nSelected == NUITST_NUIPROGRESS)      return NUIPRG_WIN;
    if (nSelected == NUITST_NUICOMBO)         return NUICMB_WIN;
    if (nSelected == NUITST_NUIBUTTONSELECT)  return NUIBSL_WIN;
    if (nSelected == NUITST_NUILABEL)         return NUILBL_WIN;
    if (nSelected == NUITST_NUITEXT)          return NUITXTW_WIN;
    if (nSelected == NUITST_NUITOGGLES)       return NUITOG_WIN;
    if (nSelected == NUITST_NUIOPTIONS)       return NUIOPT_WIN;
    if (nSelected == NUITST_NUICOLORPICKER)   return NUICLR_WIN;
    if (nSelected == NUITST_NUISLIDERFLOAT)   return NUISLF_WIN;
    if (nSelected == NUITST_NUICHART)         return NUICHT_WIN;
    if (nSelected == NUITST_NUILIST)          return NUILST_WIN;
    if (nSelected == NUITST_NUIIMAGE_HAK)     return NUIHKI_WIN;
    if (nSelected == NUITST_NUIDRAW_PRIMITIV) return NUIDRP_WIN;
    if (nSelected == NUITST_NUIDRAW_HOVER)    return NUIDRH_WIN;
    if (nSelected == NUITST_NUIDRAW_ORDER)    return NUIDRO_WIN;
    if (nSelected == NUITST_NUIGROUP)         return NUIGRP_WIN;
    if (nSelected == NUITST_NUIIMGREGION)     return NUIIMR_WIN;
    if (nSelected == NUITST_NUIASPECT)        return NUIASP_WIN;
    if (nSelected == NUITST_NUILISTBTN)       return NUILBT_WIN;
    if (nSelected == NUITST_NUIPROGCOLOR)     return NUIPC_WIN;
    if (nSelected == NUITST_NUIASPMOD)        return NUIASM_WIN;
    if (nSelected == NUITST_NUITOOLTIP)       return NUITIP_WIN;
    if (nSelected == NUITST_NUIDISTIP)        return NUIDST_WIN;
    if (nSelected == NUITST_NUIVISIBLE)       return NUIVIS_WIN;
    if (nSelected == NUITST_NUIENCOURAGE)     return NUIENC_WIN;
    if (nSelected == NUITST_NUIMARGIN)        return NUIMGN_WIN;
    if (nSelected == NUITST_NUIPADDING)       return NUIPAD_WIN;
    if (nSelected == NUITST_NUISWAPLAY)       return NUISWP_WIN;
    if (nSelected == NUITST_NUILSTENC)        return NUILSE_WIN;
    if (nSelected == NUITST_NUIDRAWIMGBTN)    return NUIDIB_WIN;
    if (nSelected == NUITST_NUIDRAWBGROOT)    return NUIDBR_WIN;
    if (nSelected == NUITST_NUIACCINPUT)      return NUIACI_WIN;
    if (nSelected == NUITST_NUIGEOMBIND)      return NUIGEO_WIN;
    if (nSelected == NUITST_NUISIZECONS)      return NUISIZ_WIN;
    if (nSelected == NUITST_NUIEDGECONS)      return NUIEDG_WIN;
    if (nSelected == NUITST_NUICHARTCOL)      return NUICC_WIN;
    if (nSelected == NUITST_NUIDEMO_MOON)     return NUIDMO_WIN;
    if (nSelected == NUITST_NUIDUELUI)        return NUIDUEL_WIN;
    return "";
}

string NuiTstLimitJsonText(string sText)
{
    int nMax = 65000;
    if (GetStringLength(sText) <= nMax) return sText;
    return GetSubString(sText, 0, nMax) + "\n\n[TRUNCATED to 65000 chars]";
}

void NuiTstOpenJsonViewer(object oPC, string sWindowId, string sCaption, string sJsonText)
{
    int nTokenExisting = NuiFindWindow(oPC, NUITST_JSN_WIN);
    if (nTokenExisting != 0)
    {
        NuiSetBind(oPC, nTokenExisting, NUITST_JSN_WID, JsonString(sWindowId));
        NuiSetBind(oPC, nTokenExisting, NUITST_JSN_CAP, JsonString(sCaption));
        NuiSetBind(oPC, nTokenExisting, NUITST_JSN_TXT, JsonString(NuiTstLimitJsonText(sJsonText)));
        return;
    }

    json jWidLabel = NuiLabel(JsonString("Window ID (copy):"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jWidLabel = NuiWidth(jWidLabel, 130.0);
    jWidLabel = NuiHeight(jWidLabel, 24.0);

    json jWid = NuiTextEdit(JsonString(""), NuiBind(NUITST_JSN_WID), 64, FALSE);
    jWid = NuiWidth(jWid, 260.0);
    jWid = NuiHeight(jWid, 30.0);

    json jWidRow = JsonArray();
    jWidRow = JsonArrayInsert(jWidRow, NuiSpacer());
    jWidRow = JsonArrayInsert(jWidRow, jWidLabel);
    jWidRow = JsonArrayInsert(jWidRow, NuiWidth(NuiSpacer(), 8.0));
    jWidRow = JsonArrayInsert(jWidRow, jWid);
    jWidRow = JsonArrayInsert(jWidRow, NuiSpacer());
    jWidRow = NuiRow(jWidRow);

    json jCap = NuiLabel(NuiBind(NUITST_JSN_CAP), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jCap = NuiHeight(jCap, 24.0);

    json jText = NuiTextEdit(JsonString(""), NuiBind(NUITST_JSN_TXT), 65535, TRUE);
    jText = NuiWidth(jText, 730.0);
    jText = NuiHeight(jText, 410.0);

    json jHelp = NuiLabel(
        JsonString("Copy JSON from the field below and save as <test>.jui."),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE));
    jHelp = NuiHeight(jHelp, 22.0);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 8.0));
    jCol = JsonArrayInsert(jCol, jWidRow);
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 6.0));
    jCol = JsonArrayInsert(jCol, jCap);
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 6.0));
    jCol = JsonArrayInsert(jCol, jHelp);
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 8.0));
    jCol = JsonArrayInsert(jCol, NuiTstCentered(jText));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 8.0));

    json jWin = NuiWindow(
        NuiCol(jCol),
        JsonString("NUI JSON Export"),
        NuiRect(-1.0, -1.0, 790.0, 540.0),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE));

    int nToken = NuiCreate(oPC, jWin, NUITST_JSN_WIN, NUITST_EVENT);
    if (nToken == 0) return;

    NuiSetBind(oPC, nToken, NUITST_JSN_WID, JsonString(sWindowId));
    NuiSetBind(oPC, nToken, NUITST_JSN_CAP, JsonString(sCaption));
    NuiSetBind(oPC, nToken, NUITST_JSN_TXT, JsonString(NuiTstLimitJsonText(sJsonText)));
}

void NuiTstExportSelectedJson(object oPC, int nSelected)
{
    if (nSelected <= NUITST_NONE)
    {
        NuiTstOpenJsonViewer(oPC, "", "No Test Selected", "Select a test first in the launcher.");
        return;
    }

    string sWinId = NuiTstWindowIdFromSelected(nSelected);
    if (sWinId == "")
    {
        NuiTstOpenJsonViewer(oPC, "", "No Window Mapping", "No window mapping found for selected test.");
        return;
    }

    int nTarget = NuiFindWindow(oPC, sWinId);
    if (nTarget == 0)
    {
        NuiTstOpenJsonViewer(oPC, sWinId, "Window Not Open", "Open the selected test window first, then click JSON.");
        return;
    }

    json jUserData = NuiGetUserData(oPC, nTarget);
    if (JsonGetType(jUserData) == JSON_TYPE_NULL)
    {
        NuiTstOpenJsonViewer(oPC, sWinId, "No JSON Captured", "Selected window has no userdata JSON yet.");
        return;
    }

    NuiTstOpenJsonViewer(oPC, sWinId, "Copy JSON from the field below and save as <test>.jui.", JsonDump(jUserData));
}

void NuiTstOpenSelected(object oPC, int nSelected)
{
    if (nSelected == NUITST_NUIBUTTON)        { NuiBtnOpen(oPC); return; }
    if (nSelected == NUITST_NUIBUTTONIMAGE)   { NuiBtnImgOpen(oPC); return; }
    if (nSelected == NUITST_NUIIMAGE)         { NuiImgOpen(oPC); return; }
    if (nSelected == NUITST_NUITEXTEDIT)      { NuiTxtOpen(oPC); return; }
    if (nSelected == NUITST_NUICHECK)         { NuiChkOpen(oPC); return; }
    if (nSelected == NUITST_NUISLIDER)        { NuiSldOpen(oPC); return; }
    if (nSelected == NUITST_NUIPROGRESS)      { NuiPrgOpen(oPC); return; }
    if (nSelected == NUITST_NUICOMBO)         { NuiCmbOpen(oPC); return; }
    if (nSelected == NUITST_NUIBUTTONSELECT)  { NuiBslOpen(oPC); return; }
    if (nSelected == NUITST_NUILABEL)         { NuiLblOpen(oPC); return; }
    if (nSelected == NUITST_NUITEXT)          { NuiTxtwOpen(oPC); return; }
    if (nSelected == NUITST_NUITOGGLES)       { NuiTogOpen(oPC); return; }
    if (nSelected == NUITST_NUIOPTIONS)       { NuiOptOpen(oPC); return; }
    if (nSelected == NUITST_NUICOLORPICKER)   { NuiClrOpen(oPC); return; }
    if (nSelected == NUITST_NUISLIDERFLOAT)   { NuiSlfOpen(oPC); return; }
    if (nSelected == NUITST_NUICHART)         { NuiChtOpen(oPC); return; }
    if (nSelected == NUITST_NUILIST)          { NuiLstOpen(oPC); return; }
    if (nSelected == NUITST_NUIIMAGE_HAK)     { NuiHkiOpen(oPC); return; }
    if (nSelected == NUITST_NUIDRAW_PRIMITIV) { NuiDrpOpen(oPC); return; }
    if (nSelected == NUITST_NUIDRAW_HOVER)    { NuiDrhOpen(oPC); return; }
    if (nSelected == NUITST_NUIDRAW_ORDER)    { NuiDroOpen(oPC); return; }
    if (nSelected == NUITST_NUIGROUP)         { NuiGrpOpen(oPC); return; }
    if (nSelected == NUITST_NUIIMGREGION)     { NuiImrOpen(oPC); return; }
    if (nSelected == NUITST_NUIASPECT)        { NuiAspOpen(oPC); return; }
    if (nSelected == NUITST_NUILISTBTN)       { NuiLbtOpen(oPC); return; }
    if (nSelected == NUITST_NUIPROGCOLOR)     { NuiPcOpen(oPC); return; }
    if (nSelected == NUITST_NUIASPMOD)        { NuiAsmOpen(oPC); return; }
    if (nSelected == NUITST_NUITOOLTIP)       { NuiTipOpen(oPC); return; }
    if (nSelected == NUITST_NUIDISTIP)        { NuiDstOpen(oPC); return; }
    if (nSelected == NUITST_NUIVISIBLE)       { NuiVisOpen(oPC); return; }
    if (nSelected == NUITST_NUIENCOURAGE)     { NuiEncOpen(oPC); return; }
    if (nSelected == NUITST_NUIMARGIN)        { NuiMgnOpen(oPC); return; }
    if (nSelected == NUITST_NUIPADDING)       { NuiPadOpen(oPC); return; }
    if (nSelected == NUITST_NUISWAPLAY)       { NuiSwpOpen(oPC); return; }
    if (nSelected == NUITST_NUILSTENC)        { NuiLseOpen(oPC); return; }
    if (nSelected == NUITST_NUIDRAWIMGBTN)    { NuiDibOpen(oPC); return; }
    if (nSelected == NUITST_NUIDRAWBGROOT)    { NuiDbrOpen(oPC); return; }
    if (nSelected == NUITST_NUIACCINPUT)      { NuiAciOpen(oPC); return; }
    if (nSelected == NUITST_NUIGEOMBIND)      { NuiGeoOpen(oPC); return; }
    if (nSelected == NUITST_NUISIZECONS)      { NuiSizOpen(oPC); return; }
    if (nSelected == NUITST_NUIEDGECONS)      { NuiEdgOpen(oPC); return; }
    if (nSelected == NUITST_NUICHARTCOL)      { NuiCclOpen(oPC); return; }
    if (nSelected == NUITST_NUIDEMO_MOON)     { NuiDmoOpen(oPC); return; }
    if (nSelected == NUITST_NUIDUELUI)        { NuiDuelSwapOpen(oPC); return; }
}

void NuiTstOpen(object oPC)
{
    if (!GetIsPC(oPC)) return;

    int nOld = NuiFindWindow(oPC, NUITST_WIN);
    if (nOld != 0) NuiDestroy(oPC, nOld);

    json jCombo = NuiCombo(NuiBind(NUITST_LIST), NuiBind(NUITST_SELECTED));
    jCombo = NuiWidth(jCombo, 250.0);
    jCombo = NuiHeight(jCombo, 32.0);

    json jShow = NuiId(NuiButton(JsonString("Show")), NUITST_SHOW_BTN);
    jShow = NuiWidth(jShow, 84.0);
    jShow = NuiHeight(jShow, 32.0);
    jShow = NuiEnabled(jShow, NuiBind(NUITST_SHOW_EN));

    json jJson = NuiId(NuiButton(JsonString("JSON")), NUITST_JSON_BTN);
    jJson = NuiWidth(jJson, 84.0);
    jJson = NuiHeight(jJson, 32.0);
    jJson = NuiEnabled(jJson, NuiBind(NUITST_SHOW_EN));

    json jMainRow = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, jCombo);
    jMainRow = JsonArrayInsert(jMainRow, NuiWidth(NuiSpacer(), 12.0));
    jMainRow = JsonArrayInsert(jMainRow, jShow);
    jMainRow = JsonArrayInsert(jMainRow, NuiWidth(NuiSpacer(), 8.0));
    jMainRow = JsonArrayInsert(jMainRow, jJson);
    jMainRow = NuiRow(jMainRow);

    json jHelp = NuiLabel(
        JsonString("Select test, click Show, then JSON."),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE));
    jHelp = NuiWidth(jHelp, 470.0);
    jHelp = NuiHeight(jHelp, 24.0);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));
    jCol = JsonArrayInsert(jCol, NuiTstCentered(jHelp));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 8.0));
    jCol = JsonArrayInsert(jCol, NuiTstCentered(jMainRow));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));

    json jWin = NuiWindow(
        NuiCol(jCol),
        JsonString("NUI Integration Launcher"),
        NuiRect(-1.0, -1.0, 500.0, 150.0),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE));

    int nToken = NuiCreate(oPC, jWin, NUITST_WIN, NUITST_EVENT);
    if (nToken == 0) return;

    NuiSetBind(oPC, nToken, NUITST_LIST, NuiTstEntries());
    NuiSetBind(oPC, nToken, NUITST_SELECTED, JsonInt(NUITST_NONE));
    NuiSetBind(oPC, nToken, NUITST_SHOW_EN, JsonBool(FALSE));
    NuiSetBindWatch(oPC, nToken, NUITST_SELECTED, TRUE);
}

void main()
{
    string sEvent = NuiGetEventType();

    // Direct execution (item use / console / DM run) opens launcher.
    if (sEvent == "")
    {
        object oPC = GetLastUsedBy();
        NuiTstOpen(oPC);
        return;
    }

    object oPC = NuiGetEventPlayer();
    int nToken = NuiGetEventWindow();
    string sElement = NuiGetEventElement();

    if (sEvent == "open")
    {
        NuiTstSyncShowEnabled(oPC, nToken);
        return;
    }

    if (sEvent == "watch" && sElement == NUITST_SELECTED)
    {
        NuiTstSyncShowEnabled(oPC, nToken);
        return;
    }

    if (sEvent == "click" && sElement == NUITST_SHOW_BTN)
    {
        int nSelected = JsonGetInt(NuiGetBind(oPC, nToken, NUITST_SELECTED));
        NuiTstOpenSelected(oPC, nSelected);
        return;
    }

    if (sEvent == "click" && sElement == NUITST_JSON_BTN)
    {
        int nSelected = JsonGetInt(NuiGetBind(oPC, nToken, NUITST_SELECTED));
        NuiTstExportSelectedJson(oPC, nSelected);
        return;
    }
}
