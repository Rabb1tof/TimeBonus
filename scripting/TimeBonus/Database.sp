char g_sCreateMainTable[] = "CREATE TABLE IF NOT EXISTS `tb_players` (\
`account_id` int(10) unsigned NOT NULL COMMENT 'Steam Account ID',\
`username` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'unnamed',\
`bonuses` smallint(6) unsigned NOT NULL DEFAULT '0' COMMENT 'Amount received bonus',\
`time` int(10) unsigned NOT NULL DEFAULT '0' COMMENT 'Count of played time (zeroed once a day)',\
`prev_time` int(10) unsigned NOT NULL DEFAULT '0' COMMENT 'Next time value for get bonus (zeroed once a day)',\
PRIMARY KEY (`account_id`)\
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Перечень всех игроков';",

g_szSQL_SelectData[] = "SELECT `bonuses`, `time`, `prev_time` FROM `tb_players` WHERE `account_id` = '%d'",
g_szSQL_UploadData[] = "INSERT INTO `tb_players` (`account_id`, `username`, `bonuses`, `time`, `prev_time`) VALUES ('%d', '%s', '0', '0', '0');",
g_szSQL_UpdateData[] = "UPDATE `tb_players` SET `username` = '%s' WHERE `account_id` = '%d';",
g_szSQL_SaveData[] = "UPDATE `tb_players` SET `bonuses` = '%d', `time` = '%d', `prev_time` = '%d' WHERE `account_id` = '%d';";

public void createDB(Database hDB, const char[] szError, any data)
{
    if(hDB != INVALID_HANDLE || !szError[0])
        g_hDB = hDB;
    else
        SetFailState("[TimeBonus] Can't connect to DB: %s", szError);

    Handle hDriver = view_as<Handle>(g_hDB.Driver);
    if(hDriver != SQL_GetDriver("mysql"))
        SetFailState("[TimeBonus] Use MySQL driver.");

    g_hDB.SetCharset("utf8mb4");

    g_hDB.Query(SQL_checkError, g_sCreateMainTable, 1, DBPrio_High); // 0

    for(int iClient = 1; iClient <= MaxClients; ++iClient)
        preLoadData(iClient);
}

public void SQL_checkError(Database hDB, DBResultSet hResult, const char[] error, any data)
{
    char table[23];
    switch(data)
    {
        case 1: strcopy(table, sizeof(table), "createDB()");
        case 2: strcopy(table, sizeof(table), "resetTime()");
        case 3: strcopy(table, sizeof(table), "saveData()");
    }
    if(!hResult || error[0])
    {
        LogError("Failed on %s (%s)", table, error);
        return;
    }
}

void preLoadData(int iClient)
{
    if(g_hDB && IsValidClient(iClient))
    {
        UTIL_checkTime();

        char szQuery[512];
        g_iAccountID[iClient] = GetSteamAccountID(iClient);
        g_hDB.Format(szQuery, sizeof(szQuery), g_szSQL_SelectData, g_iAccountID[iClient]);
        g_hDB.Query(SQL_PreLoadDataCheck, szQuery, GetClientUserId(iClient));
    }
}

public void SQL_PreLoadDataCheck(Database hDB, DBResultSet hResult, const char[] error, int iClient)
{
    if(!hResult || error[0])
    {
        LogError("Failed Preload check data: %s", error);
        return;
    }
    iClient = GetClientOfUserId(iClient);
    if(IsValidClient(iClient))
    {
        char szQuery[256], szName[64], szEscapedName[129];
        GetClientName(iClient, szName, sizeof(szName));
        SQL_EscapeString(g_hDB, szName, szEscapedName, sizeof(szEscapedName));
        if(hResult.RowCount == 0)
        {
            g_iBonuses[iClient] = g_iTime[iClient] = g_iPrevTime[iClient] = 0;
            g_hDB.Format(szQuery, sizeof(szQuery), g_szSQL_UploadData, g_iAccountID[iClient], szEscapedName);
            g_hDB.Query(SQL_uploadData, szQuery, GetClientUserId(iClient));
        } else {
            if(hResult.FetchRow())      SetFailState("[TimeBonus] Failed FetchRow() at SQL_PreLoadDataCheck()");

            g_iBonuses[iClient]     = hResult.FetchInt(1);
            g_iTime[iClient]        = hResult.FetchInt(2);
            g_iPrevTime[iClient]    = hResult.FetchInt(3);

            g_hDB.Format(szQuery, sizeof(szQuery), g_szSQL_UpdateData, szEscapedName, g_iAccountID[iClient]);
            g_hDB.Query(SQL_updateData, szQuery, GetClientUserId(iClient));
        }
    }
}

/* TODO: дописать логику 2-х ниже функций. */
public void SQL_uploadData(Database hDB, DBResultSet hResult, const char[] error, int iClient)
{
    if(hResult == INVALID_HANDLE || error[0])
    {
        LogError("Failed upload data: %s", error);
        return;
    }
    iClient = GetClientOfUserId(iClient);

}

public void SQL_updateData(Database hDB, DBResultSet hResult, const char[] error, int iClient)
{
    if(hResult == INVALID_HANDLE || error[0])
    {
        LogError("Failed update data: %s", error);
        return;
    }
    iClient = GetClientOfUserId(iClient);

}

void saveData(int iClient)
{
    if(IsValidClient(iClient) && g_hDB)
    {
        char szQuery[512];
        g_hDB.Format(szQuery, sizeof(szQuery), g_szSQL_SaveData, g_iBonuses[iClient], g_iTime[iClient], g_iPrevTime[iClient], g_iAccountID[iClient]);
        g_hDB.Query(SQL_checkError, szQuery, 3);
    }
}

void resetTime()
{
    g_hDB.Query(SQL_checkError, "UPDATE `tb_players` SET `time` = '0', `prev_time` = '0' WHERE `time` <> '0';", 2, DBPrio_High);
}

void giveBonus(int iClient, StringMap hCurrent, int time)
{
    if(IsValidClient(iClient))
    {
        int credits, itemID;
        char value[20];

        hCurrent.GetString("credits", value, sizeof(value));
        credits = StringToInt(value);

        hCurrent.GetString("item", value, sizeof(value));
        itemID = StringToInt(value);

        value[0] = '\0';
        hCurrent.GetString("group", value, sizeof(value));

        if(credits > 0)
            Shop_GiveClientCredits(iClient, credits);

        if(itemID > 0)
            Shop_GiveClientItem(iClient, view_as<ItemId>(itemID));

        if(StrEqual(value, ""))
        {
            if(!VIP_IsClientVIP(iClient))
                VIP_GiveClientVIP(_, iClient, g_iTimeVIP, value);
            else
            {
                /**
                * TODO: дописать логику (если у игрока есть вип)
                **/
                
            }
        }

        g_iPrevTime[iClient] = time;
        g_iBonuses[iClient]++;
        char query[128];
        g_hDB.Format(query, sizeof(query), "UPDATE `tb_players` SET `time` = '%d', `prev_time` = '%d' WHERE `account_id` = '%d';");
        g_hDB.Query(SQL_giveBonus, query);
    }
}

public void SQL_giveBonus(Database hDB, DBResultSet hResult, const char[] error, any data)
{
    if(hResult == INVALID_HANDLE || error[0])
    {
        LogError("Failed update data: %s", error);
        return;
    }

    
}