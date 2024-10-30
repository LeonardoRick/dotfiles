local utils = import '../utils.libsonnet';
local From = utils.From;
local AppCondition = utils.AppCondition;

local apps = ['md.obsidian', 'com.apple.TextEdit', 'com.microsoft.onenote.mac', 'com.google.Chrome', 'com.brave.Browser'];


local MultiKey(code, modifiers, times) = {
    type: 'basic',
    from: From(code, modifiers),
    to: [
        { key_code: code } for _ in std.range(1, times)
    ],
    conditions: AppCondition(apps)
};

local TextEditorRules() = [
    {
        description: 'On specific text editing apps, cursor jumping lines funcionality I do in VSCode like',
        manipulators: [
            MultiKey('up_arrow', ['left_control', 'left_command'], 10),
            MultiKey('up_arrow', ['fn', 'left_command'], 10),
            MultiKey('up_arrow', ['left_control'], 5),
            MultiKey('up_arrow', ['fn'], 5),

            MultiKey('down_arrow', ['left_control', 'left_command'], 10),
            MultiKey('down_arrow', ['fn', 'left_command'], 10),
            MultiKey('down_arrow', ['left_control'], 5),
            MultiKey('down_arrow', ['fn'], 5),
        ]
    }
];

{
  TextEditorRules: TextEditorRules,
}
