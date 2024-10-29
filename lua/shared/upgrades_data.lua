upgrades = {
    { name = "Health", unit = "+", description = " Max health", defaultDescription = "Increases maximum health", baseCost = 21, maxLevel = 10, valuePerLevel = 20 },
    { name = "Agility", unit = "+", description = " Speed", defaultDescription = "Increases running and walking speeds", baseCost = 9, maxLevel = 8, valuePerLevel = 15 },
    { name = "Power Legs", unit = "+", description = " Jump power", defaultDescription = "Increases jump power", baseCost = 6, maxLevel = 4, valuePerLevel = 45 },
    { name = "Regeneration", unit = "", description = " Health-per-second", defaultDescription = "Regenerate health every second", baseCost = 22, maxLevel = 5, valuePerLevel = 5 },
    { name = "Blunt Resistance", unit = "", description = "% Damage reduction", defaultDescription = "Reduce incoming damage from props/vehicles", baseCost = 20, maxLevel = 5, valuePerLevel = 18 },
    { name = "Bullet Resistance", unit = "", description = "% Damage reduction", defaultDescription = "Reduce incoming damage from bullets", baseCost = 21, maxLevel = 5, valuePerLevel = 10 },
    { name = "Blast Resistance", unit = "", description = "% Damage reduction", defaultDescription = "Reduce incoming damage from explosions/blast", baseCost = 17, maxLevel = 5, valuePerLevel = 9 },
    { name = "Fire Resistance", unit = "", description = "% Fire damage reduction", defaultDescription = "Reduce incoming fire damage", baseCost = 20, maxLevel = 3, valuePerLevel = 33.3 },
    { name = "Chemical Resistance", unit = "", description = "% Damage reduction", defaultDescription = "Reduce damage from hazards", baseCost = 20, maxLevel = 2, valuePerLevel = 50 }
}


function CalculateUpgradeCost(upgrade) // I fear removing this
    return math.floor(upgrade.baseCost * math.pow(1.25, upgrade.currentLevel or 0))
end