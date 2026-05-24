// =============================================================================
// nuibutton.nss
// Integration test: one window + one NuiButton.
// =============================================================================

#include "nw_inc_nui"

const string NUIBTN_WIN = "IT_NUIBTN_WIN";

json NuiBtnCentered(json jWidget)
{
    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    jRow = JsonArrayInsert(jRow, jWidget);
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    return NuiRow(jRow);
}

void NuiBtnOpen(object oPC)
{
    if (!GetIsPC(oPC)) return;

    int nOld = NuiFindWindow(oPC, NUIBTN_WIN);
    if (nOld != 0) NuiDestroy(oPC, nOld);

    json jBtn = NuiButton(JsonString("Integration Button"));
    jBtn = NuiWidth(jBtn, 180.0);
    jBtn = NuiHeight(jBtn, 34.0);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));
    jCol = JsonArrayInsert(jCol, NuiBtnCentered(jBtn));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));

    json jWin = NuiWindow(
        NuiCol(jCol),
        JsonString("NuiButton Test"),
        NuiRect(-1.0, -1.0, 340.0, 120.0),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE));

    int nToken = NuiCreate(oPC, jWin, NUIBTN_WIN, "");

    if (nToken == 0) return;

    NuiSetUserData(oPC, nToken, jWin);
}

