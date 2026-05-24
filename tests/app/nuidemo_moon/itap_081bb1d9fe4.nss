// Auto-generated static launcher (entry wrapper).
#include "nuidemo_moon"

void main()
{
    object oPC = GetLastUsedBy();
    if (!GetIsObjectValid(oPC) || !GetIsPC(oPC))
    {
        oPC = GetFirstPC();
    }
    if (!GetIsObjectValid(oPC) || !GetIsPC(oPC)) return;

    NuiDmoOpen(oPC);
}
