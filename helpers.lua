function DecodeValue(value, table)
    local options = {}
    for enum_val, name in pairs(table) do
        if BitwiseAnd(value, enum_val) ~= 0 then
            table.insert(options, name)
        end
    end
    return options
end

function BitwiseAnd(a, b)
    local result = 0
    local bitval = 1
    while a > 0 and b > 0 do
        if a % 2 == 1 and b % 2 == 1 then
            result = result + bitval
        end
        bitval = bitval * 2
        a = math.floor(a / 2)
        b = math.floor(b / 2)
    end
    return result
end

function MapValue(oldValue, low, high)
    local newValue = ((oldValue * low) / high)

    return math.floor(newValue + 0.5)
end

function HasValue(tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

function TablesMatch(a, b)
    return table.concat(a) == table.concat(b)
end


function ToCelsius(f)
    return (f - 32) * 5 / 9
end

function ToFahrenheit(c)
    return c * 9 / 5 + 32
end