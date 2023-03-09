# CounterStats

[![Gamedata](https://github.com/Mooshua/CounterStats/actions/workflows/gamedata.yml/badge.svg)](https://github.com/Mooshua/CounterStats/actions/workflows/gamedata.yml) [![Plugins](https://github.com/Mooshua/CounterStats/actions/workflows/plugins.yml/badge.svg)](https://github.com/Mooshua/CounterStats/actions/workflows/plugins.yml)

Developer Kit for working with internal Counter-Strike stats.

### What's this?

CS:GO automatically aggregates and stores a ton of player statistics, which are often used for the end-of-round fun facts.
This plugin exposes an API that allows you to fetch these statistics and use them for your own purposes--without having to hook the entire game to store it yourself. [Check out the include here!](/src/scripting/include/counterstats.inc)

 - MVP rewards? Sure!
 - Player rankings? Why not.
 - Autobalancing? Get it all in here!
 - Unethical data mining? To the moon and back :)

> **Warning**:
>
> Due to using many internal counter-strike structs and subroutines,
> CounterStats is extremely sensitive to game updates.
> Please check the GitHub actions to ensure that the current gamedata is correct,
> And please open an issue with your `crash.limetech.org` URL if your server crashes regardless.

### Status

- [x] Player Stats Lookup
- [x] Weapon Stats Enumeration (deagle shots missed)
- [x] Fun Fact Evaluation/Enumeration (number of bomb carriers that round)
- [ ] Generic Stats Enumeration (props broken)
- [ ] Custom Fun Facts (most coins picked up that round...)
- [ ] Player-To-Player stats (how many times x killed y...)
- [ ] Language Integrated Query

### Known Issues
- Stats collected by a player while controlling a bot are not attributed to the controlling player, but to the bot. **Likely WONTFIX.**

### Installation
* Compile `counterstats.sp` (or use the artifacts from the GitHub Actions)
* Move `counterstats.csgo.txt` to your server's gamedata file

### Test Suite

CounterStats exposes several admin commands (`RCON` perms needed) which allow
you to assess CounterStats for issues.

If running any of these commands causes a crash on your server, please immediately file an issue on GitHub with a `crash.limetech.org` URL showing the crash. 

Also, please run these commands before deploying CounterStats on servers after a major game update to ensure that all the values are still valid.

 - `cs_enumerate_weapons`: Enumerate all available weaponstats, their `StatType`s, and 
   check if they are valid.
 - `cs_debug_weapon <weapon_name>`: List all of *your* stats for the current round with the provided weapon. Example: `cs_debug_weapon weapon_negev`.


# Performance

CounterStats is a low level wrapper around Counter-Strike's stats tracking, with very little overhead. This generally means that all operations will be as fast as sourcemod lets them be, and in many cases this is around ~200ns. See for yourself--Hop in a server and run `cs_benchmark` and `cs_benchmark_leakmemory`. Speed is measured in microseconds (1 millionth of a second)

| Operation                       | Speed (us) | Description |
| ------------------------------- | ----- | ------- |
| `WSE.Seek("__none__")`          | 25    | Time to iterate over the entire weaponstats table
| `WSE.GetName()`                 | 0.3   | Time to retreieve the name of a single weaponstats table entry
| `WSE.Kills/S/H/D`               | 0.2   | Time to retrieve the `StatType` of a `WeaponStat`.
| `PS.PlayerStats(1)`             | 0.2   | Time to retrieve the stats _table_ for a single player
| `FFE.Current()/Evaluate() COLD` | 318   | Time to compile all sdkcalls for every `.Current()`. and `.Evaluate()` function
| `FFE.Current() HOT`             | 0.4   | Time to retrieve the current `FunFact` from an enumerator after compilation has taken place.
| `FFE.Evaluate() HOT`            | >= 2  | General amount of time it takes to execute a fun fact generator after compilation has taken place..

# User Guide

To begin using CounterStats, ensure the CounterStats plugin is installed on your server.
Include `counterstats.inc`, which contains all public native APIs.

Internally, each "statistic" is stored in a giant array. A `StatType` is a methodmap
wrapping an index into that array. `PlayerStats` allows you to easily access this array,
and the various enumerator APIs will help you find the `StatType` that you want.

## FunFacts

FunFacts expose the API used by counter strike to show end-of-round fun facts. Currently, it only allows you to execute fun fact generators and enumerate over all available ones. Use `cs_enumerate_funfact` to see all available fun facts! (Note--not all fun facts are available for every gamemode!)

> **Warning**:
> 
> When using fun facts, all objects returned from `FunFactEnumerator.Current()` and `FunFact.Evaluate()` **leak small amounts of memory**. In a future update, you will be able to free this memory using a methodmap.
>
> If you do not want to free the objects, please ensure that you create as little as possible to avoid running up a tab of memory. Every call produces a new object--there is _no_ caching.
>
> **Ideally, you should cache all fun facts at round start and exclusively use that cache.** `FunFacts` are safe to serialize as `any`s.

### Get FunFact by Translation String

Translation strings (aka "Names") can be used to consistently find a specific FunFact.

```cpp
FunFactEnumerator enumerator = new FunFactEnumerator();
do
{
	FunFact current = enumerator.Current();
  
	char name[128];	// make sure name is long enough!
	current.GetName(name, sizeof(name));

	if (StrEqual(name, "#funfact_kill_defuser"))
		return true; // found!

  	// todo: Free memory here!
} while (FunFactEnumerator.Next(enumerator));
return false; // not found!
```

### What are the "data" fields for?
The data fields are used for string formatting. You can see the format strings for a funfact by looking in `resource/csgo_<yourlanguage>.txt` and searching for "funfact".

`%s1` is subject, while `%s2-4` are the data entries.

For example:

```lua
"funfact_ct_win_no_kills"					"Counter-Terrorists won without killing any Terrorists."
"funfact_t_win_no_kills"					"Terrorists won without killing any Counter-Terrorists."
"funfact_t_win_no_casualties"				"Terrorists won without taking any casualties."
"funfact_ct_win_no_casualties"				"Counter-Terrorists won without taking any casualties."
"funfact_best_terrorist_accuracy"			"%s1 had an accuracy of %s2%, while their team's was %s3%."
"funfact_best_counterterrorist_accuracy"	"%s1 had an accuracy of %s2%, while their team's was %s3%."
```

### What's the round end for?
The "roundend" is used by Counter-Strike to determine whether or not the fun fact *should* be displayed.
If it doesn't think it should, then it will prevent it from being displayed. In most cases, this *has* to be `CTWin` or `TerroristWin`, while others will be only defuse, etc.
For this reason, it is important that you pass in a value relevant to the current round (or the type of statistic you want to get).

### Execute a FunFact and get it's result

```cpp
//	Get a FunFact somehow
FunFact current = enumerator.Current();

//  Now evaluate it
FunFactResult result;
if (current.Evaluate(RoundEnd_CTWin /*any reason except surrenders should work for most*/, result))
{
	//	Success!
	//	Now we can use "result".
	//	For example, get the data entries:
	int data[3];
	result.GetData(data, sizeof(data));
}

```

## WeaponStats

WeaponStats allow you to see how many times a player killed with, shot, hit a shot, and how much damage a player did with a specific weapon.

### Enumerating weapon stats

Using the methodmap `WeaponStatsEnumerator`, you can enumerate all available weapon stat
types. Make sure to use a `do {} while` and not a `while {}` loop for enumeration.

```cpp
WeaponStatsEnumerator enumerator = new WeaponStatsEnumerator();

do
{
	//  Do something with enumerator
	//  For example, get the lookup index of kills for this weapon:
	StatType kills = enumerator.Kills;

	//  Then look this up for a specific client
	PlayerStats player = new PlayerStats(player_index);
	int kill_count = player.GetMatch(kills);
} while (WeaponStatsEnumerator.Next(enumerator));
```

### Get stats for a specific weapon

You can use the static convenience method `WeaponStatsEnumerator.Seek` to seek the **next**
weapon entry that matches the provided name.
This method returns true if a matching entry was found--false otherwise.

(Note--If you have already called `.Next` or `.Seek` on the provided enumerator, don't use this! It *will* cause issues!)
```cpp
WeaponStatsEnumerator enumerator = new WeaponStatsEnumerator();

if (!WeaponStatsEnumerator.Seek(enumerator, "weapon_deagle"))
{
	LogError("Can't find weapon_deagle!");
	return;
}

//  Now do whatever with enumerator
PlayerStats player = new PlayerStats(player_index);
int kill_count = player.GetMatch(enumerator.Kills);
```

### Looking up player statistics

Using the methodmap `PlayerStats`, you can lookup stats for a specific player:

```cpp
PlayerStats stats_for_player = new PlayerStats(client_index);
//  Get the value of stat index "1" for the current round
stats_for_player.GetRound(1);
//  Get the value for the current match (map)
stats_for_player.GetMatch(1);
//  Get the value for the past 2-3 seconds.
//  This value is cleared continuously!
stats_for_player.GetDelta(1);
```