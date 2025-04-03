#include <sdktools>
#include <sourcemod>
#include <cstrike>

public Plugin myinfo = 
{
	name = "Admin Fix",
	author = "[CNSR] FJH_03 & [CNSR] Oreo922 & [CNSR] xiaodo",
	description = "修复服务端管理员授权",
	version = SOURCEMOD_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnClientConnected(int client) {
	CreateTimer(5.0, solvename, client);
}

Action:solvename(Handle timer, int client) {
	if (!IsFakeClient(client)) {
		char originalName[64];
		GetClientName(client, originalName, sizeof(originalName));
		
		// 创建新的名字
		char newName[64];
		Format(newName, sizeof(newName), "%s ", originalName);
		
		// 设置新名字
		SetClientName(client, newName);
		
		//设置旧名字
		SetClientName(client, originalName);
	}
}