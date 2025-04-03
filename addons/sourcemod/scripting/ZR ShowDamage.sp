#include <sourcemod>
#include <DynamicChannels>
#include <zombiereloaded>
#include <cstrike>

int damage[66];

public Plugin myinfo = 
{
	name = "[ZR] ShowDamage",
	author = "[FTKM] wudi, modified by [CNSR] FJH_03",
	description = "伤害显示插件",
	version = "1.1",
	url = ""
};

public void OnPluginStart()
{
	HookEvent("round_start",hk);
	HookEvent("player_hurt",sj);
}

public Action hk(Event e, const char[] name, bool buer)
{
	for(int i = 1; i < MaxClients; i++)
	{
		damage[i] = 0;
	}
}

public void OnClientDisconnect(int client)
{
	damage[client] = 0;	
}

public Action sj(Event e, const char[] name, bool buer)
{
	//获取userid
	int suserid = e.GetInt("userid");
	int guserid = e.GetInt("attacker");
	//获取client
	int sclient = GetClientOfUserId(suserid);
	int gclient = GetClientOfUserId(guserid);
	
	//s的血量
	int xue = e.GetInt("health");
	int dxue = e.GetInt("dmg_health");
	int buwei = e.GetInt("hitgroup");	
	if(IsValidClient(sclient) && IsValidClient(gclient) && IsClientInGame(gclient) && !IsFakeClient(gclient) && (gclient != sclient) && ZR_IsClientHuman(gclient))
	{
		if (GetClientTeam(sclient) == GetClientTeam(gclient)) {
			dxue -= 2 * dxue;
		}
		
		damage[gclient] += dxue;
		
		if (buwei == 1) {
			SetHudTextParams(-1.00, -0.280, 5.00, 238, 119, 0, 255, 0, 0, 0, 0);
			ShowHudText(gclient, GetDynamicChannel(1),"|%N|\nHP:%d|DPS:%d",sclient,xue, damage[gclient]);
			hd(gclient,dxue);
		} else {
			SetHudTextParams(-1.00, -0.280, 5.00, 0, 206, 209, 255, 0, 0, 0, 0);
			ShowHudText(gclient, GetDynamicChannel(1),"|%N|\nHP:%d|DPS:%d",sclient,xue, damage[gclient]);
			bd(gclient,dxue);
		}
	}
}

void hd(int client,int xue)
{
	SetHudTextParams(-1.0, 0.45, 0.7, 255, 0, 0, 255, 0, 0.0, 0.0, 0.0);
	ShowHudText(client, GetDynamicChannel(2), "- %i", xue);
}

void bd(int client,int xue)
{
	SetHudTextParams(-1.0, 0.45, 0.7, 255, 255, 255, 255, 0, 0.0, 0.0, 0.0);
	ShowHudText(client, GetDynamicChannel(2), "- %i", xue);
}

stock bool IsValidClient(int client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	if (!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}