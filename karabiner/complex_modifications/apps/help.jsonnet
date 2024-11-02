/**
 * This is a geenric rule but it's inside the apps folder because it has a facility to remove some apps of the rule by passing it name.
 * Usually most apps put the 'Help' button inside the Cmd + ? and ABNT-2 generates the shortcut  Cmd + Option + W instead. The hacky
 * developed here makes it possible
 */
local utils = import '../utils.libsonnet';
local From = utils.From;
local AppCondition = utils.AppCondition;

local HelpRules() = [
    // ? This solution works but it's slower than BTT so we keep it disabled here and use it there.
    // {
    //     description: 'Cmd + . to remap to Cmd + ? since ABNT-2 is weird in shortcuts that envolved question mark (?)',
    //     manipulators: [
    //         {
    //             from: From('slash', ['left_command', 'left_shift'], []),
    //         to: [
    //         {
    //             shell_command: "osascript -e 'tell application \"System Events\" to tell (first process whose frontmost is true) to click menu bar item \"Help\" of menu bar 1'"
    //         },
    //         ],
    //             type: 'basic',
    //         },
    //     ],
    // }
];

{
    HelpRules: HelpRules
}
