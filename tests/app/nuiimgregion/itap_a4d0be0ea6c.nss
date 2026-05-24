// Auto-generated static launcher (entry wrapper).
#include "nuiimgregion"

void main()
{
    object oPC = GetLastUsedBy();
    if (!GetIsObjectValid(oPC) || !GetIsPC(oPC))
    {
        oPC = GetFirstPC();
    }
    if (!GetIsObjectValid(oPC) || !GetIsPC(oPC)) return;

    NuiImrOpen(oPC);
}
