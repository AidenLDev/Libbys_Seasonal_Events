function timer.CreateWithArguments(Identifier, Delay, Repetitions, Callback, ...)
	local ArgumentCount = select("#", ...)
	local Arguments = { ... }

	timer.Create(Identifier, Delay, Repetitions, function()
		Callback(unpack(Arguments, 1, ArgumentCount))
	end)
end

function timer.SimpleWithArguments(Delay, Callback, ...)
	local ArgumentCount = select("#", ...)
	local Arguments = { ... }

	timer.Simple(Delay, function()
		Callback(unpack(Arguments, 1, ArgumentCount))
	end)
end
