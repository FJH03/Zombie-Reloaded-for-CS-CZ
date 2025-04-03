#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <franug_zp>

public Plugin:myinfo =
{
	name = "[ZP] infiniteammo",
	author = "Franc1sco franug, modified by [CNSR] FJH_03",
	description = "",
	version = "3.2",
	url = "http://steamcommunity.com/id/franug"
};

// configuration part
#define AWARDNAME "infiniteammo" // Name of award
#define PRICE 16 // Award price
#define AWARDTEAM ZP_HUMANS // Set team that can buy this award (use ZP_BOTH ZP_HUMANS ZP_ZOMBIES)
#define TRANSLATIONS "plague_infiniteammo.phrases" // Set translations file for this subplugin
// end configuration

new bool:g_AmmoInfi[MAXPLAYERS + 1];
#define NUM_WEAPONS 24

new const String:g_sWeaponNames[NUM_WEAPONS][32] = {

	"weapon_ak47", "weapon_m4a1", "weapon_sg552",
	"weapon_aug", "weapon_galil", "weapon_famas",
	"weapon_scout", "weapon_m249", "weapon_mp5navy",
	"weapon_p90", "weapon_ump45", "weapon_mac10",
	"weapon_tmp", "weapon_m3", "weapon_xm1014",
	"weapon_glock", "weapon_usp", "weapon_p228",
	"weapon_deagle", "weapon_elite", "weapon_fiveseven",
	"weapon_awp", "weapon_g3sg1", "weapon_sg550"
};

new const g_AmmoData[NUM_WEAPONS][2] = {

	{2, 500}, {3, 500}, {3, 500},
	{2, 500}, {3, 500}, {3, 500},
	{2, 400}, {4, 800}, {6, 500},
	{10, 500}, {8, 500}, {8, 500},
	{6, 500}, {7, 500}, {7, 500},
	{6, 250}, {8, 250}, {9, 250},
	{1, 250}, {6, 250}, {10, 250},
	{5, 100}, {2, 100}, {3, 100}
};

// dont touch
public OnPluginStart()
{
	CreateTimer(0.1, Lateload);
	
	HookEvent("player_spawn", EventPlayerSpawn);
	HookEvent("weapon_fire", EventWeaponFire);
}

public Action:Lateload(Handle:timer)
{
	LoadTranslations(TRANSLATIONS); // translations to the local plugin
	ZP_LoadTranslations(TRANSLATIONS); // sent translations to the main plugin
	
	ZP_AddAward(AWARDNAME, PRICE, AWARDTEAM); // add award to the main plugin
}

public OnPluginEnd()
{
	ZP_RemoveAward(AWARDNAME); // remove award when the plugin is unloaded
}

public ZP_OnAwardBought( client, const String:awardbought[])
{
	if(StrEqual(awardbought, AWARDNAME))
	{
		// use your custom code here
		PrintToChat(client, "\x01\x03[\x04SM_Franug-ZombiePlague\x03]\x01 %t", "you bought infiniteammo");
		g_AmmoInfi[client] = true;
	}
}

public Action:EventPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	g_AmmoInfi[client] = false;
}

public Action:EventWeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
    // Get all required event info.
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!g_AmmoInfi[client]) return;
	
	Client_ResetAmmo(client);
}

public Client_ResetAmmo(client) {

	new weaponIndex, dataIndex, ammoOffset;
	new bool:restocked;
	decl String:sClassName[32];
	for (new i = 0; i <= 1; i++) {
		if (((weaponIndex = GetPlayerWeaponSlot(client, i)) != -1) && 
		GetEdictClassname(weaponIndex, sClassName, 32) &&
		((dataIndex = GetAmmoDataIndex(sClassName)) != -1) &&
		((ammoOffset = FindDataMapOffs(client, "m_iAmmo")+(g_AmmoData[dataIndex][0]*4)) != -1)) {
			SetEntData(client, ammoOffset, g_AmmoData[dataIndex][1]);
		}
	}
}

GetAmmoDataIndex(const String:weapon[]) {

	for (new i = 0; i < NUM_WEAPONS; i++)
		if (StrEqual(weapon, g_sWeaponNames[i]))
			return i;
	return -1;
}