function table.ForEach(Table, Callback, ...) -- table.foreachi but better
	local A, B, C, D, E, F

	for i = 1, #Table do
		A, B, C, D, E, F = Callback(i, Table[i], ...)

		if A ~= nil then
			return A, B, C, D, E, F
		end
	end

	return nil
end

function table.RandomKeyI(Table)
	return math.random(1, #Table)
end

function table.RandomValueI(Table)
	local Key = table.RandomKeyI(Table)

	return Table[Key], Key
end
