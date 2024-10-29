hook.Add("PlayerDeath", "RewardSoulsOnKill", function(Victim, _, Attacker)
	if Attacker == Victim then return end
	if not IsValid(Attacker) or not IsValid(Victim) then return end
	if not Attacker:IsPlayer() then return end

	Attacker:ModifyPlayerBalance("souls", 1)
	SavePlayerBalances(Attacker)
end)
