local utils = import 'utils.libsonnet';

local strictOptional = utils.strictOptional;
local FromStrictTo = utils.FromStrictTo;

/**
 * Ctrl to CMD
 */

// just the label for example Remap (Ctrl + A or Fn + A to Cmd + A)
local getCtrlCmdDescription(code) = 'Remap (Ctrl + ' + std.asciiUpper(code) + ' or Fn + ' + std.asciiUpper(code) + ' to Cmd + ' + std.asciiUpper(code) + ')';

local ReplaceCtrlCmd(code, optional = strictOptional) = [
  FromStrictTo(code, 'left_control', 'left_command', optional),
  FromStrictTo(code, 'fn', 'left_command', optional),
  FromStrictTo(code, 'left_command', 'left_control', optional)
];

local ReplaceCtrlCmdOnlyShift(code, optional = strictOptional) = [
  FromStrictTo(code, ['left_control', 'shift'], ['left_command', 'shift'], optional),
  FromStrictTo(code, ['fn', 'shift'], ['left_command', 'shift'], optional),
  FromStrictTo(code, ['left_command', 'shift'], ['left_control', 'shift'], optional)
];

local ReplaceCtrlCmdItem(code) = {
  description: getCtrlCmdDescription(code),
  manipulators: ReplaceCtrlCmd(code)
};

local ReplaceCtrlCmdItemOneDirection(code) = {
    description: getCtrlCmdDescription(code),
    manipulators: [
        FromStrictTo(code, 'left_control', 'left_command'),
        FromStrictTo(code, 'fn', 'left_command'),
    ]
};

local ReplaceCtrlCmdNoShiftItem(code) = {
  description: getCtrlCmdDescription(code),
  manipulators: ReplaceCtrlCmd(code, ['caps_lock'])
};


local ReplaceCtrlCmdOnlyShiftItem(code) = {
  description: getCtrlCmdDescription(code),
  manipulators: ReplaceCtrlCmdOnlyShift(code, ['caps_lock'])
};


/**
 * list all the binds I want to replace on both directions: Ctrl+F -> Cmd+F and Cmd+F -> Ctrl+F
 */
local ReplaceCtrlCmdRules() = std.map(ReplaceCtrlCmdItem, ['f', 'j', 'l', 'n', 'o', 'p', 'r', 's', 'x', 'slash']);
/**
 * list all the binds I want to replace only one direction: Ctrl+A -> Cmd+A. Both shortcuts do the same thing
 */
local ReplaceCtrlCmdOneDirectionRules() = std.map(ReplaceCtrlCmdItemOneDirection, ['a','c', 'k', 't', 'v', 'w', 'z', 'spacebar']);
/**
 * list all the binds I want to replace both directions but the Ctrl + Shift + <KEY> should NOT be replaced
 */
local ReplaceCtrlCmdNoShiftRules() = std.map(ReplaceCtrlCmdNoShiftItem, ['d']);

/**
 * list all the binds I wwant ONLY the Ctrl + Shift + <KEY> to be replaced
 */
local ReplaceCtrlCmdOnlyShiftRules() = std.map(ReplaceCtrlCmdOnlyShiftItem, ['e']);

{
  ReplaceCtrlCmdRules: ReplaceCtrlCmdRules,
  ReplaceCtrlCmdOneDirectionRules: ReplaceCtrlCmdOneDirectionRules,
  ReplaceCtrlCmdNoShiftRules: ReplaceCtrlCmdNoShiftRules,
  ReplaceCtrlCmdOnlyShiftRules: ReplaceCtrlCmdOnlyShiftRules
}
