#include <sourcemod>
#include <DynamicChannels>
#include <zombiereloaded>
#include <sdktools>
#include <sdkhooks>

//Make it neccesary to have semicolons at the end of each line
#pragma semicolon 1

new bool:plug_debug = false;
int Health_Ent[2048+1];
//Version
new String:sVersion[5] = "3.3";
//Prefix
new String:sPrefix[256] = "\x01\x03[\x04PropSpawn\x03]\x01";

//Player properties (credits)
new iDefCredits = 20;
new iCredits[MAXPLAYERS+1];
new iPropNo[MAXPLAYERS+1];//Stores the number of props a player has
new Handle:hCredits = INVALID_HANDLE;

//Team Only
// Teams:
// 0 = No restrictions
// 1 = T
// 2 = CT
new iTeam = 2;
//ConVar Handle
new Handle:hTeamOnly = INVALID_HANDLE;
//Admin only
new bool:bAdminOnly = false;
new Handle:hAdminOnly = INVALID_HANDLE;
//Remove props on death
new Handle:hRemoveProps = INVALID_HANDLE;
new bool:bRemoveProps = true;
//Add Credits on death
new Handle:hCreditsOnDeath = INVALID_HANDLE;
new bool:bCreditsOnDeath = true;

// Prop Command String
new String:sPropCommand[256] = "sm_zprops";

//The Menu
new Handle:zr_public_prop_menu = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "[ZR] Zprops Spawn",
	author = "[CNSR] FJH_03",
	description = "A plugin which allows you to spawn physics props predefined in a text file: Public Version with Credits",
	version = sVersion,
	url = "<-URL->"
};

public OnPluginStart()
{
	// Control ConVars. 1 Team Only, Public Enabled etc.
	hTeamOnly = CreateConVar("zr_prop_teamonly", "2", "0 is no team restrictions, 1 is Terrorist and 2 is CT. Default: 2");
	hAdminOnly = CreateConVar("zr_prop_public", "0", "0 means anyone can use this plugin. 1 means admins only (no credits used)");

	// Register the Credits Command
	RegConsoleCmd("credits", Command_Credits);
	// Hook Player Spawn to restore player credits when they spawn

	HookEvent("round_start", Event_RoundStart);
	
	// Hook when the player dies so that props can be removed
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_disconnect", Event_PlayerDisconnect);
	
	new String:tempCredits[5];
	IntToString(iDefCredits, tempCredits, sizeof(tempCredits));
	// Convar to control the credits players get when they spawn (default above)
	hCredits = CreateConVar("zr_prop_credits", tempCredits, "The number of credits each player should have when they spawn");
	
	/* NEW STUFF */
	hRemoveProps = CreateConVar("zr_prop_removeondeath", "1", "0 is keep the props on death, 1 is remove them on death. Default: 1");
	hCreditsOnDeath = CreateConVar("zr_prop_addcreditsonkill", "0", "0 is off, 1 is on. Default: 0");
	
	//Hook all the ConVar changes
	HookConVarChange(hTeamOnly, OnConVarChanged);
	HookConVarChange(hAdminOnly, OnConVarChanged);
	HookConVarChange(hCredits, OnConVarChanged);
	HookConVarChange(hRemoveProps, OnConVarChanged);
	HookConVarChange(hCreditsOnDeath, OnConVarChanged);
	
	// Register the admin command to add credits (or remove if a minus number is used)
	RegAdminCmd("zr_admin_credits", AdminCreditControl, ADMFLAG_SLAY, "Admin Credit Control Command for ZR ZProp Spawn");
	RegAdminCmd("zr_remove_prop", AdminRemovePropAim, ADMFLAG_SLAY, "Admin Prop Removal by aim");
	RegConsoleCmd(sPropCommand, PropCommand);
}

public OnConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar == hTeamOnly)
		iTeam = GetConVarInt(convar);
	if(convar == hAdminOnly)
		bAdminOnly = GetConVarBool(convar);
	if(convar == hCredits)
		iDefCredits = GetConVarInt(convar);
	if(convar == hRemoveProps)
		bRemoveProps = GetConVarBool(convar);
	if(convar == hCreditsOnDeath)
		bCreditsOnDeath = GetConVarBool(convar);
}

public Action:Command_Credits(client, args)
{
	new tempCredits = iCredits[client];
	PrintToChat(client, "%s 你现在有 %d 个物品积分!", sPrefix, tempCredits);
}

public Event_PlayerDeath(Handle: event , const String: name[] , bool: dontBroadcast)
{
	new victimuserid = GetEventInt(event, "userid");
	new victim = GetClientOfUserId(victimuserid);
	new attackeruserid = GetEventInt(event, "attacker");
	new attacker = GetClientOfUserId(attackeruserid);
	
	if(!Client_IsValid(attacker))
	{
		return;
	}
	
	if(bCreditsOnDeath && IsPlayerAlive(attacker) && ZR_IsClientHuman(attacker) && GetClientTeam(attacker) != GetClientTeam(victim))
	{
		new point = GetRandomInt(1, 5);
		PrintToChat(attacker, "%s 你被给予了 \x03%d\x01 个物品积分作为杀死 %N 的奖励!", sPrefix, point, victim);
		iCredits[attacker] += point;
	}
	
	if(bRemoveProps)
	{
		KillProps(victim);
	}
}

public Event_PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	iCredits[client] = iDefCredits;
	KillProps(client);
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new i = 1; i <= MaxClients; i++)
	{
		iPropNo[i] = 0;
	}
}

stock KillProps(client)
{
	for(new i = 0; i <= iPropNo[client]; i++)
	{
		new String:EntName[MAX_NAME_LENGTH+5];
		Format(EntName, sizeof(EntName), "ZRPropSpawnProp%d_number%d", client, i);
		new prop = Entity_FindByName(EntName);
		if(prop != -1)
			AcceptEntityInput(prop, "kill");
	}
	iPropNo[client] = 0;
}

public Action:AdminRemovePropAim(client, args)
{
	new prop = GetClientAimTarget(client, false);
	new String:EntName[256];
	Entity_GetName(prop, EntName, sizeof(EntName));
	if(plug_debug)
	{
		PrintToChatAll(EntName);
	}
	
	new validProp = StrContains(EntName, "ZRPropSpawnProp");
	
	if(validProp > -1)
	{
		//Remove the prop
		/* Find the client index in the string */
		new String:tempInd[3];
		tempInd[0] = EntName[15];
		tempInd[1] = EntName[16];
		tempInd[2] = EntName[17];
		
		if(plug_debug)
		{
			PrintToChat(client, tempInd);
		}
		
		/* We should now have the numbers somewhere, let's find out where */
		ReplaceString(tempInd, sizeof(tempInd), "_", "");
		if(plug_debug)
		{
			PrintToChat(client, tempInd);
		}
		new clientIndex = StringToInt(tempInd);
		AcceptEntityInput(prop, "kill");
		iPropNo[clientIndex] = iPropNo[clientIndex] - 1;
	}
	else
	{
		PrintToChat(client, "%s You can't delete this prop! It wasn't created by the plugin!", sPrefix);
	}
	
	return Plugin_Handled;
}

public Action:AdminCreditControl(client, args)
{
	if (args < 2)
	{
		PrintToConsole(client, "Usage: zr_admin_credits <name> <credits>");
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
	iCredits[target] = ModCredits;
	
	decl String:nombre[64];
	GetClientName(target, nombre, 64);

	PrintToChatAll("%s %s 现在拥有 %d 个物品积分！", sPrefix, nombre, iCredits[target]);
	
	return Plugin_Handled;

}

public Action:PropCommand(client, args)
{
	if(!Client_IsValid(client))
		return Plugin_Handled;
		
	if(iTeam > 0)
	{
		if(GetClientTeam(client) != iTeam+1)
		{
			PrintToChat(client, "%s 对不起你不能使用该命令！", sPrefix);
			return Plugin_Handled;
		}
	}
	if(bAdminOnly)
	{
		if(!Client_IsAdmin(client))
		{
			PrintToChat(client, "%s 对不起你无权使用该命令！", sPrefix);
			return Plugin_Handled;
		}
	}
	
	if(!IsPlayerAlive(client))
	{
		if(!Client_IsAdmin(client))
		{
			PrintToChat(client, "%s 对不起，当你死亡状态且不是管理员时，你不能使用该命令！", sPrefix);
			return Plugin_Handled;
		}
	}
	
	new String:textPath[255];
	BuildPath(Path_SM, textPath, sizeof(textPath), "configs/zr_public_props.txt");
	new Handle:kv = CreateKeyValues("Props");
	FileToKeyValues(kv, textPath);
	zr_public_prop_menu = CreateMenu(Public_Prop_Menu_Handler);
	SetMenuTitle(zr_public_prop_menu, "Prop Menu | Credits: %d", iCredits[client]);
	PopLoop(kv, client);
	DisplayMenu(zr_public_prop_menu, client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

// Make sure you populate the menu, Runs through the keyvalues.
PopLoop(Handle:kv, client)
{
	if (KvGotoFirstSubKey(kv))
	{
		do
		{
			new String:buffer[256];
			KvGetSectionName(kv, buffer, sizeof(buffer));
			new admin = KvGetNum(kv, "adminonly", 0);	//New, Allows for admin only props
			if(admin == 1)
			{
				if(Client_IsAdmin(client))
				{
					new String:price[256];
					KvGetString(kv, "price", price, sizeof(price), "0");
					new String:MenuItem[256];
					Format(MenuItem, sizeof(MenuItem), "%s - Price: %s", buffer, price);
					AddMenuItem(zr_public_prop_menu, buffer, MenuItem);
				}
			}
			else
			{
				new String:price[256];
				KvGetString(kv, "price", price, sizeof(price), "0");
				new String:MenuItem[256];
				Format(MenuItem, sizeof(MenuItem), "%s - Price: %s", buffer, price);
				AddMenuItem(zr_public_prop_menu, buffer, MenuItem);
			}
		}
		while (KvGotoNextKey(kv));
		CloseHandle(kv);
	}
}

public Public_Prop_Menu_Handler(Handle:menu, MenuAction:action, param1, param2)
{
	// Note to self: param1 is client, param2 is choice.
	if (action == MenuAction_Select)
	{
		// Initiate the Prop Spawning using Client and Choice as the parameters.
		PropSpawn(param1, param2);
		new String:textPath[255];
		BuildPath(Path_SM, textPath, sizeof(textPath), "configs/zr_public_props.txt");
		new Handle:kv = CreateKeyValues("Props");
		FileToKeyValues(kv, textPath);
		zr_public_prop_menu = CreateMenu(Public_Prop_Menu_Handler);
		SetMenuTitle(zr_public_prop_menu, "Prop Menu | Credits: %d", iCredits[param1]);
		PopLoop(kv, param1);
		DisplayMenu(zr_public_prop_menu, param1, MENU_TIME_FOREVER);
	}
}

// Prop Spawning! This does all the calculations and spawning.
public PropSpawn(client, param2)
{
	new String:prop_choice[255];
	
	GetMenuItem(zr_public_prop_menu, param2, prop_choice, sizeof(prop_choice));
	
	new String:name[255];
	GetClientName(client, name, sizeof(name));
	
	decl String:modelname[255];
	new Price,Health;
	new String:file[255];
	BuildPath(Path_SM, file, 255, "configs/zr_public_props.txt");
	new Handle:kv = CreateKeyValues("Props");
	FileToKeyValues(kv, file);
	KvJumpToKey(kv, prop_choice);
	KvGetString(kv, "model", modelname, sizeof(modelname),"");
	Price = KvGetNum(kv, "price", 0);
	Health = KvGetNum(kv, "health", 0);
	new ClientCredits = iCredits[client];
	
	if (Price > 0)
	{
		if (ClientCredits >= Price)
		{
			if(bAdminOnly)
			{
				PrintToChat(client, "%s 你生成了一个 \x04%s", sPrefix, prop_choice);
				LogAction(client, -1, "\"%s\" spawned a %s", name, prop_choice);
			}
			else
			{
				ClientCredits = ClientCredits - Price;
				iCredits[client] = ClientCredits;
				PrintToChat(client, "%s 你生成了一个 \x04%s 通过花费 \x03%d 个物品积分！", sPrefix, prop_choice, Price);
			}
		}
		else
		{
			PrintToChat(client, "%s 你没有足够的物品积分来生成该物品！", sPrefix);
			return;
		}
	}
	
	else
	{
		PrintToChat(client, "%s You have spawned a \x04%s and your credits have not been reduced!", sPrefix, prop_choice);
	}
	decl Ent;   
	PrecacheModel(modelname,true);
	Ent = CreateEntityByName("prop_physics_override"); 
	
	new String:EntName[256];
	Format(EntName, sizeof(EntName), "ZRPropSpawnProp%d_number%d", client, iPropNo[client]);
	new String:prop_health[11];
	if(Health <=0 )  Health = 10;
	IntToString(Health,prop_health,11);
	DispatchKeyValue(Ent, "health", prop_health);
	DispatchKeyValue(Ent, "physdamagescale", "0.1");
	DispatchKeyValue(Ent, "model", modelname);
	DispatchKeyValue(Ent, "targetname", EntName);
	DispatchSpawn(Ent);
	SetEntProp(Ent, Prop_Data, "m_iHealth", Health);
	Health_Ent[Ent] = Health;
	SDKUnhook(Ent,SDKHook_OnTakeDamagePost,SDKCallBackBreak_Damage);
	SDKHook(Ent,SDKHook_OnTakeDamagePost,SDKCallBackBreak_Damage);
	decl Float:FurnitureOrigin[3];
	decl Float:ClientOrigin[3];
	decl Float:EyeAngles[3];
	GetClientEyeAngles(client, EyeAngles);
	GetClientAbsOrigin(client, ClientOrigin);
	
	FurnitureOrigin[0] = (ClientOrigin[0] + (50 * Cosine(DegToRad(EyeAngles[1]))));
	FurnitureOrigin[1] = (ClientOrigin[1] + (50 * Sine(DegToRad(EyeAngles[1]))));
	FurnitureOrigin[2] = (ClientOrigin[2] + KvGetNum(kv, "height", 100));
	
	TeleportEntity(Ent, FurnitureOrigin, NULL_VECTOR, NULL_VECTOR);
	SetEntityMoveType(Ent, MOVETYPE_VPHYSICS);   
    
	CloseHandle(kv);
	
	iPropNo[client] += 1;
	
	return;
}

public SDKCallBackBreak_Damage(entity, attacker, inflictor, Float:damage, damagetype)
{
	if (entity <=0 || !IsValidEntity(entity))
	{
		SDKUnhook(entity,SDKHook_OnTakeDamagePost,SDKCallBackBreak_Damage);
		return;
	}
	Health_Ent[entity]-= RoundToFloor(damage);
	if (Health_Ent[entity]<=0)
	{
		BreakIt(entity);
	}
	
	SetHudTextParams(-1.00, -0.280, 5.00, 255, 192, 203, 255, 0, 0, 0, 0);
	ShowHudText(attacker, GetDynamicChannel(1),"|实体HP:%d|", Health_Ent[entity]);
}

stock BreakIt(entity)
{
	RemoveEntity(entity);
	SDKUnhook(entity,SDKHook_OnTakeDamagePost,SDKCallBackBreak_Damage);
	Health_Ent[entity] = 0;
}

stock int Entity_FindByName(const char[] name, const char[] className="")
{
	if (className[0] == '\0') {
		// Hack: Double the limit to gets none-networked entities too.
		int realMaxEntities = GetMaxEntities() * 2;
		for (int entity=0; entity < realMaxEntities; entity++) {

			if (!IsValidEntity(entity)) {
				continue;
			}

			if (Entity_NameMatches(entity, name)) {
				return entity;
			}
		}
	}
	else {
		int entity = INVALID_ENT_REFERENCE;
		while ((entity = FindEntityByClassname(entity, className)) != INVALID_ENT_REFERENCE) {

			if (Entity_NameMatches(entity, name)) {
				return entity;
			}
		}
	}

	return INVALID_ENT_REFERENCE;
}

stock bool Entity_NameMatches(int entity, const char[] name)
{
	char entity_name[128];
	Entity_GetName(entity, entity_name, sizeof(entity_name));

	return StrEqual(name, entity_name);
}

stock int Entity_GetName(int entity, char[] buffer, int size)
{
	return GetEntPropString(entity, Prop_Data, "m_iName", buffer, size);
}

stock bool Client_IsAdmin(int client)
{
	AdminId adminId = GetUserAdmin(client);

	if (adminId == INVALID_ADMIN_ID) {
		return false;
	}

	return GetAdminFlag(adminId, Admin_Generic);
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

stock bool Client_IsValid(int client, bool checkConnected=true)
{
	if (client > 4096) {
		client = EntRefToEntIndex(client);
	}

	if (client < 1 || client > MaxClients) {
		return false;
	}

	if (checkConnected && !IsClientConnected(client)) {
		return false;
	}

	return true;
}