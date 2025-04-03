#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cstrike>
#include <zombiereloaded>

#define VERSION "1.52"

int g_iRoundsPlayed[MAXPLAYERS + 1]; //已经玩的回合数
int showHud[MAXPLAYERS + 1] = 1;
float g_iTotalDamage[MAXPLAYERS + 1];//总伤害
int g_iHeadShotCount[MAXPLAYERS + 1] = 0;//爆头击杀数
int g_killCount[MAXPLAYERS + 1] = 0;// 总击杀数

public Plugin:myinfo =
{
    name = "[ZR] CustomMenu",
    author = "[CNSR] Oreo922 & [CNSR] FJH_03",
    description = "use in zombie reloaded mode!",
    version = VERSION,
    url = ""
};

public OnPluginStart() {
	RegConsoleCmd("sm_mymenu", Command_menu, "open CNSR custom menu");
	RegConsoleCmd("say", Command_Say);
    RegConsoleCmd("say_team", Command_Say);
	RegConsoleCmd("hud", Command_hud);
	CreateTimer(1, Timer_RepeatExc, _, TIMER_REPEAT);
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("round_start", Event_RoundStart);
}

public Action Command_hud(int client, int args)
{
    if (showHud[client]) { showHud[client] = 0; }
    else { showHud[client] = 1 ;}
}

public OnClientConnected(int client)
{
    // 重置玩家数据
    if (client > 0 && client <= MaxClients)
    {
        g_iTotalDamage[client] = 0;
        g_iHeadShotCount[client] = 0;
		g_killCount[client] = 0;
        showHud[client] = 1;
		g_iRoundsPlayed[client] = 1;
    }
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientConnected(i) && IsClientInGame(i))
        {
            g_iRoundsPlayed[i]++;
        }
    }
}

public void Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
    int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	
    bool isHeadshot = GetEventBool(event, "headshot");
	
	if (attacker == victim || GetClientTeam(victim) == GetClientTeam(attacker)) { // 排除自杀，被外界杀死，杀死队友的情况
		g_killCount[attacker]--;
	} else if (!GetEventInt(event, "attacker")) {
		g_killCount[victim]--;
	} else {
		if (isHeadshot)
		{
			// 累计攻击者的爆头击杀数
			g_iHeadShotCount[attacker]++;
		}
		
		g_killCount[attacker]++;
	}
}

public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
	new victim = GetClientOfUserId(event.GetInt("userid"));
	
    float damage = event.GetFloat("dmg_health");
	
    if (attacker > 0 && attacker <= MaxClients)
    {
		if (damage >= 1000) { // 排除一些模组改的太高离谱伤害值
			damage = 500;
		}
		
		if (GetClientTeam(victim) == GetClientTeam(attacker)) { // 友伤
			damage -= 2 * damage;
		}
		
        g_iTotalDamage[attacker] += damage;
    }
}

float GetClientKDRate(int client)
{        
    // Get Deaths, Kills and KD Rate
    int Deaths = GetClientDeaths(client);
    int Frags = g_killCount[client];
    float KDRate = float(Frags) / float(Deaths);
    
    if((Deaths == 0) && (Frags != 0))   // 死亡0，击杀n，KD取n
        KDRate = float(Frags);

    if(Frags < 0)                       // 得分有可能小于0，但KD最小取0.0
        KDRate = float(0);

    return KDRate;
}

float GetClientAvgDamage(int client)
{    
    if (g_iRoundsPlayed[client] > 0)
        return g_iTotalDamage[client] / g_iRoundsPlayed[client];
    else
        return 0.0;
}

int GetAliveHumanCount()
{
    int count = 0;
    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsClientConnected(i) && IsClientInGame(i))
        {
            if(IsPlayerAlive(i) && ZR_IsClientHuman(i))
            {
                count++;
            }
        }
    }
    return count;
}

int GetAliveZombieCount()
{
    int count = 0;
    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsClientConnected(i) && IsClientInGame(i))
        {
            if(IsPlayerAlive(i) && ZR_IsClientZombie(i))
            {
                count++;
            }
        }
    }
    return count;
}

public Action Timer_RepeatExc(Handle timer)
{    
    for(int client = 1; client <= MaxClients; client++)
    {
        if(IsClientConnected(client) && IsClientInGame(client))
        {    
            if(!IsFakeClient(client))
            {
				float AvgDamage = GetClientAvgDamage(client); // 获取回合均伤
				
                SetHudTextParams(0.15, 0.85, 1.001, 0, 255, 0, 255);
        		ShowHudText(client, -1, "欢迎来到『CNSR™-生存感染服』");
				char Line[256];
				if (showHud[client]) {
					Format(Line, sizeof(Line), "击杀K %d    死亡D %d    K/D %.1f    爆头率HS %.1f    回合均伤ADR %.1f\n人类 %d VS %d 丧尸", g_killCount[client], GetClientDeaths(client), GetClientKDRate(client), (float(g_iHeadShotCount[client]) / float(g_killCount[client])) * 100, AvgDamage, GetAliveHumanCount(), GetAliveZombieCount());
					SetHudTextParams(-1.0, 0.1, 1.001, 0, 255, 0, 255);
	                ShowHudText(client, -1, Line);
				}
            }
        }
    }    
    return Plugin_Continue;
}

public Action:Command_menu(client, argc) {
	
	MainMenu(client);
        
    return Plugin_Continue;
}

public Action:Command_Say(client, argc)
{
    decl String:args[192];
    
    GetCmdArgString(args, sizeof(args));
    ReplaceString(args, sizeof(args), "\"", "");
    
    if (StrEqual(args, "!mymenu", false))
    {        
        MainMenu(client);
        return Plugin_Handled;
    }
    
    return Plugin_Continue;
}

MainMenu(client) {
	new Handle:menu_main = CreateMenu(MainMenuHandle);
    
    SetGlobalTransTarget(client);
    
    SetMenuTitle(menu_main, "FJH_03的ZR自定义菜单");
    

    AddMenuItem(menu_main, "", "打开Zombie-Reloaded菜单");
	AddMenuItem(menu_main, "", "打开Zombie-Plague菜单");
	AddMenuItem(menu_main, "", "打开zprops物品菜单");
	AddMenuItem(menu_main, "", "购买一个激光绊雷");
	AddMenuItem(menu_main, "", "放置一个激光绊雷");
	AddMenuItem(menu_main, "", "打开或关闭动态命中反馈");
	AddMenuItem(menu_main, "", "打开或关闭HUD统计");
    
    DisplayMenu(menu_main, client, MENU_TIME_FOREVER);
}

public MainMenuHandle(Handle:menu_main, MenuAction:action, client, slot) {

	if (action == MenuAction_Select) {
		switch (slot) {
			case 0:				
				ClientCommand(client, "zmenu");
			case 1:				
				ClientCommand(client, "sm_zp");
			case 2:				
				ClientCommand(client, "sm_zprops");
			case 3:
				ClientCommand(client, "sm_bm 1");
			case 4:
				ClientCommand(client, "sm_lm");
			case 5:
				ClientCommand(client, "dhm");
			case 6:
				ClientCommand(client, "hud");
		}
	}
	
	if (action == MenuAction_End)
    {
        CloseHandle(menu_main);
    }
}