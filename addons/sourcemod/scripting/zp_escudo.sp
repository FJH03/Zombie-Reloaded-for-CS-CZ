#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <franug_zp>

public Plugin:myinfo =
{
	name = "[ZP] escudo",
	author = "Franc1sco franug",
	description = "",
	version = "3.1",
	url = "http://steamcommunity.com/id/franug"
};

// configuration part
#define AWARDNAME "inmunityzp" // Name of award
#define PRICE 15 // Award price
#define AWARDTEAM ZP_HUMANS // Set team that can buy this award (use ZP_BOTH ZP_HUMANS ZP_ZOMBIES)
#define TRANSLATIONS "plague_inmunity.phrases" // Set translations file for this subplugin
// end configuration

new inmunidad[MAXPLAYERS+1];

// dont touch
public OnPluginStart()
{
	CreateTimer(0.1, Lateload);
	//HookEvent("player_spawn", EventPlayerSpawn);
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
// END dont touch part


public ZP_OnAwardBought( client, const String:awardbought[])
{
	if(StrEqual(awardbought, AWARDNAME))
	{
		// use your custom code here
		PrintToChat(client, "\x01\x03[\x04SM_Franug-ZombiePlague\x03]\x01 %t", "You bought an human shield");
		inmunidad[client] = 5;
	}
}

/* public Action:EventPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	inmunidad[client] = 0;
} */

public OnClientPostAdminCheck(client)
{
	inmunidad[client] = 0;
}

public Action:ZR_OnClientInfect(&client, &attacker, &bool:motherInfect, &bool:respawnOverride, &bool:respawn)
{
	if(attacker < 1) return Plugin_Continue;
	
	if(inmunidad[client] > 0)
	{
		inmunidad[client] -= 1;
		new Float:pos[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}