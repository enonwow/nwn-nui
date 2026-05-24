// Auto-generated static launcher (entry wrapper).
#include "nuicolorpicker"

void main()
{
    object oPC = GetLastUsedBy();
    if (!GetIsObjectValid(oPC) || !GetIsPC(oPC))
    {
        oPC = GetFirstPC();
    }
    if (!GetIsObjectValid(oPC) || !GetIsPC(oPC)) return;

    NuiClrOpen(oPC);
}
