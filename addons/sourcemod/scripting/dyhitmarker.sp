#include <sdktools>
#include <clientprefs>

public Plugin myinfo = 
{
	name = "DyHitMarker",                         // DyHitmarker（动态命中反馈）
	author = "wixess+tongren21+Ducheese, modified by [CNSR] FJH_03",        // code: wixess*+Ducheese; vtf animation: tongren21*
	description = "Dynamic HitMarker on shoot", 
	version = "1.6",                              // HM 1.4 → DHM 1.6
	url = "vk.com/wix_ess"                        // Hitmarker 1.4's url
};

Handle cookie;
bool bEnabled[MAXPLAYERS + 1];
ConVar g_CmdCvar;

public OnPluginStart()
{	
	AddFileToDownloadsTable("sound/hitmark/hit.mp3");             // 音效1 - 击中
	AddFileToDownloadsTable("sound/hitmark/headshot.mp3");        // 音效2 - 爆头
	AddFileToDownloadsTable("sound/hitmark/kill.mp3");            // 音效3 - 击杀

	AddFileToDownloadsTable("materials/hitmark/body2.vmt");       // 动图1 - 击中
	AddFileToDownloadsTable("materials/hitmark/body.vtf");
	AddFileToDownloadsTable("materials/hitmark/head2.vmt");       // 动图2 - 爆头
	AddFileToDownloadsTable("materials/hitmark/head.vtf");
	AddFileToDownloadsTable("materials/hitmark/kill2.vmt");       // 动图3 - 击杀
	AddFileToDownloadsTable("materials/hitmark/kill.vtf");
	
	HookEvent("player_hurt", PlayerHurt);
	HookEvent("player_death", PlayerDeath);
	
	RegConsoleCmd("dhm", Command_dhm);
	
	UnlockConsoleCommandAndConvar("r_screenoverlay");
}

public OnClientConnected(int client)
{
    if (client > 0 && client <= MaxClients && !IsFakeClient(client))
    {
        bEnabled[client] = true;
    }
}

public Action Command_dhm(int client, int args)
{
	if (bEnabled[client]) {
		bEnabled[client] = false;
		PrintToChat(client, "\x01\x03[\x04动态命中反馈\x03]\x01 关闭！")
	} else {
		bEnabled[client] = true;
		PrintToChat(client, "\x01\x03[\x04动态命中反馈\x03]\x01 源神启动！");
	}
}

public Action PlayerHurt(Event event, const char[] name, bool silent)
{
	int client = GetClientOfUserId(event.GetInt("attacker"));
	
	if (client > 0 && bEnabled[client])
	{
		new hitgroup = GetEventInt(event, "hitgroup");
		
		if (hitgroup == 1)                                     //  红色虚线，击中头部（用低伤害武器击中头盔可能触发）
		{
			ClientCommand(client, "r_screenoverlay hitmark/head2.vmt");
			ClientCommand(client, "play *hitmark/headshot.mp3");
		}
		else                                                   //  白色实线，击中身体
		{
			ClientCommand(client, "r_screenoverlay hitmark/body2.vmt");
			ClientCommand(client, "play *hitmark/hit.mp3");
		}
		
		CreateTimer(0.3, HitmarkerTimer, client);
	}
}

public Action PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("attacker"));
	
	if (client > 0 && bEnabled[client])
	{	
		bool headshot = GetEventBool(event, "headshot");
		
		if (headshot)                                         //  红色虚线，爆头击杀
		{
			ClientCommand(client, "r_screenoverlay hitmark/head2.vmt");
			ClientCommand(client, "play *hitmark/headshot.mp3");
		}
		else                                                  //  红色实线，非爆头击杀 
		{
			ClientCommand(client, "r_screenoverlay hitmark/kill2.vmt");      
			ClientCommand(client, "play *hitmark/kill.mp3");
		}
		
		CreateTimer(0.3, HitmarkerTimer, client);
	}
}

public void OnMapStart()
{
	PrecacheSound("hitmark/hit.mp3", true);
	PrecacheSound("hitmark/headshot.mp3", true);
	PrecacheSound("hitmark/kill.mp3", true);
	PrecacheDecal("hitmark/body2.vmt", true);
	PrecacheDecal("hitmark/head2.vmt", true);
	PrecacheDecal("hitmark/kill2.vmt", true);
}

public Action HitmarkerTimer(Handle Timer, int client)
{
	if (IsClientConnected(client)) {
		ClientCommand(client, "r_screenoverlay off");
	}
	
	return Plugin_Stop;
}

UnlockConsoleCommandAndConvar(const String:command[])
{
    new flags = GetCommandFlags(command);
    if (flags != INVALID_FCVAR_FLAGS)
    {
        SetCommandFlags(command, flags & ~FCVAR_CHEAT);
    }
    
    new Handle:cvar = FindConVar(command);
    if (cvar != INVALID_HANDLE)
    {
        flags = GetConVarFlags(cvar);
        SetConVarFlags(cvar, flags & ~FCVAR_CHEAT);
    }
} 