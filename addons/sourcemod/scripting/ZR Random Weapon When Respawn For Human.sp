#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <zombiereloaded>

public Plugin:myinfo = {
	name = "[ZR] Random Weapon When Respawn For Human",
	author = "[CNSR] FJH_03",
	description = "为了防止购买区域限制武器的购买，对于人类重生生成随机主副武器以及随机一颗手雷",
	version = "2.0",
	url = "<- URL ->"
}

int roundNum = 0;

public OnPluginStart(){
	HookEvent("player_spawn", GiveHumanWeapon, EventHookMode_Post);
	HookEvent("round_start", AddRoundNum, EventHookMode_Post);
}

public void AddRoundNum(Handle hEvent, char[] chEvent, bool bDontBroadcast) {
	++roundNum;
}

public Action:GiveHumanWeapon(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	CreateTimer(5.0, Timer_GiveHumanWeapon, client);
}

public Action:Timer_GiveHumanWeapon(Handle timer, int client) {
	KillTimer(timer);

	if (IsClient(client, true)) {
		if (ZR_IsClientHuman(client)) {
			
			if (GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) == -1) {
				GetRandomPrimaryWeapon(client);
			}
			
			if (GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY) == -1) {
				GetRandomSecondryWeapon(client);
			}
			
			if (GetPlayerWeaponSlot(client, CS_SLOT_KNIFE) == -1) {
				GivePlayerItem(client,"weapon_knife");
			}
			
			if (GetPlayerWeaponSlot(client, CS_SLOT_GRENADE) == -1) {
				switch(GetRandomInt(1,3))
				{
					case 1: GivePlayerItem(client,"weapon_hegrenade");
					case 2: GivePlayerItem(client,"weapon_smokegrenade");
					case 3: GivePlayerItem(client,"weapon_flashbang");
				}
			}
		}
	}
}

void GetRandomPrimaryWeapon(int client) {
	if (!IsFakeClient(client) || roundNum == 1) {
		switch(GetRandomInt(1, 18)) {
			case 1: GivePlayerItem(client, "weapon_m3");
			
			case 2: GivePlayerItem(client, "weapon_xm1014");
			
			case 3: GivePlayerItem(client, "weapon_tmp");
			case 4: GivePlayerItem(client, "weapon_mac10");
			
			case 5: GivePlayerItem(client, "weapon_mp5navy");
			
			case 6: GivePlayerItem(client, "weapon_ump45");
			
			case 7: GivePlayerItem(client, "weapon_p90");
			
			case 8: GivePlayerItem(client, "weapon_famas");
			case 9: GivePlayerItem(client, "weapon_galil");
			
			case 10: GivePlayerItem(client, "weapon_scout");
			
			case 11: GivePlayerItem(client, "weapon_ak47");
			case 12: GivePlayerItem(client, "weapon_m4a1");
			
			case 13: GivePlayerItem(client, "weapon_aug");
			case 14: GivePlayerItem(client, "weapon_sg552");
			
			case 15: GivePlayerItem(client, "weapon_sg550");
			case 16: GivePlayerItem(client, "weapon_g3sg1");
			
			case 17: GivePlayerItem(client, "weapon_awp");
			
			case 18: GivePlayerItem(client, "weapon_m249");
		}
	} else {
		switch(GetRandomInt(1, 18)) {
			case 1: EquipPlayerWeapon(client, CreateEntityByName("weapon_m3"));
			
			case 2: EquipPlayerWeapon(client, CreateEntityByName("weapon_xm1014"));
			
			case 3: EquipPlayerWeapon(client, CreateEntityByName("weapon_tmp"));
			case 4: EquipPlayerWeapon(client, CreateEntityByName("weapon_mac10"));
			
			case 5: EquipPlayerWeapon(client, CreateEntityByName("weapon_mp5navy"));
			
			case 6: EquipPlayerWeapon(client, CreateEntityByName("weapon_ump45"));
			
			case 7: EquipPlayerWeapon(client, CreateEntityByName("weapon_p90"));
			
			case 8: EquipPlayerWeapon(client, CreateEntityByName("weapon_famas"));
			case 9: EquipPlayerWeapon(client, CreateEntityByName("weapon_galil"));
			
			case 10: EquipPlayerWeapon(client, CreateEntityByName("weapon_scout"));
			
			case 11: EquipPlayerWeapon(client, CreateEntityByName("weapon_ak47"));
			case 12: EquipPlayerWeapon(client, CreateEntityByName("weapon_m4a1"));
			
			case 13: EquipPlayerWeapon(client, CreateEntityByName("weapon_aug"));
			case 14: EquipPlayerWeapon(client, CreateEntityByName("weapon_sg552"));
			
			case 15: EquipPlayerWeapon(client, CreateEntityByName("weapon_sg550"));
			case 16: EquipPlayerWeapon(client, CreateEntityByName("weapon_g3sg1"));
			
			case 17: EquipPlayerWeapon(client, CreateEntityByName("weapon_awp"));
			
			case 18: EquipPlayerWeapon(client, CreateEntityByName("weapon_m249"));
		}
	}	
}

void GetRandomSecondryWeapon(int client) {
	if (!IsFakeClient(client) || roundNum == 1) {
		switch(GetRandomInt(1, 6)) {
			case 1: GivePlayerItem(client, "weapon_glock");
			
			case 2: GivePlayerItem(client, "weapon_usp");
			
			case 3: GivePlayerItem(client, "weapon_p228");
			
			case 4: GivePlayerItem(client, "weapon_deagle");
			
			case 5: GivePlayerItem(client, "weapon_fiveseven");
			case 6: GivePlayerItem(client, "weapon_elite");
		}
	} else {
		switch(GetRandomInt(1, 6)) {
			case 1: EquipPlayerWeapon(client, CreateEntityByName("weapon_glock"));
			
			case 2: EquipPlayerWeapon(client, CreateEntityByName("weapon_usp"));
			
			case 3: EquipPlayerWeapon(client, CreateEntityByName("weapon_p228"));
			
			case 4: EquipPlayerWeapon(client, CreateEntityByName("weapon_deagle"));
			
			case 5: EquipPlayerWeapon(client, CreateEntityByName("weapon_fiveseven"));
			case 6: EquipPlayerWeapon(client, CreateEntityByName("weapon_elite"));
		}
	}
	
	
}

//检测玩家属性函数
bool:IsClient(Client, bool:Alive)
{
	return Client <= MaxClients && IsClientConnected(Client) && IsClientInGame(Client) && (Alive && IsPlayerAlive(Client));
}

