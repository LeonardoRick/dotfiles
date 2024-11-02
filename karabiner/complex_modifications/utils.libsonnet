

local strictOptional = ['shift', 'caps_lock'];

local From(code, mod, optional = ['any']) = {
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

// If you do not include any in modifiers.optional, your manipulator does not change event if extra modifiers
// (modifiers which are not included in modifiers.mandatory) are pressed.
// https://karabiner-elements.pqrs.org/docs/json/complex-modifications-manipulator-definition/from/modifiers/
local FromStrict(code, mod) = From(code, mod, strictOptional);

/**
 * Utility function to wap from one modifier to another a specific code key
 * Ex: FromStrictTo('a', 'left_control', 'left_command', optional <modifiers>),
 * OBS: this is specifically to changing the modifier keys for the same character.
 */
local FromStrictTo(code, from_mod, to_mod, optional = strictOptional, conditions = null) = {
  from: From(code, from_mod, optional),
  to: To(code, to_mod),
  type: 'basic'
} + (if conditions != null && std.length(conditions) > 0 then { conditions: conditions } else {});

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

{
  strictOptional: strictOptional,
  From: From,
  To: To,
  FromStrict: FromStrict,
  FromStrictTo: FromStrictTo,
  AppCondition: AppCondition
}
