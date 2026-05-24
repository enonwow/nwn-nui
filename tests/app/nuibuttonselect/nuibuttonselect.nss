// =============================================================================
// nuibuttonselect.nss
// Integration test: one window + one NuiButtonSelect.
// =============================================================================

#include "nw_inc_nui"

const string NUIBSL_WIN  = "IT_NUIBSL_WIN";
const string NUIBSL_BIND = "it_nuibsl_bind";

json NuiBslCentered(json jWidget)
{
    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    jRow = JsonArrayInsert(jRow, jWidget);
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    return NuiRow(jRow);
}

void NuiBslOpen(object oPC)
{
    if (!GetIsPC(oPC)) return;

    int nOld = NuiFindWindow(oPC, NUIBSL_WIN);
    if (nOld != 0) NuiDestroy(oPC, nOld);

    json jBtn = NuiButtonSelect(JsonString("Toggle Option"), NuiBind(NUIBSL_BIND));
    jBtn = NuiWidth(jBtn, 220.0);
    jBtn = NuiHeight(jBtn, 34.0);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 12.0));
    jCol = JsonArrayInsert(jCol, NuiBslCentered(jBtn));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 12.0));

    json jWin = NuiWindow(
        NuiCol(jCol),
        JsonString("NuiButtonSelect Test"),
        NuiRect(-1.0, -1.0, 380.0, 140.0),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE));

    int nToken = NuiCreate(oPC, jWin, NUIBSL_WIN, "");
    if (nToken == 0) return;



    NuiSetUserData(oPC, nToken, jWin);
    NuiSetBind(oPC, nToken, NUIBSL_BIND, JsonBool(FALSE));
}

