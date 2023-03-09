
#include <profiler>
#define S_TO_US (1 * 1000 * 1000)

static void Begin(Profiler profiler)
{
	profiler.Start();
}

static void End(Profiler profiler, int client, const char[] name, int iterations = 1)
{
	profiler.Stop();

	float time_us = profiler.Time * S_TO_US;
	float iter_us = time_us / iterations;

	ReplyToCommand(client, "[CS Benchmark] %48s (%05d iter): %.3fus total (%.3fus per)",
		name, iterations, time_us, iter_us);
}

#define ITER_ENUM_WEAPONSTAT 1000
#define ITER_WEAPONSTAT_GETNAME 1000
#define ITER_WEAPONSTAT_PROPERTIES 1000
#define ITER_PLAYERSTAT_CTOR 10000

static Action Command_Benchmark(int client, int nargs)
{
	Profiler profiler = new Profiler();

	Begin(profiler);
	Bench_Enum_WeaponStat();
	End(profiler, client, "WeaponStatsEnumerator.Seek(\"__none__\")", ITER_ENUM_WEAPONSTAT);

	Begin(profiler);
	Bench_WeaponStat_GetName();
	End(profiler, client, "WeaponStatsEnumerator.GetName()", ITER_ENUM_WEAPONSTAT);

	Begin(profiler);
	Bench_WeaponStat_GetValues();
	End(profiler, client, "WeaponStatsEnumerator.Kills/Shots/Hits/Damage", ITER_WEAPONSTAT_PROPERTIES);

	Begin(profiler);
	Bench_PlayerStat_Ctor();
	End(profiler, client, "PlayerStats.PlayerStats(1)", ITER_PLAYERSTAT_CTOR);

}

static int Bench_Enum_WeaponStat()
{
	int count = 0;
	for(int i = 0; i < ITER_ENUM_WEAPONSTAT; i++)
	{
		WeaponStatsEnumerator enumerator = new WeaponStatsEnumerator();
		/*do
		{
			count++;
		} while (WeaponStatsEnumerator.Next(enumerator))*/
		if(!WeaponStatsEnumerator.Seek(enumerator, "__none__"))
			count++;
	}
	return count;
}

static int Bench_WeaponStat_GetName()
{
	WeaponStatsEnumerator enumerator = new WeaponStatsEnumerator();
	int count = 0;

	for(int i = 0; i < ITER_WEAPONSTAT_GETNAME; i++)
	{
		char name[32];
		enumerator.GetName(name, sizeof(name));
		count += name[0];
	}
	return count;
}

static int Bench_WeaponStat_GetValues()
{
	WeaponStatsEnumerator enumerator = new WeaponStatsEnumerator();
	int count = 0;

	for(int i = 0; i < ITER_WEAPONSTAT_PROPERTIES; i++)
	{
		//  Performance should be equivalent for all properties.
		count += enumerator.Kills;
	}
	return count;
}

static int Bench_PlayerStat_Ctor()
{
	int count = 0;

	for(int i = 0; i < ITER_PLAYERSTAT_CTOR; i++)
	{
		//  Performance should be equivalent for all properties.
		PlayerStats player = new PlayerStats(1);
		if (player != Address_Null)
			count++;
	}
	return count;
}

#define ITER_FUNFACT_CURRENT 1000
#define ITER_FUNFACT_EVALUATE 100
#define ITER_FUNFACT_COMPILE 5

/// Benchmarks that leak memory.
static Action Command_Unsafe_Benchmark(int client, int argc)
{
	Profiler profiler = new Profiler();

	Begin(profiler);
	Bench_FunFact_Compile();
	End(profiler, client, "FunFactEnumerator.Current()/.Evaluate() - COLD", ITER_FUNFACT_COMPILE);

	Begin(profiler);
	Bench_FunFactEnumerator_Current();
	End(profiler, client, "FunFactEnumerator.Current() - HOT", ITER_FUNFACT_CURRENT);

	Begin(profiler);
	Bench_FunFact_Evaluate();
	End(profiler, client, "FunFact.Evaluate() - HOT", ITER_FUNFACT_EVALUATE);
}

static int Bench_FunFactEnumerator_Current()
{
	int count = 0;
	FunFactEnumerator enumerator = new FunFactEnumerator();

	for(int i = 0; i < ITER_FUNFACT_CURRENT; i++)
	{
		FunFact current = enumerator.Current();
		if (current != Address_Null)
			count++;
	}
	return count;
}

static int Bench_FunFact_Evaluate()
{
	int count = 0;
	FunFactEnumerator enumerator = new FunFactEnumerator();
	if (!FunFactEnumerator.UnsafeSeek(enumerator, "#funfact_killed_enemies"))
	{
		LogError("[CS Benchmarks] #funfact_killed_enemies unable to be found!");
		return 0;
	}
	FunFact current = enumerator.Current();

	for(int i = 0; i < ITER_FUNFACT_EVALUATE; i++)
	{
		FunFactResult result;
		if(current.Evaluate(RoundEnd_CTWin, result))
		{
			count += result.Player;
		}
	}
	return count;
}

static int Bench_FunFact_Compile()
{
	int count = 0;

	for(int i = 0; i < ITER_FUNFACT_COMPILE; i++)
	{
		//  Clear the compiled cache.
		ClearSdkCache__FunFact();
		FunFactEnumerator enumerator = new FunFactEnumerator();
		do
		{
			FunFact current = enumerator.Current();
			FunFactResult result;
			if(current.Evaluate(RoundEnd_CTWin, result))
				count++;
		} while(FunFactEnumerator.Next(enumerator))
	}
	return count;
}

bool Commands__Benchmark()
{
	RegAdminCmd("cs_benchmark", Command_Benchmark, ADMFLAG_RCON, "CounterStats Test Suite: Profile all methods");
	RegAdminCmd("cs_benchmark_leakmemory", Command_Unsafe_Benchmark, ADMFLAG_RCON, "CounterStats Test Suite: Profile all methods");
	return true;
}