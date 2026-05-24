// =============================================================================
// nuiaccinput_ev.nss
// Event handler for nuiaccinput.nss.
// =============================================================================

#include "nw_inc_nui"
#include "nuiaccinput"

void main()
{
    object oPC      = NuiGetEventPlayer();
    int    nToken   = NuiGetEventWindow();
    string sEvent   = NuiGetEventType();
    string sElement = NuiGetEventElement();

    if (sEvent == "close") return;
    if (sEvent != "click") return;

    if (sElement == NUIACI_BTN_PROBE)
    {
        NuiSetBind(oPC, nToken, NUIACI_MSG, JsonString("Probe click OK (input active)."));
        return;
    }

    if (sElement == NUIACI_BTN_OFF)
    {
        NuiSetBind(oPC, nToken, NUIACI_MSG, JsonString("Input OFF for 2 seconds... clicks should fall through."));
        NuiSetBind(oPC, nToken, NUIACI_ACC, JsonBool(FALSE));
        DelayCommand(2.0, NuiAciRestore(oPC, nToken));
        return;
    }
}

