

local strictOptional = ['shift', 'caps_lock'];

local From(code, mod, optional = ['any']) = {
  key_code: code,
  modifiers: {
    mandatory: if std.isArray(mod) then mod else [mod],
    optional: optional,
  },
};

local To(code, mod) = {
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
 */
local FromStrictTo(code, from_mod, to_mod, optional = strictOptional, conditions = null) = {
  from: From(code, from_mod, optional),
  to: To(code, to_mod),
  type: 'basic'
} + (if conditions != null && std.length(conditions) > 0 then { conditions: conditions } else {});

local AppCondition(name) = [
    {
    bundle_identifiers:[
        '^com.apple.'+ name +'$'
    ],
    type: 'frontmost_application_if'
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
