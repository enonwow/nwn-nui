// =============================================================================
// itduel_swev.nss
// Event handler for itduel_sw.nss
// =============================================================================

#include "nw_inc_nui"
#include "itduel_sw"

void main()
{
    object oPC      = NuiGetEventPlayer();
    int    nToken   = NuiGetEventWindow();
    string sEvent   = NuiGetEventType();
    string sElement = NuiGetEventElement();

    if (sEvent == "close") return;
    if (sEvent != "click") return;

    if (sElement == NUIDUEL_BTN_CLOSE)
    {
        NuiDestroy(oPC, nToken);
        return;
    }

    if (sElement == NUIDUEL_BTN_CHALLENGE)
    {
        // Placeholder in integration fixture: we keep window open and route to history.
        NuiDuelShowHistory(oPC, nToken);
        return;
    }

    if (sElement == NUIDUEL_BTN_LOG)
    {
        NuiDuelShowHistory(oPC, nToken);
        return;
    }

    if (sElement == NUIDUEL_BTN_RANK)
    {
        NuiDuelShowRanking(oPC, nToken);
        return;
    }
}
