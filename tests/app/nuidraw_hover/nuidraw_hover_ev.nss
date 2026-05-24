// =============================================================================
// nuidraw_hover_ev.nss
// Event handler for nuidraw_hover.nss
// =============================================================================

#include "nw_inc_nui"

const string NUIDRH_BTN   = "it_nuidrh_btn";
const string NUIDRH_CLOSE = "it_nuidrh_close";

void main()
{
    object oPC      = NuiGetEventPlayer();
    int    nToken   = NuiGetEventWindow();
    string sEvent   = NuiGetEventType();
    string sElement = NuiGetEventElement();

    if (sEvent == "close") return;

    if (sEvent == "click")
    {
        if (sElement == NUIDRH_BTN)
        {
            SendMessageToPC(oPC, "NuiDraw hover test: click detected.");
            return;
        }

        if (sElement == NUIDRH_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }
    }
}
