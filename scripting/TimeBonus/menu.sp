void showMainMenu(int iClient)
{
    Menu menu = new Menu(MainHandler);

    menu.SetTitle("Главное меню бонусов:\n");
    menu.AddItem(NULL_STRING, "Отключить/включить HUD"); // 0
    menu.AddItem(NULL_STRING, "Отключить/включить бонус(ы)");

    menu.Display(iClient, TIME_MENU);
}

public int MainHandler(Menu menu, MenuAction action, int iClient, int item)
{
    switch(action)
    {
        case MenuAction_End: if(menu != INVALID_HANDLE) menu.Close();
        case MenuAction_Select:
        {
            switch(item)
            {
                case 0: {
                    g_bDisplayHud[iClient] = !g_bDisplayHud[iClient];
                    CGOPrintToChat(iClient, "%s Вы успешно %s {blue}HUD{default}.", PREFIX, (g_bDisplayHud[iClient]) ? "{green}включили" : "{red}выключили");

                    showMainMenu(iClient);
                }
                case 1: showDisableBonus(iClient);
            }
        }
    }
}

void showDisableBonus(int iClient)
{
    Menu menu = new Menu(disableBonusHandler);

    menu.SetTitle("Выберите бонус, который хотите отключить:\n");
    StringMap hMap;
    int time;
    char value[20], buffer[64];
    for(int i = 0, length = g_hConfig.Length; i < length; ++i)
    {
        hMap = g_hConfig.Get(i);
        hMap.GetValue("Time", time);
        IntToString(time, value, sizeof(value));
        Format(buffer, sizeof(buffer), "%d минут", time);
        UTIL_checkBlackListTime(iClient, time, buffer, sizeof(buffer));
        menu.AddItem(value, buffer, UTIL_checkExecutionTime(UTIL_getIndexByConfigTime(time), iClient) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
        /* TODO: добавить проверку не заблокирован ли уже бонус и отображение [x] - заблочен, [ ] - не заблочен. Не кликабельный текст - уже получен. */
    }

    menu.Display(iClient, TIME_MENU);
}

/* TODO: доработать логику */
public int disableBonusHandler(Menu menu, MenuAction action, int iClient, int item)
{
    switch(action)
    {
        case MenuAction_End: if(menu != INVALID_HANDLE) menu.Close();
        case MenuAction_Select: 
        {
            char info[20];
            menu.GetItem(item, info, sizeof(info));
            int index = UTIL_getIndexByConfigTime(StringToInt(info));
            if(UTIL_isBannedIndex(iClient, index))
            {
                int value = g_hBlackListBonus[iClient].FindValue(index);
                if(value != -1)
                {
                    g_hBlackListBonus[iClient].Erase(value);
                    if(g_iNextTime[iClient] > index)
                        g_iNextTime[iClient] = index;
                }
            } else {
                g_hBlackListBonus[iClient].Push(index);
            }

            showDisableBonus(iClient);
        }
    }
}