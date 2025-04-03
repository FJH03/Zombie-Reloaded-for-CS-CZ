#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <zombiereloaded>

#define PANEL_TEAM "team"

public Plugin myinfo =
{
	name = "[ZR] FixPlayerTeam",
	author = "[CNSR] FJH_03",
	description = "用于CZ-ZR模式的修正团队与角色插件",
	version = "2.4",
	url = "<-url->"
};

static int RoundNum = 0;    //回合序号
static int StopSpawn[65] = {0}; 

//定义真人用户的人物模型数组
static int iEntPlayerModelList[128] = {0};
static char iEntPlayerModeNamelList[128][64];


public OnPluginStart()
{
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("round_end", RoundEnd, EventHookMode_Pre);
}


public OnMapStart()
{
	for(int i = 0; i <= (sizeof(iEntPlayerModelList) - 1); i++) {
		iEntPlayerModelList[i] = 0;
	}
	RoundNum = 0;
	
	AddCommandListener(OnJoinClass, "joinclass");    //监听选择人物的控制台命令
}


public Action:Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsClient(client, true) && !IsFakeClient(client) && StopSpawn[client] == 0)
	{
		if(iEntPlayerModelList[client] >= 1 && iEntPlayerModelList[client] <= 5)
		{
			CreateTimer(0.2, SetPlayerModel_T, client);
			StopSpawn[client] = 1;
		}
		
		if(iEntPlayerModelList[client] >= 6 && iEntPlayerModelList[client] <= 10)
		{
			CreateTimer(0.2, SetPlayerModel_CT, client);
			StopSpawn[client] = 1;
		}
	}
	
	if (IsFakeClient(client)) {
		CreateTimer(1.0, solveBotSelect, client);
	}
}

public Action:solveBotSelect(Handle timer, int client) {
	if (ZR_IsClientHuman(client) && IsFakeClient(client)) {
		char Name[20];
		GetClientName(client, Name, sizeof(Name));
		
		decl String:ModelStr[64];
		GetClientModel(client, ModelStr, sizeof(ModelStr));
		
		if (!StrEqual(ModelStr, "models/player/ct_private_female.mdl") && StrEqual(Name, "SXY-E.YT")) {
			SetEntityModel(client, "models/player/ct_private_female.mdl");
		}
		
		if (StrEqual(ModelStr, "models/player/ct_private_female.mdl") || StrEqual(ModelStr, "models/player/ct_vip_female3.mdl")) {
			if (GetClientTeam(client) == CS_TEAM_T) {
				CreateTimer(0.2, SetPlayerModel_CT, client);
			}
		}
		
		if (StrEqual(ModelStr, "models/player/t_vip_female4.mdl") || StrEqual(ModelStr, "models/player/umbrella.mdl")) {
			if (GetClientTeam(client) == CS_TEAM_CT) {
				CreateTimer(0.2, SetPlayerModel_T, client);
			}
		}
	}
}


public Action:SetPlayerModel_T(Handle timer, int client)
{
	CS_SwitchTeam(client, CS_TEAM_T);
	SetEntityModel(client, iEntPlayerModeNamelList[client]);
	CS_RespawnPlayer(client);
}

public Action:SetPlayerModel_CT(Handle timer, int client)
{
	CS_SwitchTeam(client, CS_TEAM_CT);
	SetEntityModel(client, iEntPlayerModeNamelList[client]);
	CS_RespawnPlayer(client);
}


public Action:RoundEnd(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new WinningTeam = GetEventInt(event, "winner");
	
	if(WinningTeam > 1)
		RoundNum++;	
	
	for(int i = 1; i <= 64; i++) {
		StopSpawn[i] = 0;
	}
}


//监听选择人物的控制台命令的响应函数
public Action:OnJoinClass(client, const String:command[], args)
{
	if(!IsFakeClient(client))
	{
		decl String:sText[256]; 
		GetCmdArg(1, sText, sizeof(sText));
		StripQuotes(sText);
		TrimString(sText);
		// PrintToChatAll("命令：%s", sText); 
		int classtype = 0;
		if(strlen(sText) > 0)
			classtype = StringToInt(sText);
		
		if(classtype > 0)
		{
			decl String:ModelStr[64];
			if(classtype == 1)
				ModelStr = "models/player/ct_urban.mdl";
			if(classtype == 2)
				ModelStr = "models/player/ct_gsg9.mdl";
			if(classtype == 3)
				ModelStr = "models/player/ct_sas.mdl";
			if(classtype == 4)
				ModelStr = "models/player/ct_gign.mdl";
			if(classtype == 5)
				ModelStr = "models/player/ct_spetsnaz.mdl";
			if(classtype == 6)
				ModelStr = "models/player/t_phoenix.mdl";
			if(classtype == 7)
				ModelStr = "models/player/t_leet.mdl";
			if(classtype == 8)
				ModelStr = "models/player/t_arctic.mdl";
			if(classtype == 9)
				ModelStr = "models/player/t_guerilla.mdl";
			if(classtype == 10)
				ModelStr = "models/player/t_militia.mdl";
				
			TrimString(ModelStr);
			iEntPlayerModelList[client] = classtype;
			strcopy(iEntPlayerModeNamelList[client], strlen(ModelStr) + 1, ModelStr);
		}
	}
}


//检测玩家属性函数
bool:IsClient(Client, bool:Alive)
{
	return Client <= MaxClients && IsClientConnected(Client) && IsClientInGame(Client) && (Alive && IsPlayerAlive(Client));
}
	