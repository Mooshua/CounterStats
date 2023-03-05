
#include <sourcemod>
#include <sdktools>
#include "util.sp"

//  The size of buffers to use for weaponids
#define WEAPONID_BUFFER 32
#define OFFSET_BAD		-1

//  The name of the final weapon entry
char	   KV__Final[WEAPONID_BUFFER];

//  Size of each weapon entry
int		   Offset__Sizeof;
int		   Address__Base;

int		   Offset__Name;
int		   Offset__Kills;
int		   Offset__Shots;
int		   Offset__Hits;
int		   Offset__Damage;


/// Constructs a new WeaponStatsEnumerator
static any Native__WeaponStatsEnumerator__New(Handle plugin, int nparams)
{
	PrintToServer("BASE: %X", Address__Base
);
	return view_as<Address>( Address__Base
 );
}

/// Moves to the next value
static int Native__WeaponStatsEnumerator__Next(Handle plugin, int nparams)
{
	Address self = GetNativeCellRef(1);

	//  Increment self by sizeof to get to the next entry
	self = self + Offset__Sizeof;

	SetNativeCellRef(1, self);

	//  Now read the entry
	char weapon[WEAPONID_BUFFER];
    Address name = view_as<Address>(LoadFromAddress(self + Offset__Name, NumberType_Int32));
	UTIL_StringtToCharArray(name, weapon, sizeof(weapon));

	//  As long as we do not equal final, we are still valid.
	return !StrEqual(weapon, KV__Final);
}

static int Native__WeaponStatsEnumerator__GetName(Handle plugin, int nparams)
{
	Address self = GetNativeCell(1);

	//  Dereference into the first byte of the name
	Address name = view_as<Address>(LoadFromAddress(self + Offset__Name, NumberType_Int32));

	//  Now read the entry
	char weapon[WEAPONID_BUFFER];
	UTIL_StringtToCharArray(name, weapon, sizeof(weapon));

	//  Now get maxlen and write to param
	int maxlen = view_as<int>(GetNativeCell(3));
	return SetNativeString(2, weapon, maxlen);
}

static int Native__getter(int offset)
{
	Address self = GetNativeCell(1);

	//  Dereference into the "kills" field
	any value = LoadFromAddress(self + offset, NumberType_Int32);

	//  Now read the entry
	return view_as<int>(value);
}

static int Native__WeaponStatsEnumerator__get_Kills(Handle plugin, int nparams)
{
	return Native__getter(Offset__Kills);
}

static int Native__WeaponStatsEnumerator__get_Shots(Handle plugin, int nparams)
{
	return Native__getter(Offset__Shots);
}

static int Native__WeaponStatsEnumerator__get_Hits(Handle plugin, int nparams)
{
	return Native__getter(Offset__Hits);
}

static int Native__WeaponStatsEnumerator__get_Damage(Handle plugin, int nparams)
{
	return Native__getter(Offset__Damage);
}

bool Initialize__Enumerator(GameData config, char[] err, int err_max)
{
    //  ctor
	CreateNative("WeaponStatsEnumerator.WeaponStatsEnumerator", Native__WeaponStatsEnumerator__New);
	
    //  method
    CreateNative("WeaponStatsEnumerator.Next", Native__WeaponStatsEnumerator__Next);
	CreateNative("WeaponStatsEnumerator.GetName", Native__WeaponStatsEnumerator__GetName);

    //  properties
    CreateNative("WeaponStatsEnumerator.Kills.get", Native__WeaponStatsEnumerator__get_Kills);
    CreateNative("WeaponStatsEnumerator.Shots.get", Native__WeaponStatsEnumerator__get_Shots);
    CreateNative("WeaponStatsEnumerator.Hits.get", Native__WeaponStatsEnumerator__get_Hits);
    CreateNative("WeaponStatsEnumerator.Damage.get", Native__WeaponStatsEnumerator__get_Damage);

	Offset__Sizeof = config.GetOffset("WeaponStatId::Sizeof");
	if (Offset__Sizeof == OFFSET_BAD)
		return UTIL_EarlyFail("Unable to load WeaponStatId::Sizeof", err, err_max);

	Offset__Name = config.GetOffset("WeaponStatId::Name");
	if (Offset__Name == OFFSET_BAD)
		return UTIL_EarlyFail("Unable to load WeaponStatId::Name", err, err_max);

	Offset__Kills = config.GetOffset("WeaponStatId::Kills");
	if (Offset__Kills == OFFSET_BAD)
		return UTIL_EarlyFail("Unable to load WeaponStatId::Kills", err, err_max);

	Offset__Shots = config.GetOffset("WeaponStatId::Shots");
	if (Offset__Shots == OFFSET_BAD)
		return UTIL_EarlyFail("Unable to load WeaponStatId::Shots", err, err_max);

	Offset__Hits = config.GetOffset("WeaponStatId::Hits");
	if (Offset__Hits == OFFSET_BAD)
		return UTIL_EarlyFail("Unable to load WeaponStatId::Hits", err, err_max);

	Offset__Damage = config.GetOffset("WeaponStatId::Damage");
	if (Offset__Damage == OFFSET_BAD)
		return UTIL_EarlyFail("Unable to load WeaponStatId::Damage", err, err_max);

	Address__Base = config.GetAddress("Global::WeaponStatId");
	if (Address__Base == OFFSET_BAD)
		return UTIL_EarlyFail("Unable to load Global::WeaponStatId", err, err_max);

	if (!config.GetKeyValue("WeaponStatId::Final", KV__Final, sizeof(KV__Final)))
		return UTIL_EarlyFail("Unable to load WeaponStatId::Final.", err, err_max);

	return true;
}