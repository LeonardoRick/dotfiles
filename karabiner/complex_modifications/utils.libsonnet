

local strictOptional = ['shift', 'caps_lock'];
local freeOptional = ['any'];

local From(code, mod, optional = freeOptional) = {
  key_code: code,
  modifiers: {
    mandatory: if std.isArray(mod) then mod else [mod],
    optional: optional,
  },
};

local To(code, mod = []) = {
  key_code: code,
  modifiers: if std.isArray(mod) then mod else [mod],
};

/**
 * utility function to pass as something that might be null and you want to extend it on another function json (see usage on FromStrictTo)
 */
local ExtendOptionalJson(extension, name) = (if extension != null && std.length(extension) > 0 then { [name]: extension } else {});


// If you do not include any in modifiers.optional, your manipulator does not change event if extra modifiers
// (modifiers which are not included in modifiers.mandatory) are pressed.
// https://karabiner-elements.pqrs.org/docs/json/complex-modifications-manipulator-definition/from/modifiers/
local FromStrict(code, mod) = From(code, mod, strictOptional);

/**
 * Utility function to wap from one modifier to another a specific code key
 * Ex: FromStrictTo('a', 'left_control', 'left_command', optional <modifiers>),
 * OBS: this is specifically to changing the modifier keys for the same character.
 */
local FromStrictTo(code, from_mod, to_mod, optional = strictOptional, conditions = null, to_code = null) = {
  from: From(code, from_mod, optional),
  to: To(if to_code != null then to_code else code, to_mod),
  type: 'basic'
} + (if conditions != null && std.length(conditions) > 0 then { conditions: conditions } else {});

/**
 * Usually the FromTo or FromStrictTo are for changing the modifiers that are triggered when other modifiers are pressed with a key.
 * This function is more straightforward and just replaces one code with the other, similar with a simple_modification in a complex
 */
local BasicFromTo(code1, code2, optional = freeOptional, conditions = null) = {
    type: 'basic',
    from: { key_code: code1, modifiers: { optional: optional }},
    to: { key_code: code2 },
} + ExtendOptionalJson(conditions, 'conditions');


/**
 * Accept a list of applications and return an object that should be used as
 * restriction to limit where the shortcuts should work. use the command
 * $> osascript -e 'id of app "<AppName>"'
 * to identify the bundle name of the application you want to target, where
 * where AppName is the naeme as it's written inside the Applications folder.
 */
local AppCondition(names, mode = 'include') = [
    {
        bundle_identifiers: std.map(function(name) '^'+ name +'$', names),
        type: if mode == 'exclude' then 'frontmost_application_unless' else 'frontmost_application_if'
    }
];

local DeviceCondition(device_id) = [
    {
        type: "device_if",
        identifiers: [
            {
                //  "device_id": 4294970238,
                // vendor_id: 1111,
                // "product_id": 591,
                "is_built_in_keyboard": true,
                description: "my keyboard 1"
            },

        ]
    }
];


local RepeatKey(code, modifiers, optional = freeOptional, times = 5, apps = [], appsMode = 'exclude') = {
    type: 'basic',
    from: From(code, modifiers, optional),
    to: [
        { key_code: code } for _ in std.range(1, times)
    ],
    conditions: AppCondition(apps, appsMode)
};

{
  From: From,
  To: To,
  FromStrict: FromStrict,
  FromStrictTo: FromStrictTo,
  BasicFromTo: BasicFromTo,

  AppCondition: AppCondition,
  DeviceCondition:DeviceCondition,

  RepeatKey: RepeatKey,

  // constants
  strictOptional: strictOptional,
  freeOptional: freeOptional
}
