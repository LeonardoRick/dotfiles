local From(code, mod) = {
  key_code: code,
  modifiers: {
    mandatory: [mod],
    optional: ['any'],
  },
};

local To(code, mod) = {
  key_code: code,
  modifiers: [mod],
};

/**
 * Ctrl to CMD
 */

local ReplaceCtrlCmdOneDirection(code) = [
  {
    from: From(code, 'left_control'),
    to: To(code, 'left_command'),
    type: 'basic',
  },
  {
    from: From(code, 'fn'),
    to: To(code, 'left_command'),
    type: 'basic',
  },
];

local ReplaceCtrlCmd(code) =
  ReplaceCtrlCmdOneDirection(code)
  + [
      {
        from: From(code, 'left_command'),
        to: To(code, 'left_control'),
        type: 'basic',
      },
    ];

// just the label for example Remap (Ctrl + A or Fn + A to Cmd + A)
local getCtrlCmdDescription(code) = {
  description: 'Remap (Ctrl + ' + std.asciiUpper(code) + ' or Fn + ' + std.asciiUpper(code) + ' to Cmd + ' + std.asciiUpper(code) + ')',
};

local ReplaceCtrlCmdItem(code) =
  getCtrlCmdDescription(code) + {
    manipulators: ReplaceCtrlCmd(code)
};

local ReplaceCtrlCmdItemOneDirection(code) =
    getCtrlCmdDescription(code) + {
    manipulators: ReplaceCtrlCmdOneDirection(code)
};


local ReplaceCtrlCmdRules() = std.map(ReplaceCtrlCmdItem, ['d' ,'f', 'j', 'l', 'n', 'o', 'p', 'r', 's', 't', 'x', 'slash']);
local ReplaceCtrlCmdRulesOneDirection() = std.map(ReplaceCtrlCmdItemOneDirection, ['a', 'k','c', 'v', 'w', 'z']);

/**
 * Ctrl to Option
 */
local ReplaceCtrlOption(code) = {
  description: 'Remap Ctrl/Fn + ' + std.asciiUpper(code) + ' to Option + ' + std.asciiUpper(code),
  manipulators: [
    {
      from: From(code, 'left_control'),
      to: To(code, 'left_option'),
      type: 'basic',
    },
    {
      from: From(code, 'fn'),
      to: To(code, 'left_option'),
      type: 'basic',
    },
    {
      from: From(code, 'left_option'),
      to: To(code, 'left_control'),
      type: 'basic'
    },
  ]
};


local ReplaceCtrlOptionRules() = std.map(ReplaceCtrlOption, ['right_arrow', 'left_arrow']);

{
  complex_modifications: {
    title: 'Leonardo Perfect remap',
    rules: ReplaceCtrlCmdRules()
    + ReplaceCtrlCmdRulesOneDirection()
    + ReplaceCtrlOptionRules()
  }
}
