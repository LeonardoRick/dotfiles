local complex = import 'complex_modifications/complex_modifications.jsonnet'; // Import complex modifications
local devices = import 'devices.jsonnet';
{
    profiles: [
        {
            complex_modifications: complex.complex_modifications,
            name: 'Default profile',
            selected: true,
            devices: devices,
            virtual_hid_keyboard: {
                keyboard_type_v2: 'ansi',
            },
        },
    ],
}
