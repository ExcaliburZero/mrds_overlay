function read_current_monster()
    data = {}

    data["lifespan"] = bit.band(memory.readdwordunsigned(0x021B6718), 0xFFFF)

    data["stress"] = bit.band(memory.readdwordunsigned(0x021B6744), 0xFFFF)
    data["fatigue"] = bit.rshift(memory.readdwordunsigned(0x021B6744), 16)

    return data
end

function display_monster_data(monster)
    gui.text(1, 182, string.format("S:%3d  F:%3d  L:%3d", monster["stress"], monster["fatigue"], monster["lifespan"]))
end

local changes_display_duration = 3

local changes_last_update = 0
local changes_remaining_duration = 0
local changes_previous_monster = {
    ["stress"] = -1,
    ["fatigue"] = -1,
    ["lifespan"] = -1
}

function display_monster_changes(current_time, monster)
    -- gui.text(1, 5, current_time)
    -- gui.text(1, 15, changes_remaining_duration)

    -- gui.text(1, 35, changes_previous_monster["stress"])
    -- gui.text(1, 45, monster["stress"])

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
        -- gui.text(1, 25, "Displaying")

        if changes_previous_monster["stress"] ~= monster["stress"] then
            if monster["stress"] > changes_previous_monster["stress"] then
                gui.text(1, 172, string.format("  +%d", monster["stress"] - changes_previous_monster["stress"]), "green")
            else
                gui.text(1, 172, string.format("  %d", monster["stress"] - changes_previous_monster["stress"]), "red")
            end
        end

        if changes_previous_monster["fatigue"] ~= monster["fatigue"] then
            if monster["fatigue"] > changes_previous_monster["fatigue"] then
                gui.text(1, 172,
                    string.format("         +%d", monster["fatigue"] - changes_previous_monster["fatigue"]), "green")
            else
                gui.text(1, 172, string.format("         %d", monster["fatigue"] - changes_previous_monster["fatigue"]),
                    "red")
            end
        end

        if changes_previous_monster["lifespan"] ~= monster["lifespan"] then
            if monster["lifespan"] > changes_previous_monster["lifespan"] then
                gui.text(1, 172, string.format("                +%d",
                    monster["lifespan"] - changes_previous_monster["lifespan"]), "green")
            else
                gui.text(1, 172, string.format("                %d",
                    monster["lifespan"] - changes_previous_monster["lifespan"]), "red")
            end
        end
    end

end

function main()
    current_time = os.time()
    current_monster = read_current_monster()

    display_monster_data(current_monster)
    display_monster_changes(current_time, current_monster)
end

-- current_monster = read_current_monster()
gui.register(main)
