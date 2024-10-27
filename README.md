# 2024 Libbys Halloween Event
NOTE: This event is unfinished! Things may not work as intended. Future iterations of this or other events will have proper functionality and security.
NOTE: All commands within this even start with 'halloween'
ISSUE: ConCommand and console printing are broken and hidden. Refer to this txt file for command use

!shop - Opens shop
!balance - Shows your balance

shop - Opens shop

halloween_balance_check (server only) - prints all players stored in player_balances SQL
halloween_balance_edit <player_index/steamid64/name> <candycorn/souls> <new_amount> - edit selected players balance
halloween_balance_delete <player_name/steamid64> - removes player from SQL

halloween_filter 1/0 - toggles purple tint overlay on client. Default is 1
halloween_filter_brightness - adjust brightness of overlay

halloween_give_spell - If left blank, prints list of available spells (server only). Manually gives spell to player

halloween_soundscape 1/0 - Toggles soundscape
halloween_soundscape - Reboots soundscape. Auto-executes on map clean

halloween_spawnables_clear - Removes all active spawnables on map
halloween_spawnables_debug 0/1 - Default is 0. Prints raycast tries, fails, clearance checks, spawned, and expired spawnables (server only).
halloween_spawnables_max - Default is 100. Can be adjusted to any amount. If set to 0, stops spawning and sleeps timers.
halloween_spawnables_rate - Default is 15. Can be set to any delay. Even 0.001 seconds
halloween_spawnables_spawnall - Activates unfinished special event. Spawns all max spawnables at once. Event ends when all spawnables expire

halloween_upgrades_check - (Broken!) Prints all stored player bought upgrades and levels
halloween_upgrades_edit <index/name/steamid> <upgrade name> <level> - (Good luck) Edits selected player and their upgrade. If set to level 0, upgrade is removed from their data
