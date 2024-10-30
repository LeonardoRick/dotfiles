local utils = import '../utils.libsonnet';
local FromStrictTo = utils.FromStrictTo;
local AppCondition = utils.AppCondition;

local finder = ['com.apple.finder'];
local FinderRules() = [
  {
    description: 'Finder Remap Ctrl + Shift + V to Command + Option + V to ease moving files',
    manipulators: [
        FromStrictTo('v', ['left_control', 'shift'], ['left_command', 'left_option'], ['caps_lock'], AppCondition(finder)),
        FromStrictTo('v', ['fn', 'shift'], ['left_command', 'left_option'], ['caps_lock'], AppCondition(finder)),
    ],
  }
];

{
  FinderRules: FinderRules,
}
