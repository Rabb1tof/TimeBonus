stock bool IsValidClient(int iClient) { return (iClient > 0 && iClient < MaxClients && IsClientInGame(iClient) && !IsFakeClient(iClient)); }

stock void UTIL_CleanMemory() 
{
	UTIL_CleanArrayList(g_hConfig);
}

void UTIL_CleanArrayList(ArrayList &hArr) 
{
	if (!hArr) {
		hArr = new ArrayList(ByteCountToCells(4));
		return;
	}

	int iLength = hArr.Length;
	for (int i = iLength-1; i >= 0; i--) {
		StringMap smArray[3];
		smArray[0] = hArr.Get(i);
		smArray[0].GetValue("Requirements", smArray[1]);
		smArray[0].GetValue("Gifts", smArray[2]);
		CloseHandle(smArray[2]);
		CloseHandle(smArray[1]);
		CloseHandle(smArray[0]);
		hArr.Erase(i);
	}
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

// TODO: добавить эффекты открытия кейса
stock StringMap UTIL_getGift(int iClient, StringMap hMap)
{
	float chance;
	char value[20];
	StringMap hCurrent;
	for(int i = 0, size = hMap.Size; i < size; ++i)
	{
		hMap.GetValue("gifts", hCurrent);
		hCurrent.GetString("chance", value, sizeof(value));
		chance = float(StringToInt(value));
		if(GetRandomFloat(0.0, 1.0) <= chance)
			return hCurrent;
	}

	return null;
}

stock void UTIL_FormatTime(int iTime, char[] szBuffer, int iMaxLength) {
	int days = iTime / (60 * 60 * 24);
	int hours = (iTime - (days * (60 * 60 * 24))) / (60 * 60);
	int len;

	if (days) {
		len += Format(szBuffer[len], iMaxLength - len, "%d %s", days, "days");
	}

	len += Format(szBuffer[len], iMaxLength - len, "%s%d %t", szBuffer[0] ? " " : "", hours, "EBS_hours");
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
}*/