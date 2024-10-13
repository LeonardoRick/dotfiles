local utils = import 'utils.libsonnet';
local From = utils.From;


local OpenAppsRules() = [
  {
    description: 'Open iTerm',
    manipulators: [
      {
        from: From('t', ['left_command', 'shift'], ['caps_lock']),
        to: [
          {
            shell_command: "open -a iTerm",
          },
        ],
        type: 'basic',
      },
    ],
  }
];

{
  OpenAppsRules: OpenAppsRules,
}
