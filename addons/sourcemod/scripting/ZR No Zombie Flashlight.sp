#include <sdktools>
#include <zombiereloaded>

public Plugin:myinfo = 
{
	name = "[ZR] No Zombie Flashlight",
	author = "FrozDark (HLModders.ru LLC) & [CNSR] FJH_03",
	description = "Simple plugin that restricts flashlights for zombies",
	version = "1.1",
	url = "www.hlmod.ru"
}

public Action:OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (IsClient(client, true)) {
		if (ZR_IsClientZombie(client) && impulse == 100) {
			impulse = 0;
		}			
	}
	
		
	return Plugin_Continue;
}

//检测玩家属性函数
bool:IsClient(Client, bool:Alive)
{
	return Client <= MaxClients && IsClientConnected(Client) && IsClientInGame(Client) && (Alive && IsPlayerAlive(Client));
}