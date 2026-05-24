// =============================================================================
// nuidrawbgroot_ev.nss
// Event handler for nuidrawbgroot.nss.
// =============================================================================

#include "nw_inc_nui"
#include "nuidrawbgroot"

void main()
{
    object oPC      = NuiGetEventPlayer();
    int    nToken   = NuiGetEventWindow();
    string sEvent   = NuiGetEventType();
    string sElement = NuiGetEventElement();

    if (sEvent == "close") return;
    if (sEvent != "click") return;

    if (sElement == NUIDBR_BTN_PING)
    {
        NuiSetBind(oPC, nToken, NUIDBR_MSG, JsonString("Ping click OK (custom root still active)."));
        return;
    }

    if (sElement == NUIDBR_BTN_CLOSE)
    {
        NuiDestroy(oPC, nToken);
        return;
    }
}

