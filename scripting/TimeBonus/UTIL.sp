stock bool IsValidClient(int iClient) { return (iClient > 0 && iClient < MaxClients && IsClientInGame(iClient) && !IsFakeClient(iClient)); }

stock void UTIL_CleanMemory() 
{
	UTIL_CleanArrayList(g_hResult);
}

void UTIL_CleanArrayList(ArrayList &hArr) 
{
	if (!hArr) {
		hArr = new ArrayList(ByteCountToCells(4));
		return;
	}

	int iLength = hArr.Length;
	for (int i = iLength; --i != -1;) {
		(view_as<Handle>(hArr.Get(i))).Close();
	}
	hArr.Clear();
}

stock int UTIL_getPlayedTime(int iClient)
{
	return (g_iTime[iClient] + RoundToCeil(GetClientTime(iClient)) - g_iNonFixedTime[iClient]);
}

stock void UTIL_checkTime()
{
	char sExplodeString[2][16], sTime[16];
	ExplodeString(g_szTime, " - ", sExplodeString, sizeof(sExplodeString), sizeof(sExplodeString[]));
	FormatTime(sTime, sizeof(sTime), "%H:%M:%S");
	
	int iTime[3], iTimeStart[3], iTimeEnd[3];
	UTIL_GetTimeStringToInt(sTime, iTime);
	UTIL_GetTimeStringToInt(sExplodeString[0], iTimeStart);
	UTIL_GetTimeStringToInt(sExplodeString[1], iTimeEnd);
	
	if((iTime[0] >= iTimeStart[0] && iTime[0] <= iTimeEnd[0]) ||
		(iTime[0] == iTimeStart[0] && iTime[1] >= iTimeStart[1]) ||
		(iTime[0] == iTimeEnd[0] && iTime[1] <= iTimeEnd[1]))
	{
		g_isPluginEnable = true;
	}
	else
	{
		if(g_isPluginEnable){
			g_isPluginEnable = false;
			resetTime();
		}
	}
}

int UTIL_GetTimeStringToInt(char[] sTime, int iTime[3])
{
    char sExplodeString[3][4];
    ExplodeString(sTime, ":", sExplodeString, sizeof(sExplodeString), sizeof(sExplodeString[]));
    for(int i; i < 3; i++) iTime[i] = StringToInt(sExplodeString[i]);
    
    return iTime;
}

#define _FLOATCOMP_LOWER	-1
#define _FLOATCOMP_EQUAL	0
#define _FLOATCOMP_HIGHER	1
stock int UTIL_CompareFloat(float flFirst, float flTwo, float flFault = 0.1)
{
	if (flFirst > (flTwo - flFault))
	{
		if (flFirst < (flTwo + flFault))
		{
			return _FLOATCOMP_EQUAL;
		}

		return _FLOATCOMP_HIGHER;
	}

	return _FLOATCOMP_LOWER;
}

void UTIL_DrawGiftRoulette(int iClient, ArrayList hGifts, char[] name)
{
	char szGiftName[5][64];
	for (int iGiftId; iGiftId < 5; ++iGiftId)
	{
		(view_as<StringMap>(hGifts.Get(iGiftId))).GetString("Name", szGiftName[iGiftId], sizeof(szGiftName[]));
	}

	PrintHintText(
		iClient, "<font color='#35ce27'> %s</font>\n\n \
		%s | %s | [<font color='#FF0000'>%s</font>] | %s | %s", name,
		szGiftName[0], szGiftName[1], szGiftName[2], szGiftName[3], szGiftName[4]
	);

	ClientCommand(iClient, "playgamesound ui/csgo_ui_crate_item_scroll.wav");
}

stock int UTIL_getTimeByConfigIndex(const int index)
{
	int time = -1;
	if(index < g_hConfig.Length && index > -1)
		view_as<StringMap>(g_hConfig.Get(index)).GetValue("Time", time);
	
	return time;
}

stock int UTIL_getIndexByConfigTime(const int time)
{
	int configTime;

	for(int i = 0, length = g_hConfig.Length; i < length; ++i)
	{
		view_as<StringMap>(g_hConfig.Get(i)).GetValue("Time", configTime);
		if(time == configTime)
			return i;
	}

	return -2;
}

stock bool UTIL_checkValidIndex(const int index)
{
	return (g_hConfig.Length > index) ? true : false;
}

stock bool UTIL_checkNonCompleteTime(int iClient)
{
	for(int i = 0, length = g_hConfig.Length; i < length; ++i)
	{
		if(!UTIL_checkValidIndex(i) || UTIL_isBannedIndex(iClient, i)) continue;
		g_iNextTime[iClient] = i;
		return true;
	}

	return false;
}

stock bool UTIL_isBannedIndex(int iClient, int index)
{
	for(int i = 0, length = g_hBlackListBonus[iClient].Length; i < length; ++i)
	{
		if(index == g_hBlackListBonus[iClient].Get(i))
		{
			return true;
		}
	}

	return false;
}


stock void UTIL_clearBlackList(int iClient)
{
	if(iClient)
		return;
}

/* Func by Kruzya, thx =) */
void UTIL_FormatTime(int iTime, char[] szBuffer, int iMaxLength) {
int days = iTime / (60 * 60 * 24);
int hours = (iTime - (days * (60 * 60 * 24))) / (60 * 60);
int minutes = (iTime - (days * (60 * 60 * 24)) - (hours * (60 * 60))) / 60;
int seconds = iTime % 60;
int len;

if (hours) {
	len += Format(szBuffer[len], iMaxLength - len, "%d %s", hours, "час(ов)");
}

if (minutes) {
	len += Format(szBuffer[len], iMaxLength - len, "%s%d %s", (hours) ? " " : "", minutes, "минут(ы)");
}
if (seconds) {
	len += Format(szBuffer[len], iMaxLength - len, "%s%d %s", (hours || minutes) ? " " : "", seconds, "секунд(ы)");
}
}

/* Too thx Kruzya for this func =) */
stock int UTIL_Max(int a, int b) { return a > b ? a : b; }

stock bool UTIL_checkBlackListTime(int iClient, int time, char[] output, int maxLength)
{
	if(!g_hBlackListBonus[iClient])	return false;

	for(int i = 0, length = g_hBlackListBonus[iClient].Length; i < length; ++i)
	{
		
		if(g_hBlackListBonus[iClient].Get(i) == UTIL_getIndexByConfigTime(time))
		{
			FormatEx(output, maxLength, "%s [Выкл]", output);
			return true;
		}
		else
		{
			FormatEx(output, maxLength, "%s", output);
		}
	}

	return false;
}

/* Check complete current time position or not */
stock bool UTIL_checkExecutionTime(int index, int iClient)
{
	if(index <= g_iNextTime[iClient]-1)
		return true;
	return false;
}

// https://sm.alliedmods.net/new-api/sourcemod/FrameIterator
/*stock void UTIL_PrintStackTrace();()
{
	FrameIterator hIter = new FrameIterator();
	char szFunctionName[64];
	char szFilePath[PLATFORM_MAX_PATH];
	int iId = 0;

	do {
		szFunctionName[0] = 0;
		szFilePath[0] = 0;

		hIter.GetFunctionName(szFunctionName, sizeof(szFunctionName));
		hIter.GetFilePath(szFilePath, sizeof(szFilePath));

		LogMessage("[%d] Line %d, %s%s%s", iId++, hIter.LineNumber, szFilePath, (szFilePath[0] == 0 ? "::" : ""), szFunctionName);

		iId++;
	} while (hIter.Next());

	hIter.Close();
>>>>>>> ae716b5cc3a3c5c773115f116a011f4d5bb925d5
}*/