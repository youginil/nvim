table.index_of = function(list, element)
	if not vim.tbl_islist(list) then
		error("Parameter is not a LIST", 2)
		return -1
	end
	for i, v in ipairs(list) do
		if v == element then
			return i
		end
	end
	return -1
end

table.slice = function(list, start_index, end_index)
	if type(end_index) ~= "number" then
		end_index = #list
	elseif end_index < 0 then
		end_index = #list + end_index + 1
	end
	end_index = math.min(#list, end_index)
	start_index = math.max(1, start_index)
	local result = {}
	if start_index <= end_index then
		for i = start_index, end_index do
			table.insert(result, list[i])
		end
	end
	return result
end

table.find = function(t, value)
	for k, v in pairs(t) do
		if v == value then
			return k, v
		end
	end
end
