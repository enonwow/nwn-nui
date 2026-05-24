// =============================================================================
// nuiaccinput.nss
// Integration test: window-level jAcceptsInput toggle (temporary OFF state).
// =============================================================================

#include "nw_inc_nui"

const string NUIACI_WIN       = "IT_NUIACI_WIN";
const string NUIACI_EV        = "nuiaccinput_ev";
const string NUIACI_ACC       = "it_nuiaci_acc";
const string NUIACI_MSG       = "it_nuiaci_msg";
const string NUIACI_BTN_PROBE = "it_nuiaci_probe";
const string NUIACI_BTN_OFF   = "it_nuiaci_off";

json NuiAciCentered(json jWidget)
{
    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    jRow = JsonArrayInsert(jRow, jWidget);
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    return NuiRow(jRow);
}

void NuiAciRestore(object oPC, int nToken)
{
    if (!GetIsObjectValid(oPC)) return;
    NuiSetBind(oPC, nToken, NUIACI_ACC, JsonBool(TRUE));
    NuiSetBind(oPC, nToken, NUIACI_MSG, JsonString("Input restored. Probe button should work again."));
}

void NuiAciOpen(object oPC)
{
    if (!GetIsPC(oPC)) return;

    int nOld = NuiFindWindow(oPC, NUIACI_WIN);
    if (nOld != 0) NuiDestroy(oPC, nOld);

    json jProbe = NuiId(NuiButton(JsonString("Probe Click")), NUIACI_BTN_PROBE);
    jProbe = NuiWidth(jProbe, 170.0);
    jProbe = NuiHeight(jProbe, 34.0);

    json jOff = NuiId(NuiButton(JsonString("Disable Input (2s)")), NUIACI_BTN_OFF);
    jOff = NuiWidth(jOff, 170.0);
    jOff = NuiHeight(jOff, 34.0);

    json jButtons = JsonArray();
    jButtons = JsonArrayInsert(jButtons, NuiSpacer());
    jButtons = JsonArrayInsert(jButtons, jProbe);
    jButtons = JsonArrayInsert(jButtons, NuiWidth(NuiSpacer(), 12.0));
    jButtons = JsonArrayInsert(jButtons, jOff);
    jButtons = JsonArrayInsert(jButtons, NuiSpacer());
    jButtons = NuiRow(jButtons);

    json jMsg = NuiLabel(NuiBind(NUIACI_MSG), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jMsg = NuiHeight(jMsg, 24.0);

    json jHint = NuiLabel(
        JsonString("Click Disable Input, then try clicking during the 2-second OFF period."),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE));
    jHint = NuiHeight(jHint, 24.0);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));
    jCol = JsonArrayInsert(jCol, NuiAciCentered(jHint));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 8.0));
    jCol = JsonArrayInsert(jCol, jButtons);
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 8.0));
    jCol = JsonArrayInsert(jCol, NuiAciCentered(jMsg));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));

    json jWin = NuiWindow(
        NuiCol(jCol),
        JsonString("NuiAcceptInput Test"),
        NuiRect(-1.0, -1.0, 560.0, 190.0),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        NuiBind(NUIACI_ACC));

    int nToken = NuiCreate(oPC, jWin, NUIACI_WIN, NUIACI_EV);
    if (nToken == 0) return;

    NuiSetUserData(oPC, nToken, jWin);
    NuiSetBind(oPC, nToken, NUIACI_ACC, JsonBool(TRUE));
    NuiSetBind(oPC, nToken, NUIACI_MSG, JsonString("Input ON. Probe click should update this line."));
}

