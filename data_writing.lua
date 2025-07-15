--------------------
-- Configuration
--------------------

local output_filepath = "mrds_data.csv"

local update_interval = 1 -- seconds
local only_update_on_change = true

--------------------
-- Code
--------------------

function read_data()
    data = {}

    data["year"] = read_11110000(0x21B6560)
    data["month"] = read_00001100(0x21B6560)
    data["week"] = read_00000011(0x21B6560)

    data["name"] = read_ascii_string(0x21B66F8, 12)

    data["lifespan"] = read_11110000(0x021B6718)
    data["age"] = read_00001111(0x021B6714)

    data["stress"] = read_11110000(0x021B6744)
    data["fatigue"] = read_00001111(0x021B6744)

    return data
end

function read_11110000(offset)
    return bit.band(memory.readdwordunsigned(offset), 0x0000FFFF)
end

function read_00001111(offset)
    return bit.rshift(memory.readdwordunsigned(offset), 16)
end

function read_00001100(offset)
    return bit.rshift(bit.band(memory.readdwordunsigned(offset), 0x00FF0000), 16)
end

function read_00000011(offset)
    return bit.rshift(bit.band(memory.readdwordunsigned(offset), 0xFF000000), 24)
end

function read_ascii_string(offset, size)
    return decode_ascii_string(memory.readbyterange(offset, size))
end

function decode_ascii_string(bytes)
    s = ""
    for _, value in ipairs(bytes) do
        s = s .. string.char(value)
    end

    return s
end

function write_data(data)
    columns = {}
    for key, _ in pairs(data) do
        table.insert(columns, key)
    end
    table.sort(columns)

    -- Create the file if it does not already exist
    f = io.open(output_filepath, "r")
    if not f then
        f = io.open(output_filepath, "w")

        -- Add the header row
        for i, key in ipairs(columns) do
            if i ~= 1 then
                f:write(",")
            end

            f:write(key)
        end
        f:write("\n")
    end
    f:close()

    -- Append the new data
    f = io.open(output_filepath, "a+")
    for i, key in ipairs(columns) do
        if i ~= 1 then
            f:write(",")
        end

        f:write(data[key])
    end
    f:write("\n")
    f:close()
end

function dictionaries_neq(dict_1, dict_2)
    for key, value in pairs(dict_1) do
        if value ~= dict_2[key] then
            return true
        end
    end

    return false
end

local last_update_time = 0
local previous_data = nil
function main()
    current_time = os.time()

    if current_time > (last_update_time + update_interval) then
        data = read_data()
        last_update_time = current_time

        if previous_data == nil or dictionaries_neq(previous_data, data) or not only_update_on_change then
            previous_data = data

            data["current_time"] = current_time
            write_data(data)

            -- Remove the key so that it can be used for comparison in the next run of the function
            data["current_time"] = nil
        end
        print(data)
    end
end

gui.register(main)