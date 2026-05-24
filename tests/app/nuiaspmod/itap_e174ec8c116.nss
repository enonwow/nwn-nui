// Auto-generated static launcher (entry wrapper).
#include "nuiaspmod"

void main()
{
    object oPC = GetLastUsedBy();
    if (!GetIsObjectValid(oPC) || !GetIsPC(oPC))
    {
        oPC = GetFirstPC();
    }
    if (!GetIsObjectValid(oPC) || !GetIsPC(oPC)) return;

    NuiAsmOpen(oPC);
}
