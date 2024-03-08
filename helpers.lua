local epoch = os.time { year = 1970, month = 1, day = 1, hour = 0 }

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

function Sleep(a)
    local sec = tonumber(os.clock() + a)

    while (os.clock() < sec) do
    end
end

function ParseTime(iso_8601_time)
    local year, month, day, hour, minute, seconds, offsetsign, offsethour, offsetmin = iso_8601_time:match(
    "(%d+)%-(%d+)%-(%d+)%a(%d+)%:(%d+)%:([%d%.]+)([Z%+%- ])(%d?%d?)%:?(%d?%d?)")
    local timestamp = os.time { year = year, month = month, day = day, hour = hour, min = minute, sec = seconds } - epoch
    local offset = 0
    if offsetsign ~= 'Z' then
        offset = tonumber(offsethour) * 60 + tonumber(offsetmin)
        if offsetsign == "-" then offset = -offset end
    end
    return timestamp - offset * 60
end