DEV_MODE = false     -- Enable developer console or not
HONEY_REQUIRED = 50  -- How much honey needed per candy
TICK_RATE = 0.001    -- How much to tick every frame (0.01 = 10s per candy) 

function register()
    return {
        name = "candy",
        hooks = {}
    }
end

function define_candy_bench()
    api_define_menu_object({
        id = "candy_bench",
        name = "Candy Bench",
        category = "Tools",
        tooltip = "Lets you make Apicandy",
        layout = {
            { 7, 17, "Input", { "bottle" } },
            { 7, 40, "Input", { "sawdust2" } },
            { 7, 63, "Liquid Input", { "canister1", "canister2" } },
            { 76, 17, "Output" },
            { 76, 40, "Output" },
            { 76, 63, "Output" },
            { 7, 90 }, { 30, 90 }, { 53, 90 }, { 76, 90 }
        },
        buttons = { "Help", "Target", "Close" },
        info = {
            {"1. Bottle Input", "GREEN"},
            {"2. Sawdust Brick Input", "GREEN"},
            {"3. Honey Canister Input", "GREEN"},
            {"4. Honey Tank", "YELLOW"},
            {"5. Cooking Gauge", "YELLOW"},
            {"6. Cook Button", "RED"},
            {"7. Candy Output", "RED"},
            {"8. Storage", "WHITE"}
        },
        shop_key = false,
        shop_buy = 250,
        shop_sell = 200,
        tools = { "mouse1", "hammer1" },
        placeable = true
    }, "sprites/candy_bench_item.png", "sprites/candy_bench_menu.png", {
        define = "candy_bench_define",
        draw = "candy_bench_draw",
        change = "candy_bench_change",
        tick = "candy_bench_tick"
    })

    local recipe = {
        { item = "stone", amount = 20 }, 
        { item = "barrel", amount = 1},
        { item = "planks1", amount = 10}
    }
    api_define_recipe("crafting", "candy_candy_bench", recipe)
end

function define_candy()
    api_define_object({
        id = "candy1",
        name = "Apicandy",
        category = "Beekeeping",
        tooltip = "Sweet treats, courtesy of the bees",
        shop_key = false,
        shop_buy = 5,
        shop_sell = 2,
        placeable = false
    }, "sprites/candy1_item.png")

    api_define_object({
        id = "candy2",
        name = "Great Apicandy",
        category = "Beekeeping",
        tooltip = "High-quality sweet treats, courtesy of the bees",
        shop_key = false,
        shop_buy = 20,
        shop_sell = 10,
        placeable = false
    }, "sprites/candy2_item.png")

    api_define_object({
        id = "candy3",
        name = "Super Apicandy",
        category = "Beekeeping",
        tooltip = "The sweetest treats, courtesy of the bees",
        shop_key = false,
        shop_buy = 30,
        shop_sell = 20,
        placeable = false
    }, "sprites/candy3_item.png")
end

function init()
    define_candy_bench()
    define_candy()
    
    api_define_sprite("cooking_button", "sprites/cooking_button.png", 1)
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
    api_sp(menu_id, "_fields", fields)

    api_define_tank(menu_id, 1000, 2000, "honey", 30, 39, "large")
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

function has_all_inputs(menu_id)
    local have_bottle = api_get_slot(menu_id, 1)["item"] == "bottle"
    local have_brick = api_get_slot(menu_id, 2)["item"] == "sawdust2"
    local have_honey = api_gp(menu_id, "tank_amount") > HONEY_REQUIRED

    return have_bottle and have_brick and have_honey
end


function get_gauge_pos_local(menu_id)
    local low_y = 18
    local high_y = 52
    local x_pos = 55

    -- The y position is the linear interpolation from the low_y to high_y by the current progress
    local y_pos = high_y - ((high_y - low_y) * api_gp(menu_id, "p_start"))

    return { ["x"] = math.floor(x_pos), ["y"] = math.floor(y_pos) }
end

-- Offset a local position inside a menu to a global position
function local_pos_to_global(menu_id, local_pos)
    local menu_inst = api_get_inst(menu_id)
    local cam = api_get_cam()
    local menu_x = menu_inst["x"] - cam["x"]
    local menu_y = menu_inst["y"] - cam["y"]

    return { ["x"] = local_pos["x"] + menu_x, ["y"] = local_pos["y"] + menu_y }
end

function candy_bench_draw(menu_id)
    api_draw_tank(api_gp(menu_id, "tank_gui"))
    api_draw_button(api_gp(menu_id, "cook_button"), true)

    if api_gp(menu_id, "cooking") then
        -- Make it look like the pot is cooking, how cute!
        local button_sprite = api_get_sprite("sp_cooking_button")
        local sprite_pos = local_pos_to_global(menu_id, {["x"] = 51, ["y"] = 61})
        api_draw_sprite(button_sprite, 1, sprite_pos["x"], sprite_pos["y"])

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

function finish_cooking(menu_id)
    produce_candy(menu_id)
    candy_bench_reset(menu_id)

    -- use up a bottle, a brick, 50bl honey
    api_slot_decr(api_get_slot(menu_id, 1)["id"])
    api_slot_decr(api_get_slot(menu_id, 2)["id"])
    api_sp(menu_id, "tank_amount", api_gp(menu_id, "tank_amount") - HONEY_REQUIRED)
end

function is_cooking(menu_id)
    return api_gp(menu_id, "cooking")
end

function cook_button_click(menu_id)
    if is_cooking(menu_id) then
        finish_cooking(menu_id)
    else
        if has_all_inputs(menu_id) then
            api_sp(menu_id, "cooking", true)
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

