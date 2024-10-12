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

local ReplaceCtrlOptionRules() = std.map(ReplaceCtrlOption, ['right_arrow', 'left_arrow']);

{
  ReplaceCtrlOptionRules: ReplaceCtrlOptionRules
}
