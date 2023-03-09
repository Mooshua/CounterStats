#include <sdktools>
#include <sourcemod>

static int Native__StatType__IsValid(Handle plugin, int nargs)
{
	int self = GetNativeCell(1);
	return self != StatStatus_Invalid;
}

bool Initialize__StatType(GameData config, char[] err, int err_max)
{
	//  ctor
	CreateNative("StatType.IsValid", Native__StatType__IsValid);


	return true;
}
