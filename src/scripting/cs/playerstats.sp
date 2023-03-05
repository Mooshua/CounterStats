#include <sdktools>
#include <sourcemod>
#define nullptr (view_as<Address>(0))
#define OFFSET_BAD		-1

int Offset__PlayerState__Sizeof;
Address Address__CGameStats;
Handle SdkCall__GetPlayerStats

static int Native__PlayerStats__New(Handle plugin, int nargs)
{
    int player = GetNativeCell(1);
#if DEBUG
    PrintToServer("BASE: %X; PLAYER: %d", Address__CGameStats, player);
#endif
    Address self = SDKCall(SdkCall__GetPlayerStats, Address__CGameStats, player);
    return self;
}

static int Native__PlayerStats__getter(int segment)
{
    Address self = GetNativeCell(1);
    int idx = GetNativeCell(2);
    int offset = idx * 4;

    // If this offset crosses the array border, return -1 to indicate failure
    if (offset >= Offset__PlayerState__Sizeof)
        return -1;

    Address segment_offset = view_as<Address>( Offset__PlayerState__Sizeof * segment );
#if DEBUG
    PrintToServer("Self: %X, Off: %X, Segment: %X", self, offset, segment_offset);
#endif
    return LoadFromAddress(self + segment_offset + view_as<Address>(offset), NumberType_Int32);
}

static int Native__PlayerStats__GetDelta(Handle plugin, int nargs)
{
    return Native__PlayerStats__getter(0);
}

static int Native__PlayerStats__GetRound(Handle plugin, int nargs)
{
    return Native__PlayerStats__getter(1);
}

static int Native__PlayerStats__GetMatch(Handle plugin, int nargs)
{
    return Native__PlayerStats__getter(2);
}

bool Initialize__PlayerStats(GameData config, char[] err, int err_max)
{
    //  ctor
	CreateNative("PlayerStats.PlayerStats", Native__PlayerStats__New);

    //  methods
    CreateNative("PlayerStats.GetDelta", Native__PlayerStats__GetDelta);
    CreateNative("PlayerStats.GetRound", Native__PlayerStats__GetRound);
    CreateNative("PlayerStats.GetMatch", Native__PlayerStats__GetMatch);

	Address__CGameStats = config.GetAddress("Global::CGameStats");
	if (Address__CGameStats == nullptr)
		return UTIL_EarlyFail("Unable to load Global::CGameStats", err, err_max);

    Offset__PlayerState__Sizeof = config.GetOffset("PlayerStats::Sizeof");
	if (Offset__PlayerState__Sizeof == OFFSET_BAD)
		return UTIL_EarlyFail("Unable to load PlayerStats::Sizeof", err, err_max);

    return true;
}

bool SdkSetup__PlayerStats(GameData config)
{
    StartPrepSDKCall(SDKCall_Raw);
    PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
    PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
    PrepSDKCall_SetFromConf(config, SDKConf_Signature, "CGameStats::GetPlayerStats");
    SdkCall__GetPlayerStats = EndPrepSDKCall();

    return true;
}