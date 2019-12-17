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
		StringMap smArray;
		ArrayList hList;
		smArray = hArr.Get(i);
		smArray.GetValue("gifts", hList);
		for(int j = 0, length = hList.Length; j < length; ++j)
		CloseHandle(hList.Get(j));
		CloseHandle(hList);
		CloseHandle(smArray);
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