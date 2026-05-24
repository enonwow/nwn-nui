// =============================================================================
// itduel_sw.nss
// Duel UI fixture: one window + swap host (history/ranking) switched in-place.
// =============================================================================

#include "nw_inc_nui"

const string NUIDUEL_WIN            = "IT_NUIDUELUI_WIN";
const string NUIDUEL_EV             = "itduel_swev";
const string NUIDUEL_SWAP_GROUP     = "it_duel_swap_main";
const string NUIDUEL_BTN_CLOSE      = "it_duel_close";
const string NUIDUEL_BTN_CHALLENGE  = "it_duel_tab_challenge";
const string NUIDUEL_BTN_LOG        = "it_duel_tab_log";
const string NUIDUEL_BTN_RANK       = "it_duel_tab_rank";
const string NUIDUEL_BIND_HONOR     = "it_duel_honor_lbl";
const string NUIDUEL_BIND_RECORD    = "it_duel_record_lbl";
const string NUIDUEL_BIND_ENC_LOG   = "it_duel_enc_log";
const string NUIDUEL_BIND_ENC_RANK  = "it_duel_enc_rank";

const string NUIDUEL_HIST_A         = "duel_hist_col_a";
const string NUIDUEL_HIST_B         = "duel_hist_col_b";
const string NUIDUEL_HIST_C         = "duel_hist_col_c";
const string NUIDUEL_HIST_COLOR     = "duel_hist_color";
const string NUIDUEL_HIST_COUNT     = "duel_hist_row_count";

const string NUIDUEL_RANK_A         = "duel_rank_col_a";
const string NUIDUEL_RANK_B         = "duel_rank_col_b";
const string NUIDUEL_RANK_C         = "duel_rank_col_c";
const string NUIDUEL_RANK_COLOR     = "duel_rank_color";
const string NUIDUEL_RANK_COUNT     = "duel_rank_row_count";

json NuiDuelListTemplate(string sBindA, string sBindB, string sBindC, string sBindColor)
{
    json jTemplate = JsonArray();

    json jA = NuiLabel(NuiBind(sBindA), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jA = NuiStyleForegroundColor(jA, NuiBind(sBindColor));
    jA = NuiWidth(jA, 240.0);
    jTemplate = JsonArrayInsert(jTemplate, NuiListTemplateCell(jA, 240.0, TRUE));

    json jB = NuiLabel(NuiBind(sBindB), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jB = NuiStyleForegroundColor(jB, NuiBind(sBindColor));
    jB = NuiWidth(jB, 228.0);
    jTemplate = JsonArrayInsert(jTemplate, NuiListTemplateCell(jB, 228.0, TRUE));

    json jC = NuiLabel(NuiBind(sBindC), JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jC = NuiStyleForegroundColor(jC, NuiBind(sBindColor));
    jC = NuiWidth(jC, 102.0);
    jTemplate = JsonArrayInsert(jTemplate, NuiListTemplateCell(jC, 102.0, FALSE));

    json jPad = NuiWidth(NuiSpacer(), 12.0);
    jTemplate = JsonArrayInsert(jTemplate, NuiListTemplateCell(jPad, 12.0, FALSE));

    return jTemplate;
}

json NuiDuelViewHistory()
{
    json jList = NuiList(
        NuiDuelListTemplate(NUIDUEL_HIST_A, NUIDUEL_HIST_B, NUIDUEL_HIST_C, NUIDUEL_HIST_COLOR),
        NuiBind(NUIDUEL_HIST_COUNT),
        25.0,
        TRUE,
        NUI_SCROLLBARS_Y);
    jList = NuiWidth(jList, 626.0);
    jList = NuiHeight(jList, 370.0);
    return jList;
}

json NuiDuelViewRanking()
{
    json jList = NuiList(
        NuiDuelListTemplate(NUIDUEL_RANK_A, NUIDUEL_RANK_B, NUIDUEL_RANK_C, NUIDUEL_RANK_COLOR),
        NuiBind(NUIDUEL_RANK_COUNT),
        25.0,
        TRUE,
        NUI_SCROLLBARS_Y);
    jList = NuiWidth(jList, 626.0);
    jList = NuiHeight(jList, 370.0);
    return jList;
}

void NuiDuelSetHistoryRows(object oPC, int nToken)
{
    json jA = JsonArray();
    jA = JsonArrayInsert(jA, JsonString("Defeat by Enon Duel"));
    jA = JsonArrayInsert(jA, JsonString("Defeat by Enon Duel"));
    jA = JsonArrayInsert(jA, JsonString("Declined with Enon Duel"));
    jA = JsonArrayInsert(jA, JsonString("Declined with Grannith Undt"));
    jA = JsonArrayInsert(jA, JsonString("Defeat by Grannith Undt"));
    jA = JsonArrayInsert(jA, JsonString("Declined with Grannith Undt"));
    jA = JsonArrayInsert(jA, JsonString("Defeat by Grannith Undt"));
    jA = JsonArrayInsert(jA, JsonString("Victory over Grannith Undt"));
    jA = JsonArrayInsert(jA, JsonString("Victory over Grannith Undt"));
    jA = JsonArrayInsert(jA, JsonString("Victory over Grannith Undt"));
    jA = JsonArrayInsert(jA, JsonString("Victory over Grannith Undt"));
    jA = JsonArrayInsert(jA, JsonString("Victory over Grannith Undt"));
    jA = JsonArrayInsert(jA, JsonString("Victory over Grannith Undt"));
    jA = JsonArrayInsert(jA, JsonString("Defeat by Grannith Undt"));

    json jB = JsonArray();
    jB = JsonArrayInsert(jB, JsonString("By killing blow"));
    jB = JsonArrayInsert(jB, JsonString("By fleeing"));
    jB = JsonArrayInsert(jB, JsonString("By decline"));
    jB = JsonArrayInsert(jB, JsonString("By decline"));
    jB = JsonArrayInsert(jB, JsonString("By killing blow"));
    jB = JsonArrayInsert(jB, JsonString("By decline"));
    jB = JsonArrayInsert(jB, JsonString("By fleeing"));
    jB = JsonArrayInsert(jB, JsonString("By killing blow"));
    jB = JsonArrayInsert(jB, JsonString("By fleeing"));
    jB = JsonArrayInsert(jB, JsonString("By fleeing"));
    jB = JsonArrayInsert(jB, JsonString("By fleeing"));
    jB = JsonArrayInsert(jB, JsonString("By fleeing"));
    jB = JsonArrayInsert(jB, JsonString("By fleeing"));
    jB = JsonArrayInsert(jB, JsonString("By fleeing"));

    json jC = JsonArray();
    jC = JsonArrayInsert(jC, JsonString("30.04 13:16"));
    jC = JsonArrayInsert(jC, JsonString("30.04 13:16"));
    jC = JsonArrayInsert(jC, JsonString("30.04 13:14"));
    jC = JsonArrayInsert(jC, JsonString("30.04 13:08"));
    jC = JsonArrayInsert(jC, JsonString("30.04 13:08"));
    jC = JsonArrayInsert(jC, JsonString("30.04 13:06"));
    jC = JsonArrayInsert(jC, JsonString("30.04 13:06"));
    jC = JsonArrayInsert(jC, JsonString("30.04 12:57"));
    jC = JsonArrayInsert(jC, JsonString("30.04 12:56"));
    jC = JsonArrayInsert(jC, JsonString("30.04 12:48"));
    jC = JsonArrayInsert(jC, JsonString("30.04 12:46"));
    jC = JsonArrayInsert(jC, JsonString("30.04 12:45"));
    jC = JsonArrayInsert(jC, JsonString("30.04 12:44"));
    jC = JsonArrayInsert(jC, JsonString("30.04 12:31"));

    json jColor = JsonArray();
    jColor = JsonArrayInsert(jColor, NuiColor(228, 86, 86));
    jColor = JsonArrayInsert(jColor, NuiColor(228, 86, 86));
    jColor = JsonArrayInsert(jColor, NuiColor(190, 190, 190));
    jColor = JsonArrayInsert(jColor, NuiColor(190, 190, 190));
    jColor = JsonArrayInsert(jColor, NuiColor(228, 86, 86));
    jColor = JsonArrayInsert(jColor, NuiColor(190, 190, 190));
    jColor = JsonArrayInsert(jColor, NuiColor(228, 86, 86));
    jColor = JsonArrayInsert(jColor, NuiColor(94, 214, 124));
    jColor = JsonArrayInsert(jColor, NuiColor(94, 214, 124));
    jColor = JsonArrayInsert(jColor, NuiColor(94, 214, 124));
    jColor = JsonArrayInsert(jColor, NuiColor(94, 214, 124));
    jColor = JsonArrayInsert(jColor, NuiColor(94, 214, 124));
    jColor = JsonArrayInsert(jColor, NuiColor(94, 214, 124));
    jColor = JsonArrayInsert(jColor, NuiColor(228, 86, 86));

    NuiSetBind(oPC, nToken, NUIDUEL_HIST_A, jA);
    NuiSetBind(oPC, nToken, NUIDUEL_HIST_B, jB);
    NuiSetBind(oPC, nToken, NUIDUEL_HIST_C, jC);
    NuiSetBind(oPC, nToken, NUIDUEL_HIST_COLOR, jColor);
    NuiSetBind(oPC, nToken, NUIDUEL_HIST_COUNT, JsonInt(14));
}

void NuiDuelSetRankingRows(object oPC, int nToken)
{
    json jA = JsonArray();
    jA = JsonArrayInsert(jA, JsonString("1. Enon Duel"));
    jA = JsonArrayInsert(jA, JsonString("2. Gar Mamm"));
    jA = JsonArrayInsert(jA, JsonString("3. Avri Email"));
    jA = JsonArrayInsert(jA, JsonString("4. Avri Email"));
    jA = JsonArrayInsert(jA, JsonString("5. Grannith Undt"));

    json jB = JsonArray();
    jB = JsonArrayInsert(jB, JsonString("W: 2 (1K/1F) | L: 0 (0K/0F)"));
    jB = JsonArrayInsert(jB, JsonString("W: 1 (1K/0F) | L: 0 (0K/0F)"));
    jB = JsonArrayInsert(jB, JsonString("W: 0 (0K/0F) | L: 1 (1K/0F)"));
    jB = JsonArrayInsert(jB, JsonString("W: 12 (2K/10F) | L: 12 (4K/8F)"));
    jB = JsonArrayInsert(jB, JsonString("W: 10 (3K/7F) | L: 12 (2K/10F)"));

    json jC = JsonArray();
    jC = JsonArrayInsert(jC, JsonString("Honor 20"));
    jC = JsonArrayInsert(jC, JsonString("Honor 10"));
    jC = JsonArrayInsert(jC, JsonString("Honor -3"));
    jC = JsonArrayInsert(jC, JsonString("Honor -92"));
    jC = JsonArrayInsert(jC, JsonString("Honor -156"));

    json jColor = JsonArray();
    jColor = JsonArrayInsert(jColor, NuiColor(250, 206, 54));
    jColor = JsonArrayInsert(jColor, NuiColor(186, 186, 186));
    jColor = JsonArrayInsert(jColor, NuiColor(186, 186, 186));
    jColor = JsonArrayInsert(jColor, NuiColor(186, 186, 186));
    jColor = JsonArrayInsert(jColor, NuiColor(186, 186, 186));

    NuiSetBind(oPC, nToken, NUIDUEL_RANK_A, jA);
    NuiSetBind(oPC, nToken, NUIDUEL_RANK_B, jB);
    NuiSetBind(oPC, nToken, NUIDUEL_RANK_C, jC);
    NuiSetBind(oPC, nToken, NUIDUEL_RANK_COLOR, jColor);
    NuiSetBind(oPC, nToken, NUIDUEL_RANK_COUNT, JsonInt(5));
}

void NuiDuelShowHistory(object oPC, int nToken)
{
    NuiSetGroupLayout(oPC, nToken, NUIDUEL_SWAP_GROUP, NuiDuelViewHistory());
    NuiSetBind(oPC, nToken, NUIDUEL_BIND_ENC_LOG, JsonBool(TRUE));
    NuiSetBind(oPC, nToken, NUIDUEL_BIND_ENC_RANK, JsonBool(FALSE));
    NuiSetBind(oPC, nToken, NUIDUEL_BIND_HONOR, JsonString("Honor: -92"));
    NuiSetBind(oPC, nToken, NUIDUEL_BIND_RECORD, JsonString("W: 12 / L: 12"));
}

void NuiDuelShowRanking(object oPC, int nToken)
{
    NuiSetGroupLayout(oPC, nToken, NUIDUEL_SWAP_GROUP, NuiDuelViewRanking());
    NuiSetBind(oPC, nToken, NUIDUEL_BIND_ENC_LOG, JsonBool(FALSE));
    NuiSetBind(oPC, nToken, NUIDUEL_BIND_ENC_RANK, JsonBool(TRUE));
    NuiSetBind(oPC, nToken, NUIDUEL_BIND_HONOR, JsonString("Honor: 20"));
    NuiSetBind(oPC, nToken, NUIDUEL_BIND_RECORD, JsonString("W: 2 / L: 0"));
}

void NuiDuelSwapOpen(object oPC)
{
    if (!GetIsPC(oPC)) return;

    int nOld = NuiFindWindow(oPC, NUIDUEL_WIN);
    if (nOld != 0) NuiDestroy(oPC, nOld);

    json jClose = NuiId(NuiButton(JsonString("X")), NUIDUEL_BTN_CLOSE);
    jClose = NuiWidth(jClose, 18.0);
    jClose = NuiHeight(jClose, 28.0);

    json jTop = JsonArray();
    jTop = JsonArrayInsert(jTop, NuiWidth(NuiSpacer(), 794.0));
    jTop = JsonArrayInsert(jTop, jClose);

    json jHonor = NuiLabel(NuiBind(NUIDUEL_BIND_HONOR), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jHonor = NuiWidth(jHonor, 148.0);
    json jRecord = NuiLabel(NuiBind(NUIDUEL_BIND_RECORD), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jRecord = NuiWidth(jRecord, 170.0);

    json jStat = JsonArray();
    jStat = JsonArrayInsert(jStat, NuiWidth(NuiSpacer(), 330.0));
    jStat = JsonArrayInsert(jStat, jHonor);
    jStat = JsonArrayInsert(jStat, NuiWidth(NuiSpacer(), 54.0));
    jStat = JsonArrayInsert(jStat, jRecord);
    jStat = JsonArrayInsert(jStat, NuiSpacer());

    json jSword = NuiId(NuiButtonImage(JsonString("duel_ico_sword")), NUIDUEL_BTN_CHALLENGE);
    jSword = NuiWidth(jSword, 38.0);
    jSword = NuiHeight(jSword, 38.0);

    json jBook = NuiId(NuiButtonImage(JsonString("duel_ico_book")), NUIDUEL_BTN_LOG);
    jBook = NuiEncouraged(jBook, NuiBind(NUIDUEL_BIND_ENC_LOG));
    jBook = NuiWidth(jBook, 38.0);
    jBook = NuiHeight(jBook, 38.0);

    json jCup = NuiId(NuiButtonImage(JsonString("duel_ico_cup")), NUIDUEL_BTN_RANK);
    jCup = NuiEncouraged(jCup, NuiBind(NUIDUEL_BIND_ENC_RANK));
    jCup = NuiWidth(jCup, 38.0);
    jCup = NuiHeight(jCup, 38.0);

    json jIcons = JsonArray();
    jIcons = JsonArrayInsert(jIcons, NuiWidth(NuiSpacer(), 324.0));
    jIcons = JsonArrayInsert(jIcons, jSword);
    jIcons = JsonArrayInsert(jIcons, NuiWidth(NuiSpacer(), 70.0));
    jIcons = JsonArrayInsert(jIcons, jBook);
    jIcons = JsonArrayInsert(jIcons, NuiWidth(NuiSpacer(), 70.0));
    jIcons = JsonArrayInsert(jIcons, jCup);
    jIcons = JsonArrayInsert(jIcons, NuiSpacer());

    json jSwap = NuiId(NuiGroup(NuiDuelViewHistory(), FALSE, NUI_SCROLLBARS_NONE), NUIDUEL_SWAP_GROUP);
    jSwap = NuiWidth(jSwap, 626.0);
    jSwap = NuiHeight(jSwap, 370.0);

    json jListRow = JsonArray();
    jListRow = JsonArrayInsert(jListRow, NuiWidth(NuiSpacer(), 132.0));
    jListRow = JsonArrayInsert(jListRow, jSwap);
    jListRow = JsonArrayInsert(jListRow, NuiSpacer());

    json jBgItems = JsonArrayInsert(
        JsonArray(),
        NuiDrawListImage(
            JsonBool(TRUE),
            JsonString("it_duel_bg"),
            NuiRect(20.0, 0.0, 860.0, 560.0),
            JsonInt(NUI_ASPECT_STRETCH),
            JsonInt(NUI_HALIGN_LEFT),
            JsonInt(NUI_VALIGN_TOP),
            NUI_DRAW_LIST_ITEM_ORDER_BEFORE,
            NUI_DRAW_LIST_ITEM_RENDER_ALWAYS));

    json jContentCol = JsonArray();
    jContentCol = JsonArrayInsert(jContentCol, NuiHeight(NuiSpacer(), 14.0));
    jContentCol = JsonArrayInsert(jContentCol, NuiRow(jStat));
    jContentCol = JsonArrayInsert(jContentCol, NuiHeight(NuiSpacer(), 9.0));
    jContentCol = JsonArrayInsert(jContentCol, NuiRow(jIcons));
    jContentCol = JsonArrayInsert(jContentCol, NuiHeight(NuiSpacer(), 14.0));
    jContentCol = JsonArrayInsert(jContentCol, NuiRow(jListRow));
    jContentCol = JsonArrayInsert(jContentCol, NuiSpacer());

    json jContent = NuiDrawList(NuiCol(jContentCol), JsonBool(FALSE), jBgItems);

    json jRoot = JsonArray();
    jRoot = JsonArrayInsert(jRoot, NuiCol(JsonArrayInsert(JsonArrayInsert(JsonArray(), NuiHeight(NuiSpacer(), 34.0)), NuiRow(jTop))));
    jRoot = JsonArrayInsert(jRoot, jContent);

    json jWindow = NuiWindow(
        NuiCol(jRoot),
        JsonBool(FALSE),
        NuiRect(-1.0, -1.0, 900.0, 600.0),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JSON_NULL,
        JSON_NULL,
        JsonString(""));

    int nToken = NuiCreate(oPC, jWindow, NUIDUEL_WIN, NUIDUEL_EV);
    if (nToken == 0) return;

    NuiSetUserData(oPC, nToken, jWindow);
    NuiDuelSetHistoryRows(oPC, nToken);
    NuiDuelSetRankingRows(oPC, nToken);
    NuiDuelShowHistory(oPC, nToken);
}
