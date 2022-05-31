function register()
    return {
        name = "candy",
        hooks = {"gui"},
        modules = {"define", "config"}
    }
end
function gui()
    -- Draw the progress line for the tooltip of highlighted candy benches
    local obj_id = api_get_highlighted("menu_obj")
    if obj_id == nil then return end
    
    local inst = api_get_inst(obj_id)
    if inst["oid"] == "candy_candy_bench" then    
        local menu_id = inst["menu_id"]

        if is_cooking(menu_id) then
            local local_gauge_pos = get_gauge_pos_local(menu_id)
            local gauge_pos = local_pos_to_global(obj_id, local_gauge_pos)
            gauge_pos = { x = gauge_pos["x"] - 53, y = gauge_pos["y"] - 62}
            local line_width = 10
    
            api_draw_line(gauge_pos["x"], gauge_pos["y"], gauge_pos["x"] + line_width, gauge_pos["y"])
        end
    end
end

function init()
    define_mod()
    api_set_devmode(DEV_MODE)

    return "Success"
end

function candy_bench_define(menu_id)
    -- This will track whether the candymaking is in-progress or not
    api_dp(menu_id, "cooking", false)

    -- This will track the progress of candymaking
    api_dp(menu_id, "p_start", 0)
    api_dp(menu_id, "p_end", 1)

    -- The button a user will press to start cooking
    api_define_button(menu_id, "cook_button", 51, 61, "", "cook_button_click", "sprites/cook_button.png")

    -- Save progress on game save
    local fields = api_gp(menu_id, "_fields")
    if fields == nil then
        fields = {}
    end
    table.insert(fields, "p_start")
    table.insert(fields, "p_end")
    table.insert(fields, "cooking")
    table.insert(fields, "tank_amount")
    api_sp(menu_id, "_fields", fields)

    api_define_tank(menu_id, 0, 2000, "honey", 30, 39, "large")
end

function candy_bench_draw_obj(obj_id)
    local bench_sprite = api_get_sprite("sp_candy_candy_bench")
    local cooking_sprite = api_get_sprite("sp_candy_bench_cooking")
    local tooltip_sprite = api_get_sprite("sp_candy_bench_tooltip")

    local inst = api_get_inst(obj_id)
    local is_highlighted = api_get_highlighted("menu_obj") == obj_id

    -- Draw the relevant sprite and frame depending on whether we're 
    -- highlighted and/or cooking
    if is_highlighted then
        if is_cooking(inst["menu_id"]) then
            if api_get_counter("cooking_counter") == 0 then
                api_draw_sprite(cooking_sprite, 1, inst["x"], inst["y"])
            else
                api_draw_sprite(cooking_sprite, 3, inst["x"], inst["y"])
            end
        else
            api_draw_sprite(bench_sprite, 1, inst["x"], inst["y"])
        end

        -- If we're highlighted, also draw the tooltip
        api_draw_sprite(tooltip_sprite, 0, inst["x"]-2, inst["y"]-50)
    else
        if is_cooking(inst["menu_id"]) then 
            if api_get_counter("cooking_counter") == 0 then
                api_draw_sprite(cooking_sprite, 0, inst["x"], inst["y"])
            else
                api_draw_sprite(cooking_sprite, 2, inst["x"], inst["y"])
            end
        else
            api_draw_sprite(bench_sprite, 0, inst["x"], inst["y"])
        end
    end
end

function candy_bench_change(menu_id)
    -- Fill tank from slot 3
    in_slot = api_get_slot(menu_id, 3)
    if in_slot["item"] == "canister1" or in_slot["item"] == "canister2" then
        api_slot_fill(menu_id, 3)
    end

    if is_cooking(menu_id) and not has_all_inputs(menu_id) then
        candy_bench_reset(menu_id)
    end
end

function has_brick_and_sawdust(menu_id)
    local have_bottle = api_get_slot(menu_id, 1)["item"] == "bottle"
    local have_brick = api_get_slot(menu_id, 2)["item"] == "sawdust2"

    return have_bottle and have_brick
end

function has_enough_honey(menu_id)
    return api_gp(menu_id, "tank_amount") >= HONEY_REQUIRED
end

function has_all_inputs(menu_id)
    return has_brick_and_sawdust(menu_id) and has_enough_honey(menu_id)
end

function get_gauge_pos_local(menu_id)
    local low_y = 18
    local high_y = 52
    local x_pos = 55

    -- The y position is the linear interpolation from the low_y to high_y by the current progress
    local y_pos = high_y - ((high_y - low_y) * api_gp(menu_id, "p_start"))

    return { x = math.floor(x_pos), y = math.floor(y_pos) }
end

-- Offset a position relative to some object to a global position
function local_pos_to_global(id, local_pos)
    local menu_inst = api_get_inst(id)
    local cam = api_get_cam()
    local menu_x = menu_inst["x"] - cam["x"]
    local menu_y = menu_inst["y"] - cam["y"]

    return { x = local_pos["x"] + menu_x, y = local_pos["y"] + menu_y }
end

function candy_bench_draw(menu_id)
    api_draw_tank(api_gp(menu_id, "tank_gui"))
    api_draw_button(api_gp(menu_id, "cook_button"), true)

    -- Draw a warning if the only input missing is honey
    if has_brick_and_sawdust(menu_id) and not has_enough_honey(menu_id) then
        local warning_pos = local_pos_to_global(menu_id, {x = 0, y = 115})
        api_draw_sprite(api_get_sprite("sp_candy_warning"), 0, warning_pos["x"], warning_pos["y"])
    end

    if is_cooking(menu_id) then
        -- Make it look like the pot is cooking, how cute!
        local button_sprite = api_get_sprite("sp_cooking_button")
        local sprite_pos = local_pos_to_global(menu_id, {x = 51, y = 61})

        if api_get_counter("cooking_counter") == 0 then
            api_draw_sprite(button_sprite, 0, sprite_pos["x"], sprite_pos["y"])
        else
            api_draw_sprite(button_sprite, 1, sprite_pos["x"], sprite_pos["y"])
        end 

        -- Draw a white line at the current gauge position
        local gauge_pos = local_pos_to_global(menu_id, get_gauge_pos_local(menu_id))
        local line_width = 10

        api_draw_line(gauge_pos["x"], gauge_pos["y"], gauge_pos["x"] + line_width, gauge_pos["y"])
    end
end

function candy_bench_reset(menu_id)
    api_sp(menu_id, "cooking", false)
    api_sp(menu_id, "p_start", 0)
end

function consume_ingredients(menu_id) 
    -- Consume 1 bottle, 5 sawdust, required amount of honey
    api_slot_decr(api_get_slot(menu_id, 1)["id"])
    api_slot_decr(api_get_slot(menu_id, 2)["id"], 5)
    api_sp(menu_id, "tank_amount", api_gp(menu_id, "tank_amount") - HONEY_REQUIRED)
end

function finish_cooking(menu_id)
    produce_candy(menu_id)
    candy_bench_reset(menu_id)
    consume_ingredients(menu_id)
end

function start_cooking(menu_id)
    api_create_counter("cooking_counter", 0.5, 0, 1, 1)
    api_sp(menu_id, "cooking", true)
end

function is_cooking(menu_id)
    return api_gp(menu_id, "cooking") == true
end

function cook_button_click(menu_id)
    if is_cooking(menu_id) then
        finish_cooking(menu_id)
    else
        if has_all_inputs(menu_id) then
            start_cooking(menu_id)
        end
    end
end

function determine_candy_to_produce(menu_id)
    local gauge_pos = get_gauge_pos_local(menu_id)
    local y = gauge_pos["y"]

    -- Return candy1 if the gauge is in the red area
    -- candy2 if it is in the yellow area
    -- candy3 if it is in the green
    if y >= 18 and y < 25 then
        return "candy_candy1"
    elseif y >= 25 and y < 29 then
        return "candy_candy2"
    elseif y >= 29 and y < 31 then
        return "candy_candy3"
    elseif y >= 31 and y < 35 then
        return "candy_candy2"
    elseif y >= 35 and y < 42 then
        return "candy_candy1"
    end

    -- Hit the button too early, no candy for you
    return nil
end

function produce_candy(menu_id)
    local candy = determine_candy_to_produce(menu_id)

    -- See if we've already produced the relevant type of candy,
    -- if we have, increment the count there, otherwise, make some in a new slot
    if candy ~= nil then
        local slot = api_slot_match_range(menu_id, {"", candy}, {4,5,6}, true)
        if slot["item"] == "" then
            api_slot_set(slot["id"], candy, 1)
            return
        elseif slot["count"] < 99 then
            api_slot_incr(slot["id"])
            return
        end
    end
end

function candy_bench_tick(menu_id)
    if is_cooking(menu_id) then
        api_sp(menu_id, "p_start", api_gp(menu_id, "p_start") + TICK_RATE)

        if api_gp(menu_id, "p_start") >= api_gp(menu_id, "p_end") then
            finish_cooking(menu_id)
        end
    end
end

function candy_bee_mutation_script(bee_a, bee_b, hive_id)
    local slots = api_slot_match(hive_id, { "candy_candy3" })

    local count = 0
    for slot in slots do
        count = count + api_get_inst(slot).count
    end
    
    local chance = api_random(99) + 1
    return count >= 5 and chance >= 60
end