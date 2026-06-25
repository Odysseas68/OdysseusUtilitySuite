std = "lua51"

globals = {
  "CreateFrame",
  "UIParent",
  "GameTooltip",
  "C_Timer",
  "C_AddOns",
  "C_Map",
  "C_QuestLog",
  "C_CVar",
  "C_Container",
  "C_MountJournal",
  "C_Spell",
  "Enum",
  "EventRegistry",
  "SlashCmdList",
  "StaticPopupDialogs",
  "STATICPOPUP_DIALOGS",
  "UISpecialFrames",

  "OdysseusUtilitySuite",
  "OdysseusDB",
  "OdysseusCharDB",
}

read_globals = {
  "_G",
  "print",
  "pairs",
  "ipairs",
  "next",
  "type",
  "tonumber",
  "tostring",
  "string",
  "table",
  "math",
  "select",
  "unpack",
  "wipe",
  "tinsert",

  "LibStub",
  "CreateColor",
  "GameFontNormalSmall",
  "StaticPopup_Show",
  "IsInInstance",
  "IsMounted",
  "IsFlying",
  "InCombatLockdown",
  "UnitIsDeadOrGhost",
  "UnitClass",
  "GetShapeshiftForm",
  "ProfessionsFrame",
  "TradeSkillFrame",
}

ignore = {
  "212", -- unused argument
  "213", -- unused loop variable
}