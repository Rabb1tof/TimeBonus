/**
* Global variable.
*/
ArrayList	g_hResult;
StringMap	g_hCurrentMap;
int			g_iConfigState;

#define		CS_UNDEFINED	0
#define		CS_ROOT			1
#define		CS_TIME			2
#define		CS_GIFTS		3

void createConfig()
{
	UTIL_CleanMemory();

	char szPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, szPath, sizeof(szPath), "configs/timebonus/core.cfg");
	if(!FileExists(szPath))
		OpenFile(szPath, "w+");

	ParseConfig(szPath);
}

void ParseConfig(const char[] szConfig)
{
	g_iConfigState = CS_UNDEFINED;
	g_hConfig = new ArrayList(4);
	g_hResult = new ArrayList(4);

	SMCParser hSMC = new SMCParser();
	hSMC.OnEnterSection	= ConfigParser_OnEnterSection;
	hSMC.OnLeaveSection	= ConfigParser_OnLeaveSection;
	hSMC.OnKeyValue		= ConfigParser_OnKeyValue;

	int iLine, iCol;
	SMCError eResult = hSMC.ParseFile(szConfig, iLine, iCol);
	hSMC.Close();
	
	if (eResult != SMCError_Okay)
	{
		char szBuffer[256];
		SMC_GetErrorString(eResult, szBuffer, sizeof(szBuffer));

		LogError("Config parsing failure: %s (line %d, column %d)", szBuffer, iLine, iCol);
	}
}

/**
* Callbacks.
*/
public SMCResult ConfigParser_OnEnterSection(SMCParser hSMC, const char[] szName, bool bOptQuotes)
{
	switch (g_iConfigState)
	{
		case CS_UNDEFINED:				g_iConfigState = CS_ROOT;
		case CS_ROOT:					
		{
			ArrayList hGifts = new ArrayList(4);
			g_hCurrentMap = new StringMap();
			g_hCurrentMap.SetValue("Time", StringToInt(szName));
			g_hCurrentMap.SetValue("gifts", hGifts);
			g_hConfig.Push(g_hCurrentMap);
			g_hResult.Push(g_hCurrentMap);
			g_hResult.Push(hGifts);

			g_iConfigState = CS_TIME;
		}

		case CS_TIME:
		{
			StringMap hParent = g_hCurrentMap;
			ArrayList hGifts;

			g_hCurrentMap = new StringMap();
			g_hCurrentMap.SetString("Name", szName); // тут отображаемого имя (приза)
			g_hCurrentMap.SetValue("__parent", hParent);
			hParent.GetValue("gifts", hGifts);
			hGifts.Push(g_hCurrentMap);

			g_iConfigState = CS_GIFTS;
			g_hResult.Push(g_hCurrentMap);
			return SMCParse_Continue;
		}

		case CS_GIFTS:	return SMCParse_HaltFail; // undefined behavior.
	}
	return SMCParse_Continue;
}

public SMCResult ConfigParser_OnLeaveSection(SMCParser hSMC)
{
	switch (g_iConfigState)
	{
		case CS_GIFTS:	{
			g_hCurrentMap.GetValue("__parent", g_hCurrentMap);
			g_iConfigState = CS_TIME;
		}

		case CS_TIME:					{
			g_hCurrentMap = null;
			g_iConfigState = CS_ROOT;
		}

		case CS_ROOT:					g_iConfigState = CS_UNDEFINED;
		case CS_UNDEFINED:				return SMCParse_HaltFail;
	}

	return SMCParse_Continue;
}

public SMCResult ConfigParser_OnKeyValue(SMCParser smc, const char[] szKey, const char[] szValue, bool bKeyQuotes, bool bValueQuotes)
{
	if (g_iConfigState != CS_GIFTS)
	{
		if(strcmp(szKey, "name") == 0) // получение отображаемого имени (для конткретного времени)
		{
			g_hCurrentMap.SetString(szKey, szValue);
			return SMCParse_Continue;
		}
		return SMCParse_HaltFail;
	}

	g_hCurrentMap.SetString(szKey, szValue);
	return SMCParse_Continue;
}