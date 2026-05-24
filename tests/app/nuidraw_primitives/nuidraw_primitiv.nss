// =============================================================================
// nuidraw_primitiv.nss
// Integration test: one window + DrawList primitives showcase.
// =============================================================================

#include "nw_inc_nui"

const string NUIDRP_WIN = "IT_NUIDRP_WIN";

json NuiDrpCentered(json jWidget)
{
    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    jRow = JsonArrayInsert(jRow, jWidget);
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    return NuiRow(jRow);
}

json NuiDrpPolyPoints()
{
    json jPoints = JsonArray();
    jPoints = JsonArrayInsert(jPoints, JsonFloat(260.0));
    jPoints = JsonArrayInsert(jPoints, JsonFloat(185.0));
    jPoints = JsonArrayInsert(jPoints, JsonFloat(290.0));
    jPoints = JsonArrayInsert(jPoints, JsonFloat(145.0));
    jPoints = JsonArrayInsert(jPoints, JsonFloat(330.0));
    jPoints = JsonArrayInsert(jPoints, JsonFloat(165.0));
    jPoints = JsonArrayInsert(jPoints, JsonFloat(360.0));
    jPoints = JsonArrayInsert(jPoints, JsonFloat(130.0));
    return jPoints;
}

void NuiDrpOpen(object oPC)
{
    if (!GetIsPC(oPC)) return;

    int nOld = NuiFindWindow(oPC, NUIDRP_WIN);
    if (nOld != 0) NuiDestroy(oPC, nOld);

    json jDraw = JsonArray();

    jDraw = JsonArrayInsert(jDraw, NuiDrawListText(
        JsonBool(TRUE),
        NuiColor(120, 200, 255, 255),
        NuiRect(14.0, 10.0, 220.0, 24.0),
        JsonString("DrawList Primitives")));

    jDraw = JsonArrayInsert(jDraw, NuiDrawListLine(
        JsonBool(TRUE),
        NuiColor(235, 180, 80, 255),
        JsonFloat(2.0),
        NuiVec(20.0, 44.0),
        NuiVec(220.0, 44.0)));

    jDraw = JsonArrayInsert(jDraw, NuiDrawListRect(
        JsonBool(TRUE),
        NuiColor(240, 180, 90, 255),
        JsonBool(FALSE),
        JsonFloat(2.0),
        NuiRect(20.0, 64.0, 120.0, 62.0)));

    jDraw = JsonArrayInsert(jDraw, NuiDrawListRect(
        JsonBool(TRUE),
        NuiColor(80, 140, 230, 180),
        JsonBool(TRUE),
        JsonFloat(1.0),
        NuiRect(160.0, 64.0, 70.0, 62.0)));

    jDraw = JsonArrayInsert(jDraw, NuiDrawListCircle(
        JsonBool(TRUE),
        NuiColor(120, 220, 170, 255),
        JsonBool(FALSE),
        JsonFloat(2.0),
        NuiRect(250.0, 64.0, 60.0, 60.0)));

    jDraw = JsonArrayInsert(jDraw, NuiDrawListCircle(
        JsonBool(TRUE),
        NuiColor(220, 130, 180, 190),
        JsonBool(TRUE),
        JsonFloat(1.0),
        NuiRect(326.0, 64.0, 60.0, 60.0)));

    jDraw = JsonArrayInsert(jDraw, NuiDrawListArc(
        JsonBool(TRUE),
        NuiColor(255, 220, 120, 255),
        JsonBool(FALSE),
        JsonFloat(3.0),
        NuiVec(90.0, 190.0),
        JsonFloat(34.0),
        JsonFloat(0.0),
        JsonFloat(3.14)));

    jDraw = JsonArrayInsert(jDraw, NuiDrawListCurve(
        JsonBool(TRUE),
        NuiColor(150, 210, 255, 255),
        JsonFloat(2.5),
        NuiVec(140.0, 216.0),
        NuiVec(250.0, 216.0),
        NuiVec(175.0, 160.0),
        NuiVec(220.0, 252.0)));

    jDraw = JsonArrayInsert(jDraw, NuiDrawListPolyLine(
        JsonBool(TRUE),
        NuiColor(170, 255, 140, 255),
        JsonBool(FALSE),
        JsonFloat(2.5),
        NuiDrpPolyPoints()));

    jDraw = JsonArrayInsert(jDraw, NuiDrawListImage(
        JsonBool(TRUE),
        JsonString("ir_cast"),
        NuiRect(340.0, 180.0, 48.0, 48.0),
        JsonInt(NUI_ASPECT_FIT),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE)));

    json jCanvasBase = NuiGroup(NuiSpacer(), TRUE, NUI_SCROLLBARS_NONE);
    jCanvasBase = NuiWidth(jCanvasBase, 410.0);
    jCanvasBase = NuiHeight(jCanvasBase, 245.0);

    json jCanvas = NuiDrawList(jCanvasBase, JsonBool(TRUE), jDraw);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));
    jCol = JsonArrayInsert(jCol, NuiDrpCentered(jCanvas));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));

    json jWin = NuiWindow(
        NuiCol(jCol),
        JsonString("NuiDraw Primitives Test"),
        NuiRect(-1.0, -1.0, 520.0, 350.0),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE));

    int nToken = NuiCreate(oPC, jWin, NUIDRP_WIN, "");

    if (nToken == 0) return;

    NuiSetUserData(oPC, nToken, jWin);
}

