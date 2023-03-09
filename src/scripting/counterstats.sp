#include <sourcemod>
#include <counterstats>

#define DEBUG 0

//	Util always comes first!
#include "cs/util.sp"

//  Include CounterStats dependencies
#include "cs/benchmark.sp"
#include "cs/enumerator.sp"
#include "cs/funfact.sp"
#include "cs/playerstats.sp"
#include "cs/stattype.sp"
#include "cs/test.sp"

public Plugin myinfo =
{
	name		= "[CS:GO] CounterStats",
	author		= "Mooshua",
	description = "Tools for working with internal counter-strike stats",
	version		= "0.1",
	url			= "https://mooshua.net/"

}

#define GAMEDATA_FILE "counterstats.csgo"

GameData Config;

public OnPluginStart()
{
	if (!SdkSetup__PlayerStats(Config))
		SetFailState("Failed SdkSetup__PlayerStats");

	//	Setup commands
	if (!Commands__Test())
		SetFailState("Failed setting up test suite");

	if (!Commands__Benchmark())
		SetFailState("Failed setting up benchmarks");

	if (!Setup__FunFact())
		SetFailState("Failed setting up fun facts");
}

public APLRes AskPluginLoad2(Handle self, bool late, char[] error, int err_max)
{
	Config = LoadGameConfigFile(GAMEDATA_FILE);

	if (GetEngineVersion() != Engine_CSGO)
		return UTIL_EarlyFail("This plugin is only compatible with CS:GO.", error, err_max);

	if (!Initialize__Enumerator(Config, error, err_max))
		return APLRes_Failure;

	if (!Initialize__PlayerStats(Config, error, err_max))
		return APLRes_Failure;

	if (!Initialize__StatType(Config, error, err_max))
		return APLRes_Failure;

	if (!Initialize__FunFact(Config, error, err_max))
		return APLRes_Failure;

	return APLRes_Success;
}

public OnPluginEnd()
{
}