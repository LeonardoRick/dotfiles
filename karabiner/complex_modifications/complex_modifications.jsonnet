
local utils = import 'utils.libsonnet';
local ctrlCmd = import 'ctrl_cmd.jsonnet';
local ctrlOption = import 'ctrl_option.jsonnet';
local openApps = import 'open_apps.jsonnet';

local general = import 'general.jsonnet';
local stubs = import 'stubs.jsonnet';

local finder = import 'apps/finder.jsonnet';
local text = import 'apps/text.jsonnet';
local search = import 'apps/search.jsonnet';
local help = import 'apps/help.jsonnet';

local FromStrictTo = utils.FromStrictTo;

local ReplaceCtrlCmdRules = ctrlCmd.ReplaceCtrlCmdRules;
local ReplaceCtrlCmdOneDirectionRules = ctrlCmd.ReplaceCtrlCmdOneDirectionRules;
local ReplaceCtrlCmdNoShiftRules = ctrlCmd.ReplaceCtrlCmdNoShiftRules;
local ReplaceCtrlCmdOnlyShiftRules = ctrlCmd.ReplaceCtrlCmdOnlyShiftRules;

local ReplaceCtrlOptionRules = ctrlOption.ReplaceCtrlOptionRules;
local OptionCtrlOneDirectionRules = ctrlOption.OptionCtrlOneDirectionRules;

local OpenAppsRules = openApps.OpenAppsRules;

/**
 * Other rules
 */
local GeneralRules = general.GeneralRules;
local StubRules = stubs.StubRules;


/**
 * Apps rules
 */
local FinderRules = finder.FinderRules;
local TextEditorRules = text.TextEditorRules;
local AppSearchRules = search.AppSearchRules;
local HelpRules = help.HelpRules;

/**
 * Final JSON
 */
{
  complex_modifications: {
    title: 'Leonardo Perfect remap',
    rules: []

    + StubRules()

    // ? Apps rules needs to come first to take priority
    + FinderRules()
    + TextEditorRules()
    + AppSearchRules()
    + HelpRules()

    + ReplaceCtrlCmdRules()
    + ReplaceCtrlCmdOneDirectionRules()
    + ReplaceCtrlCmdNoShiftRules()
    + ReplaceCtrlCmdOnlyShiftRules()

    + ReplaceCtrlOptionRules()
    + OptionCtrlOneDirectionRules()


    + OpenAppsRules()
    + GeneralRules()

  }
}
