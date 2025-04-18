/*
 * ============================================================================
 *
 *  Zombie:Reloaded
 *
 *  File:          event.inc
 *  Type:          Core
 *  Description:   Event hooking and forwarding.
 *
 *  Copyright (C) 2009  Greyscale, Richard Helgeby
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * ============================================================================
 */

/**
 * Init function for event module.
 */
EventInit()
{
    // Hook all events used by plugin.
    EventHook();
}

/**
 * Hook events used by plugin.
 * 
 * @param unhook    If true, then unhook all events, if false, then hook.
 */ 
EventHook(bool:unhook = false)
{
    // If unhook is true, then continue.
    if (unhook)
    {
        // Unhook all events.
        UnhookEvent("round_start", EventRoundStart);
        UnhookEvent("round_freeze_end", EventRoundFreezeEnd);
        UnhookEvent("round_end", EventRoundEnd);
        UnhookEvent("player_team", EventPlayerTeam, EventHookMode_Pre);
        UnhookEvent("player_spawn", EventPlayerSpawn);
        UnhookEvent("player_hurt", EventPlayerHurt);
        UnhookEvent("player_death", EventPlayerDeath);
        UnhookEvent("player_jump", EventPlayerJump);
        UnhookEvent("weapon_fire", EventWeaponFire);
        
        // Stop after unhooking events.
        return;
    }
    
    // Hook all events used by plugin.
    HookEvent("round_start", EventRoundStart);
    HookEvent("round_freeze_end", EventRoundFreezeEnd);
    HookEvent("round_end", EventRoundEnd);
    HookEvent("player_team", EventPlayerTeam, EventHookMode_Pre);
    HookEvent("player_spawn", EventPlayerSpawn);
    HookEvent("player_hurt", EventPlayerHurt);
    HookEvent("player_death", EventPlayerDeath);
    HookEvent("player_jump", EventPlayerJump);
    HookEvent("weapon_fire", EventWeaponFire);
}

/**
 * Event callback (round_start)
 * The round is starting.
 * 
 * @param event     The event handle.
 * @param name      Name of the event.
 * @dontBroadcast   If true, event is broadcasted to all clients, false if not.
 */
public Action:EventRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    // Forward event to sub-modules.
    OverlaysOnRoundStart();
    RoundStartOnRoundStart();
    RoundEndOnRoundStart();
    InfectOnRoundStart();
    SEffectsOnRoundStart();
    ZSpawnOnRoundStart();
    VolOnRoundStart();
    
    // Fire post round_start event.
    //CreateTimer(0.0, EventRoundStartPost);
}

/**
 * Event callback (round_start)
 * The round is starting. *Post
 * 
 * @param event     The event handle.
 * @param name      Name of the event.
 * @dontBroadcast   If true, event is broadcasted to all clients, false if not.
 */
//public Action:EventRoundStartPost(Handle:timer)
//{
    // Forward event to modules.
//}

/**
 * Event callback (round_freeze_end)
 * The freeze time is ending.
 * 
 * @param event     The event handle.
 * @param name      Name of the event.
 * @dontBroadcast   If true, event is broadcasted to all clients, false if not.
 */
public Action:EventRoundFreezeEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
    // Forward events to modules.
    RoundEndOnRoundFreezeEnd();
    InfectOnRoundFreezeEnd();
    ZSpawnOnRoundFreezeEnd();
}

/**
 * Event callback (round_end)
 * The round is ending.
 * 
 * @param event     The event handle.
 * @param name      Name of the event.
 * @dontBroadcast   If true, event is broadcasted to all clients, false if not.
 */
public Action:EventRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
    // Get all required event info.
    new reason = GetEventInt(event, "reason");
    
    // Forward event to modules.
    WeaponsOnRoundEnd();
    RoundEndOnRoundEnd(reason);
    InfectOnRoundEnd();
    SEffectsOnRoundEnd();
    RespawnOnRoundEnd();
    ZSpawnOnRoundEnd();
    VolOnRoundEnd();
}

/**
 * Event callback (player_team)
 * Client is joining a team.
 * 
 * @param event     The event handle.
 * @param name      Name of the event.
 * @dontBroadcast   If true, event is broadcasted to all clients, false if not.
 */
public Action:EventPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
    // Get all required event info.
    new index = GetClientOfUserId(GetEventInt(event, "userid"));
    new team = GetEventInt(event, "team");
    
    // Forward event to modules.
    InfectOnClientTeam(index, team);
    
    return Plugin_Handled;
}

/**
 * Event callback (player_spawn)
 * Client is spawning into the game.
 * 
 * @param event     The event handle.
 * @param name      Name of the event.
 * @dontBroadcast   If true, event is broadcasted to all clients, false if not.
 */
public Action:EventPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
    // Get all required event info.
    new index = GetClientOfUserId(GetEventInt(event, "userid"));
    
    // Forward event to modules.
    InfectOnClientSpawn(index);     // Some modules depend on this to finish first.
    AccountOnClientSpawn(index);    // Some modules depend on this to finish first.
    ClassOnClientSpawn(index);
    WeaponsOnClientSpawn(index);
    RoundStartOnClientSpawn(index);
    SEffectsOnClientSpawn(index);
    RespawnOnClientSpawn(index);
    ZTeleOnClientSpawn(index);
    ZHPOnClientSpawn(index);
    VolOnPlayerSpawn(index);
    
    // Fire post player_spawn event.
    CreateTimer(0.1, EventPlayerSpawnPost, index);
}

/**
 * Event callback (player_spawn)
 * Client is spawning into the game. *Post
 * 
 * @param event     The event handle.
 * @param name      Name of the event.
 * @dontBroadcast   If true, event is broadcasted to all clients, false if not.
 */
public Action:EventPlayerSpawnPost(Handle:timer, any:client)
{
    // If client isn't in-game, then stop.
    if (!IsClientInGame(client))
    {
        return;
    }
    
    // Forward event to modules.
    WeaponsOnClientSpawnPost(client);
    SEffectsOnClientSpawnPost(client);
    ClassOnClientSpawnPost(client);
    SpawnProtectOnClientSpawnPost(client);	// Must be executed after class attributes are applied.
}

/**
 * Event callback (player_hurt)
 * Client is being hurt.
 * 
 * @param event     The event handle.
 * @param name      Name of the event.
 * @dontBroadcast   If true, event is broadcasted to all clients, false if not.
 */
public Action:EventPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
    // Get all required event info.
    new index = GetClientOfUserId(GetEventInt(event, "userid"));
    new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    new hitgroup = GetEventInt(event, "hitgroup");
    new dmg_health = GetEventInt(event, "dmg_health");
    
    decl String:weapon[WEAPONS_MAX_LENGTH];
    GetEventString(event, "weapon", weapon, sizeof(weapon));
    
    // Forward event to modules.
    ClassAlphaUpdate(index);
    InfectOnClientHurt(index, attacker, weapon);
    AccountOnClientHurt(index, attacker, dmg_health);
    SEffectsOnClientHurt(index);
    KnockbackOnClientHurt(index, attacker, weapon, hitgroup, dmg_health);
    NapalmOnClientHurt(index, attacker, weapon);
    ZHPOnClientHurt(index);
}

/**
 * Event callback (player_death)
 * Client has been killed.
 * 
 * @param event     The event handle.
 * @param name      Name of the event.
 * @dontBroadcast   If true, event is broadcasted to all clients, false if not.
 */
public Action:EventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
    // Get the weapon name.
    decl String:weapon[WEAPONS_MAX_LENGTH];
    GetEventString(event, "weapon", weapon, sizeof(weapon));
    
    // If client is being infected, then stop.
    if (StrEqual(weapon, "zombie_claws_of_death", false))
    {
        return;
    }
    
    // Get all required event info.
    new index = GetClientOfUserId(GetEventInt(event, "userid"));
    new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    
    // Forward event to modules.
    ClassOnClientDeath(index);
    InfectOnClientDeath(index, attacker);
    VEffectsOnClientDeath(index);
    SEffectsOnClientDeath(index);
    SpawnProtectOnClientDeath(index);
    RespawnOnClientDeath(index, attacker, weapon);
    NapalmOnClientDeath(index);
    ZSpawnOnClientDeath(index);
    ZTeleOnClientDeath(index);
    ZHPOnClientDeath(index);
    VolOnPlayerDeath(index);
    RoundEndOnClientDeath();
}

/**
 * Event callback (player_jump)
 * Client is jumping.
 * 
 * @param event     The event handle.
 * @param name      Name of the event.
 * @dontBroadcast   If true, event is broadcasted to all clients, false if not.
 */
public Action:EventPlayerJump(Handle:event, const String:name[], bool:dontBroadcast)
{
    // Get all required event info.
    new index = GetClientOfUserId(GetEventInt(event, "userid"));
    
    // Fire post player_jump event.
    CreateTimer(0.0, EventPlayerJumpPost, index);
}

/**
 * Event callback (player_jump)
 * Client is jumping. *Post
 * 
 * @param event     The event handle.
 * @param name      Name of the event.
 * @dontBroadcast   If true, event is broadcasted to all clients, false if not.
 */
public Action:EventPlayerJumpPost(Handle:timer, any:client)
{
    // If client isn't in-game, then stop.
    if (!IsClientInGame(client))
    {
        return;
    }
    
    // Forward event to modules.
    JumpBoostOnClientJumpPost(client);
}

/**
 * Event callback (weapon_fire)
 * Weapon has been fired.
 * 
 * @param event     The event handle.
 * @param name      Name of the event.
 * @dontBroadcast   If true, event is broadcasted to all clients, false if not.
 */
public Action:EventWeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
    // Get all required event info.
    new index = GetClientOfUserId(GetEventInt(event, "userid"));
    decl String:weapon[32];
    GetEventString(event, "weapon", weapon, sizeof(weapon));
    
    // Forward event to modules.
    NapalmOnWeaponFire(index, weapon);
}
