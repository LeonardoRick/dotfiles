
local utils = import 'utils.libsonnet';
local From = utils.From;

local StubRules() = [
    {
        description: 'Disable right_option (Which is actually remapped to right command key) + Spacebar because it keeps activating ChatGPT when Im placing question marks',
        manipulators: [
            {
                from: From('spacebar', 'right_option'),
                to: [],
                type: 'basic'
            }
        ]
    }
];

{
    StubRules: StubRules
}
