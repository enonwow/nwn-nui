// =============================================================================
// nuiaspect.nss
// Integration test: NuiImage aspect modes (FIT / FILL / STRETCH).
// =============================================================================

#include "nw_inc_nui"

const string NUIASP_WIN = "IT_NUIASP_WIN";

json NuiAspCentered(json jWidget)
{
    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    jRow = JsonArrayInsert(jRow, jWidget);
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    return NuiRow(jRow);
}

json NuiAspCell(string sTitle, int nAspect)
{
    json jImg = NuiImage(
        JsonString("ir_follow"),
        JsonInt(nAspect),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE));
    jImg = NuiWidth(jImg, 96.0);
    jImg = NuiHeight(jImg, 60.0);

    json jFrame = NuiGroup(jImg, TRUE, NUI_SCROLLBARS_NONE);
    jFrame = NuiWidth(jFrame, 104.0);
    jFrame = NuiHeight(jFrame, 68.0);

    json jLabel = NuiLabel(JsonString(sTitle), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jLabel = NuiHeight(jLabel, 24.0);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jLabel);
    jCol = JsonArrayInsert(jCol, jFrame);
    return NuiCol(jCol);
}

void NuiAspOpen(object oPC)
{
    if (!GetIsPC(oPC)) return;

    int nOld = NuiFindWindow(oPC, NUIASP_WIN);
    if (nOld != 0) NuiDestroy(oPC, nOld);

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiAspCell("FIT", NUI_ASPECT_FIT));
    jRow = JsonArrayInsert(jRow, NuiWidth(NuiSpacer(), 12.0));
    jRow = JsonArrayInsert(jRow, NuiAspCell("FILL", NUI_ASPECT_FILL));
    jRow = JsonArrayInsert(jRow, NuiWidth(NuiSpacer(), 12.0));
    jRow = JsonArrayInsert(jRow, NuiAspCell("STRETCH", NUI_ASPECT_STRETCH));
    jRow = NuiRow(jRow);

    json jHint = NuiLabel(
        JsonString("Same icon, different aspect modes."),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE));
    jHint = NuiHeight(jHint, 24.0);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));
    jCol = JsonArrayInsert(jCol, NuiAspCentered(jHint));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 8.0));
    jCol = JsonArrayInsert(jCol, NuiAspCentered(jRow));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));

    json jWin = NuiWindow(
        NuiCol(jCol),
        JsonString("NuiAspect Test"),
        NuiRect(-1.0, -1.0, 460.0, 230.0),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE));

    int nToken = NuiCreate(oPC, jWin, NUIASP_WIN, "");

    if (nToken == 0) return;

    NuiSetUserData(oPC, nToken, jWin);
}
