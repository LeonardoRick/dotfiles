local utils = import '../utils.libsonnet';

local FromStrictTo = utils.FromStrictTo;

local AppCondition = utils.AppCondition;
local optional = utils.strictOptional;

local onenote = ['com.microsoft.onenote.mac'];

local OneNoteRules() = [
    {
        description: 'Remap Cmd+Option + up/down arrows to Option + Shift up/down arrows so moving a line up and down behaves like VSCode',
        manipulators: [
            FromStrictTo('up_arrow', ['left_option'], ['left_command', 'left_option'], ['caps_lock'], AppCondition(onenote)),
            FromStrictTo('down_arrow', ['option'], ['command', 'option'], ['caps_lock'], AppCondition(onenote))
        ]
    }
];

{
  OneNoteRules: OneNoteRules,
}
