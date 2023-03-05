# CounterStats

[![Gamedata](https://github.com/Mooshua/CounterStats/actions/workflows/gamedata.yml/badge.svg)](https://github.com/Mooshua/CounterStats/actions/workflows/gamedata.yml) [![Plugins](https://github.com/Mooshua/CounterStats/actions/workflows/plugins.yml/badge.svg)](https://github.com/Mooshua/CounterStats/actions/workflows/plugins.yml)

Developer Kit for working with internal Counter-Strike stats.

### What's this?

CS:GO automatically aggregates and stores a ton of player statistics, which are often used for the end-of-round fun facts.
This plugin and it's API allows you to easily fetch these stats and use them for your own purposes.

> **Warning:**
>
> Due to using many internal counter-strike structs and subroutines,
> CounterStats is extremely sensitive to game updates.
> Please check the GitHub actions to ensure that the current gamedata is correct,
> And please open an issue with your `crash.limetech.org` URL if your server crashes regardless.

### Status

- [x] Player Stats Lookup
- [x] Weapon Stats Enumeration (deagle shots missed)
- [ ] Generic Stats Enumeration (props broken)
- [ ] Fun Fact Evaluation/Enumeration (number of bomb carriers that round)
- [ ] Language Integrated Query

### Known Issues
- Stats collected by a player while controlling a bot are not attributed to the controlling player, but to the bot. **Likely WONTFIX.**

### Installation
* Compile `counterstats.sp` (or use the artifacts from the GitHub Actions)
* Move `counterstats.csgo.txt` to your server's gamedata file

### Test Suite

CounterStats exposes several admmin commands (`RCON` perms needed) which allow
you to assess CounterStats for issues.

If running any of these commands causes a crash on your server, please immediately file an issue on GitHub with a `crash.limetech.org` URL. 

Please run these commands before deploying CounterStats on servers after a major game update to ensure that all the values are still valid.

 - `cs_enumerate_weapons`: Enumerate all available weaponstats, their `StatType`s, and 
   check if they are valid.
 - `cs_debug_weapon <weapon_name>`: List all of *your* stats for the current round with the provided weapon. Example: `cs_debug_weapon weapon_negev`.

## User Guide

To begin using CounterStats, ensure the CounterStats plugin is installed on your server.
Include `counterstats.inc`, which contains all public native APIs.

Internally, each "statistic" is stored in a giant array. A `StatType` is a methodmap
wrapping an index into that array. `PlayerStats` allows you to easily access this array,
and the various enumerator APIs will help you find the `StatType` that you want.

#### Enumerating weapon stats

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