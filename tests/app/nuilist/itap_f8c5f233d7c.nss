// Auto-generated static launcher (entry wrapper).
#include "nuilist"

void main()
{
    object oPC = GetLastUsedBy();
    if (!GetIsObjectValid(oPC) || !GetIsPC(oPC))
    {
        oPC = GetFirstPC();
    }
    if (!GetIsObjectValid(oPC) || !GetIsPC(oPC)) return;

    NuiLstOpen(oPC);
}
