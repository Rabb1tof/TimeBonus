#include <sourcemod>
#include <vip_core>
#include <shop>
#include <csgo_colors>

#pragma newdecls required
#pragma semicolon 1

#define VERS_PLUGIN "0.2.1b"

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
stock int g_iAccountID[MAXPLAYERS+1], g_iBonuses[MAXPLAYERS+1], g_iTime[MAXPLAYERS+1], g_iNonFixedTime[MAXPLAYERS+1], g_iPrevTime[MAXPLAYERS+1];
Database g_hDB;
ArrayList g_hConfig;
Handle    g_hSync;

#include "TimeBonus/convar.sp"
//#include "TimeBonus/API.sp"
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
    createConfig();
    createConvars();
    Database.Connect(createDB, "timebonus");

    char szPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, szPath, sizeof(szPath), "configs/timebonus");
    if(!DirExists(szPath))
        CreateDirectory(szPath, FPERM_O_WRITE | FPERM_O_READ | FPERM_O_EXEC);

    CreateTimer(1.0, checkTime, _, TIMER_REPEAT);

    UTIL_Debug();
}

public void OnPluginEnd()
{
    UTIL_CleanMemory();
}

public void OnAllPluginsLoaded()
{
    //API_MarkAsReady(); // API ready to use
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
    if(IsValidClient(iClient))
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
        int team = GetClientTeam(iClient);
        if(team > 1) 
        {
            CloseHandle(timer);
            return Plugin_Stop;
        }
        ++g_iNonFixedTime[iClient];
    }
    return Plugin_Stop;
}

public Action checkTime(Handle timer)
{
    if(timer != INVALID_HANDLE)
    {
        int playedTime, currentPosTime;
        char name[64], sTime[64];
        StringMap hCurrent;
        SetHudTextParams(0.75, 0.9, 1.0, 255, 255, 255, 255, 0, 0.0, 0.0, 0.0);
        for(int iClient = 1; iClient <= MaxClients; ++iClient)
        {
            if(IsValidClient(iClient))
            {
                playedTime = UTIL_getPlayedTime(iClient);
                for(int i = 0, length = g_hConfig.Length; i < length; ++i)
                {
                    hCurrent = g_hConfig.Get(i);
                    if(hCurrent.GetValue("Time", currentPosTime) 
                        && playedTime/60 < currentPosTime
                        && hCurrent.GetString("name", name, sizeof(name)))
                    {
                        UTIL_FormatTime(currentPosTime*60 - playedTime, sTime, sizeof(sTime));
                        ShowSyncHudText(iClient, g_hSync, "До следующего бонуса: %s\nСледующий бонус: %s", sTime, name);
                    }
                }
                if(playedTime/60 >= currentPosTime) // рофл в том, что выполняется
                {
                    g_iPrevTime[iClient] = time;
                    StartFindGift(iClient, hCurrent); 
                }
            }
        }
    }
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

void UTIL_Debug()
{
    // g_hConfig - ArrayList
    StringMap hReadVal;
    ArrayList hGifts;

    int iCount = g_hConfig.Length;
    char szName[64];
    int iTime;
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
}


// Примерный алгоритм рандома:
// 1. Выдернуть рандомные гифты, проверяя шанс. Всего нужно достать, условно, 5 шт.
// 2. Запустить таймер крутилки, который будет повторяться каждый раз с увеличенным интервалом, пока не остановится.
// 3. В момент остановки, достать итоговый выбранный гифт и выдать награду.
stock void StartFindGift(int iClient, StringMap hMap)
{
    ArrayList hGifts = new ArrayList(4);
    ArrayList hFullGiftList;
    StringMap hGift;

    hMap.GetValue("gifts", hFullGiftList);
    while (hGifts.Length < 5)
    {
        hGift = FindGiftByChance(hFullGiftList, GetRandomFloat(0.0, 1.0));

        if (hGift)
        {
            hGifts.Push(hGift);
        }
    }

    RunGiftTimer(iClient, hGifts, GetRandomInt(15, 30));
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

void RunGiftTimer(int iClient, ArrayList hGifts, int iSuccessChances)
{
    DataPack hPack;
    float flTime = 0.2;
    if (iSuccessChances < 0)
    {
        flTime *= float(iSuccessChances);
    }

    CreateDataTimer(flTime, GiftTimer, hPack);
    hPack.WriteCell(GetClientUserId(iClient));
    hPack.WriteCell(hGifts);
    hPack.WriteCell(iSuccessChances);
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

    // Check our client.
    if (!iClient)
    {
        hGifts.Close();
        return;
    }

    if (iSuccessChances == -10)
    {
        giveBonus(iClient, hGifts.Get(2));
        hGifts.Close();

        return;
    }

    UTIL_DrawGiftRoulette(iClient, hGifts);
    SortADTArrayCustom(hGifts, OnReorderGiftList);
    RunGiftTimer(iClient, hGifts, iSuccessChances - 1);
}

public int OnReorderGiftList(int iIndexFirst, int iIndexTwo, Handle hArray, Handle hHndl /*not used*/)
{
    if (iIndexFirst == 0 && iIndexTwo == GetArraySize(hArray))
    {
        return 1;
    }

    return (iIndexFirst < iIndexTwo) ? 1 : -1;
}