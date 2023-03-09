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

static Action Command_DumpFunFacts(int client, int argc)
{
	FunFactEnumerator enumerator = new FunFactEnumerator();
	do
	{
		FunFact current = enumerator.Current();

		char name[32];
		current.GetName(name, sizeof(name));

		ReplyToCommand(client, "[FUNFACT] Name: %s; Id: %d; Prestige: %f", name, current.Id, current.Prestige);

	} while (FunFactEnumerator.Next(enumerator));
}

static Action Command_DebugFunFact(int client, int argc)
{
	if (argc != 1)
	{
		ReplyToCommand(client, "[CS] Usage: cs_debug_funfact <funfact_name>");
		return Plugin_Handled;
	}

	char funfact[128];
	GetCmdArg(1, funfact, sizeof(funfact));

	FunFactEnumerator enumerator = new FunFactEnumerator();
	if (FunFactEnumerator.UnsafeSeek(enumerator, funfact))
	{
		char name[128];

		FunFact current = enumerator.Current();
		current.GetName(name, sizeof(name));
		ReplyToCommand(client, "[CS] FunFact %d; Prestige: %f; Name: %s", current.Id, current.Prestige, name);

		//  Now evaluate it
		FunFactResult result;
		if (current.Evaluate(RoundEnd_CTWin, result))
		{
			ReplyToCommand(client, "[CS] Evaluated! Id %d; Subject %d; Magnitude: %f", result.Id, result.Player, result.Magnitude);
			int data[3];
			result.GetData(data, sizeof(data));
			ReplyToCommand(client, "[CS] Data: %d %d %d", data[0], data[1], data[2]);

			return Plugin_Handled;
		}

		ReplyToCommand(client, "[CS] Unable to evaluate '%s' for RoundEnd_CTWin.", name);
		return Plugin_Handled;
	}

	ReplyToCommand(client, "[CS] Unable to find '%s'. Example: #funfact_knife_kills", funfact);

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
	RegAdminCmd("cs_debug_funfact", Command_DebugFunFact, ADMFLAG_RCON, "CounterStats Test Suite: Test funfact stats", COMMAND_GROUP);
	RegAdminCmd("cs_debug_weapon", Command_AllForWeapon, ADMFLAG_RCON, "CounterStats Test Suite: Test local client weapon stats", COMMAND_GROUP);
	RegAdminCmd("cs_enumerate_weapons", Command_DumpWeapons, ADMFLAG_RCON, "CounterStats Test Suite: List all available weapons", COMMAND_GROUP);
	RegAdminCmd("cs_enumerate_funfact", Command_DumpFunFacts, ADMFLAG_RCON, "CounterStats Test Suite: List all available funfacts", COMMAND_GROUP);


	return true;
}