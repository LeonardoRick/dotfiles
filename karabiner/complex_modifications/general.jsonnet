local utils = import 'utils.libsonnet';

local strictOptional = utils.strictOptional;
local FromStrictTo = utils.FromStrictTo;

local GeneralRules() = [
    {

        description: 'Ctrl+Shift+Esc to open task manager',
        manipulators: [
            FromStrictTo('escape', ['left_control', 'shift'], ['left_command', 'left_option'], []),
            FromStrictTo('escape', ['fn', 'shift'], ['left_command', 'left_option'], [])
        ]

    }
];

{
    GeneralRules: GeneralRules
}
