local utils = import 'utils.libsonnet';

local strictOptional = utils.strictOptional;
local freeOptional = utils.freeOptional;

local FromStrictTo = utils.FromStrictTo;
local BasicFromTo = utils.BasicFromTo;
local DeviceCondition = utils.DeviceCondition;

local To = utils.To;
local From = utils.From;

local GeneralRules() = [
    {
        description: 'Ctrl+Shift+Esc to open task manager',
        manipulators: [
            FromStrictTo('escape', ['left_control', 'shift'], ['left_command', 'left_option'], []),
            FromStrictTo('escape', ['fn', 'shift'], ['left_command', 'left_option'], [])
        ]
    },
    {
        description: 'Replace "Œ" symbol with "/" that is done when we press option + w with caps lock enabled. I just want my slash everytime',
        manipulators: [
            FromStrictTo('q', ['option', 'caps_lock'], ['option'], [])
        ]
    },
    {
        description: 'Replace " \' " with "" but only for specific keyboards because we dont want to affect the keyboards with big left_shift',
        manipulators: [
            BasicFromTo('grave_accent_and_tilde', 'non_us_backslash', freeOptional, DeviceCondition(123)),
            BasicFromTo('non_us_backslash', 'grave_accent_and_tilde', freeOptional, DeviceCondition(123)),
        ]
    },
    {
        description: 'Fix missing key since this left shift is super big without any reason :(',
        manipulators: [
            // fix missing \ and |
            FromStrictTo('z', ['left_shift', 'left_option'], ['left_shift'], ['caps_lock'], null, 'non_us_backslash'),
            FromStrictTo('grave_accent_and_tilde', ['fn', 'left_shift'], [], ['caps_lock'], null, 'non_us_backslash'),
            FromStrictTo('grave_accent_and_tilde', ['left_control', 'left_shift'], [], ['caps_lock'], null, 'non_us_backslash'),

            // makes Z behaves as the missing key for vscode shortcut that toggle focus between opening and closing of scope
            FromStrictTo('z', ['fn', 'left_option'], ['fn', 'left_option'], ['left_shift'], null, 'non_us_backslash'),
            FromStrictTo('z', ['left_control', 'left_option'], ['left_control', 'left_option'], ['left_shift'], null, 'non_us_backslash'),
        ]
    }

];

{
    GeneralRules: GeneralRules
}

