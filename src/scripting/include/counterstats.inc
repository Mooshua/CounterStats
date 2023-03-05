
enum StatStatus
{
    /// If the weaponstat returned from WeaponStatsEnumerator
    StatStatus_Invalid = 0xFFFFFFFF
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