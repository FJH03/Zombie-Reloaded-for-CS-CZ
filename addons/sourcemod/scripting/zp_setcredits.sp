#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <franug_zp>

public Plugin:myinfo =
{
	name = "[ZP] setcredits",
	author = "Franc1sco franug & [CNSR] FJH_03",
	description = "",
	version = "3.3",
	url = "http://steamcommunity.com/id/franug"
};

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("plague_setcredits.phrases");
	RegAdminCmd("sm_setcredits", CreditControl, ADMFLAG_CUSTOM2);
}


public Action:CreditControl(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] 使用方法: sm_setcredits <#用户id||用户名称> [数量]");
		return Plugin_Handled;
	}

	new String:targetName[MAX_NAME_LENGTH];
	GetCmdArg(1, targetName, sizeof(targetName));
	
	new target = Client_FindByName(targetName);
	
	if (target == -1)
	{
		PrintToChat(client, "没有发现任何玩家名称包括: \"%s\"", targetName);
		return Plugin_Handled;
	}

	new String:NewCredits[32];
	GetCmdArg(2, NewCredits, sizeof(NewCredits));
	
	new ModCredits = StringToInt(NewCredits);
	ZP_SetCredits(target, ModCredits);
	decl String:nombre[64];
	GetClientName(target, nombre, 64);
	PrintToChat(client, "\x01\x03[\x04SM_Franug-ZombiePlague\x03]\x01 %t", "Puesto creditos", ModCredits, nombre);
	
	return Plugin_Handled;

}

stock int Client_FindByName(const char[] name, bool partOfName=true, bool caseSensitive=false)
{
	char clientName[MAX_NAME_LENGTH];
	for (int client=1; client <= MaxClients; client++) {
		
		if (IsClientConnected(client)) {
			GetClientName(client, clientName, sizeof(clientName));

			if (partOfName) {
				if (StrContains(clientName, name, caseSensitive) != -1) {
					return client;
				}
			}
			else if (StrEqual(name, clientName, caseSensitive)) {
				return client;
			}
		}
	}

	return -1;
}