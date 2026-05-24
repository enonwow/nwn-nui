// =============================================================================
// nuigeombind_ev.nss
// Event handler for nuigeombind.nss.
// =============================================================================

#include "nw_inc_nui"
#include "nuigeombind"

void main()
{
    object oPC      = NuiGetEventPlayer();
    int    nToken   = NuiGetEventWindow();
    string sEvent   = NuiGetEventType();
    string sElement = NuiGetEventElement();

    if (sEvent == "close") return;
    if (sEvent != "click") return;

    if (sElement == NUIGEO_BTN_MID)
    {
        NuiSetBind(oPC, nToken, NUIGEO_RECT, NuiRect(-1.0, -1.0, 520.0, 210.0));
        NuiSetBind(oPC, nToken, NUIGEO_MSG, JsonString("Current: centered 520x210."));
        return;
    }

    if (sElement == NUIGEO_BTN_SMALL)
    {
        NuiSetBind(oPC, nToken, NUIGEO_RECT, NuiRect(90.0, 120.0, 420.0, 180.0));
        NuiSetBind(oPC, nToken, NUIGEO_MSG, JsonString("Current: compact 420x180 at fixed screen position."));
        return;
    }

    if (sElement == NUIGEO_BTN_WIDE)
    {
        NuiSetBind(oPC, nToken, NUIGEO_RECT, NuiRect(-1.0, -1.0, 640.0, 220.0));
        NuiSetBind(oPC, nToken, NUIGEO_MSG, JsonString("Current: wide centered 640x220."));
        return;
    }
}

