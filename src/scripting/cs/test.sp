//  Counter-Stats test suite
#include <sourcemod>

#define COMMAND_GROUP "CounterStats_TS"

static Action Command_DumpWeapons(int client, int argc)
{
    WeaponStatsEnumerator enumerator = new WeaponStatsEnumerator();
    do
	{
		char name[32];
		enumerator.GetName(name, sizeof(name));

		ReplyToCommand(client, "[VALUES] Name: %s; Kills: %X; Shots: %X; Hits: %X; Damage: %X;", name, enumerator.Kills, enumerator.Shots, enumerator.Hits, enumerator.Damage);
        ReplyToCommand(client, "[VALID?] Name: %s; Kills: %b; Shots: %b; Hits: %b; Damage: %b;", name, enumerator.Kills.IsValid(), enumerator.Shots.IsValid(), enumerator.Hits.IsValid(), enumerator.Damage.IsValid());

	} while (WeaponStatsEnumerator.Next(enumerator));

	{
		char name[32];
		enumerator.GetName(name, sizeof(name));

		ReplyToCommand(client, "[LAST VALUES] Name: %s; Kills: %X; Shots: %X; Hits: %X; Damage: %X;", name, enumerator.Kills, enumerator.Shots, enumerator.Hits, enumerator.Damage);
        ReplyToCommand(client, "[LAST VALID?] Name: %s; Kills: %b; Shots: %b; Hits: %b; Damage: %b;", name, enumerator.Kills.IsValid(), enumerator.Shots.IsValid(), enumerator.Hits.IsValid(), enumerator.Damage.IsValid());
    }

    return Plugin_Handled;
}

static Action Command_AllForWeapon(int client, int argc)
{
    if (argc != 1)
    {
        ReplyToCommand(client, "[CS] Usage: cs_debug_weapon <weapon_name>");
        return Plugin_Handled;
    }

    char weapon[32];
    GetCmdArg(1, weapon, sizeof(weapon));

	WeaponStatsEnumerator enumerator = new WeaponStatsEnumerator();
	if (WeaponStatsEnumerator.Seek(enumerator, weapon))
	{
		PlayerStats client_stats = new PlayerStats(client);

		ReplyToCommand(client, "[CS] Match | Kills: %d; Shots: %d; Hits: %d; Damage %d;", 
            client_stats.GetMatch(enumerator.Kills),
            client_stats.GetMatch(enumerator.Shots),
            client_stats.GetMatch(enumerator.Hits),
            client_stats.GetMatch(enumerator.Damage));

        ReplyToCommand(client, "[CS] Round | Kills: %d; Shots: %d; Hits: %d; Damage %d;", 
            client_stats.GetRound(enumerator.Kills),
            client_stats.GetRound(enumerator.Shots),
            client_stats.GetRound(enumerator.Hits),
            client_stats.GetRound(enumerator.Damage));
        
        ReplyToCommand(client, "[CS] Delta | Kills: %d; Shots: %d; Hits: %d; Damage %d;", 
            client_stats.GetDelta(enumerator.Kills),
            client_stats.GetDelta(enumerator.Shots),
            client_stats.GetDelta(enumerator.Hits),
            client_stats.GetDelta(enumerator.Damage));

        return Plugin_Handled;
	}

	ReplyToCommand(client, "[CS] Unable to find '%s'. Example: weapon_deagle", weapon);

	return Plugin_Handled;
} 

bool Commands__Test()
{
    RegAdminCmd("cs_debug_weapon", Command_AllForWeapon, ADMFLAG_RCON, "CounterStats Test Suite: Test local client weapon stats", COMMAND_GROUP);
    RegAdminCmd("cs_enumerate_weapons", Command_DumpWeapons, ADMFLAG_RCON, "CounterStats Test Suite: List all available weapons", COMMAND_GROUP);


    return true;
}