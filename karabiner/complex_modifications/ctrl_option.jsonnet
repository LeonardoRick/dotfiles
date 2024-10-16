local utils = import 'utils.libsonnet';

local FromStrictTo = utils.FromStrictTo;

/**
 * Ctrl to Option
 */
local ReplaceCtrlOption(code) = {
  description: 'Remap Ctrl/Fn + ' + std.asciiUpper(code) + ' to Option + ' + std.asciiUpper(code),
  manipulators: [
    FromStrictTo(code, 'left_control', 'left_option'),
    FromStrictTo(code, 'fn', 'left_option'),
    FromStrictTo(code, 'left_option', 'left_control'),
  ]
};

local ReplaceOptionCtrlOneDirection(code) = {
    description: 'Remap Option + ' + std.asciiUpper(code) + 'to Ctrl + '+ std.asciiUpper(code),
    manipulators: [
        FromStrictTo(code, 'left_option', 'left_control')
    ]
};

/**
 * Replace behaviour of navigating through words from option to control
 */
local ReplaceCtrlOptionRules() = std.map(ReplaceCtrlOption, ['right_arrow', 'left_arrow']);
/**
 * Replace option + something to ctrl + something in this direction only. Useful for restoring ctrl+c ability,
 * for example, since we lost this ability maintaining both cmd + c and ctrl + c as copy action
 */
local OptionCtrlOneDirectionRules()  = std.map(ReplaceOptionCtrlOneDirection, ['c']);

{
  ReplaceCtrlOptionRules: ReplaceCtrlOptionRules,
  OptionCtrlOneDirectionRules: OptionCtrlOneDirectionRules
}
