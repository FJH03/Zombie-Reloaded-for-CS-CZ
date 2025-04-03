#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <zombiereloaded>
#include <franug_zp>

public Plugin:myinfo =
{
	name = "[ZP] zombie_smoke",
	author = "[CNSR] FJH_03",
	description = "僵尸放毒雾",
	version = "3.0",
	url = "<-url->"
};

Handle	g_cSmokeTime,g_cSmokeColor,g_cSmokeAlpha,g_cTimerDamage,g_cSmokeRadius,g_cSmokeDamage,g_cSmokeStartSize,g_cSmokeEndSize,
g_cBaseSpread, g_cSpreadSpeed,g_cSpeed, g_cRate, g_cJetLength, g_cTwist, g_cPublicMsg;
bool 	g_bPublicMsg,StopSmoke[MAXPLAYERS + 1], g_haveSmoke[MAXPLAYERS + 1];
int     g_iSmokeTime,g_iTimerDamage,g_iSmokeRadius,g_iSmokeDamage;
float   g_pos[MAXPLAYERS + 1][3];
char    g_sSmokeColor[12],g_sSmokeAlpha[4],g_sSmokeStartSize[7],g_sSmokeEndSize[7], g_sBaseSpread[7], 
g_sSpreadSpeed[7],g_sSpeed[7], g_sRate[7], g_sJetLength[7], g_sTwist[7];

// configuration part
#define AWARDNAME "zombie_smoke" // Name of award
#define PRICE 18 // Award price
#define AWARDTEAM ZP_ZOMBIES // Set team that can buy this award (use ZP_BOTH ZP_HUMANS ZP_ZOMBIES)
#define TRANSLATIONS "plague_zombie_smoke.phrases" // Set translations file for this subplugin
// end configuration

public void OnPluginStart()
{
	CreateTimer(0.1, Lateload);
	
	g_cSmokeTime			= CreateConVar("zp_Smoke_time", 	"5", 		"毒气持续时间（以秒为单位）", FCVAR_NOTIFY);
	g_cSmokeColor         = CreateConVar("zp_Smoke_color", "0 255 0", "毒气颜色.\n三个值取值均在0-255之间，并且三个值之间均通过空格分开 (若不懂，请百度rgb就知道了).", FCVAR_NOTIFY);
	g_cSmokeAlpha         = CreateConVar("zp_Smoke_alpha", "255", "毒气透明度（0-255之间，值越低，越透明）", FCVAR_NOTIFY);
	g_cSmokeStartSize         = CreateConVar("zp_Smoke_Startsize", "600", "首次发射毒气粒子时的大小", FCVAR_NOTIFY);
	g_cSmokeEndSize         = CreateConVar("zp_Smoke_Endsize", "600", "完全淡出时毒气粒子的大小", FCVAR_NOTIFY);
	
	g_cBaseSpread         = CreateConVar("zp_Smoke_BaseSpread", "80", "产生毒气粒子时随机散布的数量", FCVAR_NOTIFY);
	g_cSpreadSpeed         = CreateConVar("zp_Smoke_SpreadSpeed", "80", "毒气粒子速度的随机分布量。", FCVAR_NOTIFY);
	g_cSpeed         = CreateConVar("zp_Smoke_Speed", "80", "毒气粒子在生成后移动的速度", FCVAR_NOTIFY);
	g_cRate         = CreateConVar("zp_Smoke_Rate", "80", "发射毒气粒子的速率（即每秒发射的粒子数）", FCVAR_NOTIFY);
	g_cJetLength         = CreateConVar("zp_Smoke_JetLength", "30", "毒气的长度", FCVAR_NOTIFY);
	g_cTwist         = CreateConVar("zp_Smoke_Twist", "50", "毒气粒子绕原点扭曲的量,即涡流", FCVAR_NOTIFY);
	
	g_cTimerDamage         = CreateConVar("zp_Smoke_TimerDamage", "0.5", "毒气每多少秒制造一次伤害", FCVAR_NOTIFY);
	g_cSmokeRadius        = CreateConVar("zp_Smoke_Radius", "600", "玩家距离毒气中心多少范围才会受到伤害", FCVAR_NOTIFY);
	g_cSmokeDamage        = CreateConVar("zp_Smoke_Damage", "10", "毒气每制造一次伤害的大小", FCVAR_NOTIFY);
	
	g_cPublicMsg			= CreateConVar("zp_Smoke_message", 	"1", 		"当有人释放毒气时打印一条公共消息？| 1 = 启用 | 0 = 禁用（默认 1）");

	HookConVarChange(g_cSmokeTime, eConvarChanged);
	HookConVarChange(g_cSmokeColor, eConvarChanged);
	HookConVarChange(g_cSmokeAlpha, eConvarChanged);
	HookConVarChange(g_cSmokeStartSize, eConvarChanged);
	HookConVarChange(g_cSmokeEndSize, eConvarChanged);
	
	HookConVarChange(g_cBaseSpread, eConvarChanged);
	HookConVarChange(g_cSpreadSpeed, eConvarChanged);
	HookConVarChange(g_cSpeed, eConvarChanged);
	HookConVarChange(g_cRate, eConvarChanged);
	HookConVarChange(g_cJetLength, eConvarChanged);
	HookConVarChange(g_cTwist, eConvarChanged);
	
	HookConVarChange(g_cTimerDamage, eConvarChanged);
	HookConVarChange(g_cSmokeRadius, eConvarChanged);
	HookConVarChange(g_cSmokeDamage, eConvarChanged);
	
	HookConVarChange(g_cPublicMsg, eConvarChanged);
	AutoExecConfig(true, "zombiereloaded/zp_zombie_smoke");
	CvarsChanged();
}

public OnConfigsExecuted()
{
	CvarsChanged();
}

public void eConvarChanged(Handle hCvar, const char[] sOldVal, const char[] sNewVal)
{
	CvarsChanged();
}

void CvarsChanged()
{
	g_bPublicMsg = GetConVarBool(g_cPublicMsg);
	g_iSmokeTime = GetConVarInt(g_cSmokeTime);
	g_iTimerDamage = GetConVarInt(g_cTimerDamage);
	g_iSmokeRadius = GetConVarInt(g_cSmokeRadius);
	g_iSmokeDamage = GetConVarInt(g_cSmokeDamage);
	GetConVarString(g_cSmokeColor,g_sSmokeColor, sizeof(g_sSmokeColor));
	TrimString(g_sSmokeColor);
	GetConVarString(g_cSmokeAlpha,g_sSmokeAlpha, sizeof(g_sSmokeAlpha));
	GetConVarString(g_cSmokeStartSize,g_sSmokeStartSize, sizeof(g_sSmokeStartSize));
	GetConVarString(g_cSmokeEndSize,g_sSmokeEndSize, sizeof(g_sSmokeEndSize));
	
	GetConVarString(g_cBaseSpread,g_sBaseSpread, sizeof(g_sBaseSpread));
	GetConVarString(g_cSpreadSpeed,g_sSpreadSpeed, sizeof(g_sSpreadSpeed));
	GetConVarString(g_cSpeed,g_sSpeed, sizeof(g_sSpeed));
	GetConVarString(g_cRate,g_sRate, sizeof(g_sRate));
	GetConVarString(g_cJetLength,g_sJetLength, sizeof(g_sJetLength));
	GetConVarString(g_cTwist,g_sTwist, sizeof(g_sTwist));
}

public Action:Lateload(Handle:timer)
{
	LoadTranslations(TRANSLATIONS); // translations to the local plugin
	ZP_LoadTranslations(TRANSLATIONS); // sent translations to the main plugin
	
	ZP_AddAward(AWARDNAME, PRICE, AWARDTEAM); // add award to the main plugin
}

public ZP_OnAwardBought( client, const String:awardbought[])
{
	if(StrEqual(awardbought, AWARDNAME))
	{
		// use your custom code here
		PrintToChat(client, "\x01\x03[\x04SM_Franug-ZombiePlague\x03]\x01 %t", "you bought zombie_smoke");
		g_haveSmoke[client] = true;
	}
}

public void OnMapStart()
{
	PrecacheModel("particle/particle_smokegrenade1.vmt");
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (IsClient(client, true)) {
		if(GetEntProp(client, Prop_Data, "m_afButtonPressed") & IN_ATTACK2) {
			if (g_haveSmoke[client] && !IsFakeClient(client)) {
				Command_Smoke(client, 0); 
			}
		}
	}

	return Plugin_Continue;
}

public Action Command_Smoke(int client, int args)
{
	if(!IsClientInGame(client))
	{
		return Plugin_Handled;
	}

	if(!IsPlayerAlive(client))
	{
		PrintToChat(client, "\x01\x03[\x04SM_Franug-ZombiePlague\x03]\x01 %t", "you must be alive");
		return Plugin_Handled;
	}
	
	if(IsClient(client, true) && !ZR_IsClientZombie(client))
	{
		PrintToChat(client, "\x01\x03[\x04SM_Franug-ZombiePlague\x03]\x01 %t", "only zombie can use this");
		return Plugin_Handled;
	}

	g_haveSmoke[client] = false;
	CreateColorSmoke(client, g_iSmokeTime*1.0);

	if(g_bPublicMsg) {
		PrintToChatAll("\x01\x03[\x04SM_Franug-ZombiePlague\x03]\x01 %t", "the smoke has been released");
	}

	return Plugin_Handled;
}

//毒物
stock CreateColorSmoke(client, Float:SmokeTimer)
{
	new SmokeEnt = CreateEntityByName("env_smokestack");
	if(SmokeEnt)
	{
		//坐标
		new Float:pos[3];
		new String:originData[64];
		GetClientAbsOrigin(client, pos);
		Format(originData, sizeof(originData), "%f %f %f", pos[0], pos[1], (pos[2]+15.0));
		DispatchKeyValue(SmokeEnt,"Origin", originData);
		//基本蔓延
		DispatchKeyValue(SmokeEnt,"BaseSpread", g_sBaseSpread);
		//蔓延速度
		DispatchKeyValue(SmokeEnt,"SpreadSpeed", g_sSpreadSpeed);
		//速度
		DispatchKeyValue(SmokeEnt,"Speed", g_sSpeed);
		//初始大小
		DispatchKeyValue(SmokeEnt,"StartSize", g_sSmokeStartSize);
		//完结大小
		DispatchKeyValue(SmokeEnt,"EndSize", g_sSmokeEndSize);
		//厚度
		DispatchKeyValue(SmokeEnt,"Rate", g_sRate);
		//射流长度
		DispatchKeyValue(SmokeEnt,"JetLength", g_sJetLength);
		//漩涡
		DispatchKeyValue(SmokeEnt,"Twist", g_sTwist); 
		//颜色
		DispatchKeyValue(SmokeEnt,"RenderColor", g_sSmokeColor); 
		//透明度
		DispatchKeyValue(SmokeEnt,"RenderAmt", g_sSmokeAlpha);
		//材料
		DispatchKeyValue(SmokeEnt,"SmokeMaterial", "particle/particle_smokegrenade1.vmt");
			
		DispatchSpawn(SmokeEnt);
		AcceptEntityInput(SmokeEnt, "TurnOn");
		
		new Handle:pack;
		CreateDataTimer(SmokeTimer, Timer_KillSmoke, pack);
		WritePackCell(pack, SmokeEnt);
		WritePackCell(pack, client);
		
		new Float:longerdelay = 0.2 + SmokeTimer;
		new Handle:pack2;
		CreateDataTimer(longerdelay, Timer_StopSmoke, pack2);
		WritePackCell(pack2, SmokeEnt);
		StopSmoke[client] = false;
		
		GetClientAbsOrigin(client, g_pos[client]);
		CreateTimer(g_iTimerDamage * 1.0, Timer_Damage, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Timer_Damage(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (!client || !IsClientInGame(client) || !ZR_IsClientZombie(client) || StopSmoke[client]) 
	{
		return Plugin_Stop;
	}

	new Float:pos_t[3];
	new Float:distance;
	
	for (int i = 1; i <= MaxClients; i++) 
	{
		if (IsClientInGame(i) && ZR_IsClientHuman(i))
		{
			GetClientAbsOrigin(i, pos_t);
			distance = GetVectorDistance(g_pos[client], pos_t);
			if(distance <= g_iSmokeRadius)
			{
				DealDamage(client,i,g_iSmokeDamage,0,"smoke");
			}
		}
	}
	return Plugin_Continue;
}

stock DealDamage(attacker=0,victim,damage,dmg_type=0,String:weapon[]="")
{
	if(IsValidEdict(victim) && damage>0)
	{
		new String:victimid[64];
		new String:dmg_type_str[32];
		IntToString(dmg_type,dmg_type_str,32);
		new PointHurt = CreateEntityByName("point_hurt");
		if(PointHurt)
		{
			Format(victimid, 64, "victim%d", victim);
			DispatchKeyValue(victim,"targetname",victimid);
			DispatchKeyValue(PointHurt,"DamageTarget",victimid);
			DispatchKeyValueFloat(PointHurt,"Damage",float(damage));
			DispatchKeyValue(PointHurt,"DamageType",dmg_type_str);
			if(!StrEqual(weapon,""))
			{
				DispatchKeyValue(PointHurt,"classname",weapon);
			}
			DispatchSpawn(PointHurt);
			if(IsClientInGame(attacker))
				AcceptEntityInput(PointHurt, "Hurt", attacker);
			else 	
				AcceptEntityInput(PointHurt, "Hurt", -1);
				
			RemoveEdict(PointHurt);
		}
	}
}

public Action:Timer_KillSmoke(Handle:timer, Handle:pack)
{	
	ResetPack(pack);
	new SmokeEnt = ReadPackCell(pack);
	new client = ReadPackCell(pack);
	StopSmokeEnt(SmokeEnt);
	StopSmoke[client] = true;
}
public Action:Timer_StopSmoke(Handle:timer, Handle:pack)
{	
	ResetPack(pack);
	new SmokeEnt = ReadPackCell(pack);
	RemoveSmokeEnt(SmokeEnt);
}
StopSmokeEnt(target)
{

	if (IsValidEntity(target))
	{
		AcceptEntityInput(target, "TurnOff");
	}
}
RemoveSmokeEnt(target)
{
	if (IsValidEntity(target))
	{
		AcceptEntityInput(target, "Kill");
	}
}

//检测玩家属性函数
bool:IsClient(Client, bool:Alive)
{
	return Client <= MaxClients && IsClientConnected(Client) && IsClientInGame(Client) && (Alive && IsPlayerAlive(Client));
}
