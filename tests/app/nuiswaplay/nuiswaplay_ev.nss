// =============================================================================
// nuiswaplay_ev.nss
// Event handler for nuiswaplay.nss.
// =============================================================================

#include "nw_inc_nui"
#include "nuiswaplay"

void main()
{
    object oPC      = NuiGetEventPlayer();
    int    nToken   = NuiGetEventWindow();
    string sEvent   = NuiGetEventType();
    string sElement = NuiGetEventElement();

    if (sEvent == "close") return;
    if (sEvent != "click") return;

    if (sElement == NUISWP_BTN_A)
    {
        NuiSetGroupLayout(oPC, nToken, NUISWP_GRP, NuiSwpViewA());
        NuiSetBind(oPC, nToken, NUISWP_ENC_A, JsonBool(TRUE));
        NuiSetBind(oPC, nToken, NUISWP_ENC_B, JsonBool(FALSE));
        return;
    }

    if (sElement == NUISWP_BTN_B)
    {
        NuiSetGroupLayout(oPC, nToken, NUISWP_GRP, NuiSwpViewB());
        NuiSetBind(oPC, nToken, NUISWP_ENC_A, JsonBool(FALSE));
        NuiSetBind(oPC, nToken, NUISWP_ENC_B, JsonBool(TRUE));
        return;
    }
}
