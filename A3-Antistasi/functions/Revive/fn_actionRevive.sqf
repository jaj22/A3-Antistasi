private ["_cured","_medicX","_healed","_player","_timer","_sideX","_actionX"];

_cured = _this select 0;
_medicX = _this select 1;
_player = isPlayer _medicX;
_inPlayerGroup = if !(_player) then {if ({isPlayer _x} count (units group _medicX) > 0) then {true} else {false}} else {false};
if (captive _medicX) then
    {
    [_medicX,false] remoteExec ["setCaptive",0,_medicX];
    _medicX setCaptive false;
    };
if !(alive _cured) exitWith
    {
    if (_player) then {["Revive", format ["%1 is already dead",name _cured]] call A3A_fnc_customHint;};
    if (_inPlayerGroup) then {_medicX groupChat format ["%1 is already dead",name _cured]};
    _healed
    };
if !([_medicX] call A3A_fnc_canFight) exitWith {if (_player) then {["Revive", "You are not able to revive anyone"] call A3A_fnc_customHint;};_healed};
if  (
        (!([_medicX] call A3A_fnc_isMedic && "Medikit" in (items _medicX))) &&
        {(!("FirstAidKit" in (items _medicX))) &&
        {(!("FirstAidKit" in (items _cured)))}}
    ) exitWith
{
    if (_player) then {["Revive", format ["You or %1 need a First Aid Kit or Medikit to be able to revive",name _cured]] call A3A_fnc_customHint;};
    if (_inPlayerGroup) then {_medicX groupChat "I'm out of FA kits and I have no Medikit!"};
    _healed
};
if ((not("FirstAidKit" in (items _medicX))) and !(_medicX canAdd "FirstAidKit")) exitWith
    {
    if (_player) then {["Revive", format ["%1 has a First Aid Kit but you do not have enough space in your inventory to use it",name _cured]] call A3A_fnc_customHint;};
    if (_inPlayerGroup) then {_medicX groupChat "I'm out of FA kits!"};
    _healed
    };
if ((([_cured] call A3A_fnc_fatalWound)) and !([_medicX] call A3A_fnc_isMedic)) exitWith
    {
    if (_player) then {["Revive", format ["%1 is injured by a fatal wound, only a medic can revive him",name _cured]] call A3A_fnc_customHint;};
    if (_inPlayerGroup) then {_medicX groupChat format ["%1 is injured by a fatal wound, only a medic can revive him",name _cured]};
    _healed
    };
if !(isNull attachedTo _cured) exitWith
    {
    if (_player) then {["Revive", format ["%1 is being carried or transported and you cannot heal him",name _cured]] call A3A_fnc_customHint;};
    if (_inPlayerGroup) then {_medicX groupChat format ["%1 is being carried or transported and I cannot heal him",name _cured]};
    _healed
    };
if !(_cured getVariable ["incapacitated",false]) exitWith
    {
    if (_player) then {["Revive", format ["%1 no longer needs your help",name _cured]] call A3A_fnc_customHint;};
    if (_inPlayerGroup) then {_medicX groupChat format ["%1 no longer needs my help",name _cured]};
    _healed
    };
if  (
        (!("FirstAidKit" in (items _medicX))) &&
        {!("Medikit" in (items _medicX))}
    ) then
{
    _medicX addItem "FirstAidKit";
    _cured removeItem "FirstAidKit";
};
_timer = if ([_cured] call A3A_fnc_fatalWound) then
            {
            time + 35 + (random 20)
            }
        else
            {
            if ((!isMultiplayer and (isPlayer _cured)) or ([_medicX] call A3A_fnc_isMedic)) then
                {
                time + 10 + (random 5)
                }
            else
                {
                time + 15 + (random 10)
                };
            };


_medicX setVariable ["helping",true];
_medicX playMoveNow selectRandom medicAnims;
_medicX setVariable ["cancelRevive",false];

if (!_player) then
{
    {_medicX disableAI _x} forEach ["ANIM","AUTOTARGET","FSM","MOVE","TARGET"];
}
else
{
    _actionX = _medicX addAction ["Cancel Revive", {(_this select 1) setVariable ["cancelRevive",true]},nil,6,true,true,"",""];
    _cured setVariable ["helped",_medicX,true];
};

private _animHandler = _medicX addEventHandler ["AnimDone",
{
    private _medicX = _this select 0;
    _medicX playMoveNow selectRandom medicAnims;
}];

waitUntil {
    sleep 1;
    !([_medicX] call A3A_fnc_canFight)
    or (time > _timer)
    or (_medicX getVariable "cancelRevive")
    or !(alive _cured)
};

_medicX removeEventHandler ["AnimDone", _animHandler];
_medicX setVariable ["helping",false];
_medicX playMoveNow "AinvPknlMstpSnonWnonDnon_medicEnd";

if (!_player) then
{
    {_medicX enableAI _x} forEach ["ANIM","AUTOTARGET","FSM","MOVE","TARGET"];
}
else
{
    _medicX removeAction _actionX;
    _cured setVariable ["helped",objNull,true];
};

if (_medicX getVariable ["cancelRevive",false]) exitWith
{
    // AI medics can be cancelled from A3A_fnc_help
    if (_player) then
    {
        ["Revive", "Revive cancelled"] call A3A_fnc_customHint;
        _medicX setVariable ["cancelRevive",nil];
    };
    false;
};

if !(alive _cured) exitWith
{
    if (_player) then {["Revive", format ["We lost %1",name _cured]] call A3A_fnc_customHint;};
    if (_inPlayerGroup) then {_medicX groupChat format ["We lost %1",name _cured]};
    false;
};

if (!([_medicX] call A3A_fnc_canFight)) exitWith
{
    if (_player) then {["Revive", "Revive cancelled"] call A3A_fnc_customHint;};
    false;
};

// If we get here, it's a successful revive, right?
if ([_medicX] call A3A_fnc_isMedic) then {_cured setDamage 0.25} else {_cured setDamage 0.5};
if(!("Medikit" in items _medicX)) then { _medicX removeItem "FirstAidKit"; };

_sideX = side (group _cured);
if ((_sideX != side (group _medicX)) and ((_sideX == Occupants) or (_sideX == Invaders))) then
{
    _cured setVariable ["surrendering",true,true];
    sleep 2;
};
_cured setVariable ["incapacitated",false,true];        // why is this applied later? check
true;
