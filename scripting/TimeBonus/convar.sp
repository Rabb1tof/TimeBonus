int g_iTimeVIP;
char g_szTime[39];

ConVar g_hTimeVIP, g_hWorkingTime;

void createConvars()
{
    g_hTimeVIP      = CreateConVar("sm_tb_time_vip", "3600", "Время выдаваемой випки", _, true, 0.0);
    g_hWorkingTime  = CreateConVar("sm_tb_working_time", "00:00:00 - 23:00:00", "Когда выдавать бонус? Например: 00:00:00 - 08:30:00");

    g_iTimeVIP = g_hTimeVIP.IntValue;
    g_hWorkingTime.GetString(g_szTime, sizeof(g_szTime));
    
    g_hTimeVIP.AddChangeHook(OnTimeChanged);
    g_hWorkingTime.AddChangeHook(OnTimeWorkChanged);

    AutoExecConfig(true, "core", "timebonus");
}

public void OnTimeChanged(ConVar cv, const char[] oldValue, const char[] newValue) { g_iTimeVIP = cv.IntValue; }
public void OnTimeWorkChanged(ConVar cv, const char[] oldValue, const char[] newValue) { cv.GetString(g_szTime, sizeof(g_szTime)); }