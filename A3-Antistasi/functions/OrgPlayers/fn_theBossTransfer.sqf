if !(isServer) exitWith {};
private _filename = "fn_theBossTransfer";
params [["_newBoss", objNull]];

private _transferGroups = false;
if (!isNil "theBoss" and {!isNull theBoss}) then
{
	[3, format ["Removing %1 from Boss roles.", name theBoss], _filename] call A3A_fnc_log;
	
	_groups = hcAllGroups theBoss;
	hcRemoveAllGroups theBoss;
	_transferGroups = true;

	theBoss synchronizeObjectsRemove [HC_commanderX];
	HC_commanderX synchronizeObjectsRemove [theBoss];
};

theBoss = _newBoss;
publicVariable "theBoss";

if (isNull _newBoss) exitWith { 
	[] spawn {
		sleep 5;
		private _textX = format ["The commander has resigned. There is no eligible commander."];
		[petros,"hint",_textX, "New Commander"] remoteExec ["A3A_fnc_commsMP", 0];
		[] remoteExec ["A3A_fnc_statistics",[teamPlayer,civilian]];
	};
};

[group theBoss, theBoss] remoteExec ["selectLeader", groupOwner group theBoss];

theBoss synchronizeObjectsAdd [HC_commanderX];
HC_commanderX synchronizeObjectsAdd [theBoss];

if (_transferGroups) then
{
	theBoss hcSetGroup _groups;
}
else {
	// No previous boss, try to find HC groups by scanning
	{
		if ((leader _x getVariable ["spawner",false]) and (!isPlayer leader _x) and (side _x == teamPlayer)) then
		{
			theBoss hcSetGroup [_x];
		};
	} forEach allGroups;
};

[3, format ["New boss %1 (%2) set.", str theBoss, name theBoss], _filename] call A3A_fnc_log;

[] spawn {
	sleep 5;
	private _textX = format ["%1 is the new commander of our forces. Greet them!", name theBoss];
	[petros,"hint",_textX, "New Commander"] remoteExec ["A3A_fnc_commsMP", 0];
	[] remoteExec ["A3A_fnc_statistics",[teamPlayer,civilian]];
};
