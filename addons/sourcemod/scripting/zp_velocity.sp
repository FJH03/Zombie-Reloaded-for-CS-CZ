#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <franug_zp>

public Plugin:myinfo =
{
	name = "[ZP] velocity",
	author = "Franc1sco franug",
	description = "",
	version = "3.1",
	url = "http://steamcommunity.com/id/franug"
};

// configuration part
#define AWARDNAME "velocity" // Name of award
#define PRICE 15 // Award price
#define AWARDTEAM ZP_BOTH // Set team that can buy this award (use ZP_BOTH ZP_HUMANS ZP_ZOMBIES)
#define TRANSLATIONS "plague_velocity.phrases" // Set translations file for this subplugin
// end configuration


// dont touch
public OnPluginStart()
{
	CreateTimer(0.1, Lateload);
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
		PrintToChat(client, "\x01\x03[\x04SM_Franug-ZombiePlague\x03]\x01 %t", "you bought velocity");
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.4);
	}
}