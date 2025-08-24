local first_var = "stress"

--

function read_current_monster()
    data = {}

    data["year"] = read_11110000(0x21B6560)
    data["month"] = read_00001100(0x21B6560)
    data["week"] = read_00000011(0x21B6560)

    data["week_full"] = data["week"] + 4 * (data["month"] + 12 * data["year"])

    data["gold"] = read_11111111(0x21B6690)

    data["name"] = read_ascii_string(0x21B66F8, 12)
    data["species_id"] = read_00001111(0x021B6708)
    data["main_breed"] = memory.readbyteunsigned(0x021B670C)
    data["sub_breed"] = memory.readbyteunsigned(0x021B670D)

    data["fame"] = memory.readbyteunsigned(0x021B6710)

    data["lifespan"] = read_11110000(0x021B6718)
    data["age"] = read_00001111(0x021B6714)
    data["action_points"] = read_11110000(0x021B671C)

    data["discipline"] = memory.readbytesigned(0x021B6741)
    data["trust"] = memory.readbyteunsigned(0x021B6743)
    data["stress"] = read_11110000(0x021B6744)
    data["fatigue"] = read_00001111(0x021B6744)
    data["wits"] = memory.readbyteunsigned(0x021B6748)
    data["shape"] = memory.readbytesigned(0x021B6749)

    data["power"] = read_11110000(0x021B6720)
    data["intelligence"] = read_00001111(0x021B6720)
    data["skill"] = read_11110000(0x021B6724)
    data["speed"] = read_00001111(0x021B6724)
    data["defense"] = read_11110000(0x021B6728)
    data["life"] = read_00001111(0x021B6728)

    return data
end

function read_11111111(offset)
    return memory.readdwordunsigned(offset)
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
        if value == 0 then
            -- Stop if we see a string terminator, since the data after it is not guaranteed to be
            -- zeroed out
            break
        end

        s = s .. string.char(value)
    end

    return s
end

function display_monster_data(monster)
    gui.text(1, 182, string.format("S:%3d  F:%3d  L:%4d", monster[first_var], monster["fatigue"], monster["lifespan"]))
end

local changes_display_duration = 3

local changes_last_update = 1
local changes_remaining_duration = 0
local changes_previous_monster = {
    [first_var] = -1,
    ["fatigue"] = -1,
    ["lifespan"] = -1
}

function show_stat_change(stat_name, monster, max_digits, offset)
    offset = offset - 1 -- Allow +/- sign to be over the colon
    if changes_previous_monster[stat_name] ~= monster[stat_name] then
        change = monster[stat_name] - changes_previous_monster[stat_name]
        abs_change = math.abs(change)

        if max_digits >= 2 and abs_change < 10 then
            offset = offset + 1
        end
        if max_digits >= 3 and abs_change < 100 then
            offset = offset + 1
        end
        if max_digits >= 4 and abs_change < 1000 then
            offset = offset + 1
        end

        prefix = string.rep(" ", offset)
        
        if monster[stat_name] > changes_previous_monster[stat_name] then
            text = string.format("%s+%d", prefix, change)
            color = "green"
        else
            text = string.format("%s%d", prefix, change)
            color = "red"
        end
        gui.text(1, 172, text, color)
    end
end

function display_monster_changes(current_time, monster)
    if changes_last_update == 0 or current_time - changes_last_update > 1 then
        changes_last_update = current_time

        if changes_remaining_duration > 0 then
            changes_remaining_duration = changes_remaining_duration - 1
            if changes_remaining_duration == 0 then
                changes_previous_monster = monster
            end
        end
    end

    if changes_remaining_duration > 0 then
    elseif changes_previous_monster[first_var] == -1 then
        changes_previous_monster = monster
    elseif changes_previous_monster[first_var] ~= monster[first_var] or changes_previous_monster["fatigue"] ~=
        monster["fatigue"] or changes_previous_monster["lifespan"] ~= monster["lifespan"] then
        changes_remaining_duration = changes_display_duration
    end

    if changes_remaining_duration > 0 then
        offset = 2

        max_digits = 3
        show_stat_change(first_var, monster, max_digits, offset)
        offset = offset + max_digits + 4

        max_digits = 3
        show_stat_change("fatigue", monster, max_digits, offset)
        offset = offset + max_digits + 4

        max_digits = 4
        show_stat_change("lifespan", monster, max_digits, offset)
        offset = offset + max_digits + 4
    end

end

function main()
    current_time = os.time()
    current_monster = read_current_monster()

    display_monster_data(current_monster)
    display_monster_changes(current_time, current_monster)
end

gui.register(main)
