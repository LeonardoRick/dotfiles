
local utils = import 'utils.libsonnet';
local ctrlCmd = import 'ctrl_cmd.jsonnet';
local ctrlOption = import 'ctrl_option.jsonnet';
local openApps = import 'open_apps.jsonnet';

local FromStrictTo = utils.FromStrictTo;


local ReplaceCtrlCmdRules = ctrlCmd.ReplaceCtrlCmdRules;
local ReplaceCtrlCmdOneDirectionRules = ctrlCmd.ReplaceCtrlCmdOneDirectionRules;
local ReplaceCtrlCmdNoShiftRules = ctrlCmd.ReplaceCtrlCmdNoShiftRules;
local ReplaceCtrlCmdOnlyShiftRules = ctrlCmd.ReplaceCtrlCmdOnlyShiftRules;

local ReplaceCtrlOptionRules = ctrlOption.ReplaceCtrlOptionRules;

local OpenAppsRules = openApps.OpenAppsRules;

{
  complex_modifications: {
    title: 'Leonardo Perfect remap',
    rules: []
    + ReplaceCtrlCmdRules()
    + ReplaceCtrlCmdOneDirectionRules()
    + ReplaceCtrlCmdNoShiftRules()

    + ReplaceCtrlOptionRules()
    + ReplaceCtrlCmdOnlyShiftRules()

    + OpenAppsRules()
  }
}
