#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>


bool DEBUGGING = false;

// csgo/scripts/game_sound_...
// ctmap_ and tmap_ are map positions for bots
char g_radioSounds[][] = {
	"affirmative",
	"agree",
	"blinded",
	"bombexploding",
	"bombsiteclear",
	"bombtickingdown",
	"clearedarea",
	"commanderdown",
	"coveringfriend",
	"coverme",
	"decoy",
	"defendingbombsitea",
	"defendingbombsiteb",
	"defusingbomb",
	"disagree",
	"endclean",
	"endclose",
	"endsolid",
	"enemydown",
	"enemyspotted",
	"fallback",
	"flashbang",
	"followingfriend",
	"followme",
	"friendlyfire",
	"goingtodefendbombsite",
	"goingtoguardhostageescapezone",
	"goingtoguardloosebomb",
	"goingtoplantbomb",
	"goingtoplantbomba",
	"goingtoplantbombb",
	"grenade",
	"guardingloosebomb",
	"heardnoise",
	"help",
	"incombat",
	"inposition",
	"killedfriend",
	"lastmanstanding",
	"letsgo",
	"locknload",
	"lostenemy",
	"molotov",
	"needbackup",
	"negative",
	"niceshot",
	"noenemiesleft",
	"noenemiesleftbomb",
	"onarollbrag",
	"oneenemyleft",
	"onmyway",
	"peptalk",
	"pinneddown",
	"plantingbomb",
	"query",
	"regroup",
	"reportingin",
	"requestreport",
	"scaredemote",
	"smoke",
	"sniperkilled",
	"sniperwarning",
	"spottedbomber",
	"spottedloosebomb",
	"takingfire",
	"thanks",
	"theypickedupthebomb",
	"threeenemiesleft",
	"time",
	"twoenemiesleft",
	"waitingforhumantodefusebomb",
	"waitinghere",
	"whereisthebomb",
	"gameafkbombdrop",
	"needdrop",
	"goa",
	"gob",
	"sorry",
	"go",
	"getinpos",
	"stormfront",
	"report",
	"takepoint",
	"holdpos",
	"sticktog",
	"roger",
	"enemyspot",
	"sectorclear",
	"getout",
	"hold",
	"clear",
	"moveout",
	"fireinthehole",
}

#define MAXMODEL 200
char g_radioFiles[MAXMODEL][93][512];
char g_model[MAXMODEL][512];
int modelcount;

public Plugin myinfo =
{
	name = "[ZR] Custom Radio Sound",
	author = "Kento & [CNSR] FJH_03",
	version = "1.22",
	description = "Custom Radio Sound.",
	url = "http://steamcommunity.com/id/kentomatoryoshika/"
};

public void OnPluginStart() 
{	
	// For disable default radio sound.
	AddNormalSoundHook(Event_SoundPlayed);
	
	// Grenades
	HookUserMessage(GetUserMessageId("RadioText"), RadioText, true);
	HookUserMessage(GetUserMessageId("SendAudio"), SendAudioNew, true);
	HookEvent("round_end", RoundEnd_Radio, EventHookMode_Post);

	if(DEBUGGING)	RegAdminCmd("sm_radiomodels", Command_Model, ADMFLAG_ROOT);
}

void FindSampleByCmd(const char[] command, char[] sample, int maxlen)
{
	if(StrContains(command, "requestmove") != -1)						strcopy(sample, maxlen, "letsgo");
	else if(StrContains(command, "roundstart") != -1)						strcopy(sample, maxlen, "locknload");
	// else if(StrContains(command, "sticktog") != -1)					strcopy(sample, maxlen, "regroup");	
	else if(StrContains(command, "sticktogetherteam") != -1)			strcopy(sample, maxlen, "sticktog");	
	else if(StrContains(command, "sticktogether") != -1)				strcopy(sample, maxlen, "regroup");	
	// else if(StrContains(command, "holdpos") != -1)					strcopy(sample, maxlen, "hold");	
	//else if(StrContains(command, "affirmation") != -1)					strcopy(sample, maxlen, "affirmative");	
	// else if(StrContains(command, "roger") != -1)						strcopy(sample, maxlen, "affirmative");	
	else if(StrContains(command, "cheer") != -1)						strcopy(sample, maxlen, "onarollbrag");	
	else if(StrContains(command, "compliment") != -1)				strcopy(sample, maxlen, "onarollbrag");	
	// else if(StrContains(command, "enemyspot") != -1)					strcopy(sample, maxlen, "enemyspotted");	
	else if(StrContains(command, "seesenemy") != -1)					strcopy(sample, maxlen, "enemyspotted");	
	// else if(StrContains(command, "takepoint") != -1)					strcopy(sample, maxlen, "followingfriend");
	// else if(StrContains(command, "sectorclear") != -1)				strcopy(sample, maxlen, "clear");
	// else if(StrContains(command, "getout") != -1)					strcopy(sample, maxlen, "bombtickingdown");
	// else if(StrContains(command, "getoutofthere") != -1)				strcopy(sample, maxlen, "bombtickingdown");
	//else if(StrContains(command, "fireinthehole") != -1)				strcopy(sample, maxlen, "grenade");
	else if(StrContains(command, "molotovinthehole") != -1)			strcopy(sample, maxlen, "molotov");
	else if(StrContains(command, "flashbanginthehole") != -1)		strcopy(sample, maxlen, "flashbang");
	else if(StrContains(command, "smokeinthehole") != -1)			strcopy(sample, maxlen, "smoke");
	else if(StrContains(command, "decoyinthehole") != -1)			strcopy(sample, maxlen, "decoy");
	else if(StrContains(command, "negativeno") != -1)				strcopy(sample, maxlen, "negative");
	else if(StrContains(command, "requestweapon") != -1)				strcopy(sample, maxlen, "needdrop");
	else if(StrContains(command, "gotoa") != -1)							strcopy(sample, maxlen, "goa");
	else if(StrContains(command, "gotob") != -1)							strcopy(sample, maxlen, "gob");
	else if(StrContains(command, "goa") != -1)							strcopy(sample, maxlen, "goa");
	else if(StrContains(command, "gob") != -1)							strcopy(sample, maxlen, "gob");
	// else if(StrContains(command, "go") != -1)							strcopy(sample, maxlen, "letsgo");
	else if(StrContains(command, "holdthisposition") != -1)							strcopy(sample, maxlen, "holdpos");
	else if(StrContains(command, "gogogo") != -1)							strcopy(sample, maxlen, "go");
	//else if(StrContains(command, "letsgo") != -1)							strcopy(sample, maxlen, "go");
	else if(StrContains(command, "enemyspotted") != -1)					strcopy(sample, maxlen, "enemyspot");
	else if(StrContains(command, "clear") != -1)				strcopy(sample, maxlen, "sectorclear");
	else if(StrContains(command, "youtakethepoint") != -1)				strcopy(sample, maxlen, "takepoint");
	else if(StrContains(command, "stormthefront") != -1)				strcopy(sample, maxlen, "stormfront");
	else if(StrContains(command, "hold") != -1)					strcopy(sample, maxlen, "holdpos");
	else if(StrContains(command, "getinpositionandwait") != -1)					strcopy(sample, maxlen, "getinpos");
	else if(StrContains(command, "affirmative") != -1)					strcopy(sample, maxlen, "roger");
	else if(StrContains(command, "affirmation") != -1)					strcopy(sample, maxlen, "roger");	
	else if(StrContains(command, "rogerthat") != -1)					strcopy(sample, maxlen, "roger");
	else strcopy(sample, maxlen, command);
}

// grenades, planting, defusing and bot chats are radio text
public Action RadioText(UserMsg msg_id, Handle msg, const int[] players, int playersNum, bool reliable, bool init)
{
	/*
	https://github.com/alliedmodders/hl2sdk/blob/csgo/public/game/shared/csgo/protobuf/cstrike15_usermessages.proto#L268
	------------------------------------
	optional int32 msg_dst = 1;
	optional int32 client = 2;
	optional string msg_name = 3;
	repeated string params = 4;
	
	params strings cs_bloodstrike
	------------------------------------
	0 - #ENTNAME[2]Tim
	1 - #Cstrike_TitlesTXT_Sector_clear

	params strings de_inferno
	------------------------------------
	0 - #ENTNAME[8]Tom
	1 - Middle
	2 - #SFUI_TitlesTXT_Smoke_in_the_hole
	3 - auto
	
	csgo/resource/csgo_...
	------------------------------------
	"[english]SFUI_TitlesTXT_Fire_in_the_hole"	"Fire in the hole!"
	"[english]SFUI_TitlesTXT_Molotov_in_the_hole"	"FireBomb on the way!"
	"[english]SFUI_TitlesTXT_Flashbang_in_the_hole"	"Flashbang Out!"
	"[english]SFUI_TitlesTXT_Smoke_in_the_hole"	"Smoke Out!"
	"[english]SFUI_TitlesTXT_Decoy_in_the_hole"	"Decoy Out!"
	*/
	
	if(DEBUGGING)	PrintToServer("RadioText");
	
	char sBuffer[128];
	char buffer[64], sample[64];
	int TempInt = BfReadByte(msg);
	
	int client = BfReadByte(msg);	
	//int client = PbReadInt(msg, "client");
	char model[512];
	GetClientModel(client, model, sizeof(model));
	int mid = FindModelIDByName(model);
		
	BfReadString(msg, sBuffer, sizeof(sBuffer));
	if(strcmp(sBuffer, "#Game_radio_location", false) == 0)
    {
        BfReadString(msg, sBuffer, sizeof(sBuffer));
    }
	BfReadString(msg, sBuffer, sizeof(sBuffer));
	
	// for maps have zones
	//PbReadString(msg, "params", buffer, sizeof(buffer), 1);
	BfReadString(msg, buffer, sizeof(buffer));
	// for maps doesn't have zones
	// if( StrContains(buffer,"#Cstrike_TitlesTXT_") == -1 && StrContains(buffer,"#SFUI_TitlesTXT_") == -1)
		// PbReadString(msg, "params", buffer, sizeof(buffer), 2);

	if(DEBUGGING)	PrintToServer("params %s", buffer);
	ReplaceString(buffer, sizeof(buffer), "#Cstrike_TitlesTXT_", "", false);
	ReplaceString(buffer, sizeof(buffer), "#SFUI_TitlesTXT_", "", false);
	ReplaceString(buffer, sizeof(buffer), "_", "", false);

	for(int i = 0; i <= strlen(buffer); ++i) 
	{ 
		buffer[i] = CharToLower(buffer[i]); 
	} 

	FindSampleByCmd(buffer, sample, sizeof(sample));
	int rid = FindRadioBySample(sample);

	if(DEBUGGING)	PrintToServer("buf: %s, sample: %s, mid %d, rid %d, playersNum: %d, model - %s", buffer, sample, mid, rid, playersNum, model);
	
	if(mid > -1 && rid > -1)
	{
		DataPack pack;		
		CreateDataTimer(0.0, SendAudio, pack, TIMER_FLAG_NO_MAPCHANGE);
		pack.WriteCell(mid);
		pack.WriteCell(rid);
		pack.WriteCell(client);
		pack.WriteCell(playersNum);
		
		for(int i = 0; i < playersNum; i++)
		{
			pack.WriteCell(players[i]);
			if(DEBUGGING)	PrintToServer("players %d, %N", i, players[i]);
			if(DEBUGGING)	PrintToServer("客户端索引： %d", client);
		}

		pack.Reset();
		
		char sound[512];
		
		
		char SoundName[50], SoundStr[512];
		Format(SoundStr, sizeof(SoundStr), "%s", g_radioFiles[mid][rid]);
		char ArgumentStr[10][50];
		int num = 0;
		num = ExplodeString(SoundStr, "/", ArgumentStr, 10, 50);
		strcopy(SoundName, sizeof(SoundName), ArgumentStr[num-1]);
		char PreStr[] = "radio/";
		Format(sound, sizeof(sound), "%s%s", PreStr, SoundName);
		
		
		if(DEBUGGING)	PrintToServer("阻止: %s", sound);
		
		if(!StrEqual(sound, "") && !StrEqual(sound, "*/"))
		    StopSound(client, SNDCHAN_VOICE, sound);
		// if(StrEqual(sample, "go"))
		// {
			// StopSound(client, SNDCHAN_VOICE, "radio/letsgo.wav");
			// StopSound(client, SNDCHAN_VOICE, "radio/go.wav");
		// }
		if(StrEqual(sample, "roger"))
			StopSound(client, SNDCHAN_VOICE, "radio/ct_affirm.wav");
		
		//return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action SendAudio(Handle timer, DataPack pack)
{
	int mid = pack.ReadCell();
	int rid = pack.ReadCell();
	int MyClient = pack.ReadCell();
	int playersNum = pack.ReadCell();
	int[] players = new int [playersNum];
	int count, client;
	for(int i = 0; i < playersNum; i++)
	{
		client = pack.ReadCell();
		if(IsValidClient(client) && !IsFakeClient(client))
		{
			players[count] = client;
			count++;
		}
	}
	playersNum = count;
	
	char sound[512];
	//Format(sound, sizeof(sound), "*/%s", g_radioFiles[mid][rid]);
	Format(sound, sizeof(sound), "%s", g_radioFiles[mid][rid]);
	if(DEBUGGING)	PrintToServer("客户端: %d,%s", players[0],sound);
	if(!StrEqual(sound, "") && !StrEqual(sound, "*/"))
	{
		for(int i = 0; i < playersNum; i++)
		{
			EmitSoundToClient(players[i], sound, players[i], SNDCHAN_VOICE);
		}
		// EmitSound(players, playersNum, sound, MyClient, SNDCHAN_VOICE);
	}
	
	// we don't need this
	// https://forums.alliedmods.net/showthread.php?p=2523676
	// delete pack;
}

public void OnMapStart() 
{
	LoadRadio();
}

// For disable default radio sound.
public Action Event_SoundPlayed(int clients[64], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags)
{
	// +playervophoenixclear02.wav
	// csgo/scripts/game_sound...
	
	// Is player voice
	// PrintToChatAll("%s", sample);
	// +player\vo\leet\threeenemiesleft03.wav
	
	if(DEBUGGING)	PrintToServer("实体索引:%d", entity);
	//if(StrContains(sample, "player") != -1 && IsValidEntity(entity) && entity > 0 && entity <= MaxClients)
	if(IsValidEntity(entity) && entity > 0 && entity <= MaxClients)
	{
		ReplaceString(sample, sizeof(sample), ".wav", "", false);
		ReplaceString(sample, sizeof(sample), "_", "", false);

		char model[512];
		GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));
		int mid = FindModelIDByName(model);

		// Has found model id.
		if (mid > -1)
		{
			int rid = -1;
		
			// player/death1.wav
			if(StrContains(sample, "death") != -1)
			{
				rid = FindRadioBySample("death");
				if(DEBUGGING)	PrintToServer("hook sample: death, mid %d, rid %d, model - %s", mid, rid, model);

				// Has found radio id
				if (rid > -1)
				{
					// Re-use "sample" buffer
					Format(sample, sizeof(sample), "*/%s", g_radioFiles[mid][rid]);
					// Get the position of the entity that emitted the sound on the map
					float position[3];
					GetEntPropVector(entity, Prop_Send, "m_vecOrigin", position);
					if (ArrayDeleteItem(clients, numClients, entity))
					{
						// The entity is found in the "clients" array and has been removed successfully.
						// Another emit especially for the entity since it's their own voice.
						// So "updatePos" = true for the entity.
						// EmitSoundToClient(entity, sample, entity, channel, level, (volume == SNDVOL_NORMAL) ? SND_NOFLAGS : SND_CHANGEVOL, volume);

						// Since the entity within "clients" array is removed from the array.
						// Correct the size of the array.
						numClients = numClients - 1;
					}

					// Can use the "clients" array since the game engine already take care of which clients should be able to hear the sound.
					// Hence, no need to check team for radio emit. And death groan can be heard by everyone (including enemies).
					// param "updatePos" = false means the sound will not change its position to follow the entities hearing the sound.
					// EmitSound(clients, numClients, sample, entity, channel, level, (volume == SNDVOL_NORMAL) ? SND_NOFLAGS : SND_CHANGEVOL, volume, SNDPITCH_NORMAL, -1, position, NULL_VECTOR, false);
					return Plugin_Stop;
				}
			}
			else
			{
				char radio[4][64];
				ExplodeString(sample, "\\", radio, sizeof(radio), sizeof(radio[]));	
				FindSampleByCmd(radio[3], radio[3], sizeof(radio[]));
				rid = FindRadioBySample(radio[3]);
				if(DEBUGGING)	PrintToServer("hook sample: %s, mid %d, rid %d, model - %s", radio[3], mid, rid, model);

				if (rid > -1)
				{
					Format(sample, sizeof(sample), "*/%s", g_radioFiles[mid][rid]);
					// updatePos = true will make the sound update its position follow to the hearing entity
					// Since this is radio sound, all clients (that should be able to hear) should hear the sound as if it's next to their ears.
					// EmitSound(clients, numClients, sample, entity, channel, level, (volume == SNDVOL_NORMAL) ? SND_NOFLAGS : SND_CHANGEVOL, volume);
					return Plugin_Stop;
				}
			}
		}
	}
	
	return Plugin_Continue;
}

int FindRadioBySample(char [] sample)
{
	int r = -1;
	for (int i = 0; i < sizeof(g_radioSounds); i++)
	{
		if(StrContains(sample, g_radioSounds[i]) != -1){
			r = i;
			break;
		}
	}
	return r;
}

int FindModelIDByName(char [] model)
{
	int r = -1;
	for (int i = 0; i < modelcount; i++)
	{
		if(StrContains(model, g_model[i]) != -1) 
		{
			r = i;
			break;
		}
	}
	return r;
}

void LoadRadio()
{
	char Configfile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, Configfile, sizeof(Configfile), "configs/kento_radio.cfg");
	
	if (!FileExists(Configfile))
	{
		SetFailState("Fatal error: Unable to open configuration file \"%s\"!", Configfile);
	}
	
	KeyValues kv = CreateKeyValues("Radio");
	kv.ImportFromFile(Configfile);
	
	if(!kv.GotoFirstSubKey())
	{
		SetFailState("Fatal error: Unable to read configuration file \"%s\"!", Configfile);
	}
	
	char model[512], file[512];
	modelcount = 0;
	do
	{
		kv.GetSectionName(model, sizeof(model));
		strcopy(g_model[modelcount], sizeof(g_model[]), model);
		
		for (int i = 0; i < sizeof(g_radioSounds); i++)
		{
			kv.GetString(g_radioSounds[i], file, sizeof(file), "");
			
			if(!StrEqual(file, ""))
			{
				PrecacheSound(file);
				
				char filepath[512];
			    Format(filepath, sizeof(filepath), "sound/%s", file)
				AddFileToDownloadsTable(filepath);
				
				char soundpath[512];
				Format(soundpath, sizeof(soundpath), "*/%s", file);
				FakePrecacheSound(soundpath);
				
				strcopy(g_radioFiles[modelcount][i], sizeof(g_radioFiles[][]), file);
			}		
		}
		modelcount++;
	} while (kv.GotoNextKey());
	
	kv.Rewind();
	delete kv;
}

stock bool IsValidClient(int client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	if (!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}

stock int FindIndex(int[] array, int length, int item)
{
	for (int i = 0; i < length; i++)
	{
		if (array[i] == item)
		{
			return i;
		}
	}
	return -1;
}

bool ArrayDeleteItem(int[] array, int length, int item)
{
	int index = FindIndex(array, length, item);
	if (index == -1)
	{
		return false;
	}
	else
	{
		int lastIndex = length - 1;
		if (lastIndex == index)
		{
			array[index] = 0;
		}
		else
		{
			for (int i = index + 1; i < length; i++)
			{
				array[i - 1] = array[i];
			}
		}
		return true;
	}
}

// https://wiki.alliedmods.net/Csgo_quirks
stock void FakePrecacheSound(const char[] szPath)
{
	AddToStringTable(FindStringTable("soundprecache"), szPath);
}

public Action Command_Model(int client, int args){
	PrintToConsole(client, "Models: %d", modelcount);
	for (int i = 0; i < modelcount; i++)
	{
		PrintToConsole(client, "%d - %s", i, g_model[i]);
	}
	return Plugin_Handled;
}


public Action SendAudioNew(UserMsg msg_id, Handle msg, const int[] players, int playersNum, bool reliable, bool init)
{
	char sBuffer[128];
	char classname[64];
	int TempInt = BfReadByte(msg);
	
	int client = BfReadByte(msg);	
	//int client = PbReadInt(msg, "client");		
	BfReadString(msg, sBuffer, sizeof(sBuffer));
	
	ReplaceString(sBuffer, sizeof(sBuffer), "dio.", "", false);
	// PrintToServer("声音内容old： %s", sBuffer);
	
	if(StrEqual(sBuffer, "moveout") || StrEqual(sBuffer, "locknload") || StrEqual(sBuffer, "go") || StrEqual(sBuffer, "letsgo"))
	{
		if(playersNum > 0)
		{
			if(players[0] <= MaxClients && IsClientConnected(players[0]) && IsClientInGame(players[0]) && GetClientTeam(players[0]) == CS_TEAM_T)
			{
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}


public Action:RoundEnd_Radio(Handle:event, const String:name[], bool:dontBroadcast) 
{
	decl winner;
    if((winner = GetEventInt(event, "winner")) > 1)
    {
        for(new i = 1; i < MaxClients; i++)
        {
            if(IsClientConnected(i) && IsClientInGame(i))
            {
                StopSound(i, -2, winner == 2 ? "radio/terwin.wav":"radio/ctwin.wav");				
				// PrintToServer("胜利方： %d", winner);
				if(winner == 2)    //匪徒胜利
				{
					if(GetClientTeam(i) == CS_TEAM_T)
					{
						DataPack pack = new DataPack();
						pack.WriteCell(1);
						pack.WriteCell(i);
						CreateTimer(0.5, task_Clean4, pack);
					}
					else
					{
						DataPack pack = new DataPack();
						pack.WriteCell(2);
						pack.WriteCell(i);
						CreateTimer(0.5, task_Clean4, pack);
					}
				}
				if(winner == 3)    //警察胜利
				{
					if(GetClientTeam(i) == CS_TEAM_T)
					{
						DataPack pack = new DataPack();
						pack.WriteCell(3);
						pack.WriteCell(i);
						CreateTimer(0.5, task_Clean4, pack);
					}
					else
					{
						DataPack pack = new DataPack();
						pack.WriteCell(4);
						pack.WriteCell(i);
						CreateTimer(0.5, task_Clean4, pack);
					}
				}					
            }
        }		
    }
}


public Action:task_Clean4(Handle:Timer, DataPack pack)
{
	pack.Reset(); 
	int TempNum = pack.ReadCell();
	int player = pack.ReadCell();
	CloseHandle(pack);
	if(IsClientInGame(player)) {
		if(TempNum == 2)
			EmitSoundToClient(player, "radio/terwin.wav", player, SNDCHAN_VOICE, _, SND_STOP);
		else
			EmitSoundToClient(player, "radio/ctwin.wav", player, SNDCHAN_VOICE, _, SND_STOP);
	}
	
}