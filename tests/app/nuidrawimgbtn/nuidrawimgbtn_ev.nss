// =============================================================================
// nuidrawimgbtn_ev.nss
// Event handler for nuidrawimgbtn.nss.
// =============================================================================

#include "nw_inc_nui"
#include "nuidrawimgbtn"

void main()
{
    object oPC      = NuiGetEventPlayer();
    int    nToken   = NuiGetEventWindow();
    string sEvent   = NuiGetEventType();
    string sElement = NuiGetEventElement();

    if (sEvent == "close") return;
    if (sEvent != "click") return;

    if (sElement == NUIDIB_BTN_BASE)
    {
        NuiSetBind(oPC, nToken, NUIDIB_MSG, JsonString("Base button click OK."));
        return;
    }

    if (sElement == NUIDIB_BTN_OVR)
    {
        NuiSetBind(oPC, nToken, NUIDIB_MSG, JsonString("Overlay button click OK."));
        return;
    }
}

