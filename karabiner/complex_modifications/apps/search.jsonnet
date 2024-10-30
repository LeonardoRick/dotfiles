local utils = import '../utils.libsonnet';
local FromStrictTo = utils.FromStrictTo;
local AppCondition = utils.AppCondition;

local apps = ['com.apple.Notes', 'com.apple.mail'];

local AppSearchRules() = [
  {
    description: 'Apps Remap Ctrl + Shift + F to Command + Option + F to ease searching globally',
    manipulators: [
        FromStrictTo('f', ['left_control', 'shift'], ['left_command', 'left_option'], ['caps_lock'], AppCondition(apps)),
        FromStrictTo('f', ['fn', 'shift'], ['left_command', 'left_option'], ['caps_lock'], AppCondition(apps)),
    ],
  }
];

{
  AppSearchRules: AppSearchRules,
}
