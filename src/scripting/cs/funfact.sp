
#include <sourcemod>
#include <sdktools>
#include <dhooks>

#define nullptr (view_as<Address>(0))
#define FUNFACT_BUFFER 128
#define ADDRESS_BUFFER 12

//  Base address
static int		   Address__FunFact;
static int		   Offset__List_Instantiate;
static int		   Offset__Next;
static int		   Offset__FunFactId;
static int		   Offset__Prestige;
static int		   Offset__Delegate;
static int		   Offset__Name;

static int		   Offset__Result_DataBase;
static int		   Offset__Result_Name;
static int		   Offset__Result_Player;
static int		   Offset__Result_Id;
static int		   Offset__Result_Magnitude;

//	Cache for sdkcall preps to avoid handle leaks
static StringMap   Map__SdkCache;

/// Constructs a new WeaponStatsEnumerator
static any Native__FunFactEnumerator__New(Handle plugin, int nparams)
{
#if DEBUG
	PrintToServer("FF BASE: %X", Address__FunFact);
#endif
	return view_as<Address>( Address__FunFact );
}

/// Moves to the next value
static int Native__FunFactEnumerator__Next(Handle plugin, int nparams)
{
	Address self = GetNativeCellRef(1);

	//  TODO: Do we want to null guard this or just let idiots crash their server?
    self = view_as<Address>(LoadFromAddress(self + Offset__Next, NumberType_Int32));

	SetNativeCellRef(1, self);

	//  As long as we do not equal final, we are still valid.
	return self != nullptr;
}

static int Native__FunFactEnumerator__Current(Handle plugin, int nparams)
{
	Address self = GetNativeCell(1);
	
	Address creator = view_as<Address>(LoadFromAddress(self + Offset__List_Instantiate, NumberType_Int32));
#if DEBUG
	PrintToServer("CREATOR: %X", creator);
#endif
	char key[ADDRESS_BUFFER];
	IntToString(creator, key, sizeof(key));

	Handle call;
	//	Have we cached the sdkcall for this fun fact creator?
	if (!Map__SdkCache.GetValue(key, call))
	{
		//	Create an sdkcall to create this fun fact instance.
		StartPrepSDKCall(SDKCall_Static);
		PrepSDKCall_SetAddress(creator);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		call = EndPrepSDKCall()

		//	Cache the initializer
		if (!Map__SdkCache.SetValue(key, call, true))
			LogError("[CounterStats] Failed to store FunFactCreator for %X.", creator);
	}

	Address funfact = SDKCall(call);

	return funfact;
}

static int Native__FunFact__GetName(Handle plugin, int nparams)
{
	Address self = GetNativeCell(1);

	//  Dereference into the first byte of the name
	Address name = view_as<Address>(LoadFromAddress(self + Offset__Name, NumberType_Int32));

	//  Now read the entry
	char funfact[FUNFACT_BUFFER];
	UTIL_StringtToCharArray(name, funfact, sizeof(funfact));

	//  Now get maxlen and write to param
	int maxlen = view_as<int>(GetNativeCell(3));
	return SetNativeString(2, funfact, maxlen);
}

static int Native__FunFact__Evaluate(Handle plugin, int nparams)
{
	Address self = GetNativeCell(1);
	int roundend = GetNativeCell(2);
	
	Address vtable = view_as<Address>(LoadFromAddress(self, NumberType_Int32));
	Address delegate = view_as<Address>(LoadFromAddress(vtable + Offset__Delegate, NumberType_Int32));
#if DEBUG
	PrintToServer("EVALUATOR: %X", delegate);
#endif
	char key[ADDRESS_BUFFER];
	IntToString(delegate, key, sizeof(key));

	Handle call;
	//	Have we cached the sdkcall for this fun fact delegate?
	if (!Map__SdkCache.GetValue(key, call))
	{
		//	Create an sdkcall to evaluate this fun fact.
		//	Raw so we pass an arbitrary "this".
		StartPrepSDKCall(SDKCall_Raw);
		PrepSDKCall_SetAddress(delegate);

		//	round_end_reason
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);

		//	cutlvector
		PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
		
		//	return bool
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		call = EndPrepSDKCall()

		//	Cache the initializer
		if (!Map__SdkCache.SetValue(key, call, true))
			LogError("[CounterStats] Failed to store FunFact Delegate for %X.", delegate);
	}

	//	The fact that this is a valid CUtlVector is hilarious
	//	cant wait until this causes a segfault in 2 years
	int vector[5] = { 0, ... };

	bool success = SDKCall(call, self, roundend, vector);
#if DEBUG
	PrintToServer("Vector: %X %X %X %X", vector[0], vector[1], vector[2], vector[3]);
#endif
	if (success && vector[0] != nullptr)
		SetNativeCellRef(3, vector[0]);

	return success;
}

static int Native__getter(int offset)
{
	Address self = GetNativeCell(1);

	//  Dereference into the "kills" field
	any value = LoadFromAddress(self + offset, NumberType_Int32);

	//  Now read the entry
	return view_as<int>(value);
}

static int Native__FunFact__get_Id(Handle plugin, int nparams)
{
	return Native__getter(Offset__FunFactId);
}

static int Native__FunFact__get_Prestige(Handle plugin, int nparams)
{
	return Native__getter(Offset__Prestige);
}

static int Native__FunFactResult__GetName(Handle plugin, int nparams)
{
	Address self = GetNativeCell(1);

	//  Dereference into the first byte of the name
	Address name = view_as<Address>(LoadFromAddress(self + Offset__Result_Name, NumberType_Int32));

	//  Now read the entry
	char funfact[FUNFACT_BUFFER];
	UTIL_StringtToCharArray(name, funfact, sizeof(funfact));

	//  Now get maxlen and write to param
	int maxlen = view_as<int>(GetNativeCell(3));
	return SetNativeString(2, funfact, maxlen);
}

static int Native__FunFactResult__GetData(Handle plugin, int nparams)
{
	Address self = GetNativeCell(1);
	int maxlen = GetNativeCell(3);
	int data[3];

	data[0] = LoadFromAddress(self + Offset__Result_DataBase + 0, NumberType_Int32);
	data[1] = LoadFromAddress(self + Offset__Result_DataBase + 4, NumberType_Int32);
	data[2] = LoadFromAddress(self + Offset__Result_DataBase + 8, NumberType_Int32);

	return SetNativeArray(2, data, maxlen);
}

static int Native__FunFactResult__get_Player(Handle plugin, int nparams)
{
	return Native__getter(Offset__Result_Player);
}

static int Native__FunFactResult__get_Id(Handle plugin, int nparams)
{
	return Native__getter(Offset__Result_Id);
}

static int Native__FunFactResult__get_Magnitude(Handle plugin, int nparams)
{
	return Native__getter(Offset__Result_Magnitude);
}

bool Initialize__FunFact(GameData config, char[] err, int err_max)
{
    //  ctor
	CreateNative("FunFactEnumerator.FunFactEnumerator", Native__FunFactEnumerator__New);
    //  method
    CreateNative("FunFactEnumerator.Next", Native__FunFactEnumerator__Next);
	CreateNative("FunFactEnumerator.Current", Native__FunFactEnumerator__Current);

	//	method
	CreateNative("FunFact.GetName", Native__FunFact__GetName);
	CreateNative("FunFact.Evaluate", Native__FunFact__Evaluate);
	//	prop
	CreateNative("FunFact.Id.get", Native__FunFact__get_Id);
	CreateNative("FunFact.Prestige.get", Native__FunFact__get_Prestige);

	//	method
	CreateNative("FunFactResult.GetData", Native__FunFactResult__GetData);
	CreateNative("FunFactResult.GetName", Native__FunFactResult__GetName);

	//	prop
	CreateNative("FunFactResult.Player.get", Native__FunFactResult__get_Player);
	CreateNative("FunFactResult.Magnitude.get", Native__FunFactResult__get_Magnitude);
	CreateNative("FunFactResult.Id.get", Native__FunFactResult__get_Id);

	//	TODO: De-spaghettify this

	//	Fun fact list

	Offset__Next = config.GetOffset("CFunFactList::Next");
	if (Offset__Next == OFFSET_BAD)
		return UTIL_EarlyFail("Unable to load CFunFactList::Next", err, err_max);

	Offset__List_Instantiate = config.GetOffset("CFunFactList::Instantiate");
	if (Offset__List_Instantiate == OFFSET_BAD)
		return UTIL_EarlyFail("Unable to load CFunFactList::Instantiate", err, err_max);

	//	Fun fact instantiators

	Offset__Name = config.GetOffset("CFunFact::Name");
	if (Offset__Name == OFFSET_BAD)
		return UTIL_EarlyFail("Unable to load CFunFact::Name", err, err_max);

	Offset__Prestige = config.GetOffset("CFunFact::Prestige");
	if (Offset__Prestige == OFFSET_BAD)
		return UTIL_EarlyFail("Unable to load CFunFact::Prestige", err, err_max);

	Offset__FunFactId = config.GetOffset("CFunFact::ID");
	if (Offset__FunFactId == OFFSET_BAD)
		return UTIL_EarlyFail("Unable to load CFunFact::ID", err, err_max);

	Offset__Delegate = config.GetOffset("CFunFact[VTable]::Evaluate");
	if (Offset__Delegate == OFFSET_BAD)
		return UTIL_EarlyFail("Unable to load CFunFact[VTable]::Evaluate", err, err_max);

	//	Fun fact result instantiators.

	Offset__Result_Id = config.GetOffset("CFunFactResult::Id");
	if (Offset__Result_Id == OFFSET_BAD)
		return UTIL_EarlyFail("Unable to load CFunFactResult::Id", err, err_max);

	Offset__Result_DataBase = config.GetOffset("CFunFactResult::DataBase");
	if (Offset__Result_DataBase == OFFSET_BAD)
		return UTIL_EarlyFail("Unable to load CFunFactResult::DataBase", err, err_max);

	Offset__Result_Name = config.GetOffset("CFunFactResult::Name");
	if (Offset__Result_Name == OFFSET_BAD)
		return UTIL_EarlyFail("Unable to load CFunFactResult::Name", err, err_max);

	Offset__Result_Player = config.GetOffset("CFunFactResult::Player");
	if (Offset__Result_Player == OFFSET_BAD)
		return UTIL_EarlyFail("Unable to load CFunFactResult::Player", err, err_max);

	Offset__Result_Magnitude = config.GetOffset("CFunFactResult::Magnitude");
	if (Offset__Result_Magnitude == OFFSET_BAD)
		return UTIL_EarlyFail("Unable to load CFunFactResult::Magnitude", err, err_max);

	//	Globals.

	Address__FunFact = config.GetAddress("Global::CFunFactList");
	if (Address__FunFact == OFFSET_BAD)
		return UTIL_EarlyFail("Unable to load Global::CFunFactList", err, err_max);

	return true;
}


//	Called after natives are bound
bool Setup__FunFact()
{
	Map__SdkCache = new StringMap();

	return true;
}