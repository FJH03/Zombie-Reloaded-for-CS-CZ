#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <franug_zp>

public Plugin:myinfo =
{
	name = "[ZP] givecredits",
	author = "Franc1sco franug & [CNSR] FJH_03",
	description = "",
	version = "3.2",
	url = "http://steamcommunity.com/id/franug"
};

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("plague_givecredits.phrases");
	RegConsoleCmd("sm_givecredits", Dar);
}

public Action:Dar(client, args)
{
	if(args < 2) // Not enough parameters
	{
		ReplyToCommand(client, "%t", "[SM] Utiliza: sm_dar <#userid|nombre> [cantidad]");
		return Plugin_Handled;
	}
	
	new String:targetName[MAX_NAME_LENGTH];
	GetCmdArg(1, targetName, sizeof(targetName));
	
	new target = Client_FindByName(targetName);
	
	if (target == -1)
	{
		PrintToChat(client, "\x01\x03[\x04SM_Franug-ZombiePlague\x03]\x01 没有发现任何玩家名称包括: \"%s\"", targetName);
		return Plugin_Handled;
	}
	
	new String:NewCredits[32];
	GetCmdArg(2, NewCredits, sizeof(NewCredits));
	
	new ModCredits = StringToInt(NewCredits);
	
	if (ModCredits > ZP_GetCredits(client)) {
		PrintToChat(client, "\x01\x03[\x04SM_Franug-ZombiePlague\x03]\x01 %t", "Tu no tienes tantos creditos!");
		return Plugin_Handled;
	}
	
	if (ModCredits <= 0) {
		PrintToChat(client, "\x01\x03[\x04SM_Franug-ZombiePlague\x03]\x01 %t", "No puedes dar menos de 0 creditos!");
		return Plugin_Handled;
	}
	
	ZP_SetCredits(target, ZP_GetCredits(target) + ModCredits);
	ZP_SetCredits(client, ZP_GetCredits(client) - ModCredits);
	
	decl String:nombre[32];
	GetClientName(client, nombre, sizeof(nombre));
	decl String:nombre2[32];
	GetClientName(target, nombre2, sizeof(nombre2));
	
	PrintToChat(client, "\x01\x03[\x04SM_Franug-ZombiePlague\x03]\x01 %t","Entregados", ModCredits, nombre2);
	PrintToChat(target, "\x01\x03[\x04SM_Franug-ZombiePlague\x03]\x01 %t","Te ha Entregado", ModCredits, nombre);
	
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