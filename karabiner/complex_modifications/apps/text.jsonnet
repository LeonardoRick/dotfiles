local utils = import '../utils.libsonnet';

local From = utils.From;

local AppCondition = utils.AppCondition;
local RepeatKey = utils.RepeatKey;

local appsToExclude = ['com.microsoft.VSCode'];
local optional = utils.freeOptional;


local TextEditorRules() = [
    {
        description: 'Excluding some apps, cursor jumping lines funcionality I do in VSCode like',
        manipulators: [
            RepeatKey('up_arrow', ['left_control', 'left_command'], optional, 10, appsToExclude),
            RepeatKey('up_arrow', ['fn', 'left_command'], optional, 10, appsToExclude),
            RepeatKey('up_arrow', ['left_control'], optional, 5, appsToExclude),
            RepeatKey('up_arrow', ['fn'], optional, 5),
            RepeatKey('down_arrow', ['left_control', 'left_command'], optional, 10, appsToExclude),
            RepeatKey('down_arrow', ['fn', 'left_command'], optional, 10, appsToExclude),
            RepeatKey('down_arrow', ['left_control'], optional, 5, appsToExclude),
            RepeatKey('down_arrow', ['fn'], optional, 5, appsToExclude),
        ]
    }
];

{
  TextEditorRules: TextEditorRules,
}
