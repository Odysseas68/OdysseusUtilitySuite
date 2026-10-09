-- ============================================================
-- Addon   : OdysseusUtilitySuite
-- File    : AutoRemount.lua
-- Version : 2026.10.09
-- Desc    : Auto remount engine — detects dismount and re-applies last mount
-- ============================================================

-- ==========================================
-- 1. ODYSSEUS UTILITY SUITE: AUTO REMOUNT ENGINE
-- ==========================================
local _, OUS = ...
-- luacheck: globals C_UnitAuras C_SpellBook C_ClassTalents C_Traits CreateScrollBoxLinearView ScrollUtil

OUS.AutoRemount = {}
local AR = OUS.AutoRemount

local SPY_PENDING_TIMEOUT = 5

-- Module state
local isGathering = false
local isTryingToMount = false
local lootWindowOpened = false
local noLootTimer = nil
local pendingSpySpellID = nil  -- tracks last unknown spell waiting for loot confirmation
local pendingSpyLootObserved = false
local pendingSpyTimer = nil
local interactionSequence = 0
local currentInteractionID = nil

-- ==========================================
-- 2. HELPERS
-- ==========================================

-- Keeps optional diagnostic enrichment from inspecting inaccessible spell values.
local function FormatSpellDebug(spellID)
    local canAccessValue = _G.canaccessvalue
    if not canAccessValue or not canAccessValue(spellID) or type(spellID) ~= "number" then
        return "Unknown"
    end

    local spellText = tostring(spellID)
    if not C_Spell or not C_Spell.GetSpellName then return spellText end
    local success, spellName = pcall(C_Spell.GetSpellName, spellID)
    if success and canAccessValue(spellName) and type(spellName) == "string" and spellName ~= "" then
        return spellText .. " — " .. spellName
    end
    return spellText
end

-- Resolves spell names only while the suite's debug output is enabled.
local function LogSpellDebug(message, spellID)
    if not OUS.IsDebugModeOn() then return end
    OUS.LogDebug("AutoRemount", message .. FormatSpellDebug(spellID))
end

-- Only a safely established harmful classification may block custom triggers or Spy.
local function IsHarmfulSpell(spellID)
    local canAccessValue = _G.canaccessvalue
    if not canAccessValue or not canAccessValue(spellID) or type(spellID) ~= "number" then
        return false
    end
    if spellID <= 0 or spellID % 1 ~= 0 then return false end
    if not C_Spell or type(C_Spell.IsSpellHarmful) ~= "function" then return false end

    local success, isHarmful = pcall(C_Spell.IsSpellHarmful, spellID)
    return success and canAccessValue(isHarmful) and type(isHarmful) == "boolean" and isHarmful == true
end

-- Audit failures retain their reason instead of becoming negative classifications.
local function QueryAuditValue(api, spellID, valueType, allowNil)
    local canAccessValue = _G.canaccessvalue
    if type(api) ~= "function" or not canAccessValue then return nil, "unavailable" end
    if not canAccessValue(spellID) then return nil, "inaccessible input" end
    if type(spellID) ~= "number" or spellID <= 0 or spellID % 1 ~= 0 then return nil, "unexpected input" end
    local success, value = pcall(api, spellID)
    if not success then return nil, "error" end
    if not canAccessValue(value) then return nil, "inaccessible" end
    if value == nil then
        if allowNil then return nil end
        return nil, "nil result"
    end
    if type(value) ~= valueType then return nil, "unexpected result" end
    return value
end

-- Self-only effects and current player aura state are separate from general spell classification.
local function CollectExclusionAudit()
    local result = {
        entries = {},
        counts = { harmful = 0, helpful = 0, mounts = 0, selfBuff = 0, activeAura = 0,
            neither = 0, unresolved = 0, namesUnresolved = 0, overlap = 0,
            harmfulMount = 0, helpfulMount = 0, structural = 0 },
    }
    local counts = result.counts
    for spellID in pairs(OUS.AutoRemountExcludeSpells or {}) do
        local entry = { id = spellID, errors = {} }
        entry.harmful, entry.errors.harmful = QueryAuditValue(C_Spell and C_Spell.IsSpellHarmful, spellID, "boolean")
        entry.helpful, entry.errors.helpful = QueryAuditValue(C_Spell and C_Spell.IsSpellHelpful, spellID, "boolean")
        entry.mountID, entry.errors.mountID =
            QueryAuditValue(C_MountJournal and C_MountJournal.GetMountFromSpell, spellID, "number", true)
        entry.selfBuff, entry.errors.selfBuff = QueryAuditValue(C_Spell and C_Spell.IsSelfBuff, spellID, "boolean")
        local aura, auraError =
            QueryAuditValue(C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID, spellID, "table", true)
        entry.errors.activeAura = auraError
        if not auraError then entry.activeAura = aura ~= nil end
        local name, nameError = QueryAuditValue(C_Spell and C_Spell.GetSpellName, spellID, "string")
        entry.nameResolved = name ~= nil and name ~= ""
        entry.name = entry.nameResolved and name:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "") or "Unknown"
        entry.nameError = nameError or (not entry.nameResolved and "empty name" or nil)
        if not entry.nameResolved then counts.namesUnresolved = counts.namesUnresolved + 1 end
        if entry.harmful == true then counts.harmful = counts.harmful + 1 end
        if entry.helpful == true then counts.helpful = counts.helpful + 1 end
        if entry.mountID ~= nil then counts.mounts = counts.mounts + 1 end
        if entry.selfBuff == true then counts.selfBuff = counts.selfBuff + 1 end
        if entry.activeAura == true then counts.activeAura = counts.activeAura + 1 end
        if entry.harmful == true and entry.helpful == true then counts.overlap = counts.overlap + 1 end
        if entry.harmful == true and entry.mountID ~= nil then counts.harmfulMount = counts.harmfulMount + 1 end
        if entry.helpful == true and entry.mountID ~= nil then counts.helpfulMount = counts.helpfulMount + 1 end
        if entry.harmful == true or entry.mountID ~= nil then counts.structural = counts.structural + 1 end
        if next(entry.errors) then counts.unresolved = counts.unresolved + 1 end
        if not entry.errors.harmful and not entry.errors.helpful and not entry.errors.mountID
            and entry.harmful == false and entry.helpful == false and entry.mountID == nil then
            counts.neither = counts.neither + 1
        end
        result.entries[#result.entries + 1] = entry
    end
    table.sort(result.entries, function(a, b)
        if a.nameResolved ~= b.nameResolved then return a.nameResolved end
        if a.nameResolved then
            local aName, bName = a.name:lower(), b.name:lower()
            if aName ~= bName then return aName < bName end
        end
        return a.id < b.id
    end)
    result.total = #result.entries
    return result
end

-- Both the visible rows and plain-text export use these same status definitions.
local function AuditValueText(value, failure, mount)
    if failure then return "?" end
    if mount then return value ~= nil and ("Yes / " .. tostring(value)) or "No" end
    return value == true and "Yes" or "No"
end

local AUDIT_STATIC_NOTE = "Static general Buff/Aura classification: unavailable in verified Retail API."
local AUDIT_SELF_NOTE = "Self Buff: self-only effects flag; No does not rule out a buff/aura."
local AUDIT_ACTIVE_NOTE = "Active Aura Now: player aura returned at refresh; No does not mean not an aura spell."

-- Exports every row and unresolved reason without WoW color formatting.
local function BuildExclusionAuditText(result)
    local c = result.counts
    local lines = {
        "Odysseus AutoRemount Audit — DB Audit",
        "Exclusions: " .. result.total,
        "Harmful: " .. c.harmful,
        "Helpful: " .. c.helpful,
        "Mounts: " .. c.mounts,
        "Self Buff: " .. c.selfBuff,
        "Active Aura Now: " .. c.activeAura,
        "Unresolved classifications (any audit field): " .. c.unresolved,
        "Unresolved names: " .. c.namesUnresolved,
        "Neither harmful/helpful/mount: " .. c.neither,
        "Harmful+Helpful overlap: " .. c.overlap,
        "Harmful+Mount overlap: " .. c.harmfulMount,
        "Helpful+Mount overlap: " .. c.helpfulMount,
        "Unique harmful/mount candidates (diagnostic only): " .. c.structural,
        AUDIT_STATIC_NOTE, AUDIT_SELF_NOTE, AUDIT_ACTIVE_NOTE, "",
        "SpellID | Name | Harmful | Helpful | Mount | Self Buff | Active Aura Now | Notes",
    }
    for _, entry in ipairs(result.entries) do
        local failures = {}
        for _, field in ipairs({ "harmful", "helpful", "mountID", "selfBuff", "activeAura" }) do
            if entry.errors[field] then failures[#failures + 1] = field .. "=" .. entry.errors[field] end
        end
        if entry.nameError then failures[#failures + 1] = "name=" .. entry.nameError end
        lines[#lines + 1] = table.concat({
            tostring(entry.id), entry.name,
            AuditValueText(entry.harmful, entry.errors.harmful),
            AuditValueText(entry.helpful, entry.errors.helpful),
            AuditValueText(entry.mountID, entry.errors.mountID, true),
            AuditValueText(entry.selfBuff, entry.errors.selfBuff),
            AuditValueText(entry.activeAura, entry.errors.activeAura),
            table.concat(failures, "; "),
        }, " | ")
    end
    return table.concat(lines, "\n")
end

-- Diagnostic values are checked before comparison, indexing, or presentation.
local function ResearchValue(value, valueType, allowNil)
    local canAccessValue = _G.canaccessvalue
    if not canAccessValue then return nil, "unavailable" end
    if not canAccessValue(value) then return nil, "inaccessible" end
    if value == nil and allowNil then return nil end
    if type(value) ~= valueType then return nil, "unexpected/nil result" end
    return value
end

-- Errors are contained within optional read-only research, never the remount engine.
local function QueryResearchValue(api, valueType, allowNil, ...)
    if type(api) ~= "function" then return nil, "unavailable" end
    local success, value = pcall(api, ...)
    if not success then return nil, "error" end
    return ResearchValue(value, valueType, allowNil)
end

-- Only ordinary nonnegative integers may become indices, IDs, or rank text.
local function ResearchInteger(value, allowZero)
    local number, failure = ResearchValue(value, "number")
    if failure then return nil, failure end
    if number % 1 ~= 0 or number < (allowZero and 0 or 1) then return nil, "unexpected integer" end
    return number
end

-- Context remains transient and inaccessible identity values stay unresolved.
local function NewResearchAudit(mode)
    local character, characterError = QueryResearchValue(_G.UnitName, "string", false, "player")
    local class, classError = QueryResearchValue(_G.UnitClass, "string", false, "player")
    return { mode = mode, entries = {}, issues = {}, total = 0,
        character = character and character:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "") or ("Unknown: " .. characterError),
        class = class and class:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "") or ("Unknown: " .. classError),
        counts = { passive = 0, harmful = 0, helpful = 0, selfBuff = 0, unresolved = 0,
            skipped = 0, unmapped = 0 } }
end

-- Shared research classification does not imply production authority or DB membership.
local function ResearchSpell(spellID)
    local entry = { id = spellID, errors = {} }
    if not spellID then
        entry.name, entry.nameResolved = "No primary spell mapping", false
        for _, field in ipairs({ "passive", "harmful", "helpful", "selfBuff" }) do
            entry.errors[field] = "no primary spell mapping"
        end
        return entry
    end
    local name, nameError = QueryAuditValue(C_Spell and C_Spell.GetSpellName, spellID, "string")
    entry.nameResolved = name ~= nil and name ~= ""
    entry.name = entry.nameResolved and name:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "") or "Unknown"
    entry.nameError = nameError or (not entry.nameResolved and "empty name" or nil)
    entry.harmful, entry.errors.harmful = QueryAuditValue(C_Spell and C_Spell.IsSpellHarmful, spellID, "boolean")
    entry.helpful, entry.errors.helpful = QueryAuditValue(C_Spell and C_Spell.IsSpellHelpful, spellID, "boolean")
    entry.selfBuff, entry.errors.selfBuff = QueryAuditValue(C_Spell and C_Spell.IsSelfBuff, spellID, "boolean")
    return entry
end

-- Stable ordering also retains distinct talent entries sharing one primary spell.
local function FinishResearchAudit(result)
    for _, entry in ipairs(result.entries) do
        for _, field in ipairs({ "passive", "harmful", "helpful", "selfBuff" }) do
            if entry[field] == true then result.counts[field] = result.counts[field] + 1 end
        end
        if next(entry.errors) or entry.nameError then result.counts.unresolved = result.counts.unresolved + 1 end
        if not entry.id then result.counts.unmapped = result.counts.unmapped + 1 end
    end
    table.sort(result.entries, function(a, b)
        if a.nameResolved ~= b.nameResolved then return a.nameResolved end
        local aName, bName = a.name:lower(), b.name:lower()
        if aName ~= bName then return aName < bName end
        if a.id ~= b.id then return (a.id or math.huge) < (b.id or math.huge) end
        if a.node ~= b.node then return (a.node or 0) < (b.node or 0) end
        return (a.entryID or 0) < (b.entryID or 0)
    end)
    result.total = #result.entries
    return result
end

local SPELLBOOK_NOTE = "Known player skill-line spells only; pet bank, profession offsets and flyout contents are not enumerated."
local TALENT_NOTE = "Selected active entries and primary definition SpellIDs only; secondary effects/auras and PvP talents are not enumerated."

-- Spellbook presence alone is insufficient: future and off-spec items must not become known-spell evidence.
local function CollectSpellbookAudit()
    local result = NewResearchAudit("Spellbook")
    local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player
    local spellType = Enum and Enum.SpellBookItemType and Enum.SpellBookItemType.Spell
    local numLines, failure = QueryResearchValue(C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines, "number")
    if numLines then numLines, failure = ResearchInteger(numLines, true) end
    if bank == nil or spellType == nil or not numLines then
        result.issues[1] = "Spellbook enumeration: " .. (failure or "unavailable enums")
        return FinishResearchAudit(result)
    end
    local seen = {}
    for lineIndex = 1, numLines do
        local line, lineError = QueryResearchValue(C_SpellBook and C_SpellBook.GetSpellBookSkillLineInfo,
            "table", false, lineIndex)
        local offset, size, offSpec, offsetError, sizeError, offSpecError
        if line then
            offset, offsetError = ResearchInteger(line.itemIndexOffset, true)
            size, sizeError = ResearchInteger(line.numSpellBookItems, true)
            offSpec, offSpecError = ResearchValue(line.offSpecID, "number", true)
        end
        if not line or offsetError or sizeError or offSpecError then
            result.issues[#result.issues + 1] = "Skill line " .. lineIndex .. ": "
                .. (lineError or offsetError or sizeError or offSpecError)
        elseif offSpec then
            result.counts.skipped = result.counts.skipped + size
        else
            for slot = offset + 1, offset + size do
                local item, itemError = QueryResearchValue(C_SpellBook and C_SpellBook.GetSpellBookItemInfo,
                    "table", false, slot, bank)
                local itemType, isOffSpec, typeError, specError
                if item then
                    itemType, typeError = ResearchValue(item.itemType, "number")
                    isOffSpec, specError = ResearchValue(item.isOffSpec, "boolean")
                end
                if not item or typeError or specError then
                    result.issues[#result.issues + 1] = "Spellbook slot " .. slot .. ": "
                        .. (itemError or typeError or specError)
                elseif itemType ~= spellType or isOffSpec then
                    result.counts.skipped = result.counts.skipped + 1
                else
                    local id, idError = ResearchInteger(item.spellID)
                    local known, knownError
                    if id then
                        known, knownError = QueryResearchValue(C_SpellBook and C_SpellBook.IsSpellKnown,
                            "boolean", false, id, bank)
                    end
                    if idError or knownError then
                        result.issues[#result.issues + 1] = "Spellbook slot " .. slot .. ": " .. (idError or knownError)
                    elseif not known then
                        result.counts.skipped = result.counts.skipped + 1
                    elseif not seen[id] then
                        seen[id] = true
                        local entry = ResearchSpell(id)
                        entry.itemType = "Spell"
                        entry.passive, entry.errors.passive = ResearchValue(item.isPassive, "boolean")
                        result.entries[#result.entries + 1] = entry
                    end
                end
            end
        end
    end
    return FinishResearchAudit(result)
end

-- Selected entries without definitions remain research rows rather than fabricated spell IDs.
local function AddTalentAuditEntry(result, configID, nodeID, entryID, rank)
    local info, infoError = QueryResearchValue(C_Traits and C_Traits.GetEntryInfo, "table", false, configID, entryID)
    local definitionID, mappingError
    if info then definitionID, mappingError = ResearchValue(info.definitionID, "number", true) end
    local definition, definitionError
    if definitionID then
        definitionID, mappingError = ResearchInteger(definitionID)
        if definitionID then
            definition, definitionError = QueryResearchValue(C_Traits and C_Traits.GetDefinitionInfo,
                "table", false, definitionID)
        end
    end
    local spellID, spellError
    if definition then
        spellID, spellError = ResearchValue(definition.spellID, "number", true)
        if spellID then spellID, spellError = ResearchInteger(spellID) end
    end
    local entry = ResearchSpell(spellID)
    entry.node, entry.entryID, entry.rank = nodeID, entryID, rank
    if not rank then entry.errors.rank = "rank unavailable for this entry" end
    if not spellID then entry.errors.mapping = infoError or mappingError or definitionError or spellError
        or "no primary spell mapping" end
    if spellID then
        entry.passive, entry.errors.passive = QueryAuditValue(C_Spell and C_Spell.IsSpellPassive, spellID, "boolean")
    end
    result.entries[#result.entries + 1] = entry
end

-- Staged edits are withheld so selection and rank describe the applied active configuration.
local function CollectTalentAudit()
    local result = NewResearchAudit("Talents")
    local configID, failure = QueryResearchValue(C_ClassTalents and C_ClassTalents.GetActiveConfigID, "number", true)
    if configID then configID, failure = ResearchInteger(configID) end
    result.config = configID and tostring(configID) or "Unavailable"
    if not configID then
        result.issues[1] = "Active talent configuration: " .. (failure or "none")
        return FinishResearchAudit(result)
    end
    local config, configError = QueryResearchValue(C_Traits and C_Traits.GetConfigInfo, "table", false, configID)
    if config then
        local name = ResearchValue(config.name, "string", true)
        if name then result.config = result.config .. " / " .. name:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "") end
    end
    local staged, stagedError = QueryResearchValue(C_Traits and C_Traits.ConfigHasStagedChanges, "boolean", false, configID)
    if not config or stagedError or staged then
        result.issues[1] = staged and "Uncommitted talent edits: apply or discard, then Refresh."
            or ("Talent configuration: " .. (configError or stagedError))
        return FinishResearchAudit(result)
    end
    local trees, treeError = ResearchValue(config.treeIDs, "table")
    if not trees then
        result.issues[1] = "Talent tree IDs: " .. treeError
        return FinishResearchAudit(result)
    end
    local seenNodes = {}
    for _, treeValue in ipairs(trees) do
        local treeID, idError = ResearchInteger(treeValue)
        local nodes, nodesError
        if treeID then nodes, nodesError = QueryResearchValue(C_Traits and C_Traits.GetTreeNodes, "table", false, treeID) end
        if not nodes then
            result.issues[#result.issues + 1] = "Talent tree: " .. (idError or nodesError)
        else
            for _, nodeValue in ipairs(nodes) do
                local nodeID, nodeIDError = ResearchInteger(nodeValue)
                if not nodeID then
                    result.issues[#result.issues + 1] = "Talent node ID: " .. nodeIDError
                elseif not seenNodes[nodeID] then
                    seenNodes[nodeID] = true
                    local node, nodeError = QueryResearchValue(C_Traits and C_Traits.GetNodeInfo, "table", false, configID, nodeID)
                    local committed, committedError, subtree, subtreeError
                    if node then
                        committed, committedError = ResearchValue(node.entryIDsWithCommittedRanks, "table")
                        subtree, subtreeError = ResearchValue(node.subTreeActive, "boolean", true)
                    end
                    if not node or committedError or subtreeError then
                        result.issues[#result.issues + 1] = "Talent node " .. nodeID .. ": "
                            .. (nodeError or committedError or subtreeError)
                    elseif subtree ~= false then
                        local active, activeError = ResearchValue(node.activeEntry, "table", true)
                        local activeID, rank
                        if active then
                            local activeIDError, rankError
                            activeID, activeIDError = ResearchInteger(active.entryID)
                            rank, rankError = ResearchInteger(active.rank, true)
                            activeError = activeIDError or rankError
                        end
                        if activeError then
                            result.issues[#result.issues + 1] = "Talent node " .. nodeID .. " active entry: " .. activeError
                        end
                        local selected = {}
                        for _, value in ipairs(committed) do
                            local entryID, entryError = ResearchInteger(value)
                            if entryID then selected[entryID] = true
                            else result.issues[#result.issues + 1] = "Talent entry ID: " .. entryError end
                        end
                        if activeID and rank and rank > 0 then selected[activeID] = true end
                        for entryID in pairs(selected) do
                            AddTalentAuditEntry(result, configID, nodeID, entryID, entryID == activeID and rank or nil)
                        end
                    end
                end
            end
        end
    end
    return FinishResearchAudit(result)
end

-- Exports the same research fields and explicit limitations used by the visible snapshot.
local function BuildResearchAuditText(result)
    local c = result.counts
    local lines = { "Odysseus AutoRemount Audit — " .. result.mode, "Character: " .. result.character,
        "Class: " .. result.class }
    if result.config then lines[#lines + 1] = "Active Config: " .. result.config end
    lines[#lines + 1] = "Entries: " .. result.total .. " | Passive: " .. c.passive .. " | Harmful: " .. c.harmful
        .. " | Helpful: " .. c.helpful .. " | Self Buff: " .. c.selfBuff .. " | Unresolved rows: " .. c.unresolved
        .. " | Skipped slots: " .. c.skipped .. " | Unmapped entries: " .. c.unmapped
    lines[#lines + 1] = result.mode == "Spellbook" and SPELLBOOK_NOTE or TALENT_NOTE
    lines[#lines + 1] = AUDIT_STATIC_NOTE
    lines[#lines + 1] = AUDIT_SELF_NOTE
    for _, issue in ipairs(result.issues) do lines[#lines + 1] = "Unavailable: " .. issue end
    lines[#lines + 1] = result.mode == "Spellbook"
        and "SpellID | Name | Type | Passive | Harmful | Helpful | Self Buff | Notes"
        or "SpellID | Name | Node | Entry | Rank | Passive | Harmful | Helpful | Self Buff | Notes"
    for _, entry in ipairs(result.entries) do
        local fields = { entry.id and tostring(entry.id) or "?", entry.name }
        if result.mode == "Spellbook" then fields[#fields + 1] = entry.itemType
        else
            fields[#fields + 1] = tostring(entry.node)
            fields[#fields + 1] = tostring(entry.entryID)
            fields[#fields + 1] = entry.rank and tostring(entry.rank) or "?"
        end
        local failures = {}
        for _, field in ipairs({ "passive", "harmful", "helpful", "selfBuff" }) do
            fields[#fields + 1] = AuditValueText(entry[field], entry.errors[field])
        end
        for _, field in ipairs({ "mapping", "rank", "passive", "harmful", "helpful", "selfBuff" }) do
            if entry.errors[field] then failures[#failures + 1] = field .. "=" .. entry.errors[field] end
        end
        if entry.nameError then failures[#failures + 1] = "name=" .. entry.nameError end
        fields[#fields + 1] = table.concat(failures, "; ")
        lines[#lines + 1] = table.concat(fields, " | ")
    end
    return table.concat(lines, "\n")
end

-- Strips WoW link formatting from a mount name dragged into chat.
local function CleanMountName(name)
    if not name then return nil end
    local linkName = name:match("|h%[(.+)%]|h")
    name = linkName or name
    name = name
        :gsub("|c%x%x%x%x%x%x%x%x", "")
        :gsub("|r", "")
        :gsub("|H.-|h", "")
        :gsub("[%[%]]", "")
        :match("^%s*(.-)%s*$")
    return name
end

-- Finds a collected mount ID by exact name match.
local function FindMountIDByName(searchName)
    for _, mountID in ipairs(C_MountJournal.GetMountIDs()) do
        local name, _, _, _, _, _, _, _, _, _, isCollected =
            C_MountJournal.GetMountInfoByID(mountID)
        if isCollected and name == searchName then
            return mountID, name
        end
    end
    return nil
end

-- Returns true if the player is in a dungeon or raid (not delves).
local function IsInRestrictedInstance()
    local _, instanceType = IsInInstance()
    return instanceType == "party" or instanceType == "raid"
end

-- Returns true if spellID is in the master spell list.
local function IsKnownGatherSpell(spellID)
    return spellID and OUS.AutoRemountSpells and OUS.AutoRemountSpells[spellID] or false
end

-- Returns true if spellID is in the custom spell list.
local function IsInCustomSpells(spellID)
    local custom = OdysseusDB.autoRemount.customSpells
    if not custom then return false end
    for _, id in ipairs(custom) do
        if id == spellID then return true end
    end
    return false
end

-- Returns true if spellID is in the permanent exclude list.
local function IsExcludedSpell(spellID)
    return spellID and OUS.AutoRemountExcludeSpells and OUS.AutoRemountExcludeSpells[spellID] or false
end

-- Returns true if spellID is already in the discovered spy list.
local function IsInDiscoveredSpells(spellID)
    local discovered = OdysseusDB.autoRemount.discoveredSpells
    if not discovered then return false end
    for _, entry in ipairs(discovered) do
        if entry.id == spellID then return true end
    end
    return false
end

-- Returns true if spellID is in the persisted spy filter blacklist.
local function IsSpyBlacklisted(spellID)
    local filter = OdysseusDB.autoRemount.spyFilter
    if not filter then return false end
    for _, id in ipairs(filter) do
        if id == spellID then return true end
    end
    return false
end

-- Returns true if the player currently has a profession crafting UI open.
local function IsProfessionCraftingContext()
    if ProfessionsFrame and ProfessionsFrame:IsShown() then return true end
    if TradeSkillFrame and TradeSkillFrame:IsShown() then return true end
    return false
end

local function IsMountSpell(spellID)
    if not spellID or not C_MountJournal or not C_MountJournal.GetMountFromSpell then
        return false
    end

    local mountID = C_MountJournal.GetMountFromSpell(spellID)
    return mountID ~= nil
end

-- Returns true if the spell is obviously not useful for AutoRemount spy detection.
local function IsIgnoredSpyCategorySpell(spellID)
    if not spellID then return false end
    return IsMountSpell(spellID)
end

-- Returns true if all safety conditions allow remounting.
local function CanRemount()
    local db = OdysseusDB.autoRemount
    if not db.enabled then return false end
    if IsMounted() then return false end
    if IsFlying() then return false end
    if InCombatLockdown() then return false end
    if UnitIsDeadOrGhost("player") then return false end
    if IsInRestrictedInstance() then return false end
    if IsProfessionCraftingContext() then
        OUS.LogDebug("AutoRemount", "Remount skipped — profession crafting context detected.")
        return false
    end

    -- Skip druids in any shapeshift form (Travel Form etc.)
    if db.skipDruid then
        local _, class = UnitClass("player")
        if class == "DRUID" and GetShapeshiftForm() ~= 0 then
            return false
        end
    end

    return true
end

local function FormatSpellEntry(entry)
    return string.format("    [%d] = true,   -- %s", entry.id, entry.name or "Unknown")
end

-- ==========================================
-- 3. MOUNT LOGIC
-- ==========================================

-- Resolves mount ID: character override → account → favourite (0).
local function GetMountID()
    local charDB = OdysseusCharDB.autoRemountChar
    local db = OdysseusDB.autoRemount
    return charDB.mountID or db.accountMountID or 0
end

local function TryRemount()
    if not CanRemount() then
        OUS.LogDebug("AutoRemount", "Remount skipped — safety check failed.")
        return
    end

    local mountID = GetMountID()
    OUS.LogDebug("AutoRemount", "Attempting remount. mountID: " .. tostring(mountID))

    isTryingToMount = true
    C_MountJournal.SummonByID(mountID)

    -- Clear flag after 2s whether or not an error fired.
    C_Timer.After(2, function()
        isTryingToMount = false
    end)
end

-- Cancels the no-loot fallback timer if it's running.
local function CancelNoLootTimer()
    if noLootTimer then
        noLootTimer:Cancel()
        noLootTimer = nil
    end
end

-- Discards the entire pending Spy association so no expired evidence survives.
local function ClearPendingSpySpell(reason)
    -- Keep invalidation reasons attached to the candidate being discarded.
    if reason and pendingSpySpellID then
        LogSpellDebug("Spy candidate cleared " .. reason .. ": ", pendingSpySpellID)
    end
    pendingSpySpellID = nil
    pendingSpyLootObserved = false
    if pendingSpyTimer then
        pendingSpyTimer:Cancel()
        pendingSpyTimer = nil
    end
end

-- Confirms a pending spy spell after loot trigger — records and notifies only on first discovery.
local function ConfirmSpySpell()
    if not pendingSpySpellID then return end
    if not OdysseusDB.autoRemount.spyMode then return end

    local spellID = pendingSpySpellID

    -- Permanent exclusions always reject Spy confirmation.
    if IsExcludedSpell(spellID) then return end

    -- Also ignore if already in custom list.
    if IsInCustomSpells(spellID) then return end

    -- Log valid associations even when the SpellID was already discovered.
    LogSpellDebug("Spy candidate confirmed: ", spellID)
    local spellName = C_Spell.GetSpellName(spellID) or "Unknown"

    -- Add to spy frame discovered list if not already there.
    if not IsInDiscoveredSpells(spellID) then
        if not OdysseusDB.autoRemount.discoveredSpells then
            OdysseusDB.autoRemount.discoveredSpells = {}
        end
        table.insert(OdysseusDB.autoRemount.discoveredSpells, {
            id   = spellID,
            name = spellName,
        })
        if OUS.AutoRemount and OUS.AutoRemount.RefreshSpyFrame then
            OUS.AutoRemount.RefreshSpyFrame()
        end
        print("|cFF00CCFFOdysseus AutoRemount Spy:|r New spell discovered: "
            .. spellName .. " (" .. tostring(spellID) .. ")")
    end
end

-- Starts the no-loot fallback timer after a gather spell with no loot window.
local function StartNoLootTimer(interactionID)
    CancelNoLootTimer()
    local delay = OdysseusDB.autoRemount.delay or 0.5
    noLootTimer = C_Timer.NewTimer(1.5 + delay, function()
        -- A stale fallback must not clear a newer interaction's state or timer.
        if interactionID ~= currentInteractionID then return end
        noLootTimer = nil
        if not lootWindowOpened and isGathering then
            OUS.LogDebug("AutoRemount", "No loot window detected — remounting via fallback.")
            -- Spy confirms only on LOOT_CLOSED after loot evidence, never through this fallback.
            isGathering = false
            TryRemount()
        end
    end)
end

-- ==========================================
-- 4. SPY FRAME
-- ==========================================
local spyFrame = CreateFrame("Frame", "OdysseusAutoRemountSpyFrame", UIParent, "BackdropTemplate")
spyFrame:SetSize(420, 300)
spyFrame:SetPoint("CENTER")
spyFrame:SetFrameStrata("DIALOG")
spyFrame:Hide()
spyFrame:SetMovable(true)
spyFrame:SetClampedToScreen(true)
spyFrame:EnableMouse(true)
spyFrame:RegisterForDrag("LeftButton")
spyFrame:SetScript("OnDragStart", spyFrame.StartMoving)
spyFrame:SetScript("OnDragStop", spyFrame.StopMovingOrSizing)
tinsert(UISpecialFrames, spyFrame:GetName())

spyFrame:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = false, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
spyFrame:SetBackdropColor(0.07, 0.05, 0.1, 0.95)
spyFrame:SetBackdropBorderColor(0.0, 0.8, 1.0, 1)

-- Header bar
local spyHeaderBg = spyFrame:CreateTexture(nil, "BACKGROUND", nil, 2)
spyHeaderBg:SetPoint("TOPLEFT", 4, -4)
spyHeaderBg:SetPoint("TOPRIGHT", -4, -4)
spyHeaderBg:SetHeight(28)
spyHeaderBg:SetColorTexture(1, 1, 1, 1)
spyHeaderBg:SetGradient("HORIZONTAL",
    CreateColor(0.3, 0.1, 0.5, 0.8),
    CreateColor(0.07, 0.05, 0.1, 0.8)
)

local spyTitle = spyFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
spyTitle:SetPoint("TOP", spyFrame, "TOP", 0, -12)
spyTitle:SetText("|cFF00FFFFOdysseus AutoRemount|r — Custom Spell List")
spyTitle:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")

local spyCloseBtn = CreateFrame("Button", nil, spyFrame, "UIPanelCloseButton")
spyCloseBtn:SetPoint("TOPRIGHT", spyFrame, "TOPRIGHT", -2, -2)
spyCloseBtn:SetScript("OnClick", function() spyFrame:Hide() end)

-- ScrollingMessageFrame for clean list display
local spyMsgFrame = CreateFrame("ScrollingMessageFrame", nil, spyFrame)
spyMsgFrame:SetPoint("TOPLEFT", 10, -38)
spyMsgFrame:SetPoint("BOTTOMRIGHT", -10, 44)
spyMsgFrame:SetFontObject(GameFontNormalSmall)
spyMsgFrame:SetJustifyH("LEFT")
spyMsgFrame:SetFading(false)
spyMsgFrame:SetMaxLines(200)

-- Copy overlay
local spyCopyOverlay = CreateFrame("ScrollFrame", nil, spyFrame, "UIPanelScrollFrameTemplate")
spyCopyOverlay:SetPoint("TOPLEFT", 10, -38)
spyCopyOverlay:SetPoint("BOTTOMRIGHT", -30, 44)
spyCopyOverlay:Hide()

local spyCopyEditBox = CreateFrame("EditBox", nil, spyCopyOverlay)
spyCopyEditBox:SetMultiLine(true)
spyCopyEditBox:SetFontObject(GameFontNormalSmall)
spyCopyEditBox:SetWidth(360)
spyCopyEditBox:SetAutoFocus(false)
spyCopyOverlay:SetScrollChild(spyCopyEditBox)

-- Bottom buttons
local spyCopyBtn = CreateFrame("Button", nil, spyFrame, "UIPanelButtonTemplate")
spyCopyBtn:SetSize(100, 22)
spyCopyBtn:SetPoint("BOTTOMLEFT", 10, 12)
spyCopyBtn:SetText("Copy All")

local spyRefreshBtn = CreateFrame("Button", nil, spyFrame, "UIPanelButtonTemplate")
spyRefreshBtn:SetSize(70, 22)
spyRefreshBtn:SetPoint("LEFT", spyCopyBtn, "RIGHT", 8, 0)
spyRefreshBtn:SetText("Refresh")

local spyClearBtn = CreateFrame("Button", nil, spyFrame, "UIPanelButtonTemplate")
spyClearBtn:SetSize(80, 22)
spyClearBtn:SetPoint("LEFT", spyRefreshBtn, "RIGHT", 8, 0)
spyClearBtn:SetText("Clear")

local spyCountText = spyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
spyCountText:SetPoint("BOTTOMRIGHT", spyFrame, "BOTTOMRIGHT", -14, 16)
spyCountText:SetTextColor(0.6, 0.6, 0.6)

StaticPopupDialogs["ODYSSEUS_CONFIRM_WIPE_SPY"] = {
    text = "Are you sure you want to clear all discovered spy spells? This cannot be undone.",
    button1 = "Clear",
    button2 = "Cancel",
    OnAccept = function()
        OdysseusDB.autoRemount.discoveredSpells = {}
        AR.RefreshSpyFrame()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- Rebuilds the spy frame from persisted DB.
function AR.RefreshSpyFrame()
    spyCopyOverlay:Hide()
    spyMsgFrame:Show()
    spyCopyBtn:SetText("Copy All")
    spyMsgFrame:Clear()

    local discovered = OdysseusDB.autoRemount.discoveredSpells or {}
    for _, entry in ipairs(discovered) do
        spyMsgFrame:AddMessage(FormatSpellEntry(entry))
    end

    local count = #discovered
    spyCountText:SetText(count .. " spell" .. (count == 1 and "" or "s") .. " discovered")
end

spyCopyBtn:SetScript("OnClick", function()
    if spyCopyOverlay:IsShown() then
        spyCopyOverlay:Hide()
        spyMsgFrame:Show()
        spyCopyBtn:SetText("Copy All")
    else
        local discovered = OdysseusDB.autoRemount.discoveredSpells or {}
        if #discovered == 0 then
            print("|cFF00CCFFOdysseus AutoRemount:|r No discovered spells to copy.")
            return
        end
        local lines = {}
        for _, entry in ipairs(discovered) do
            table.insert(lines, FormatSpellEntry(entry))
        end
        spyMsgFrame:Hide()
        spyCopyEditBox:SetText(table.concat(lines, "\n"))
        spyCopyOverlay:Show()
        spyCopyEditBox:HighlightText()
        spyCopyEditBox:SetFocus()
        spyCopyBtn:SetText("Back to List")
    end
end)

spyRefreshBtn:SetScript("OnClick", function()
    AR.RefreshSpyFrame()
end)

spyClearBtn:SetScript("OnClick", function()
    StaticPopup_Show("ODYSSEUS_CONFIRM_WIPE_SPY")
end)

-- User-approved triggers have their own UI and never share Spy discovery storage.
local customFrame, customContent, customCountText, customEmpty
local customRows = {}

-- Refreshes a display copy so rendering never reorders the approved trigger list.
function AR.RefreshCustomSpellsFrame()
    if not customFrame then return end
    for _, row in ipairs(customRows) do row:Hide() end
    local entries = {}
    for _, spellID in ipairs(OdysseusDB.autoRemount.customSpells or {}) do
        entries[#entries + 1] = spellID
    end
    table.sort(entries)
    for i, spellID in ipairs(entries) do
        local row = customRows[i]
        if not row then
            row = CreateFrame("Frame", nil, customContent)
            row:SetSize(370, 36)
            row.icon = row:CreateTexture(nil, "ARTWORK")
            row.icon:SetSize(22, 22)
            row.icon:SetPoint("LEFT", 4, 0)
            row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            row.label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            row.label:SetPoint("TOPLEFT", 30, -3)
            row.label:SetWidth(272)
            row.label:SetJustifyH("LEFT")
            row.label:SetWordWrap(false)
            row.idText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            row.idText:SetPoint("TOPLEFT", row.label, "BOTTOMLEFT", 0, -2)
            row.removeBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            row.removeBtn:SetSize(60, 20)
            row.removeBtn:SetPoint("RIGHT", -2, 0)
            row.removeBtn:SetText("Remove")
            customRows[i] = row
        end
        local name, icon = "Unknown Spell", nil
        local canAccessValue = _G.canaccessvalue
        if canAccessValue and canAccessValue(spellID) then
            if C_Spell and C_Spell.GetSpellName then
                local success, value = pcall(C_Spell.GetSpellName, spellID)
                if success and canAccessValue(value) and type(value) == "string" and value ~= "" then name = value end
            end
            if C_Spell and C_Spell.GetSpellTexture then
                local success, value = pcall(C_Spell.GetSpellTexture, spellID)
                if success and canAccessValue(value) and type(value) == "number" then icon = value end
            end
        end
        row.label:SetText(name)
        row.idText:SetText("SpellID: " .. tostring(spellID))
        row.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        row:SetPoint("TOPLEFT", 0, -(i - 1) * 36)
        row.removeBtn:SetScript("OnClick", function() AR.SlashHandler("remove " .. tostring(spellID)) end)
        row:Show()
    end
    customContent:SetHeight(math.max(#entries * 36, 1))
    customCountText:SetText(#entries .. " custom spells")
    if #entries == 0 then customEmpty:Show() else customEmpty:Hide() end
end

-- Opens a separate user-approved list; Spy discoveries never populate this frame.
function AR.ShowCustomSpellsFrame()
    if not customFrame then
        customFrame = CreateFrame("Frame", "OdysseusAutoRemountCustomSpellsFrame", UIParent, "BackdropTemplate")
        customFrame:SetSize(420, 350)
        customFrame:SetPoint("CENTER")
        customFrame:SetFrameStrata("DIALOG")
        customFrame:SetMovable(true)
        customFrame:SetClampedToScreen(true)
        customFrame:EnableMouse(true)
        customFrame:RegisterForDrag("LeftButton")
        customFrame:SetScript("OnDragStart", customFrame.StartMoving)
        customFrame:SetScript("OnDragStop", customFrame.StopMovingOrSizing)
        customFrame:SetBackdrop({
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = false, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 },
        })
        customFrame:SetBackdropColor(0.07, 0.05, 0.1, 0.95)
        customFrame:SetBackdropBorderColor(0, 0.8, 1, 1)
        tinsert(UISpecialFrames, "OdysseusAutoRemountCustomSpellsFrame")
        local title = customFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        title:SetPoint("TOP", 0, -12)
        title:SetText("|cFF00FFFFAutoRemount Custom Spells|r")
        local close = CreateFrame("Button", nil, customFrame, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", -2, -2)
        close:SetScript("OnClick", function() customFrame:Hide() end)

        local inputLabel = customFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        inputLabel:SetPoint("TOPLEFT", 10, -42)
        inputLabel:SetText("SpellID")
        local input = CreateFrame("EditBox", nil, customFrame, "InputBoxTemplate")
        input:SetSize(174, 24)
        input:SetPoint("TOPLEFT", 72, -36)
        input:SetAutoFocus(false)
        input:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        local add = CreateFrame("Button", nil, customFrame, "UIPanelButtonTemplate")
        add:SetSize(120, 24)
        add:SetPoint("LEFT", input, "RIGHT", 10, 0)
        add:SetText("Add Spell")
        -- Reuses the legacy command so UI approval has exactly the same authority.
        local function AddFromInput()
            local spellID = tonumber(input:GetText())
            local alreadyAdded = spellID and IsInCustomSpells(spellID)
            AR.SlashHandler("add " .. input:GetText())
            if spellID and not alreadyAdded and IsInCustomSpells(spellID) then
                input:SetText("")
                input:ClearFocus()
            end
        end
        add:SetScript("OnClick", AddFromInput)
        input:SetScript("OnEnterPressed", AddFromInput)

        local scroll = CreateFrame("ScrollFrame", nil, customFrame, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 10, -70)
        scroll:SetPoint("BOTTOMRIGHT", -30, 50)
        customContent = CreateFrame("Frame", nil, scroll)
        customContent:SetSize(375, 1)
        scroll:SetScrollChild(customContent)
        customEmpty = customFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        customEmpty:SetPoint("CENTER", 0, 0)
        customEmpty:SetText("No custom spells. Add a SpellID above.")
        customCountText = customFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        customCountText:SetPoint("BOTTOMRIGHT", -14, 16)
        local clear = CreateFrame("Button", nil, customFrame, "UIPanelButtonTemplate")
        clear:SetSize(120, 24)
        clear:SetPoint("BOTTOMLEFT", 10, 12)
        clear:SetText("Clear All")
        clear:SetScript("OnClick", function() StaticPopup_Show("ODYSSEUS_CONFIRM_CLEAR_AR_CUSTOM") end)
        StaticPopupDialogs["ODYSSEUS_CONFIRM_CLEAR_AR_CUSTOM"] = {
            text = "Clear the entire AutoRemount custom spell list?",
            button1 = "Clear", button2 = "Cancel",
            OnAccept = function() AR.SlashHandler("wipe") end,
            timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
        }
        customFrame:SetScript("OnHide", function() input:ClearFocus() end)
    end
    AR.RefreshCustomSpellsFrame()
    customFrame:Show()
end

-- Audit snapshots belong only to this display, never to production state or SavedVariables.
local auditFrame, auditSummary, auditNote, auditHeaders, auditScroll, auditBar, auditContent
local auditCopy, auditCopyBar, auditCopyBtn
local auditRows = {}
local auditMode = "DB Audit"
local auditModeButtons, auditHeaderCells = {}, {}
local auditColumnSets = {
    ["DB Audit"] = {
        { title = "SpellID", field = "id", x = 0, width = 68 },
        { title = "Name", field = "name", x = 70, width = 238 },
        { title = "Harmful", field = "harmful", x = 312, width = 60, color = { 1, 0.3, 0.3 } },
        { title = "Helpful", field = "helpful", x = 374, width = 60, color = { 0.3, 1, 0.4 } },
        { title = "Mount", field = "mountID", x = 436, width = 80, color = { 0, 0.8, 1 } },
        { title = "Self Buff", field = "selfBuff", x = 518, width = 82, color = { 0.75, 0.5, 1 } },
        { title = "Active Aura Now", field = "activeAura", x = 602, width = 146, color = { 0.75, 0.5, 1 } },
    },
    ["Spellbook"] = {
        { title = "SpellID", field = "id", x = 0, width = 68 },
        { title = "Name", field = "name", x = 70, width = 238 },
        { title = "Type", field = "itemType", x = 312, width = 68 },
        { title = "Passive", field = "passive", x = 382, width = 72, color = { 0.75, 0.5, 1 } },
        { title = "Harmful", field = "harmful", x = 456, width = 80, color = { 1, 0.3, 0.3 } },
        { title = "Helpful", field = "helpful", x = 538, width = 80, color = { 0.3, 1, 0.4 } },
        { title = "Self Buff", field = "selfBuff", x = 620, width = 128, color = { 0.75, 0.5, 1 } },
    },
    ["Talents"] = {
        { title = "SpellID", field = "id", x = 0, width = 68 },
        { title = "Name", field = "name", x = 70, width = 220 },
        { title = "Node", field = "node", x = 292, width = 70 },
        { title = "Rank", field = "rank", x = 364, width = 44 },
        { title = "Passive", field = "passive", x = 410, width = 70, color = { 0.75, 0.5, 1 } },
        { title = "Harmful", field = "harmful", x = 482, width = 70, color = { 1, 0.3, 0.3 } },
        { title = "Helpful", field = "helpful", x = 554, width = 70, color = { 0.3, 1, 0.4 } },
        { title = "Self Buff", field = "selfBuff", x = 626, width = 122, color = { 0.75, 0.5, 1 } },
    },
}

-- Compact BackdropTemplate controls follow the standalone Help navigation pattern.
local function CreateAuditButton(text, width, x, onClick)
    local button = CreateFrame("Button", nil, auditFrame, "BackdropTemplate")
    button:SetSize(width, 24)
    button:SetPoint("TOPLEFT", x, -82)
    button:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    button.label = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    button.label:SetPoint("CENTER")
    button.label:SetText(text)
    button.UpdateAppearance = function()
        if button.pressed then button:SetBackdropColor(0.12, 0.05, 0.2, 1)
        elseif button.hovered then button:SetBackdropColor(0.27, 0.14, 0.4, 1)
        elseif button.selected then button:SetBackdropColor(0.2, 0.1, 0.31, 1)
        else button:SetBackdropColor(0.1, 0.06, 0.16, 1) end
        if button.selected or button.hovered then
            button:SetBackdropBorderColor(0, 0.8, 1, 1)
            button.label:SetTextColor(0, 1, 1)
        else
            button:SetBackdropBorderColor(0.3, 0.32, 0.48, 1)
            button.label:SetTextColor(0.75, 0.85, 0.95)
        end
    end
    button:SetScript("OnEnter", function() button.hovered = true; button.UpdateAppearance() end)
    button:SetScript("OnLeave", function()
        button.hovered, button.pressed = false, false
        button.UpdateAppearance()
    end)
    button:SetScript("OnMouseDown", function() button.pressed = true; button.UpdateAppearance() end)
    button:SetScript("OnMouseUp", function() button.pressed = false; button.UpdateAppearance() end)
    button:SetScript("OnClick", onClick)
    button.UpdateAppearance()
    return button
end

-- Switches between the current snapshot's rows and its selectable plain-text report.
local function SetAuditCopyMode(copy)
    if copy then
        auditHeaders:Hide()
        auditScroll:Hide()
        auditBar:Hide()
        auditContent:Hide()
        auditCopy:SetText(auditFrame.copyText)
        auditCopy:Show()
        auditCopyBar:Show()
        auditCopy:GetEditBox():HighlightText()
        auditCopy:SetFocus()
        auditCopyBtn.label:SetText("Back to List")
    else
        auditCopy:ClearFocus()
        auditCopy:Hide()
        auditCopyBar:Hide()
        auditHeaders:Show()
        auditScroll:Show()
        auditBar:Show()
        auditContent:Show()
        auditCopyBtn.label:SetText("Copy All")
    end
end

-- Creates only addon-owned, unprotected UI with fixed anchors and native scrolling controls.
local function CreateAuditFrame()
    auditFrame = CreateFrame("Frame", "OdysseusAutoRemountExclusionAuditFrame", UIParent, "BackdropTemplate")
    auditFrame:SetSize(800, 560)
    auditFrame:SetPoint("CENTER")
    auditFrame:SetFrameStrata("DIALOG")
    auditFrame:Hide()
    auditFrame:SetMovable(true)
    auditFrame:SetClampedToScreen(true)
    auditFrame:EnableMouse(true)
    auditFrame:RegisterForDrag("LeftButton")
    auditFrame:SetScript("OnDragStart", auditFrame.StartMoving)
    auditFrame:SetScript("OnDragStop", auditFrame.StopMovingOrSizing)
    auditFrame:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    auditFrame:SetBackdropColor(0.07, 0.05, 0.1, 0.95)
    auditFrame:SetBackdropBorderColor(0, 0.8, 1, 1)
    tinsert(UISpecialFrames, "OdysseusAutoRemountExclusionAuditFrame")
    local header = auditFrame:CreateTexture(nil, "BACKGROUND", nil, 2)
    header:SetPoint("TOPLEFT", 4, -4)
    header:SetPoint("TOPRIGHT", -4, -4)
    header:SetHeight(28)
    header:SetColorTexture(1, 1, 1, 1)
    header:SetGradient("HORIZONTAL", CreateColor(0.3, 0.1, 0.5, 0.8), CreateColor(0.07, 0.05, 0.1, 0.8))
    local title = auditFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", 0, -12)
    title:SetText("Odysseus AutoRemount — Audit")
    title:SetTextColor(0, 1, 1)
    local close = CreateFrame("Button", nil, auditFrame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -2, -2)
    close:SetScript("OnClick", function() auditFrame:Hide() end)
    auditSummary = auditFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    auditSummary:SetPoint("TOPLEFT", 12, -42)
    auditSummary:SetSize(776, 32)
    auditSummary:SetJustifyH("LEFT")
    auditNote = auditFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    auditNote:SetPoint("TOPLEFT", 12, -114)
    auditNote:SetSize(776, 44)
    auditNote:SetJustifyH("LEFT")
    auditNote:SetTextColor(0.7, 0.7, 0.7)
    auditHeaders = CreateFrame("Frame", nil, auditFrame)
    auditHeaders:SetPoint("TOPLEFT", 12, -166)
    auditHeaders:SetSize(748, 18)
    auditScroll = CreateFrame("Frame", nil, auditFrame, "WowScrollBox")
    auditScroll:SetPoint("TOPLEFT", 12, -188)
    auditScroll:SetPoint("BOTTOMRIGHT", -36, 16)
    auditBar = CreateFrame("EventFrame", nil, auditFrame, "MinimalScrollBar")
    auditBar:SetPoint("TOPLEFT", auditScroll, "TOPRIGHT", 8, 0)
    auditBar:SetPoint("BOTTOMLEFT", auditScroll, "BOTTOMRIGHT", 8, 0)
    auditContent = CreateFrame("Frame", nil, auditScroll)
    auditContent:SetSize(748, 1)
    auditContent.scrollable = true
    local view = CreateScrollBoxLinearView()
    view:SetPanExtent(22)
    ScrollUtil.InitScrollBoxWithScrollBar(auditScroll, auditBar, view)

    auditCopy = CreateFrame("Frame", nil, auditFrame, "ScrollingEditBoxTemplate")
    auditCopy:SetPoint("TOPLEFT", 12, -166)
    auditCopy:SetPoint("BOTTOMRIGHT", -36, 16)
    auditCopy:SetFontObject("GameFontNormalSmall")
    auditCopy:GetEditBox():SetMaxLetters(0)
    auditCopyBar = CreateFrame("EventFrame", nil, auditFrame, "MinimalScrollBar")
    auditCopyBar:SetPoint("TOPLEFT", auditCopy, "TOPRIGHT", 8, 0)
    auditCopyBar:SetPoint("BOTTOMLEFT", auditCopy, "BOTTOMRIGHT", 8, 0)
    ScrollUtil.RegisterScrollBoxWithScrollBar(auditCopy:GetScrollBox(), auditCopyBar)
    ScrollUtil.InitScrollBar(auditCopy:GetScrollBox(), auditCopyBar)
    auditCopy:RegisterCallback("OnEscapePressed", function() SetAuditCopyMode(false) end)
    auditCopy:Hide()
    auditCopyBar:Hide()

    local x = 58
    for _, mode in ipairs({ "DB Audit", "Spellbook", "Talents" }) do
        local selectedMode = mode
        auditModeButtons[mode] = CreateAuditButton(mode, 104, x, function() AR.ShowAuditFrame(selectedMode) end)
        x = x + 112
    end
    x = x + 12
    CreateAuditButton("Refresh", 100, x, function() AR.RefreshAuditFrame() end)
    auditCopyBtn = CreateAuditButton("Copy All", 120, x + 108, function() SetAuditCopyMode(not auditCopy:IsShown()) end)
    CreateAuditButton("Close", 100, x + 236, function() auditFrame:Hide() end)
    auditFrame:SetScript("OnHide", function()
        auditFrame:StopMovingOrSizing()
        SetAuditCopyMode(false)
    end)
end

-- Refreshes only the selected research mode and replaces its display snapshot together.
function AR.RefreshAuditFrame()
    if not auditFrame then CreateAuditFrame() end
    local result
    if auditMode == "Spellbook" then result = CollectSpellbookAudit()
    elseif auditMode == "Talents" then result = CollectTalentAudit()
    else result = CollectExclusionAudit() end
    auditFrame.copyText = auditMode == "DB Audit" and BuildExclusionAuditText(result) or BuildResearchAuditText(result)
    SetAuditCopyMode(false)
    for mode, button in pairs(auditModeButtons) do
        button.selected = mode == auditMode
        button.UpdateAppearance()
    end
    local c = result.counts
    if auditMode == "DB Audit" then
        auditSummary:SetText("Exclusions: " .. result.total .. "    Harmful: " .. c.harmful
            .. "    Helpful: " .. c.helpful .. "    Mounts: " .. c.mounts .. "    Unresolved: " .. c.unresolved
            .. "\nSelf Buff: " .. c.selfBuff .. "    Active Aura Now: " .. c.activeAura
            .. "    Unresolved names: " .. c.namesUnresolved)
        auditNote:SetText(AUDIT_STATIC_NOTE .. "\n" .. AUDIT_SELF_NOTE .. "\n" .. AUDIT_ACTIVE_NOTE)
    else
        auditSummary:SetText(auditMode .. ": " .. result.total .. " entries    " .. result.character .. " / " .. result.class
            .. (result.config and ("    Config: " .. result.config) or "")
            .. "\nPassive: " .. c.passive .. "    Harmful: " .. c.harmful .. "    Helpful: " .. c.helpful
            .. "    Self Buff: " .. c.selfBuff .. "    Unresolved rows: " .. c.unresolved
            .. "    Issues: " .. #result.issues .. "    Skipped: " .. c.skipped .. "    Unmapped: " .. c.unmapped)
        auditNote:SetText((auditMode == "Spellbook" and SPELLBOOK_NOTE or TALENT_NOTE) .. "\n" .. AUDIT_SELF_NOTE
            .. "\n" .. (result.issues[1] or AUDIT_STATIC_NOTE))
    end
    local columns = auditColumnSets[auditMode]
    for _, label in ipairs(auditHeaderCells) do label:Hide() end
    for j, column in ipairs(columns) do
        local label = auditHeaderCells[j]
        if not label then
            label = auditHeaders:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            label:SetJustifyH("LEFT")
            label:SetTextColor(0, 0.8, 1)
            auditHeaderCells[j] = label
        end
        label:ClearAllPoints()
        label:SetPoint("LEFT", column.x, 0)
        label:SetWidth(column.width)
        label:SetText(column.title)
        label:Show()
    end
    for _, row in ipairs(auditRows) do row:Hide() end
    for i, entry in ipairs(result.entries) do
        local row = auditRows[i]
        if not row then
            row = CreateFrame("Frame", nil, auditContent)
            row:SetSize(748, 22)
            row.cells = {}
            auditRows[i] = row
        end
        row:SetPoint("TOPLEFT", 0, -(i - 1) * 22)
        for _, cell in ipairs(row.cells) do cell:Hide() end
        for j, column in ipairs(columns) do
            local cell = row.cells[j]
            if not cell then
                cell = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                cell:SetJustifyH("LEFT")
                cell:SetWordWrap(false)
                row.cells[j] = cell
            end
            cell:ClearAllPoints()
            cell:SetPoint("LEFT", column.x, 0)
            cell:SetWidth(column.width)
            local value, failure = entry[column.field], entry.errors[column.field]
            if column.field == "id" or column.field == "node" or column.field == "rank" or column.field == "itemType" then
                cell:SetText(value ~= nil and tostring(value) or "?")
                if value == nil then cell:SetTextColor(1, 0.8, 0) else cell:SetTextColor(0.85, 0.85, 0.85) end
            elseif column.field == "name" then
                cell:SetText(value)
                if entry.nameResolved then cell:SetTextColor(0.85, 0.85, 0.85) else cell:SetTextColor(1, 0.8, 0) end
            else
                local mount = column.field == "mountID"
                cell:SetText(AuditValueText(value, failure, mount))
                if failure then
                    cell:SetTextColor(1, 0.8, 0)
                elseif value == true or (mount and value ~= nil) then
                    cell:SetTextColor(unpack(column.color))
                else
                    cell:SetTextColor(0.6, 0.6, 0.6)
                end
            end
            cell:Show()
        end
        row:Show()
    end
    auditContent:SetHeight(math.max(result.total * 22, 1))
    auditScroll:FullUpdate(true)
    auditScroll:ScrollToBegin()
    return result
end

-- Opens the selected mode with a fresh snapshot and no production-state changes.
function AR.ShowAuditFrame(mode)
    if mode ~= nil then
        if not auditColumnSets[mode] then return end
        auditMode = mode
    end
    local result = AR.RefreshAuditFrame()
    auditFrame:Show()
    return result
end

-- Legacy callers retain the exclusion-specific entry point.
function AR.ShowExclusionAuditFrame()
    return AR.ShowAuditFrame("DB Audit")
end

-- The old refresh name remains compatible with callers of the original audit frame.
AR.RefreshExclusionAuditFrame = AR.RefreshAuditFrame

-- ==========================================
-- 5. EVENT HANDLER
-- ==========================================
local frame = CreateFrame("Frame")
frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
frame:RegisterEvent("LOOT_READY")
frame:RegisterEvent("LOOT_OPENED")
frame:RegisterEvent("LOOT_CLOSED")
frame:RegisterEvent("UI_ERROR_MESSAGE")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unit, _, spellID = ...
        if unit ~= "player" then return end

        -- Classify once; built-in authority wins, while custom triggers require the structural guards.
        local excluded = IsExcludedSpell(spellID)
        local known = not excluded and IsKnownGatherSpell(spellID)
        local mount = not excluded and not known and IsIgnoredSpyCategorySpell(spellID)
        local harmful = not excluded and not known and not mount and IsHarmfulSpell(spellID)

        if excluded then
            ClearPendingSpySpell("by excluded spell")
            LogSpellDebug("Excluded spell ignored: ", spellID)

        elseif known or (not mount and not harmful and IsInCustomSpells(spellID)) then
            -- Built-in or structurally eligible custom spell — trigger remount path.
            interactionSequence = interactionSequence + 1
            currentInteractionID = interactionSequence
            isGathering = true
            lootWindowOpened = false
            ClearPendingSpySpell("by known gather spell")
            LogSpellDebug("Gather spell detected: ", spellID)
            StartNoLootTimer(currentInteractionID)

        elseif mount then
            ClearPendingSpySpell("by mount spell")
            LogSpellDebug("Spy ignored non-gather spell: ", spellID)

        elseif harmful then
            ClearPendingSpySpell("by harmful spell")
            LogSpellDebug("Spy ignored harmful spell: ", spellID)

        elseif OdysseusDB.autoRemount.spyMode and not IsSpyBlacklisted(spellID) then
            -- Spy mode: track unknown spell as pending but do NOT set isGathering.
            -- Requires a timely loot signal followed by closure — no remount triggered.
            -- Blacklisted spellIDs are silently ignored.
            ClearPendingSpySpell("by replacement")
            pendingSpySpellID = spellID
            local expiryTimer
            expiryTimer = C_Timer.NewTimer(SPY_PENDING_TIMEOUT, function()
                -- Replaced or canceled timers must not discard the current candidate.
                if pendingSpyTimer ~= expiryTimer then return end
                LogSpellDebug("Spy candidate expired: ", pendingSpySpellID)
                ClearPendingSpySpell()
            end)
            pendingSpyTimer = expiryTimer
            LogSpellDebug("Spy candidate started: ", spellID)
        end

    elseif event == "LOOT_READY" then
        if pendingSpySpellID and not pendingSpyLootObserved then
            LogSpellDebug("Spy candidate loot ready: ", pendingSpySpellID)
            pendingSpyLootObserved = true
            if pendingSpyTimer then
                pendingSpyTimer:Cancel()
                pendingSpyTimer = nil
            end
        end

    elseif event == "LOOT_OPENED" then
        if pendingSpySpellID and not pendingSpyLootObserved then
            LogSpellDebug("Spy candidate loot opened: ", pendingSpySpellID)
            pendingSpyLootObserved = true
            if pendingSpyTimer then
                pendingSpyTimer:Cancel()
                pendingSpyTimer = nil
            end
        end
        if not isGathering then return end
        lootWindowOpened = true
        CancelNoLootTimer()
        OUS.LogDebug("AutoRemount", "Loot window opened — waiting for LOOT_CLOSED.")

    elseif event == "LOOT_CLOSED" then
        if pendingSpySpellID and pendingSpyLootObserved then
            ConfirmSpySpell()
        elseif pendingSpySpellID then
            LogSpellDebug("Spy candidate cleared without loot observation: ", pendingSpySpellID)
        end
        ClearPendingSpySpell()

        if not isGathering then
            return
        end

        local interactionID = currentInteractionID
        isGathering = false
        lootWindowOpened = false
        CancelNoLootTimer()

        local delay = OdysseusDB.autoRemount.delay or 0.5
        OUS.LogDebug("AutoRemount", "Loot closed after gather. Remounting in " .. delay .. "s.")
        C_Timer.After(delay, function()
            -- A newer accepted interaction supersedes this delayed remount.
            if interactionID ~= currentInteractionID then return end
            TryRemount()
        end)

    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Combat ended — discard any pending spy spell to prevent
        -- combat spells being confirmed by subsequent loot windows.
        if pendingSpySpellID then
            LogSpellDebug("Combat ended — discarding pending spy spell: ", pendingSpySpellID)
            ClearPendingSpySpell()
        end
    elseif event == "UI_ERROR_MESSAGE" then
        if not isTryingToMount then return end
        local _, message = ...
        isTryingToMount = false
        if not OdysseusDB.autoRemount.silent then
            print("|cFF00CCFFOdysseus AutoRemount:|r " .. tostring(message))
        end
        OUS.LogDebug("AutoRemount", "Mount error: " .. tostring(message))
    end
end)

-- ==========================================
-- 6. SLASH COMMAND HANDLER
-- ==========================================

local function PrintStatus()
    local db = OdysseusDB.autoRemount
    local charDB = OdysseusCharDB.autoRemountChar

    local charMount = "|cFF888888None|r"
    if charDB.mountID then
        local name = C_MountJournal.GetMountInfoByID(charDB.mountID)
        charMount = name or "|cFFFF0000Unknown|r"
    end

    local acctMount = "|cFF888888None|r"
    if db.accountMountID then
        local name = C_MountJournal.GetMountInfoByID(db.accountMountID)
        acctMount = name or "|cFFFF0000Unknown|r"
    end

    local customCount = db.customSpells and #db.customSpells or 0
    local discoveredCount = db.discoveredSpells and #db.discoveredSpells or 0

    print("|cFF00CCFFOdysseus AutoRemount Status:|r")
    print("  Enabled: " .. (db.enabled and "|cFF00FF00Yes|r" or "|cFFFF0000No|r"))
    print("  Delay: " .. tostring(db.delay) .. "s")
    print("  Skip Druid: " .. (db.skipDruid and "|cFF00FF00Yes|r" or "|cFFFF0000No|r"))
    print("  Silent: " .. (db.silent and "|cFF00FF00Yes|r" or "|cFFFF0000No|r"))
    print("  Spy Mode: " .. (db.spyMode and "|cFFFFAA00ON|r" or "|cFF888888Off|r"))
    print("  Character Mount: " .. charMount)
    print("  Account Mount: " .. acctMount)
    print("  Fallback: |cFF888888Favourite mount (ID 0)|r")
    print("  Custom Spells: " .. customCount .. " added")
    print("  Discovered Spells: " .. discoveredCount .. " found")
end

function AR.SlashHandler(msg)
    local db = OdysseusDB.autoRemount
    local charDB = OdysseusCharDB.autoRemountChar
    local command, arg = msg:match("^(%S+)%s*(.*)$")
    if not command then command = "help" end
    command = command:lower()

    if command == "mount" then
        if arg == "" then
            print("|cFFFF0000[AutoRemount]|r Usage: /ar mount <name>")
            return
        end
        local cleanName = CleanMountName(arg)
        local mountID, mountName = FindMountIDByName(cleanName)
        if mountID then
            charDB.mountID = mountID
            print("|cFF00CCFFOdysseus AutoRemount:|r Character mount set to " .. mountName)
        else
            print("|cFFFF0000[AutoRemount]|r Mount not found: " .. cleanName)
        end

    elseif command == "account" then
        if arg == "" then
            print("|cFFFF0000[AutoRemount]|r Usage: /ar account <name>")
            return
        end
        local cleanName = CleanMountName(arg)
        local mountID, mountName = FindMountIDByName(cleanName)
        if mountID then
            db.accountMountID = mountID
            print("|cFF00CCFFOdysseus AutoRemount:|r Account mount set to " .. mountName)
        else
            print("|cFFFF0000[AutoRemount]|r Mount not found: " .. cleanName)
        end

    elseif command == "reset" then
        if arg:lower():match("^account") then
            db.accountMountID = nil
            print("|cFF00CCFFOdysseus AutoRemount:|r Account mount reset to favourite.")
        else
            charDB.mountID = nil
            print("|cFF00CCFFOdysseus AutoRemount:|r Character mount reset to account setting.")
        end

    elseif command == "toggle" then
        db.enabled = not db.enabled
        print("|cFF00CCFFOdysseus AutoRemount:|r " .. (db.enabled and "|cFF00FF00Enabled|r" or "|cFFFF0000Disabled|r"))

    elseif command == "enable" then
        db.enabled = true
        print("|cFF00CCFFOdysseus AutoRemount:|r |cFF00FF00Enabled|r")

    elseif command == "disable" then
        db.enabled = false
        print("|cFF00CCFFOdysseus AutoRemount:|r |cFFFF0000Disabled|r")

    elseif command == "druid" then
        db.skipDruid = not db.skipDruid
        print("|cFF00CCFFOdysseus AutoRemount:|r Druid skip " .. (db.skipDruid and "|cFF00FF00enabled|r" or "|cFFFF0000disabled|r"))

    elseif command == "delay" then
        local seconds = tonumber(arg)
        if seconds and seconds >= 0.1 and seconds <= 5.0 then
            db.delay = seconds
            print("|cFF00CCFFOdysseus AutoRemount:|r Delay set to " .. seconds .. "s")
        else
            print("|cFFFF0000[AutoRemount]|r Usage: /ar delay <0.1 - 5.0>")
        end

    elseif command == "silent" then
        db.silent = not db.silent
        print("|cFF00CCFFOdysseus AutoRemount:|r Error notifications " .. (db.silent and "|cFFFF0000suppressed|r" or "|cFF00FF00enabled|r"))

    elseif command == "debug" then
        db.debug = not db.debug
        OUS.Session.isDebugOn = db.debug
        print("|cFF00CCFFOdysseus AutoRemount:|r Debug " .. (db.debug and "|cFF00FF00ON|r" or "|cFFFF0000OFF|r"))

    elseif command == "audit" or command == "harmfulaudit" then
        AR.ShowAuditFrame()

    elseif command == "custom" then
        AR.ShowCustomSpellsFrame()

    elseif command == "spy" then
        db.spyMode = not db.spyMode
        if db.spyMode then
            AR.RefreshSpyFrame()
            spyFrame:Show()
            print("|cFF00CCFFOdysseus AutoRemount:|r Spy mode |cFFFFAA00ON|r — newly discovered loot-confirmed spells are announced once in chat.")
        else
            ClearPendingSpySpell("when Spy mode disabled")
            spyFrame:Hide()
            print("|cFF00CCFFOdysseus AutoRemount:|r Spy mode |cFF888888Off|r")
        end

    elseif command == "add" then
        local spellID = tonumber(arg)
        if not spellID then
            print("|cFFFF0000[AutoRemount]|r Usage: /ar add <spellID>")
            return
        end
        if IsInCustomSpells(spellID) then
            print("|cFFFF0000[AutoRemount]|r SpellID " .. spellID .. " is already in your custom list.")
            return
        end
        if not db.customSpells then db.customSpells = {} end
        table.insert(db.customSpells, spellID)
        AR.RefreshCustomSpellsFrame()
        print("|cFF00CCFFOdysseus AutoRemount:|r Added spellID " .. spellID .. " to custom list.")

    elseif command == "remove" then
        local spellID = tonumber(arg)
        if not spellID then
            print("|cFFFF0000[AutoRemount]|r Usage: /ar remove <spellID>")
            return
        end
        local custom = db.customSpells
        if not custom then
            print("|cFFFF0000[AutoRemount]|r Custom spell list is empty.")
            return
        end
        for i, id in ipairs(custom) do
            if id == spellID then
                table.remove(custom, i)
                AR.RefreshCustomSpellsFrame()
                print("|cFF00CCFFOdysseus AutoRemount:|r Removed spellID " .. spellID .. " from custom list.")
                return
            end
        end
        print("|cFFFF0000[AutoRemount]|r SpellID " .. spellID .. " not found in custom list.")

    elseif command == "export" then
        local custom = db.customSpells
        if not custom or #custom == 0 then
            print("|cFFFF0000[AutoRemount]|r Custom spell list is empty — nothing to export.")
            return
        end

        local lines = {}
        table.sort(custom)

        for _, spellID in ipairs(custom) do
            local spellName = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(spellID) or ("Spell " .. tostring(spellID))
            table.insert(lines, FormatSpellEntry({ id = spellID, name = spellName }))
        end

        print("|cFF00CCFFOdysseus AutoRemount Custom SpellIDs:|r")
        for _, line in ipairs(lines) do
            print(line)
        end

    elseif command == "spyfilter" then
        local sub, subarg = arg:match("^(%S+)%s*(.*)$")
        if not sub then
            -- Show current filter list
            local filter = db.spyFilter or {}
            if #filter == 0 then
                print("|cFF00CCFFOdysseus AutoRemount:|r Spy filter is empty.")
            else
                print("|cFF00CCFFOdysseus AutoRemount Spy Filter:|r")
                for _, id in ipairs(filter) do
                    local name = C_Spell.GetSpellName(id) or "Unknown"
                    print("  " .. id .. " — " .. name)
                end
            end
            return
        end
        sub = sub:lower()
        if sub == "add" then
            local spellID = tonumber(subarg)
            if not spellID then
                print("|cFFFF0000[AutoRemount]|r Usage: /ar spyfilter add <spellID>")
                return
            end
            if not db.spyFilter then db.spyFilter = {} end
            for _, id in ipairs(db.spyFilter) do
                if id == spellID then
                    print("|cFFFF0000[AutoRemount]|r SpellID " .. spellID .. " is already in the spy filter.")
                    return
                end
            end
            table.insert(db.spyFilter, spellID)
            local name = C_Spell.GetSpellName(spellID) or "Unknown"
            print("|cFF00CCFFOdysseus AutoRemount:|r Added " .. name .. " (" .. spellID .. ") to spy filter.")
        elseif sub == "remove" then
            local spellID = tonumber(subarg)
            if not spellID then
                print("|cFFFF0000[AutoRemount]|r Usage: /ar spyfilter remove <spellID>")
                return
            end
            local filter = db.spyFilter
            if not filter then
                print("|cFFFF0000[AutoRemount]|r Spy filter is empty.")
                return
            end
            for i, id in ipairs(filter) do
                if id == spellID then
                    local name = C_Spell.GetSpellName(spellID) or "Unknown"
                    table.remove(filter, i)
                    print("|cFF00CCFFOdysseus AutoRemount:|r Removed " .. name .. " (" .. spellID .. ") from spy filter.")
                    return
                end
            end
            print("|cFFFF0000[AutoRemount]|r SpellID " .. spellID .. " not found in spy filter.")
        elseif sub == "clear" then
            db.spyFilter = {}
            print("|cFF00CCFFOdysseus AutoRemount:|r Spy filter cleared.")
        else
            print("|cFFFF0000[AutoRemount]|r Usage: /ar spyfilter [add|remove|clear] <spellID>")
        end

    elseif command == "wipe" then
        db.customSpells = {}
        AR.RefreshCustomSpellsFrame()
        print("|cFF00CCFFOdysseus AutoRemount:|r Custom spell list cleared.")

    elseif command == "status" then
        PrintStatus()

    elseif command == "help" then
        print("|cFF00CCFFOdysseus AutoRemount Commands:|r")
        print("  /ar mount <name> — Set character mount")
        print("  /ar account <name> — Set account-wide mount")
        print("  /ar reset — Clear character mount override")
        print("  /ar reset account — Clear account mount override")
        print("  /ar toggle — Toggle on/off")
        print("  /ar enable / disable — Explicit on/off")
        print("  /ar druid — Toggle druid form skip")
        print("  /ar delay <sec> — Set remount delay (0.1-5.0)")
        print("  /ar silent — Toggle error notifications")
        print("  /ar spy — Toggle spy mode (announces newly discovered loot-confirmed spells once in chat)")
        print("  /ar audit — Open AutoRemount audit")
        print("  /ar spyfilter — Show spy filter list")
        print("  /ar spyfilter add <id> — Add spellID to spy filter (never recorded)")
        print("  /ar spyfilter remove <id> — Remove spellID from spy filter")
        print("  /ar spyfilter clear — Clear entire spy filter")
        print("  /ar add <id> — Add custom spellID")
        print("  /ar custom — Open custom spells frame")
        print("  /ar remove <id> — Remove custom spellID")
        print("  /ar export — Print custom spellIDs for copy/paste")
        print("  /ar wipe — Clear all custom spellIDs")
        print("  /ar debug — Toggle debug mode")
        print("  /ar status — Show current settings")

    else
        print("|cFFFF0000[AutoRemount]|r Unknown command: " .. command .. ". Type /ar help.")
    end
end
