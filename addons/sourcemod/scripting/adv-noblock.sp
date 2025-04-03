#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "2.0"

public Plugin:myinfo = 
{
    name = "Advance-Noblock",
    author = "[CNSR] FJH_03",
    description = "连点计分板取消指定玩家的碰撞体积，过段时间恢复",
    version = PLUGIN_VERSION,
    url = "http://otstrel.ru"
};

// ===========================================================================
// GLOBALS
// ===========================================================================

new g_offsCollisionGroup;
new bool:g_enabled_nades;
new bool:g_enabled_hostages;
new Float:g_noblockTime;

new Handle:sm_noblock_nades;
new Handle:sm_noblock_hostages;
new Handle:sm_noblock_time;
new Handle:g_hTimer[MAXPLAYERS+1];

#define cDefault 0x01
#define cLightGreen 0x03

public OnPluginStart()
{
    g_offsCollisionGroup = FindSendPropOffs("CBaseEntity", "m_CollisionGroup");
	
    if (g_offsCollisionGroup == -1)
    {
        SetFailState("[NoBlock] Failed to get offset for CBaseEntity::m_CollisionGroup.");
    }
	
	sm_noblock_nades = CreateConVar("sm_noblock_nades", "1", "Removes player vs. nade collisions");
    
    HookConVarChange(sm_noblock_nades, OnConVarChange);
	
	sm_noblock_hostages = CreateConVar("sm_noblock_hostages", "1", "Removes player vs. hostage collisions");
    
    HookConVarChange(sm_noblock_hostages, OnConVarChange);
	
	sm_noblock_time = CreateConVar("sm_noblock_time", "2", "No blocking only for that time");
	
	AutoExecConfig(true, "adv-noblock");
	CvarsChanged();
}

public OnConfigsExecuted()
{
	CvarsChanged();
}

public OnConVarChange(Handle:hCvar, const String:oldValue[], const String:newValue[])
{
    CvarsChanged();
}

void CvarsChanged()
{
	g_enabled_nades = GetConVarBool(sm_noblock_nades);
	
	g_enabled_hostages = GetConVarBool(sm_noblock_hostages);
	if (g_enabled_hostages) {
		 UnblockHostages();
	} else {
		BlockHostages();
	}
	
	g_noblockTime = GetConVarFloat(sm_noblock_time);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (IsClient(client, true)) {
		if(GetEntProp(client, Prop_Data, "m_afButtonPressed") & IN_SCORE) {
			if (!IsFakeClient(client)) {
				int Target = GetClientAimTarget(client, true);   // 获取准心目标实体
				if (IsClient(Target, true)) {
					noblock(client, Target); 
				}
			}
		}
	}

	return Plugin_Continue;
}

public OnEntityCreated(entity, const String:classname[])
{
    if ( g_enabled_nades )
    {
        //Enable NoBlock on Nades
        if (StrEqual(classname, "hegrenade_projectile")) {
            UnblockEntity(entity);
        } else if (StrEqual(classname, "flashbang_projectile")) {
            UnblockEntity(entity);
        } else if (StrEqual(classname, "smokegrenade_projectile")) {
            UnblockEntity(entity);
        }
    }
}

noblock(client, Target) {
	if (g_hTimer[client] != INVALID_HANDLE) {
		CloseHandle(g_hTimer[client]);
		g_hTimer[client] = INVALID_HANDLE;
		
		UnblockEntity(Target);
		PrintToChat(Target, "%c[NoBlock] %c%N 尝试穿透你！", cLightGreen, cDefault, client);
	}
	
	new encodedData = (client & 0xFF) | ((Target & 0xFF) << 8);
	g_hTimer[client] = CreateTimer(g_noblockTime, Timer_PlayerUnblock, encodedData);
}

public Action:Timer_PlayerUnblock(Handle:timer, any encodedData)
{
	new client = encodedData & 0xFF; 
    new Target = (encodedData >> 8) & 0xFF; 
    g_hTimer[client] = INVALID_HANDLE;            
    if ( !IsClient(client, true) || !IsClient(client, true))
    {
        return Plugin_Continue;
    }
    
    PrintToChat(client, "%c[NoBlock] %c现在你不能穿透 %N 了！", cLightGreen, cDefault, Target);
    
    BlockEntity(Target);
	PrintToChat(Target, "%c[NoBlock] %c现在你不可被穿透！", cLightGreen, cDefault);
	
    return Plugin_Continue;
}

UnblockHostages() {
    new String:sClassName[32];
    new iMaxEntities = GetMaxEntities();
    
    /* Apparently the clients are always at the start of the entity list,
        so we can skip them in hopes of reducing roundstart lag */
        
    for ( new iEntity = MaxClients + 1; iEntity < iMaxEntities; iEntity++ )
    {
        if ( !IsValidEntity(iEntity) || !IsValidEdict(iEntity) ) {
            continue;
        }        
        GetEdictClassname(iEntity, sClassName, sizeof(sClassName));
        if ( StrEqual("hostage_entity", sClassName) ) {
            UnblockEntity(iEntity);
        }
    }
}    

BlockHostages() {
    new String:sClassName[32];
    new iMaxEntities = GetMaxEntities();
    
    /* Apparently the clients are always at the start of the entity list,
        so we can skip them in hopes of reducing roundstart lag */
        
    for ( new iEntity = MaxClients + 1; iEntity < iMaxEntities; iEntity++ )
    {
        if ( !IsValidEntity(iEntity) || !IsValidEdict(iEntity) ) {
            continue;
        }        
        GetEdictClassname(iEntity, sClassName, sizeof(sClassName));
        if ( StrEqual("hostage_entity", sClassName) ) {
            BlockEntity(iEntity);
        }
    }
}

BlockEntity(client)
{
    SetEntData(client, g_offsCollisionGroup, 5, 4, true);
}

UnblockEntity(client)
{
    SetEntData(client, g_offsCollisionGroup, 2, 4, true);
}

//检测玩家属性函数
bool:IsClient(Client, bool:Alive)
{
	return Client <= MaxClients && IsClientConnected(Client) && IsClientInGame(Client) && (Alive && IsPlayerAlive(Client));
}




