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
	int iTime = GetTime();
	if(iTime / (60 * 60 * 24) == 0)
		resetTime();
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

void UTIL_DrawGiftRoulette(int iClient, ArrayList hGifts)
{
	char szGiftName[5][64];
	for (int iGiftId; iGiftId < 5; ++iGiftId)
	{
		(view_as<StringMap>(hGifts.Get(iGiftId))).GetString("Name", szGiftName[iGiftId], sizeof(szGiftName[]));
	}

	PrintHintText(
		iClient, "%s | %s | [%s] | %s | %s",
		szGiftName[0], szGiftName[1], szGiftName[2], szGiftName[3], szGiftName[4]
	);
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
	if(g_hBlackListBonus[iClient] == INVALID_HANDLE)	return false;
	int lengthBlackList = g_hBlackListBonus[iClient].Length;
	int blackListTime;
	char blackList[20];
	for(int i = 0; i < lengthBlackList; ++i)
	{
		g_hBlackListBonus[iClient].GetString(i, blackList, sizeof(blackList));
		StringToInt(blackList, blackListTime);
		if(time == blackListTime)
		{
			FormatEx(output, maxLength, "%s", output, " [X]");
			return true;
		}
	}
	return false;
}

/* Check complete current time position or not */
stock bool UTIL_checkExecutionTime(int time)
{
	int length = g_hConfig.Length;
	int timeValue;
	for(int i = 0; i < length; ++i)
	{
		view_as<StringMap>(g_hConfig.Get(i)).GetValue("Time", timeValue);
		if(time == timeValue)
			return true;
	}

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