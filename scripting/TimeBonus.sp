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
    
    createConfig();
    createConvars();
    //Database.Connect(createDB, "timebonus");

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
        //int playedTime;
        StringMap hCurrent;
        for(int iClient = 1; iClient <= MaxClients; ++iClient)
        {
            if(IsValidClient(iClient))
            //playedTime = UTIL_getPlayedTime(iClient); // получаем время, которое отыграл (!) игрок
            
            /**
            * TODO:
            * Дописать тут код с проверкой времени игрока (юзать вместо лесенки из циклов - подфункции)
            **/
                findTime(iClient, UTIL_getPlayedTime(iClient), hCurrent);
        }
    }
}

// дальше есть баг, за время, за одно и тоже время игрок будет получать бонусы
void findTime(int iClient, int playedTime, StringMap hCurrent)
{
    int size = hCurrent.Size;
    int time;
    for(int i = 0; i < size; ++i)
    {
        hCurrent = g_hConfig.Get(i);
        if(!hCurrent.GetValue("Time", time) 
            || g_iPrevTime[iClient] < playedTime)    continue;
        if(playedTime < time)   return;

        /*if(hCurrent.GetValue("gifts", hCurrent)) 
        {
            SetFailState("[TimeBonus] Can't get value by key in findTime()");
            return;
        }*/

        hCurrent = UTIL_getGift(iClient, hCurrent);

        if(hCurrent != null)
        {
            g_iPrevTime[iClient] = time;
            giveBonus(iClient, hCurrent);
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
// 1. Выдернуть рандомные гифты, проверяя шанс. Всего нужно достать, условно, 4 шт.
// 2. Запустить таймер крутилки, который будет повторяться каждый раз с увеличенным интервалом, пока не остановится.
// 3. В момент остановки, достать итоговый выбранный гифт и выдать награду.
stock void StartFindGift(int iClient, StringMap hMap)
{
    
}

stock StringMap FindGiftByChance(StringMap hStorage, float flChance)
{
    StringMap hGift;
    ArrayList hList = new ArrayList();

    StringMapSnapshot hShot = hGift.Shot();
    int iShotCount = hShot.Length;
    char szGiftName[64];
    for (int iId; iId < iShotCount; ++iId)
    {
        hShot.GetKey(iId, szGiftName, sizeof(szGiftName));
        hGift.
    }
    hGift = null;

    if (hList.Length)
    {
        hGift = hList.Get(GetRandomInt(0, hList.Length-1));
    }

    hList.Close();
    return hGift;
}