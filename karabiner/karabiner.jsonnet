local complex = import 'complex_modifications.jsonnet'; // Import complex modifications

{
  profiles: [
    {
      complex_modifications: complex.complex_modifications,
      devices: [
        {
          identifiers: {
            is_keyboard: true,
          },
          simple_modifications: [
            {
              from: {
                key_code: 'grave_accent_and_tilde',
              },
              to: [
                {
                  key_code: 'non_us_backslash',
                },
              ],
            },
            {
              from: {
                key_code: 'non_us_backslash',
              },
              to: [
                {
                  key_code: 'grave_accent_and_tilde',
                },
              ],
            },
            {
              from: {
                key_code: 'right_command',
              },
              to: [
                {
                  key_code: 'right_option',
                },
              ],
            },
            {
              from: {
                key_code: 'right_option',
              },
              to: [
                {
                  key_code: 'right_command',
                },
              ],
            },
          ],
        },
      ],
      name: 'Default profile',
      selected: true,
      virtual_hid_keyboard: {
        keyboard_type_v2: 'ansi',
      },
    },
  ],
}
