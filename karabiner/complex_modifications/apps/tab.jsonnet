local utils = import '../utils.libsonnet';

local From = utils.From;
local AppCondition = utils.AppCondition;
local RepeatKey = utils.RepeatKey;

// ? If ever planning to enable this for all apps, remember to remove VSCode because it uses ctrl tab to navigate between recent tabs
local apps = ['com.microsoft.onenote.mac'];


local TabRules() = [
    {
        description: 'Excluding some apps, ctrl + tab is tab 5x (already works for shift)',
        manipulators: [
            RepeatKey('tab', ['left_control'], ['shift'], 4, apps, 'include'),
            RepeatKey('tab', ['fn'], ['shift'], 4, apps, 'include'),
        ]
    }
];

{
  TabRules: TabRules,
}
