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
