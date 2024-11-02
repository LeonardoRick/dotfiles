local utils = import 'utils.libsonnet';

local strictOptional = utils.strictOptional;
local FromStrictTo = utils.FromStrictTo;
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
        description: 'Replace "Œ" symbol with "/" that is done when we press option + w with caps lock enabled. I just want my slash everytime ',
        manipulators: [
            FromStrictTo('q', ['option', 'caps_lock'], ['option'], [])
        ]
    }
];

{
    GeneralRules: GeneralRules
}
