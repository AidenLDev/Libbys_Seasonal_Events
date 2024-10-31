local spellbooks = {}
local cachedSpells = {}
local playerLastSpells = {}
local playerSpells = {}

local function GarbageCollector()
    for i = #spellbooks, 1, -1 do
        if not IsValid(spellbooks[i]) then
            table.remove(spellbooks, i)
        end
    end

    for plyID, spell in pairs(playerSpells) do
        local ply = player.GetBySteamID(plyID)
        if not IsValid(ply) then
            playerSpells[plyID] = nil
            playerLastSpells[plyID] = nil
            timer.Remove("CastingInterruptTimer_" .. plyID)
            timer.Remove("SpellRandomizer_" .. plyID)
        end
    end
end

timer.Create("SpellGarbageCollector", 300, 0, GarbageCollector)

// Spellbook Entity //

local function SpawnSpellbook(pos)
    local spellbook = ents.Create("spellbook_entity")
    if not IsValid(spellbook) then return end
    spellbook:SetPos(pos)
    spellbook:Spawn()

    table.insert(spellbooks, spellbook)
end

local function CleanupSpellbooks()
    for _, spellbook in ipairs(spellbooks) do
        if IsValid(spellbook) then
            spellbook:Remove()
        end
    end
    spellbooks = {}
end

hook.Add("ShutDown", "SpellbookCleanup", CleanupSpellbooks)

hook.Add("PostCleanupMap", "SpellbookMapCleanup", CleanupSpellbooks)

util.AddNetworkString("SpellbookCollected")
util.AddNetworkString("StartSpellRandomizer")
util.AddNetworkString("FinalizeSpell")
util.AddNetworkString("SpellCastFail")
util.AddNetworkString("ClearSpellUI")

local COLLECTION_RANGE = 50
local SPELLBOOK_LIFETIME = 120
local SPELL_WINDUP_TIME = 0.6
local EXPLOSION_RADIUS = 150
local EXPLOSION_DAMAGE = 30
local SPELL_SOUND_RADIUS = 300

local function EmitSpellSound(pos, soundPath)
    sound.Play(soundPath, pos, 100, 100, 1)
end

local function PlayPickupSound(ply)
    ply:EmitSound("libbys/halloween/pumpkin_pickup.ogg", 85)
    ply:EmitSound("libbys/halloween/spell_tick.ogg", 45)
end

local function StopPickupSound(ply)
    ply:StopSound("libbys/halloween/spell_tick.ogg")
end

local function CreateExplosion(ply)
    if not IsValid(ply) then return end

    local explosion = ents.Create("env_explosion")
    explosion:SetPos(ply:GetPos())
    explosion:SetOwner(ply)
    explosion:SetKeyValue("iMagnitude", tostring(EXPLOSION_DAMAGE))
    explosion:Spawn()
    explosion:Activate()
    explosion:Fire("Explode", "", 0)
end

function CreateSpellbook(pos)
    local spellbook = ents.Create("prop_dynamic")
    if not IsValid(spellbook) then return end

    spellbook:SetModel("models/props_halloween/hwn_spellbook_upright.mdl")
    spellbook:SetPos(pos)
    spellbook:SetSolid(SOLID_NONE)
    spellbook:SetTrigger(true)
    spellbook:SetMoveType(MOVETYPE_NONE)
    spellbook:Spawn()

    EmitSpellSound(pos, "libbys/halloween/spawn.ogg")
    spellbook:ResetSequence(spellbook:LookupSequence("idle"))

    local spellbookLifetimeTimer = "SpellbookLifetime_" .. spellbook:EntIndex()
    timer.Create(spellbookLifetimeTimer, SPELLBOOK_LIFETIME, 1, function()
        if IsValid(spellbook) then
            spellbook:Remove()
        end
    end)

    function spellbook:OnRemove()
        if timer.Exists(spellbookLifetimeTimer) then
            timer.Remove(spellbookLifetimeTimer)
        end
    end
    return spellbook
end

// Spell Handling //

local function LoadSpells()
    if #cachedSpells > 0 then return cachedSpells end

    local spellFiles = file.Find("spells/*.lua", "LUA")
    for _, spellFile in ipairs(spellFiles) do
        local spellPath = "spells/" .. spellFile
        if file.Exists(spellPath, "LUA") then
            local spellData = include(spellPath)
            if spellData and spellData.GetDisplayName then
                local spellInfo = {
                    Name = string.StripExtension(spellFile),
                    DisplayName = spellData.GetDisplayName()
                }
                table.insert(cachedSpells, spellInfo)
            end
        end
    end

    return cachedSpells
end

local function SavePlayerSpell(ply, spell)
    playerSpells[ply:SteamID()] = { Name = spell.Name, DisplayName = spell.DisplayName }
end

local function ClearPlayerSpell(ply)
    playerSpells[ply:SteamID()] = nil
end

local function GetPlayerSpell(ply)
    return playerSpells[ply:SteamID()] or { Name = "", DisplayName = "" }
end

function AssignSpell(ply, spell)
    if not IsValid(ply) then return end
    ply:SetNWString("ActiveSpell", spell.Name)
    ply:SetNWString("ActiveSpellDisplayName", spell.DisplayName)

    SavePlayerSpell(ply, spell)
end


function MarkSpellAsFinished(ply)
    if not IsValid(ply) then return end

    ply:SetNWBool("SpellInProgress", false)
    ply:SetNWBool("IsCasting", false)
    ply:SetNWBool("IsRandomizing", false)
    ply:SetNWBool("SpellOverlay", false)

    ply:SetNWString("ActiveSpell", "")
    ply:SetNWString("ActiveSpellDisplayName", "")

    hook.Remove("Think", "CheckCastingInterruption_" .. ply:SteamID())
    hook.Remove("PlayerDeath", "CheckPlayerDeathDuringCasting_" .. ply:SteamID())
    timer.Remove("SpellRandomizer_" .. ply:SteamID())
    timer.Remove("CastingInterruptTimer_" .. ply:SteamID())
end

local function SpellCastFailure(ply)
    if not IsValid(ply) then return end
    local pos = ply:GetPos()
    EmitSpellSound(pos, "libbys/halloween/charged_death.ogg")
    CreateExplosion(ply)
    MarkSpellAsFinished(ply)

    local prevWeapon = ply:GetNWString("PreviousWeaponClass", "")
    if prevWeapon ~= "" then
        ply:Give(prevWeapon)
        ply:SelectWeapon(prevWeapon)
    end
end

local function GetRandomSpellExcludingLast(ply, spells)
    local lastSpell = playerLastSpells[ply:SteamID()]

    local availableSpells = {}
    for _, spell in ipairs(spells) do
        if spell.DisplayName ~= lastSpell then
            table.insert(availableSpells, spell)
        end
    end

    if #availableSpells == 0 then
        availableSpells = spells
    end

    return availableSpells[math.random(#availableSpells)]
end

local function getMappedEnt(ply)
    return ply.pk_pill_ent
end

local function HandleSpellbookCollect(ply, spellbook)
    if not ply:Alive() or
		ply:GetNWBool("IsRandomizing", false) or
		ply:GetNWString("ActiveSpell", "") ~= "" or
		ply:GetNWBool("IsCasting", false) or
		ply:GetNWBool("BuildMode", false) or
		(pk_pills and pk_pills.getMappedEnt(ply) or false) or
		ply:GetNWBool("_Kyle_Buildmode", false) or
		ply:GetNWBool("SpellInProgress", false) then

        return
    end

    PlayPickupSound(ply)

    if IsValid(spellbook) then
        spellbook:Remove()
    end

    local spells = LoadSpells()
    if #spells == 0 then return end

    ply:SetNWBool("IsRandomizing", true)

    local spellDisplayNames = {}
    for _, spell in ipairs(spells) do
        table.insert(spellDisplayNames, spell.DisplayName)
    end
    net.Start("StartSpellRandomizer")
    net.WriteTable(spellDisplayNames)
    net.Send(ply)

    local randoTimer = "SpellRandomizer_" .. ply:SteamID()

    timer.Create(randoTimer, 2, 1, function()
        if not IsValid(ply) or not ply:Alive() then return end
        local randomSpell = GetRandomSpellExcludingLast(ply, spells)
        finalizedSpell = randomSpell.DisplayName
        AssignSpell(ply, randomSpell)

        playerLastSpells[ply:SteamID()] = randomSpell.DisplayName

        ply:SetNWBool("IsRandomizing", false)
        net.Start("FinalizeSpell")
        net.WriteString(randomSpell.DisplayName)
        net.Send(ply)
    end)
end

local function CheckSpellbookCollect(spellbook)
    local nearbyEntities = ents.FindInSphere(spellbook:GetPos(), COLLECTION_RANGE)

    for _, entity in ipairs(nearbyEntities) do
        if entity:IsPlayer() and entity:Alive() then
            HandleSpellbookCollect(entity, spellbook)
            break
        end
    end
end

local function CastSpell(ply)
    local spellName = ply:GetNWString("ActiveSpell", "")
    if spellName == "" or ply:GetNWBool("IsCasting", false) then return end

    if ply:GetNWBool("BuildMode") or pk_pills.getMappedEnt(ply) then
        return
    end

    if ply:InVehicle() or ply:GetNWBool("IsSitting", false) then
        return
    end

    local originalWeapon = ply:GetActiveWeapon()
    if not IsValid(originalWeapon) then return end

    ply:SetNWString("PreviousWeaponClass", originalWeapon:GetClass())

    local spellcasterArms = ply:Give("spellcaster")
    if IsValid(spellcasterArms) then
        ply:SelectWeapon("spellcaster")
        spellViewModel = ply:GetViewModel()
        if IsValid(spellViewModel) then
            spellViewModel:SetModel("models/weapons/c_arms.mdl")
        end

        if not IsValid(spellViewModel) then
        end
    else
        return
    end

    if IsValid(spellViewModel) then
        local animID = spellViewModel:LookupSequence("cast_spell")
        if animID then
            spellViewModel:SendViewModelMatchingSequence(animID)
            animDuration = spellViewModel:SequenceDuration(animID)
        end
    end

    ply:SetNWBool("IsCasting", true)
    local animDuration = 1

    local function InterruptMonitor()
        if not IsValid(ply) or not ply:Alive() or ply:InVehicle() or ply:GetNWBool("IsSitting", false) then
            SpellCastFailure(ply)
            timer.Remove("CastingInterruptTimer_" .. ply:SteamID())
        end
    end


    timer.Create("CastingInterruptTimer_" .. ply:SteamID(), 0.1, 0, InterruptMonitor)

    local castFrame = 17 * (1 / 30)

    timer.Simple(castFrame, function()
        if not IsValid(ply) or not ply:Alive() then
            timer.Remove("CastingInterruptTimer_" .. ply:SteamID())
            timer.Remove("SpellRandomizer_" .. ply:SteamID())
            return
        end

        timer.Remove("CastingInterruptTimer_" .. ply:SteamID())
        timer.Remove("SpellRandomizer_" .. ply:SteamID())

        local spellScript = "spells/" .. spellName .. ".lua"
        if file.Exists(spellScript, "LUA") then
            local spellData = include(spellScript)
            if spellData and isfunction(spellData.Cast) then
                local result = spellData.Cast(ply)

                ply:SetNWBool("SpellOverlay", true)
                if result == false then
                    MarkSpellAsFinished(ply)
                    ply:SetNWBool("SpellOverlay", false)
                end
            end
        end

        net.Start("ClearSpellUI")
        net.Send(ply)
    end)

    timer.Simple(1, function()
        if IsValid(ply) and ply:Alive() then
            local previousWeaponClass = ply:GetNWString("PreviousWeaponClass", "")
            if previousWeaponClass ~= "" then
                ply:Give(previousWeaponClass)
                ply:SelectWeapon(previousWeaponClass)
            end
            ply:SetNWBool("IsCasting", false)

            ClearPlayerSpell(ply)
            ply:SetNWString("ActiveSpell", "")
        end
    end)

    timer.Simple(animDuration, function()
        if not ply:Alive() or not IsValid(ply) then
            ClearPlayerSpell(ply)
        end
    end)
end

function GiveSpellToPlayerAndCast(ply, spellName)
    if not IsValid(ply) or not file.Exists("spells/" .. spellName .. ".lua", "LUA") then
        return
    end

    AssignSpell(ply, spellName)
    CastSpell(ply)
end

// Command //

concommand.Add("halloween_give_spell", function(ply, cmd, args)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    if not ply:IsSuperAdmin() then return end
    if #args < 1 then
        local spellsList = LoadSpells()
        if #spellsList == 0 then
            print("No spells available.")
            return
        end
        print("Available spells:")
        for _, spell in ipairs(spellsList) do
            print("- " .. spell.DisplayName)
        end
        return
    end
    if not ply:Alive() or ply:GetNWBool("IsCasting", false) or ply:GetNWBool("IsRandomizing", false) or ply:GetNWString("ActiveSpell", "") ~= "" or ply:GetNWBool("SpellInProgress", false) then
        print("You cannot receive a new spell at this time.")
        return
    end

    local spellName = table.concat(args, " ")
    local foundSpell = false

    for _, spell in ipairs(LoadSpells()) do
        if spell.DisplayName == spellName then
            foundSpell = true
            AssignSpell(ply, spell)
            CastSpell(ply)
            break
        end
    end

    if not foundSpell and file.Exists("spells/" .. spellName .. ".lua", "LUA") then
        foundSpell = true
        AssignSpell(ply, { Name = spellName, DisplayName = spellName })
        CastSpell(ply)
    end

    if not foundSpell then
        print("Invalid spell")
    end
end)

// Hooks //

hook.Add("Think", "SpellbookGlobalRangeCheck", function()
    for _, spellbook in ipairs(ents.FindByClass("prop_dynamic")) do
        if spellbook:GetModel() == "models/props_halloween/hwn_spellbook_upright.mdl" then
            CheckSpellbookCollect(spellbook)
        end
    end
end)

hook.Add("PlayerButtonDown", "CastSpell", function(ply, button)
    if button == KEY_G then
        CastSpell(ply)
    end
end)

hook.Add("PlayerDeath", "RemoveSpellOverlayOnDeath", function(ply)
    MarkSpellAsFinished(ply)
    ply:SetNWBool("SpellOverlay", false)
    net.Start("ClearSpellUI")
    net.Send(ply)
end)

hook.Add("PlayerSpawn", "ResetPlayerSpellOnSpawn", function(ply)
    ply:SetNWString("ActiveSpell", "")
    ply:SetNWBool("IsCasting", false)
    ply:SetNWBool("SpellInProgress", false)
    ply:SetNWBool("SpellOverlay", false)

    timer.Remove("CastingInterruptTimer_" .. ply:SteamID())
end)

hook.Add("PlayerDisconnected", "CleanUpRandomizerOnDisconnect", function(ply)
    local randoTimer = "SpellRandomizer_" .. ply:SteamID()
    timer.Remove(randoTimer)
    ply:SetNWBool("IsRandomizing", false)
end)

hook.Add("ShutDown", "CleanupOnShutdown", function()
    for _, spellbook in ipairs(ents.FindByClass("prop_dynamic")) do
        if spellbook:GetModel() == "models/props_halloween/hwn_spellbook_upright.mdl" then
            spellbook:Remove()
        end
    end
end)

hook.Add("PlayerDeath", "RemoveSpellOnDeath", function(ply)
    if ply:GetNWBool("IsCasting", false) then
        MarkSpellAsFinished(ply)
        ply:SetNWBool("SpellOverlay", false)
        ClearPlayerSpell(ply)
    end
end)

hook.Add("PlayerSpawn", "RestorePlayerSpellOnSpawn", function(ply)
    local savedSpell = GetPlayerSpell(ply)
    if savedSpell.Name ~= "" then
        ply:SetNWString("ActiveSpell", savedSpell.Name)
        ply:SetNWString("ActiveSpellDisplayName", savedSpell.DisplayName)

        net.Start("FinalizeSpell")
        net.WriteString(savedSpell.DisplayName)
        net.Send(ply)
    else
        ply:SetNWString("ActiveSpell", "")
        ply:SetNWBool("IsCasting", false)
        ply:SetNWBool("SpellInProgress", false)
        ply:SetNWBool("SpellOverlay", false)
    end
end)
