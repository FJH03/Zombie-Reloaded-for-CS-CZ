#include <cstrike>
#include <zombiereloaded>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

int PlayerAimTarget[MAXPLAYERS+1];     // 记录目标的实体号，只有真人玩家才改变此数组
bool isClientZombie[MAXPLAYERS+1];     // 不区分Bot或真人玩家

bool IsAimed[MAXPLAYERS+1];            // 目标脱离准心立刻为0，只有真人玩家才改变此数组
bool IsInUse[MAXPLAYERS+1];            // 使用键状态数组，只有真人玩家才改变此数组

bool IsBotStayHere[MAXPLAYERS+1];      // Bot是否处于守点状态，完全靠USE来切换
bool IsFreeze[MAXPLAYERS+1];           // 解除命令时，用于形成等待时间
bool IsBotLookHere[MAXPLAYERS+1];      // Bot是否处于注意特定僵尸状态

float ReachGameTime[MAXPLAYERS+1];     // 记录Bot到达位置的游戏时间
float OrientGameTime[MAXPLAYERS+1];    // 记录Bot到达位置的游戏时间
float LoseFocusTime[MAXPLAYERS+1];     // 上一次准心失去目标的游戏时间（也就是最后的有目标的时间）

float fTempAngles[MAXPLAYERS+1][3];    // Bots面向Player的角度（总是会有点偏差）

public Plugin myinfo =
{
    name = "[ZR] Bots Stay Here",
    author = "Ducheese & [CNSR] FJH_03",
    description = "Players can force Bots to stand still with E key",
    version = "1.4",
    url = "<- URL ->"
}

public void OnPluginStart() 
{
    HookEvent("round_start", Event_RoundStart);
}

public int ZR_OnClientInfected(int client, int attacker, bool motherInfect, bool respawnOverride, bool respawn)
{
    IsBotStayHere[client] = false;
    IsBotLookHere[client] = false;
    isClientZombie[client] = true;
}

public void Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
    for(int i = 1; i <= MaxClients; i++)
    {
        PlayerAimTarget[i] = 0;
        isClientZombie[i] = false;
        IsAimed[i] = false;
        IsInUse[i] = false;
        IsBotStayHere[i] = false;
        IsFreeze[i] = false;
        IsBotLookHere[i] = false;
    }
}

public void OnMapStart()
{
	PrecacheSound("buttons/button24.wav", true);
    PrecacheSound("buttons/button3.wav", true);
	
    for(int i = 1; i <= MaxClients; i++)
    {
        ReachGameTime[i] = 0.0;
        OrientGameTime[i] = 0.0;
        LoseFocusTime[i] = 0.0;
    }
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
    if(IsBotStayHere[client] || IsFreeze[client])       // 控制Bot行动
    {
        if( ReachGameTime[client] - GetGameTime() > 0)  // Bot向自己行走
        {
            TeleportEntity(client, NULL_VECTOR, fTempAngles[client], NULL_VECTOR);    // 需要不间断的Teleport，并不会造成卡顿
            vel[0] = 200.0;      // 有走路动作的！
            vel[1] = 0.0;
            vel[2] = 0.0;
        }
        else                                           // Bot站立不动
        {
            buttons &= ~IN_JUMP;     // 禁止跳
            vel[0] = 0.0;
            vel[1] = 0.0;
            vel[2] = 0.0;
        }
    }

    if(IsBotLookHere[client])       // 控制Bot朝向该僵尸并攻击
    {
        if( OrientGameTime[client] - GetGameTime() > 0)
        {
            buttons |= IN_ATTACK;
            TeleportEntity(client, NULL_VECTOR, fTempAngles[client], NULL_VECTOR);    // 需要不间断的Teleport，并不会造成卡顿
        }
        else
        {
            IsBotLookHere[client] = false;    // 直接忘了写，但不影响
        }
    }

    if(IsValidClient(client, true) && !IsFakeClient(client) && !isClientZombie[client])   // 下命令者符合条件
    {
        int botTarget = GetClientAimTarget(client, true);   // 获取准心目标实体

        if(botTarget != -1 && IsValidClient(botTarget, true) && IsFakeClient(botTarget))   // 被命令者在准星，且符合条件
        {
            float fClientPosition[3], fTargetPosition[3];

            GetClientAbsOrigin(client, fClientPosition);
            GetClientAbsOrigin(botTarget, fTargetPosition);

            if(GetVectorDistance(fClientPosition, fTargetPosition) < 800)  // 被命令者在下令范围内
            {
                PlayerAimTarget[client] = botTarget;
                IsAimed[client] = true;

                if(!IsBotStayHere[botTarget] && !isClientZombie[botTarget])
                    PrintCenterText(client, "按E可以命令Bot在此处守点");
                else if(IsBotStayHere[botTarget] && !isClientZombie[botTarget])
                    PrintCenterText(client, "再次按E可以解除命令");
                else if(isClientZombie[botTarget])
                    PrintCenterText(client, "按E可以命令前方人类Bot朝该僵尸Bot攻击");

                LoseFocusTime[client] = GetGameTime();    // 只要有目标就一直在更新
            }
        }

        if(botTarget == -1 && IsAimed[client] && (GetGameTime() - LoseFocusTime[client] > 0.4))   // 如果准心失焦，之前准心瞄过Bot，且1s内没有新目标
        {
            PlayerAimTarget[client] = 0;
            IsAimed[client] = false;
            PrintCenterText(client, "");
        }

        if(!IsInUse[client] && (buttons & IN_USE) && IsAimed[client])    // 触发
        {
            botTarget = PlayerAimTarget[client];
            
            if(!IsBotStayHere[botTarget] && !isClientZombie[botTarget])   // 下达守点命令
            {
                IsBotStayHere[botTarget] = true;
                EmitSoundToClient(client, "buttons/button24.wav");
                IsFreeze[botTarget] = false;                              // 如果连续按E，不等creatimer，立刻解冻

                FakeClientCommand(botTarget, "say_team 收到守点命令！");

                float fTempPoints[3], fClientPosition[3], fTargetPosition[3];
                GetClientAbsOrigin(client, fClientPosition);
                GetClientAbsOrigin(botTarget, fTargetPosition);
                MakeVectorFromPoints(fTargetPosition, fClientPosition, fTempPoints);
                GetVectorAngles(fTempPoints, fTempAngles[botTarget]);
                ReachGameTime[botTarget] = GetGameTime() + GetVectorDistance(fClientPosition, fTargetPosition) / 200.0;
				
                CreateTimer(0.0, Timer_RadioMessages, client);
            }
            else if(IsBotStayHere[botTarget] && !isClientZombie[botTarget])   // 解除守点命令
            {
                IsBotStayHere[botTarget] = false;
                EmitSoundToClient(client, "buttons/button3.wav"); 
                IsFreeze[botTarget] = true;
                
                CreateTimer(2.0, Timer_Defreeze, botTarget);
            }
            else if(isClientZombie[botTarget])                // 下达注意指定敌人命令
            {
                for(int i = 1; i <= MaxClients; i++)
                {
                    if(IsValidClient(i, true) && IsFakeClient(i) && i!=botTarget && !isClientZombie[i])
                    {
                        if(IsTargetForward2(client, i))
                        {
                            IsBotLookHere[i] = true;
                            OrientGameTime[i] = GetGameTime() + 1.0;    // 注视1秒钟

                            float fTempPoints[3], fZombiePosition[3], fBotPosition[3];
                            GetClientAbsOrigin(botTarget, fZombiePosition);
                            GetClientAbsOrigin(i, fBotPosition);
                            MakeVectorFromPoints(fBotPosition, fZombiePosition, fTempPoints);
                            GetVectorAngles(fTempPoints, fTempAngles[i]);

                            fTempAngles[i][0] += 10.0;                 // 后坐力方向调整
                        }
                    }
                }
                EmitSoundToClient(client, "buttons/button24.wav");
            }
            IsInUse[client] = true;
        }
        else if(IsInUse[client] && !(buttons & IN_USE))    // 松开
        {
            IsInUse[client] = false;
        }
    }

    return Plugin_Continue;
}

bool IsTargetForward2(int client, int target)
{
    float fClientAngles[3];
    float fClientPosition[3];
    float fTargetPosition[3];
    float fTempPoints[3];
    float fTempAngles2[3];

    GetClientEyeAngles(client, fClientAngles);
    GetClientAbsOrigin(client, fClientPosition);
    GetClientAbsOrigin(target, fTargetPosition);

    if(GetVectorDistance(fClientPosition, fTargetPosition) > 300)
        return false;

    // Angles from origin
    MakeVectorFromPoints(fClientPosition, fTargetPosition, fTempPoints);
    GetVectorAngles(fTempPoints, fTempAngles2);

    // Differenz&x
    float fDiffz = fClientAngles[1] - fTempAngles2[1];     // （z管水平方向转动）眼睛看的方向，与连线方向的夹角，欧拉角里叫做“偏航角”
    // float fDiffx = fClientAngles[0] - fTempAngles[0];     // （x管纵向方向转动）眼睛看的方向，与连线方向的夹角，欧拉角里叫做“俯仰角”

    // Correct it
    if(fDiffz < -180)
        fDiffz = 360 + fDiffz;     // 调整到在-180到+180之间

    if(fDiffz > 180)
        fDiffz = 360 - fDiffz;

    // if(fDiffx < -180)
    //     fDiffx = 360 + fDiffx;

    // if(fDiffx > 180)
    //     fDiffx = 360 - fDiffx;

    if(fDiffz >= -67.5 && fDiffz <= 67.5)
    {
        return true;
    }
    else
    {
        return false;
    }
}

public Action Timer_RadioMessages(Handle timer, int client)
{
    return Plugin_Continue;
}

public Action Timer_Defreeze(Handle timer, int client)
{
    if(!IsValidClient(client, true)) return Plugin_Continue;

    IsFreeze[client] = false;

    return Plugin_Continue;
}

stock bool IsValidClient(int client, bool bAlive = false)    // 从sika那挪过来的常用函数（要求InGame）
{
    return (client >= 1 && client <= MaxClients && IsClientInGame(client) && !IsClientSourceTV(client) && (!bAlive || IsPlayerAlive(client)));
}