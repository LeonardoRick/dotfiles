/**
 * This is a geenric rule but it's inside the apps folder because it has a facility to remove some apps of the rule by passing it name.
 * Usually most apps put the 'Help' button inside the Cmd + ? and ABNT-2 generates the shortcut  Cmd + Option + W instead. The hacky
 * developed here makes it possible
 */
local utils = import '../utils.libsonnet';
local From = utils.From;
local AppCondition = utils.AppCondition;

local HelpRules() = [
    {
        description: 'Cmd + . to remap to Cmd + ? since ABNT-2 is weird in shortcuts that envolved question mark (?)',
        manipulators: [
            {
                from: {
                    // this key is actually the ';' in ABNT-2, but the keycode is slash
                    key_code: 'slash',
                    modifiers: {
                        mandatory: ['left_command', 'left_shift'],
                        optional: ['any']
                    }
                },
                to: [
                    {
                        // To avoid triggering command + w and closing the window, this solution is a hack that generates
                        // the question mark without pressing w. This allos us to remap anything to Cmd + ?
                        shell_command: "osascript -e 'tell application \"System Events\" to keystroke \"?\"'",
                        modifiers: ["left_command"]
                    }
                ],
                type: 'basic',
                // ? add here any application name that gives a weird behaviour on this and you simply want to disable.
                conditions: AppCondition([''], 'exclude')
            }
        ]
    }
];

{
    HelpRules: HelpRules
}
