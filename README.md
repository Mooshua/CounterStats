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
- [ ] Generic Stats Enumeration (props broken)
- [x] Fun Fact Evaluation/Enumeration (number of bomb carriers that round)
- [ ] Custom Fun Facts
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

## User Guide

To begin using CounterStats, ensure the CounterStats plugin is installed on your server.
Include `counterstats.inc`, which contains all public native APIs.

Internally, each "statistic" is stored in a giant array. A `StatType` is a methodmap
wrapping an index into that array. `PlayerStats` allows you to easily access this array,
and the various enumerator APIs will help you find the `StatType` that you want.

> **Warning**:
> 
> When using fun facts, all objects returned from `FunFactEnumerator.Current()` and `FunFact.Evaluate()` **leak memory**. It is your responsibility to free these objects when they are no longer needed, to avoid use-after-free bugs.
>
> If you do not want to free the objects, please ensure that you create as little as possible to avoid running out of memory. Every call produces a new object.

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