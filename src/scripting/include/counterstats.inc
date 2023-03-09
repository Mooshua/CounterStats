
enum StatStatus
{
	/// If the weaponstat returned from WeaponStatsEnumerator is invalid,
	/// it will equal this.
	StatStatus_Invalid = 0xFFFFFFFF
};

/// See https://github.com/saul/demofile/issues/38 for a list of values.
/// Thanks, saul!
/// The reason why the round ended, provided to the fun fact manager to decide valid fun facts.
enum RoundEnd
{
	RoundEnd_TargetBombed = 1, // Target Successfully Bombed!
	// 2/3 not in use in CSGO
	RoundEnd_TerroristsEscaped = 4, // The terrorists have escaped!
	RoundEnd_CTStoppedEscape = 5, // The CTs have prevented most of the terrorists from escaping!
	RoundEnd_TerroristsStopped = 6, // Escaping terrorists have all been neutralized!
	RoundEnd_BombDefused = 7, // The bomb has been defused!
	RoundEnd_CTWin = 8, // Counter-Terrorists Win!
	RoundEnd_TerroristWin = 9, // Terrorists Win!
	RoundEnd_Draw = 10, // Round Draw!
	RoundEnd_HostagesRescued = 11, // All Hostages have been rescued!
	RoundEnd_TargetSaved = 12, // Target has been saved!
	RoundEnd_HostagesNotRescued = 13, // Hostages have not been rescued!
	RoundEnd_TerroristsNotEscaped = 14, // Terrorists have not escaped!
	RoundEnd_GameStart = 16, // Game Commencing!
	// 15 not in use in CSGO
	RoundEnd_TerroristsSurrender = 17, // Terrorists Surrender
	RoundEnd_CTSurrender = 18, // CTs Surrender
	RoundEnd_TerroristsPlanted = 19, // Terrorists Planted the bomb
	RoundEnd_CTsReachedHostage = 20, // CTs Reached the hostage
};

methodmap WeaponStatsEnumerator __nullable__
{
	/// Create a new weaponstatsenumerator.
	public native WeaponStatsEnumerator();

	/// Move the enumerator to the next value.
	/// Returns false if we have reached the end of the list, or if another error occured.
	public static native bool Next(WeaponStatsEnumerator &self);

	/// Search for the desired weapon index and return true if found.
	public static bool Seek(WeaponStatsEnumerator &self, const char[] weapon)
	{
		do
		{
			char name[32];
			self.GetName(name, sizeof(name));

			if (StrEqual(name, weapon))
				return true;
		} while (WeaponStatsEnumerator.Next(self));

		//  index not found.
		return false;
	}

	/// Writes the weapon name of the current stats block to the buffer.
	/// The name length will never exceed parameter "maxlen".
	/// Returns non-0 on failure.
	public native int GetName(char[] buffer, int maxlen);

	/// Gets a weaponstat for kills using this weapon
	property StatType Kills 
	{
		public native get();
	}

	/// Gets a weaponstat for the amount of times this weapon was fired
	/// Note: Currently invalid on non-decoy grenades and knives.
	property StatType Shots 
	{
		public native get();
	} 

	/// Gets a weaponstat for the amount of shots that hit
	/// Note: Currently invalid on non-decoy grenades and knives.
	property StatType Hits 
	{
		public native get();
	} 

	/// Gets a weaponstat for the amount of damage done by this weapon
	/// Note: Currently invalid on non-decoy grenades and knives.
	property StatType Damage 
	{
		public native get();
	} 
};

methodmap PlayerStats __nullable__
{
	/// Create a playerstats object for this player index
	public native PlayerStats(int player_idx);

	/// Appears to show the stats for the past 2-3 seconds.
	/// Cleared with a timer on an unknown basis.
	/// Returns -1 on failure.
	public native int GetDelta(StatType idx);

	/// Get the value of this stat for the current round
	/// Returns -1 on failure.
	public native int GetRound(StatType idx);

	/// Get the value of this stat for the current match
	/// Returns -1 on failure.
	public native int GetMatch(StatType idx);
};

methodmap StatType
{
	/// Returns true if this is a valid weaponstat.
	/// Some weapons do not have specific stats (eg, "hits" for grenades)
	/// And will use a specific placeholder value instead.
	/// This will return false if that is the case.
	public native bool IsValid();
};

methodmap FunFactEnumerator __nullable__
{
	/// Create a new fun fact enumerator and set it to the current entry
	public native FunFactEnumerator();

	/// Move the enumerator to the next value.
	/// Returns false if we have reached the end of the list, or if another error occured.
	public static native bool Next(FunFactEnumerator &self);

	/// Search for the desired fun fact and return true if found.
	/// ONLY USE FOR DEBUGGING--LEAKS MEMORY
	public static bool UnsafeSeek(FunFactEnumerator &self, const char[] funfact)
	{
		do
		{
			FunFact current = self.Current();
			char name[128];

			current.GetName(name, sizeof(name));

			if (StrEqual(name, funfact))
				return true;
		} while (FunFactEnumerator.Next(self));

		//  index not found.
		return false;
	}

	/// Gets the current fun fact
	/// This uses an sdkcall--avoid calling this function unnecessarily.
	/// !! Unstable--this is very likely to change in March/April 2023.
	public native FunFact Current();
}

/// A FunFact is a struct that contains information about a fun fact
/// and a method to generate a fun fact of the specified type.
methodmap FunFact
{
	/// Get the localization string of this fun fact
	/// Can be used to reliably get the same funfact.
	public native int GetName(char[] buffer, int maxlen);

	/// Evaluate this fun fact assuming the round ended with "reason".
	/// Returns true if a fun fact was generated, false if none or error.
	public native bool Evaluate(RoundEnd reason, FunFactResult &result);

	/// Exact purpose unknown. Assumed to be a unique ID.
	property int Id 
	{
		public native get();
	} 

	/// Get how rare/cool/whatever this fun fact is.
	/// Expressed as a float from 0 to 1.
	property float Prestige 
	{
		public native get();
	}  
}

methodmap FunFactResult
{
	/// Gets the data values for this fun fact.
	/// Note that there are THREE data values.
	/// So you had better be passing an INT array with THREE slots in it.
	/// ONE TWO THREE. THREE. Do not make maxlen save your dumb butt.
	/// Return 0 on success, otherwise error code on failure.
	public native int GetData(int[] data, int maxlen);

	/// Get the localization string of this fun fact
	/// Can be used to reliably get the same funfact.
	public native int GetName(char[] buffer, int maxlen);

	/// Get the subject of this fun fact.
	/// EG, for the bomb planter, returns the player that planted the bomb.
	property int Player 
	{
		public native get();
	}

	/// Exact purpose unknown. Assumed to be a unique ID.
	property int Id 
	{
		public native get();
	}

	/// Exact purpose unknown. 
	/// Assumed to be how cool this fun fact is.
	property float Magnitude 
	{
		public native get();
	}
}