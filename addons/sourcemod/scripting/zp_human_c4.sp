#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <zombiereloaded>
#include <franug_zp>

public Plugin:myinfo =
{
	name = "[ZP] human_c4",
	author = "[CNSR] FJH_03",
	description = "人类放置C4炸弹",
	version = "3.2",
	url = "<-url->"
};

int g_iC4Ent = -1,
	g_iTimerExplosion,
	g_iBombDamage,
	g_iBombRadius,
	g_iIgniteTime,
	g_iPos;
	
bool g_bGC4Used = false,
	g_bPublicMsg,
	g_haveHumanC4[MAXPLAYERS + 1];
	
Handle	g_cTimerExplosion, g_cBombDamage, g_cBombRadius,
	g_cIgniteTime, g_cPublicMsg, g_cPos;	

// configuration part
#define AWARDNAME "human_c4" // Name of award
#define PRICE 18 // Award price
#define AWARDTEAM ZP_HUMANS // Set team that can buy this award (use ZP_BOTH ZP_HUMANS ZP_ZOMBIES)
#define TRANSLATIONS "plague_human_c4.phrases" // Set translations file for this subplugin
// end configuration

// dont touch
public OnPluginStart()
{
	CreateTimer(0.1, Lateload);
	
	g_cTimerExplosion 		= CreateConVar("zp_c4bomb_exp_timer", 		"15", 		"炸弹爆炸前的秒数（默认 15）");
	g_cBombDamage 			= CreateConVar("zp_c4bomb_bomb_damage", 	"5000", 	"炸弹的伤害（默认 5000）");
	g_cBombRadius 			= CreateConVar("zp_c4bomb_bomb_radius", 	"600", 		"炸弹爆炸的半径（默认 600）");
	g_cIgniteTime			= CreateConVar("zp_c4bomb_ignite_time", 	"7", 		"点燃敌人的时间（以秒为单位）| 0 = 禁用（默认 7）");

	g_cPublicMsg			= CreateConVar("zp_c4bomb_plant_message", 	"1", 		"当有人放置炸弹时打印一条公共消息？| 1 = 启用 | 0 = 禁用（默认 1）");

	g_cPos			= CreateConVar("zp_c4bomb_g_iPos", 	"10", 		"放置的c4炸弹距离眼睛位置低多少位置");
	
	HookConVarChange(g_cTimerExplosion, eConvarChanged);
	HookConVarChange(g_cBombDamage, eConvarChanged);
	HookConVarChange(g_cBombRadius, eConvarChanged);
	HookConVarChange(g_cIgniteTime, eConvarChanged);
	HookConVarChange(g_cPublicMsg, eConvarChanged);
	
	HookEvent("round_end", Event_OnRoundEnd);
	HookEvent("round_start", Event_OnRoundStart);

	AutoExecConfig(true, "zombiereloaded/zp_human_c4");
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
	g_iTimerExplosion = GetConVarInt(g_cTimerExplosion);
	g_iBombDamage = GetConVarInt(g_cBombDamage);
	g_iBombRadius = GetConVarInt(g_cBombRadius);
	g_iIgniteTime = GetConVarInt(g_cIgniteTime);
	g_bPublicMsg = GetConVarBool(g_cPublicMsg);
	g_iPos = GetConVarInt(g_cPos);
}

public void OnMapStart()
{
	PrecacheSound("weapons/c4/c4_explode1.wav");
	PrecacheSound("weapons/c4/c4_beep3.wav");
	PrecacheSound("weapons/c4/c4_initiate.wav");
	PrecacheModel("weapons/w_c4_planted.mdl");
}

public void OnClientPutInServer(int client) 
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage); 
	g_haveHumanC4[client] = false;
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype) 
{
	if(g_iIgniteTime >= 1)
	{
		char sExplosion[32];
		GetEntityClassname(inflictor, sExplosion, sizeof(sExplosion));

		if (StrContains(sExplosion, "env_explosion") != -1)
		{
			if(ZR_IsClientZombie(victim))
			{
				IgniteEntity(victim, g_iIgniteTime * 1.0);
				return Plugin_Changed;
			}
		}
	}

	return Plugin_Continue;
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
		PrintToChat(client, "\x01\x03[\x04SM_Franug-ZombiePlague\x03]\x01 %t", "you bought human_c4");
		g_haveHumanC4[client] = true;
	}
}

public Action Event_OnRoundEnd(Event event, char[] name, bool dontBroadcast)
{
	g_bGC4Used = false;
	for (int i = 1; i <= MaxClients; i++) 
	{
		if (IsClientInGame(i))
		{
			g_haveHumanC4[i] = false;
		}
	}
	
	return Plugin_Continue;
}

public Action Event_OnRoundStart(Event event, char[] name, bool dontBroadcast)
{
	g_bGC4Used = false;
	for (int i = 1; i <= MaxClients; i++) 
	{
		if (IsClientInGame(i))
		{
			g_haveHumanC4[i] = false;
		}
	}
	
	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (IsClient(client, true)) {
		if(GetEntProp(client, Prop_Data, "m_afButtonPressed") & IN_SPEED) {
			if (g_haveHumanC4[client] && !IsFakeClient(client)) {
				Command_C4(client, 0);
			}
		}
	}

	return Plugin_Continue;
}

public Action Command_C4(int client, int args)
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
	
	if(!(GetEntityFlags(client) & FL_ONGROUND))
	{
		PrintToChat(client, "\x01\x03[\x04SM_Franug-ZombiePlague\x03]\x01 %t", "you must be plant c4 on ground");
		return Plugin_Handled;
	}

	if(g_bGC4Used)
	{	
		PrintToChat(client, "\x01\x03[\x04SM_Franug-ZombiePlague\x03]\x01 %t", "wait another c4 explode");
		return Plugin_Handled;
	}

	SpawnC4(client);
	g_haveHumanC4[client] = false;
	g_bGC4Used = true;

	if(g_bPublicMsg)
	{
		PrintToChatAll("\x01\x03[\x04SM_Franug-ZombiePlague\x03]\x01 %t", "the bomb has been planted");
	}

	float fEyePos[3];
	GetClientEyePosition(client, fEyePos);
	EmitAmbientSound("weapons/c4/c4_initiate.wav", fEyePos, client);

	CreateTimer(1.0, Timer_Beep, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(g_iTimerExplosion * 1.0, Timer_Boom, GetClientUserId(client));
	return Plugin_Handled;
}

//---------------------------------------
// Purpose: Timers
//---------------------------------------


public Action Timer_Beep(Handle timer)
{
	static int iBeep = 0;
	int m_iEnt = EntRefToEntIndex(g_iC4Ent);
 
	if (iBeep > g_iTimerExplosion) 
	{
		iBeep = 0;
		return Plugin_Stop;
	}
	
	if(IsValidEntity(m_iEnt))
	{
		float fC4Possition[3];
		GetEntPropVector(m_iEnt, Prop_Send, "m_vecOrigin", fC4Possition);
		EmitAmbientSound("weapons/c4/c4_beep3.wav", fC4Possition, m_iEnt);
	}
	iBeep++;

	return Plugin_Continue;
}

public Action Timer_Boom(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (!client || !IsClientInGame(client)) 
	{
		return Plugin_Handled;
	}

	int m_iEnt = EntRefToEntIndex(g_iC4Ent);
	int iExplIndex = CreateEntityByName("env_explosion");
	int iParticleIndex = CreateEntityByName("info_particle_system");

	if(IsValidEntity(m_iEnt))
	{
		float fExploOrigin[3];
		GetEntPropVector(m_iEnt, Prop_Send, "m_vecOrigin", fExploOrigin);

		if (iExplIndex != -1 && iParticleIndex != -1)
		{
			DispatchKeyValue(iParticleIndex, "effect_name", "explosion_c4_500_fallback");
		
			SetEntProp(iExplIndex, Prop_Data, "m_spawnflags", 16384);
			SetEntProp(iExplIndex, Prop_Data, "m_iMagnitude", g_iBombDamage);
			SetEntProp(iExplIndex, Prop_Data, "m_iRadiusOverride", g_iBombRadius);
		
			TeleportEntity(iExplIndex, fExploOrigin, NULL_VECTOR, NULL_VECTOR);
			TeleportEntity(iParticleIndex, fExploOrigin, NULL_VECTOR, NULL_VECTOR);
			
			DispatchSpawn(iExplIndex);
			DispatchSpawn(iParticleIndex);

			ActivateEntity(iExplIndex);
			ActivateEntity(iParticleIndex);
			
			
			SetEntPropEnt(iExplIndex, Prop_Send, "m_hOwnerEntity", client);
			AcceptEntityInput(iParticleIndex, "Start");
			

			EmitSoundToAll("weapons/c4/c4_explode1.wav", SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0);

			AcceptEntityInput(iExplIndex, "Explode");
		}
	}

	if (g_iC4Ent != INVALID_ENT_REFERENCE)
	{
		if(IsValidEntity(m_iEnt))
			AcceptEntityInput(m_iEnt, "Kill");
		g_iC4Ent = INVALID_ENT_REFERENCE;
	}
	
	g_bGC4Used = false;
	
	
	return Plugin_Continue;
}

//---------------------------------------
// Purpose: Spawn C4 bomb
//---------------------------------------

void SpawnC4(int client) 
{
	g_iC4Ent = EntIndexToEntRef(CreateEntityByName("prop_dynamic_override"));
	int m_iEnt = EntRefToEntIndex(g_iC4Ent);

	DispatchKeyValue(m_iEnt, "model", "models/weapons/w_c4_planted.mdl"); 
	DispatchKeyValue(m_iEnt, "spawnflags", "256"); 
	DispatchKeyValue(m_iEnt, "solid", "0");
	DispatchKeyValue(m_iEnt, "modelscale", "1.0");

	float fPosition[3];
	GetClientEyePosition(client, fPosition);
	fPosition[2] -= g_iPos;
 
	DispatchSpawn(m_iEnt); 

	TeleportEntity(m_iEnt, fPosition, NULL_VECTOR, NULL_VECTOR);
}

//检测玩家属性函数
bool:IsClient(Client, bool:Alive)
{
	return Client <= MaxClients && IsClientConnected(Client) && IsClientInGame(Client) && (Alive && IsPlayerAlive(Client));
}