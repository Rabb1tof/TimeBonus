#include <sourcemod>
#include <vip_core>
#include <shop>
#include <csgo_colors>

#pragma newdecls required
#pragma semicolon 1

#define VERS_PLUGIN "1.1.0"

#pragma newdecls required
#pragma semicolon 1

#define TIME_MENU 10 // time of menu (all) //
#define PREFIX "{blue}[{purple}Time Bonus{blue}]{default}"

public Plugin myinfo =
{
    author = "Rabb1t (Discord: Rabb1t#2017)",
    name = "TimeBonus",
    version = VERS_PLUGIN,
    description = "Бонусы за время игры на сервере",
    url = "https://discord.gg/gpK9k8f https://t.me/rabb1tof"
}

// global variable (from bool to Handle)
bool    g_bIsTimerRunning[MAXPLAYERS+1] = {false, ...},
        g_bDisplayHud[MAXPLAYERS+1] = {true, ...},
        g_isPluginEnable = false;
int g_iAccountID[MAXPLAYERS+1], g_iBonuses[MAXPLAYERS+1], g_iTime[MAXPLAYERS+1], g_iNonFixedTime[MAXPLAYERS+1], g_iNextTime[MAXPLAYERS+1], g_iPrevTime[MAXPLAYERS+1] = -1;
Database g_hDB;
ArrayList g_hConfig;
ArrayList g_hBlackListBonus[MAXPLAYERS+1]; /* User can disable some specific bonus if this need him */
Handle    g_hSync;

#include "TimeBonus/convar.sp"
#include "TimeBonus/config.sp"
#include "TimeBonus/UTIL.sp"
#include "TimeBonus/Database.sp"
#include "TimeBonus/menu.sp"

public APLRes AskPluginLoad2(Handle hMySelf, bool bLate, char[] szError, int iErrorMaxLength)
{
    //createAPI();
    return APLRes_Success;
}

public void OnPluginStart()
{
    RegConsoleCmd("sm_bonus", command_Bonus);

    HookEvent("player_team", OnPlayerChangeTeam);
    
    g_hSync = CreateHudSynchronizer();
    for(int i = 0; i < MaxClients; ++i)
        g_hBlackListBonus[i] = new ArrayList();
    createConfig();
    createConvars();
    Database.Connect(createDB, "timebonus");

    char szPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, szPath, sizeof(szPath), "configs/timebonus");
    if(!DirExists(szPath))
        CreateDirectory(szPath, FPERM_O_WRITE | FPERM_O_READ | FPERM_O_EXEC);
    CreateTimer(1.0, checkTime, _, TIMER_REPEAT);

    //UTIL_Debug();
}

public void OnAutoConfigsBuffered()
{
	PrecacheSound("ui/csgo_ui_crate_item_scroll.wav");
}

public void OnPluginEnd()
{
    UTIL_CleanMemory();
}


public Action command_Bonus(int iClient, int args)
{
    if(IsValidClient(iClient))
        showMainMenu(iClient);

    return Plugin_Handled;
}

public void OnPlayerChangeTeam(Event event, const char[] name, bool dbc)
{
    int iClient = GetClientOfUserId(event.GetInt("userid"));
    if(IsValidClient(iClient) && g_isPluginEnable)
    {
        int team    = event.GetInt("team");
        if(team == 1)
            CreateTimer(1.0, nonFixedTime, GetClientUserId(iClient), TIMER_REPEAT);
    }
}

public Action nonFixedTime(Handle timer, int iClient)
{
    if(timer != INVALID_HANDLE)
    {
        iClient = GetClientOfUserId(iClient);
        if(IsValidClient(iClient))
        {
            int team = GetClientTeam(iClient);
            if(team != 1) 
            {
                CloseHandle(timer);
                return Plugin_Stop;
            }
            ++g_iNonFixedTime[iClient];
            return Plugin_Continue;
        }
    }
    return Plugin_Stop;
}

public Action checkTime(Handle timer)
{
    if(!g_isPluginEnable) return Plugin_Handled;

    UTIL_checkTime();
    
    int playedTime, currentPosTime;
    char name[64], sTime[64];
    StringMap hCurrent;
    for(int iClient = 1; iClient <= MaxClients; ++iClient)
    {
        if(IsValidClient(iClient) && !g_bIsTimerRunning[iClient])
        {
            if(g_bDisplayHud[iClient])
                SetHudTextParams(-1.0, 0.9, 1.5, 255, 255, 255, 255, 0, 0.0, 0.0, 0.0);

            if(UTIL_isBannedIndex(iClient, g_iNextTime[iClient]))
            {
                ++g_iNextTime[iClient];
                return Plugin_Handled;
            }

            if(UTIL_checkValidIndex(g_iNextTime[iClient])) 
            {
                playedTime = UTIL_getPlayedTime(iClient);
                hCurrent = g_hConfig.Get(UTIL_Max(g_iNextTime[iClient], 0));
                if(hCurrent.GetValue("Time", currentPosTime) 
                    && playedTime/60 <= currentPosTime
                    && hCurrent.GetString("name", name, sizeof(name))
                    && playedTime/60 <= UTIL_getTimeByConfigIndex(g_iNextTime[iClient]))
                {
                    if(g_bDisplayHud[iClient])
                    {
                        /*if(UTIL_getTimeByConfigIndex(g_iPrevTime[iClient]) == UTIL_getTimeByConfigIndex(g_iNextTime[iClient]))
                        {
                            LogError("checkTime()::Failed get time by index (previus and next time pos was equal):: Previus: %d | Next: %d.", 
                                g_iPrevTime[iClient], g_iNextTime[iClient]);
                            return Plugin_Handled;
                        }*/

                        //g_iNextTime[iClient] = UTIL_getIndexByConfigTime(currentPosTime);
                        UTIL_FormatTime(currentPosTime*60 - playedTime, sTime, sizeof(sTime));
                        ShowSyncHudText(iClient, g_hSync, "До следующего бонуса: %s\nСледующий бонус: %s", sTime, name);
                    }
                }
                
                if(playedTime >= currentPosTime*60)
                {
                    //g_iPrevTime[iClient] = UTIL_getIndexByConfigTime(currentPosTime);
                    StartFindGift(iClient, hCurrent); 
                }
            } else {
                if(UTIL_checkNonCompleteTime(iClient))
                    return Plugin_Handled;

                if(g_bDisplayHud[iClient])
                    ShowSyncHudText(iClient, g_hSync, "Вы получили все бонусы на сегодня, поздравляем!");
            }
        }
    }
    return Plugin_Continue;
}

public void OnClientAuthorized(int iClient) {
    IsValidClient(iClient) &&
        preLoadData(iClient);
}

public void OnClientPutInServer(int iClient) {
    IsClientAuthorized(iClient) &&
        preLoadData(iClient);
}

public void OnClientDisconnect(int iClient)
{
    saveData(iClient);
}

/*void UTIL_Debug()
{
    // g_hConfig - ArrayList
    StringMap hReadVal;
    ArrayList hGifts;

    int iCount = g_hConfig.Length;
    char szName[64];
    int iTime;
    PrintToServer("%d || %d", iCount, g_hResult.Length);
    for (int iId; iId < iCount; ++iId)
    {
        hReadVal = g_hConfig.Get(iId);
        hReadVal.GetValue("Time", iTime);
        PrintToServer("TIME - %d", iTime);

        hReadVal.GetValue("gifts", hGifts);
        for(int i, iSize = hGifts.Length; i < iSize; ++i)
        {
            hReadVal = hGifts.Get(i);
            hReadVal.GetString("Name", szName, sizeof(szName));
            PrintToServer("GIFT -> %s", szName);
        }
    }
}*/


// Примерный алгоритм рандома:
// 1. Выдернуть рандомные гифты, проверяя шанс. Всего нужно достать, условно, 5 шт.
// 2. Запустить таймер крутилки, который будет повторяться каждый раз с увеличенным интервалом, пока не остановится.
// 3. В момент остановки, достать итоговый выбранный гифт и выдать награду.
stock void StartFindGift(int iClient, StringMap hMap)
{
    ArrayList hGifts = new ArrayList(4);
    ArrayList hFullGiftList;
    StringMap hGift;
    char name[64];
    hMap.GetString("name", name, sizeof(name));
    hMap.GetValue("gifts", hFullGiftList);
    while (hGifts.Length < 5)
    {
        hGift = FindGiftByChance(hFullGiftList, GetRandomFloat(0.0, 1.0));

        if (hGift)
        {
            hGifts.Push(hGift);
        }
    }

    RunGiftTimer(iClient, hGifts, GetRandomInt(15, 30), name);
}

stock StringMap FindGiftByChance(ArrayList hStorage, float flLuckyChance = -1.0)
{
    StringMap hGift;
    ArrayList hList = new ArrayList();

    int iGiftCount = hStorage.Length;
    char szGiftChance[16];
    for (int iId; iId < iGiftCount; ++iId)
    {
        hGift = hStorage.Get(iId);
        hGift.GetString("chance", szGiftChance, sizeof(szGiftChance));
        if (UTIL_CompareFloat(StringToFloat(szGiftChance), flLuckyChance, 0.01) == _FLOATCOMP_HIGHER)
        {
            hList.Push(hGift);
        }
    }
    hGift = null;

    if (hList.Length)
    {
        hGift = hList.Get(GetRandomInt(0, hList.Length-1));
    }

    hList.Close();
    return hGift;
}

void RunGiftTimer(int iClient, ArrayList hGifts, int iSuccessChances, char[] name)
{
    DataPack hPack;
    float flTime = 0.2;
    if (iSuccessChances < 0)
    {
        flTime *= float(-iSuccessChances);
    }

    CreateDataTimer(flTime, GiftTimer, hPack);
    hPack.WriteCell(GetClientUserId(iClient));
    hPack.WriteCell(hGifts);
    hPack.WriteCell(iSuccessChances);
    hPack.WriteString(name);
}

/**
* Таймер.
**/
public Action GiftTimer(Handle hTimer, DataPack hPack)
{
    hPack.Reset();
    int iClient = GetClientOfUserId(hPack.ReadCell());
    ArrayList hGifts = hPack.ReadCell();
    int iSuccessChances = hPack.ReadCell();
    char name[64];
    hPack.ReadString(name, sizeof(name));

    g_bIsTimerRunning[iClient] = true;

    // Check our client.
    if (!iClient)
    {
        hGifts.Close();
        return;
    }

    if (iSuccessChances == -10)
    {
        g_bIsTimerRunning[iClient] = false;
        ClientCommand(iClient, "playgamesound ui/csgo_ui_crate_item_scroll.wav");
        giveBonus(iClient, hGifts.Get(2));
        hGifts.Close();

        return;
    }

    UTIL_DrawGiftRoulette(iClient, hGifts, name);
    SortADTArrayCustom(hGifts, OnReorderGiftList);
    RunGiftTimer(iClient, hGifts, iSuccessChances - 1, name);
}

public int OnReorderGiftList(int iIndexFirst, int iIndexTwo, Handle hArray, Handle hHndl /*not used*/)
{
    if (iIndexFirst == 0 && iIndexTwo == GetArraySize(hArray))
    {
        return 1;
    }

    return (iIndexFirst < iIndexTwo) ? 1 : -1;
}