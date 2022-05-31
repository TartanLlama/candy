function define_mod()
    define_candy_bench()
    define_candy()
    define_candy_bee()

    api_define_sprite("cooking_button", "sprites/cooking_button.png", 2)
    api_define_sprite("candy_bench_tooltip", "sprites/candy_bench_tooltip.png", 1)
    api_define_sprite("candy_bench_cooking", "sprites/candy_bench_cooking.png", 4)
    api_define_sprite("candy_warning", "sprites/candy_warning.png", 1)
end

function define_candy_bee()
    local bee_def = {
        id = "candy",
        title = "Candy",
        latin = "Apis Caramellus",
        hint = "Loves the smell of Super Apicandy",
        desc = "As sweet as the honey it makes. A very lively bee which loves frantically going from candy to candy to find the sweetest ones. Can be kept indoors to infuse the room with the delightful scent it leaves behind.",
        lifespan = { "Short" },
        productivity = { "Fast", "Fastest" },
        fertility = { "Fecund", "Fertile" },
        stability = { "Normal", "Stable" },
        behaviour = { "Diurnal", "Cathermal" },
        climate = { "Temperate" },
        rainlover = false,
        snowlover = false,
        grumpy = false,
        produce = "candy_candy4",
        chance = 60,
        bid = "CA",
        tier = 3,
        requirement = "At least 5 Super Apicandy in the apiary/spawner"
    }

    api_define_bee(bee_def,
        "sprites/candy_bee_item.png", "sprites/candy_bee_shiny.png",
        "sprites/candy_bee_hd.png",
        { r = 146, g = 118, b = 220 },
        "sprites/candy_bee_mag.png",
        "Candy, candy, everywhere!",
        "The air is sweet with the buzzing of the Candy Bees once more."
    )

    api_define_bee_recipe(
        "rocky", "dream", "candy",
        "candy_bee_mutation_script"
    )
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
        shop_key = true,
        shop_buy = 250,
        shop_sell = 0,
        tools = { "mouse1", "hammer1" },
        placeable = true
    }, "sprites/candy_bench_item.png", "sprites/candy_bench_menu.png", {
        define = "candy_bench_define",
        draw = "candy_bench_draw",
        change = "candy_bench_change",
        tick = "candy_bench_tick"
    },
        "candy_bench_draw_obj")

    local recipe = {
        { item = "stone", amount = 20 }, 
        { item = "barrel", amount = 1},
        { item = "planks1", amount = 10}
    }
    api_define_recipe("crafting", "candy_candy_bench", recipe)

    api_create_counter("cooking_counter", 0.5, 0, 1, 1)
end

function define_candy()
    api_define_item({
        id = "candy1",
        name = "Apicandy",
        category = "Beekeeping",
        tooltip = "Sweet treats, courtesy of the bees",
        shop_key = false,
        shop_buy = 5,
        shop_sell = 2
    }, "sprites/candy1_item.png")

    api_define_item({
        id = "candy2",
        name = "Great Apicandy",
        category = "Beekeeping",
        tooltip = "High-quality sweet treats, courtesy of the bees",
        shop_key = false,
        shop_buy = 20,
        shop_sell = 10
    }, "sprites/candy2_item.png")

    api_define_item({
        id = "candy3",
        name = "Super Apicandy",
        category = "Beekeeping",
        tooltip = "The sweetest treats, courtesy of the bees",
        shop_key = false,
        shop_buy = 30,
        shop_sell = 20
    }, "sprites/candy3_item.png")

    api_define_item({
        id = "candy4",
        name = "Beemade Apicandy",
        category = "Beekeeping",
        tooltip = "Sweet treats, made solely by the bees",
        shop_key = false,
        shop_buy = 5,
        shop_sell = 2
    }, "sprites/candy4_item.png")
end