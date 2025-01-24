[
    {
        name: 'Apple Internal Keyboard',
        identifiers: {
            is_keyboard: true,
        },
        simple_modifications: [
            {
                from: { key_code: 'right_command' },
                to: [{ key_code: 'right_option' }],
            },
            {
                from: { key_code: 'right_option' },
                to: [{ key_code: 'right_command' }],
            },
        ],
    },
    {
        name: 'Logitech Keyboard',
        identifiers: {
            is_keyboard: true,
            product_id: 50503,
            vendor_id: 1133,
        },
        simple_modifications: [
            {
                from: { key_code: 'left_command' },
                to: [{ key_code: 'left_option' }],
            },
            {
                from: { key_code: 'left_option' },
                to: [{ key_code: 'left_command' }],
            },
        ],
    },

]
