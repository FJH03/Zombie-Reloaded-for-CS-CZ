#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin:myinfo =
{
	name = "Advanced Weapon Cleaner",
	author = ".#Zipcore",
	description = "",
	version = "1.0",
	url = "https://gitlab.com/Zipcore/AdvWeaponCleaner"
};

Handle g_aWeapons = null;
Handle g_aWeaponDropTimes = null;

ConVar cvRemoveDelay = null;
ConVar cvRemoveDelay2 = null;
ConVar cvMuchWeapons = null;
ConVar cvWeaponsPerPlayer = null;
ConVar cvPunishment = null;
ConVar cvKeepMapWeapons = null;

int g_iWeaponsOnGround;
int g_iWeaponCount[MAXPLAYERS + 1];

public void OnPluginStart()
{
	cvRemoveDelay = CreateConVar("adv_weapon_cleaner_remove_delay", "20.0", "Time to wait before weapon gets removed when a player drops it.");
	cvRemoveDelay2 = CreateConVar("adv_weapon_cleaner_remove_delay2", "0.1", "Reduced remove delay per weapon.");
	cvMuchWeapons = CreateConVar("adv_weapon_cleaner_much_weapons", "100", "How much weapons have to be spawned (including each players inventory) before intensifying remove delay.");
	cvWeaponsPerPlayer = CreateConVar("adv_weapon_cleaner_weapons_per_player", "50", "How much weapons a player can spawn before all his weapons get removed.");
	cvPunishment = CreateConVar("adv_weapon_cleaner_punishment", "1", "0: Disable 1: Warn player 2: Kick player");
	cvKeepMapWeapons = CreateConVar("adv_weapon_cleaner_keep_map_weapons", "1", "0: Disable 1: Keep");
	
	AutoExecConfig(true, "adv_weapon_cleaner");
}

public void OnMapStart()
{
	if(g_aWeapons == null)
	{
		g_aWeapons = CreateArray(1);
		g_aWeaponDropTimes = CreateArray(1);
	}
	else
	{
		ClearArray(g_aWeaponDropTimes);
		ClearArray(g_aWeapons);
	}
	
	CreateTimer(0.1, Timer_Check, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public void OnEntityCreated(int iEntity, const char[] classname)
{
	// Is not c4 but weapon or item
	if(StrContains(classname, "c4") == -1 && (StrContains(classname, "weapon_") != -1 || StrContains(classname, "item_") != -1))
		SDKHook(iEntity, SDKHook_Spawn, OnWeaponSpawned);
}

public void OnWeaponSpawned(int iWeapon)
{
	SDKUnhook(iWeapon, SDKHook_Spawn, OnWeaponSpawned);
	
	int iPrevOwner = HasEntProp(iWeapon, Prop_Send, "m_hPrevOwner") ? GetEntPropEnt(iWeapon, Prop_Send, "m_hPrevOwner") : -1;
	
	// Check if a player has spawned the weapon but his weapon slot was full
	if(iPrevOwner <= 0 && !SetClosestPlayerOwner(iWeapon))
	{
		// If keep map weapons don't add this weapon to watchlist
		if(cvKeepMapWeapons.BoolValue)
			return;
	}
	
	// Add weapon to watch list
	PushArrayCell(g_aWeapons, EntIndexToEntRef(iWeapon));
	PushArrayCell(g_aWeaponDropTimes, GetGameTime());
}

public Action Timer_Check(Handle timer, any data)
{
	UpdateWatchList();
	CheckPlayerWeaponCounts();
	CleanupWeapons();
	return Plugin_Continue;
}

void ResetPlayerWeaponCounts()
{
	// Check player spam
	for(int i = 1; i <= MaxClients; i++)
	{
		g_iWeaponCount[i] = 0;
	}
}

void CheckPlayerWeaponCounts()
{
	// Check player spam
	for(int i = 1; i <= MaxClients; i++)
	{
		if(g_iWeaponCount[i] >= cvWeaponsPerPlayer.IntValue)
			CleanupWeaponsByPlayer(i);
	}
}

void UpdateWatchList()
{
	ResetPlayerWeaponCounts();
	
	g_iWeaponsOnGround = 0;
	
	for (int i = GetArraySize(g_aWeapons)-1; i > 0; --i)
	{
		int iWeapon = EntRefToEntIndex(GetArrayCell(g_aWeapons, i));
		
		// Invalid weapon
		if(iWeapon <= 0 || !HasEntProp(iWeapon, Prop_Send, "m_hOwnerEntity"))
		{
			// Remove from array
			RemoveFromArray(g_aWeapons, i);
			RemoveFromArray(g_aWeaponDropTimes, i);
			
			continue;
		}
		
		int iOwner = GetEntPropEnt(iWeapon, Prop_Send, "m_hOwnerEntity");
		int iPrevOwner = HasEntProp(iWeapon, Prop_Send, "m_hPrevOwner") ? GetEntPropEnt(iWeapon, Prop_Send, "m_hPrevOwner") : -1;
		
		if(iPrevOwner <= 0)
			iPrevOwner = GetEntProp(iWeapon, Prop_Send, "m_iTeamNum");
		
		// Has owner
		if(iOwner > 0)
		{
			// Update drop time
			SetArrayCell(g_aWeaponDropTimes, i, GetGameTime());
			
			continue;
		}
			
		if(IsPlayer(iPrevOwner))
			g_iWeaponCount[iPrevOwner]++;
		
		g_iWeaponsOnGround++;
	}
}

void CleanupWeaponsByPlayer(int iClient)
{
	for (int i = GetArraySize(g_aWeapons)-1; i > 0; --i)
	{
		int iWeapon = EntRefToEntIndex(GetArrayCell(g_aWeapons, i));
		
		int iOwner = GetEntPropEnt(iWeapon, Prop_Send, "m_hOwnerEntity");
		int iPrevOwner = HasEntProp(iWeapon, Prop_Send, "m_hPrevOwner") ? GetEntPropEnt(iWeapon, Prop_Send, "m_hPrevOwner") : -1;
		
		if(iPrevOwner <= 0)
			iPrevOwner = GetEntProp(iWeapon, Prop_Send, "m_iTeamNum");
		
		// Drop time exceeded, remove entity
		if(iOwner <= 0 && iPrevOwner == iClient)
		{
			// Remove from array
			RemoveFromArray(g_aWeapons, i);
			RemoveFromArray(g_aWeaponDropTimes, i);
			
			// Remove from game
			RemoveEdict(iWeapon);
		}
	}
	
	if(cvPunishment.IntValue > 0 && IsClientInGame(iClient))
	{
		if(cvPunishment.IntValue == 1)
			PrintToChat(iClient, "Removed all your weapons! Please don't spam weapons!");
		else if(cvPunishment.IntValue == 2)
			KickClient(iClient, "Weapon SPAM");
	}
}

void CleanupWeapons()
{
	int iWeaponCount = GetArraySize(g_aWeapons);
	
	float fRemoveDelay = cvRemoveDelay.FloatValue;
	
	if(iWeaponCount > cvMuchWeapons.IntValue)
		fRemoveDelay -= float(iWeaponCount - cvMuchWeapons.IntValue) * cvRemoveDelay2.FloatValue;
	
	for (int i = iWeaponCount-1; i > 0; --i)
	{
		int iWeapon = EntRefToEntIndex(GetArrayCell(g_aWeapons, i));
		
		float fTime = GetGameTime();
		float fDropTime = GetArrayCell(g_aWeaponDropTimes, i);
		
		// Drop time exceeded, remove entity
		if(fDropTime + fRemoveDelay < fTime)
		{
			// Remove from array
			RemoveFromArray(g_aWeapons, i);
			RemoveFromArray(g_aWeaponDropTimes, i);
			
			// Remove from game
			RemoveEdict(iWeapon);
		}
	}
}

int SetClosestPlayerOwner(int iEntity)
{
	float fPos[3];
	GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fPos);
	
	float fClosestDistance = -1.0;
	int iClient;
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i))
			continue;
		
		if(!IsPlayerAlive(i))
			continue;
		
		float fTargetPos[3];
		GetClientAbsOrigin(i, fTargetPos);
		
		if(fTargetPos[0] == 0.0 && fTargetPos[1] == 0.0 && fTargetPos[2] == 0.0)
			continue;
		
		float fDistance = GetVectorDistance(fPos, fTargetPos);
		
		if (fDistance < fClosestDistance || fClosestDistance == -1.0)
		{
			fClosestDistance = fDistance;
			iClient = i;
		}
	}
	
	if(iClient > 0 && fClosestDistance <= 0.0)
	{
		SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iClient);
		return true;
	}
	
	return false;
}

stock bool IsPlayer(int iEntity)
{
	return !(iEntity < 1 || iEntity > MaxClients);
}