int g_iTimeVIP;

ConVar g_hTimeVIP;

void createConvars()
{
    g_hTimeVIP = CreateConVar("sm_tb_time_vip", "3600", "Время выдаваемой випки", _, true, 0.0);

    g_iTimeVIP = g_hTimeVIP.IntValue;
    
    g_hTimeVIP.AddChangeHook(OnTimeChanged);
}

public void OnTimeChanged(ConVar cv, const char[] oldValue, const char[] newValue) { g_iTimeVIP = cv.IntValue; }