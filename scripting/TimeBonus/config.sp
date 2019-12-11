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

	g_hConfig = ParseConfig(szPath);
}

ArrayList ParseConfig(const char[] szConfig)
{
	g_iConfigState = CS_UNDEFINED;
	g_hResult = new ArrayList(ByteCountToCells(4));

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
		return null;
	}

	return g_hResult;
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
			g_hCurrentMap = new StringMap();
			g_hCurrentMap.SetString("Time", szName);
			g_hResult.Push(g_hCurrentMap);

			g_iConfigState = CS_TIME;
		}

        case CS_TIME:
        {
            StringMap hParent = g_hCurrentMap;

            g_hCurrentMap = new StringMap();
            g_hCurrentMap.SetString("Name", szName); // тут отображаемео имя (приза)
            g_hCurrentMap.SetValue("__parent", hParent);
            if (!hParent.SetValue("gifts", g_hCurrentMap))
            {
                g_hCurrentMap.Close(); // die.
                return SMCParse_HaltFail;
            }

            g_iConfigState = CS_GIFTS;
            return SMCParse_Continue;
        }

		case CS_GIFTS:	
		{

			return SMCParse_HaltFail; // undefined behavior.
		}
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