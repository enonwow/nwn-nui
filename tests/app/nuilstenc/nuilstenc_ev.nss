// =============================================================================
// nuilstenc_ev.nss
// Event handler for nuilstenc.nss.
// =============================================================================

#include "nw_inc_nui"
#include "nuilstenc"

void main()
{
    object oPC      = NuiGetEventPlayer();
    int    nToken   = NuiGetEventWindow();
    string sEvent   = NuiGetEventType();
    string sElement = NuiGetEventElement();
    int    nRow     = NuiGetEventArrayIndex();

    if (sEvent == "close") return;
    if (sEvent != "click") return;

    if (sElement == NUILSE_BTN)
    {
        NuiLseSync(oPC, nToken, nRow);
        return;
    }
}
