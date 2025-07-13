function read_current_monster()
    data = {}

    data["lifespan"] = bit.band(memory.readdwordunsigned(0x021B6718), 0xFFFF)

    data["stress"] = bit.band(memory.readdwordunsigned(0x021B6744), 0xFFFF)
    data["fatigue"] = bit.rshift(memory.readdwordunsigned(0x021B6744), 16)

    return data
end

function display_monster_data(monster)
    gui.text(1, 182, string.format("S:%3d  F:%3d  L:%4d", monster["stress"], monster["fatigue"], monster["lifespan"]))
end

local changes_display_duration = 3

local changes_last_update = 0
local changes_remaining_duration = 0
local changes_previous_monster = {
    ["stress"] = -1,
    ["fatigue"] = -1,
    ["lifespan"] = -1
}

function show_stat_change(stat_name, monster, max_digits, offset)
    offset = offset - 1 -- Allow +/- sign to be over the colon
    if changes_previous_monster[stat_name] ~= monster[stat_name] then
        current = monster[stat_name]
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
    elseif changes_previous_monster["stress"] == -1 then
        changes_previous_monster = monster
    elseif changes_previous_monster["stress"] ~= monster["stress"] or changes_previous_monster["fatigue"] ~=
        monster["fatigue"] or changes_previous_monster["lifespan"] ~= monster["lifespan"] then
        changes_remaining_duration = changes_display_duration
    end

    if changes_remaining_duration > 0 then
        offset = 2

        max_digits = 3
        show_stat_change("stress", monster, max_digits, offset)
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
