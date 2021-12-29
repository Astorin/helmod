-------------------------------------------------------------------------------
---Description of the module.
---@class Player
local Player = {
  ---single-line comment
  classname = "HMPlayer"
}

local Lua_player = nil

-------------------------------------------------------------------------------
---Print message
function Player.print(...)
  if Lua_player ~= nil then
    Lua_player.print(table.concat({...}," "))
  end
end
-------------------------------------------------------------------------------
---Load factorio player
---@param event LuaEvent
---@return Player
function Player.load(event)
  Lua_player = game.players[event.player_index]
  return Player
end

-------------------------------------------------------------------------------
---Set factorio player
---@param player LuaPlayer
---@return Player
function Player.set(player)
  Lua_player = player
  return Player
end

-------------------------------------------------------------------------------
---Get game day
---@return number, number, number, number
function Player.getGameDay()
  local surface = game.surfaces[1]
  local day = surface.ticks_per_day
  local dusk = surface.evening-surface.dusk
  local night = surface.morning-surface.evening
  local dawn = surface.dawn-surface.morning
  return day, day*dusk, day*night, day*dawn
end

------------------------------------------------------------------------------
---Get display sizes
---@return number, number
function Player.getDisplaySizes()
  if Lua_player == nil then return 800,600 end
  local display_resolution = Lua_player.display_resolution
  local display_scale = Lua_player.display_scale
  return display_resolution.width/display_scale, display_resolution.height/display_scale
end

-------------------------------------------------------------------------------
---Set pipette
---@param entity any
---@return any
function Player.setPipette(entity)
  if Lua_player == nil then return nil end
  return Lua_player.pipette_entity(entity)
end

-------------------------------------------------------------------------------
---Get character crafting speed
---@return number
function Player.getCraftingSpeed()
  if Lua_player == nil then return 0 end
  return 1 + Lua_player.character_crafting_speed_modifier
end

-------------------------------------------------------------------------------
---Get main inventory
---@return any
function Player.getMainInventory()
  if Lua_player == nil then return nil end
  return Lua_player.get_main_inventory()
end

-------------------------------------------------------------------------------
---Begin Crafting
---@param item string
---@param count number
function Player.beginCrafting(item, count)
  if Lua_player == nil then return nil end
  local filters = {{filter = "has-product-item", elem_filters = {{filter = "name", name = item}}}}
  local recipes = Player.getRecipePrototypes(filters)
  if recipes ~= nil and table.size(recipes) > 0 then
    local first_recipe = Model.firstRecipe(recipes)
    local craft = {count=math.ceil(count),recipe=first_recipe.name,silent=false}
    Lua_player.begin_crafting(craft)
  else
    Player.print("No recipe found for this craft!")
  end
end

-------------------------------------------------------------------------------
---Get smart tool
---@return LuaItemStack
function Player.getSmartTool()
  if Lua_player == nil then return nil end
  local inventory = Player.getMainInventory()
  local tool_stack = nil
  for i = 1, #inventory do
    local stack = inventory[i]
    if stack.valid_for_read and stack.is_blueprint and stack.name == "blueprint" and stack.label == "Helmod Smart Tool" then
      if stack.is_blueprint_setup() then
        if Lua_player.cursor_stack.swap_stack(stack) then
            return Lua_player.cursor_stack
        end
      else
        Lua_player.cursor_stack.swap_stack(stack)
        return Lua_player.cursor_stack
      end
    end
  end
  Lua_player.cursor_stack.set_stack("blueprint")
  return Lua_player.cursor_stack
end

-------------------------------------------------------------------------------
---Set smart tool
---@param recipe table
---@param type string
---@return any
function Player.setSmartTool(recipe, type)
  if Lua_player == nil then return nil end
  local tool_stack = Player.getSmartTool()
  if tool_stack ~= nil then
    tool_stack.clear_blueprint()
    tool_stack.label = "Helmod Smart Tool"
    tool_stack.allow_manual_label_change = false
    local factory = recipe[type]
    local modules = {}
    for name,value in pairs(factory.modules or {}) do
      modules[name] = value
    end
    local entity = {
      entity_number = 1,
      name = factory.name,
      position = {0, 0},
      items = modules
    }
    if type == "factory" then
      entity.recipe = recipe.name
    end
    tool_stack.set_blueprint_entities({entity})
  
  end
end

-------------------------------------------------------------------------------
---Is valid sprite path
---@param sprite_path string
---@return boolean
function Player.is_valid_sprite_path(sprite_path)
  if Lua_player == nil then return false end
  return Lua_player.gui.is_valid_sprite_path(sprite_path)
end

-------------------------------------------------------------------------------
---Return factorio player
---@return LuaPlayer
function Player.native()
  return Lua_player
end

-------------------------------------------------------------------------------
---Return admin player
---@return boolean
function Player.isAdmin()
  return Lua_player.admin
end

-------------------------------------------------------------------------------
---Get gui
---@param location string
---@return LuaGuiElement
function Player.getGui(location)
  return Lua_player.gui[location]
end

-------------------------------------------------------------------------------
---Return force's player
---@return LuaForce
function Player.getForce()
  return Lua_player.force
end

-------------------------------------------------------------------------------
---Sets the toggle state of the shotcut tool/icon
---@param state boolean
function Player.setShortcutState(state)
  if Lua_player ~= nil then
    Lua_player.set_shortcut_toggled("helmod-shortcut", state)
  end
end


-------------------------------------------------------------------------------
---Return item type
---@param element LuaPrototype
---@return string
function Player.getItemIconType(element)
  local item = Player.getItemPrototype(element.name)
  if item ~= nil then
    return "item"
  end
  local fluid = Player.getFluidPrototype(element.name)
  if fluid ~= nil then
    return "fluid"
  else
    return "item"
  end
end

-------------------------------------------------------------------------------
---Return entity type
---@param element LuaPrototype
---@return string
function Player.getEntityIconType(element)
  local item = Player.getEntityPrototype(element.name)
  if item ~= nil then
    return "entity"
  end
  return Player.getItemIconType(element)
end

-------------------------------------------------------------------------------
---Return localised name
---@param element LuaPrototype
---@return string|table
function Player.getLocalisedName(element)
  local localisedName = element.name
  if element.type ~= nil then
    if element.type == "recipe" or element.type == "recipe-burnt" then
      local recipe = Player.getRecipe(element.name)
      if recipe ~= nil then
        localisedName = recipe.localised_name
      end
    end
    if element.type == "technology" then
      local technology = Player.getTechnology(element.name)
      if technology ~= nil then
        localisedName = technology.localised_name
      end
    end
    if element.type == "entity" or element.type == "resource" then
      local item = Player.getEntityPrototype(element.name)
      if item ~= nil then
        localisedName = item.localised_name
      end
    end
    if element.type == 0 or element.type == "item" then
      local item = Player.getItemPrototype(element.name)
      if item ~= nil then
        localisedName = item.localised_name
      end
    end
    if element.type == 1 or element.type == "fluid" then
      local item = Player.getFluidPrototype(element.name)
      if item ~= nil then
        localisedName = item.localised_name
      end
    end
  end
  return localisedName
end

-------------------------------------------------------------------------------
---Return localised name
---@param prototype LuaPrototype
---@return string|table
function Player.getRecipeLocalisedName(prototype)
  local element = Player.getRecipe(prototype.name)
  if element ~= nil then
    return element.localised_name
  end
  return prototype.name
end

-------------------------------------------------------------------------------
---Return localised name
---@param prototype LuaPrototype
---@return string|table
function Player.getTechnologyLocalisedName(prototype)
  local element = Player.getTechnology(prototype.name)
  if element ~= nil then
    return element.localised_name
  end
  return element.name
end

-------------------------------------------------------------------------------
---Return recipes
---@return table
function Player.getRecipes()
  return Player.getForce().recipes
end

-------------------------------------------------------------------------------
---Return recipe prototypes
---@param filters table
---@return table
function Player.getRecipePrototypes(filters)
  if filters ~= nil then
    return game.get_filtered_recipe_prototypes(filters)
  end
  return game.recipe_prototypes
end

-------------------------------------------------------------------------------
---Return technologie prototypes
---@param filters table
---@return table
function Player.getTechnologiePrototypes(filters)
  if filters ~= nil then
    return game.get_filtered_technology_prototypes(filters)
  end
  return game.technology_prototypes
end

-------------------------------------------------------------------------------
---Return technology prototype
---@param name string
---@return LuaTechnologyPrototype
function Player.getTechnologyPrototype(name)
  return game.technology_prototypes[name]
end

-------------------------------------------------------------------------------
---Return technologies
---@return table
function Player.getTechnologies()
  local technologies = {}
  for _,technology in pairs(Player.getForce().technologies) do
    technologies[technology.name] = technology
  end
  return technologies
end

-------------------------------------------------------------------------------
---Return technology
---@param name string
---@return LuaTechnology
function Player.getTechnology(name)
  local technology = Player.getForce().technologies[name]
  return technology
end

-------------------------------------------------------------------------------
---Return rule
---@param rule_name string
---@return table, table --rules_included, rules_excluded
function Player.getRules(rule_name)
  local rules_included = {}
  local rules_excluded = {}
  for rule_id, rule in spairs(Model.getRules(), function(t,a,b) return t[b].index > t[a].index end) do
    if game.active_mods[rule.mod] and rule.name == rule_name then
      if rule.excluded then
        if rules_excluded[rule.category] == nil then rules_excluded[rule.category] = {} end
        if rules_excluded[rule.category][rule.type] == nil then rules_excluded[rule.category][rule.type] = {} end
        rules_excluded[rule.category][rule.type][rule.value] = true
      else
        if rules_included[rule.category] == nil then rules_included[rule.category] = {} end
        if rules_included[rule.category][rule.type] == nil then rules_included[rule.category][rule.type] = {} end
        rules_included[rule.category][rule.type][rule.value] = true
      end
    end
  end
  return rules_included, rules_excluded
end

-------------------------------------------------------------------------------
---Return rule
---@param check boolean
---@param rules table
---@param category string
---@param lua_entity table
---@param included boolean
---@return boolean
function Player.checkRules(check, rules, category, lua_entity, included)
  if rules[category] then
    if rules[category]["entity-name"] and (rules[category]["entity-name"]["all"] or rules[category]["entity-name"][lua_entity.name]) then
      check = included
    elseif rules[category]["entity-type"] and (rules[category]["entity-type"]["all"] or rules[category]["entity-type"][lua_entity.type]) then
      check = included
    elseif rules[category]["entity-group"] and (rules[category]["entity-group"]["all"] or rules[category]["entity-group"][lua_entity.group.name]) then
      check = included
    elseif rules[category]["entity-subgroup"] and (rules[category]["entity-subgroup"]["all"] or rules[category]["entity-subgroup"][lua_entity.subgroup.name]) then
      check = included
    end
  end
  return check
end

-------------------------------------------------------------------------------
---Check factory limitation module
---@param module table
---@param lua_recipe table
---@return boolean
function Player.checkFactoryLimitationModule(module, lua_recipe)
  local rules_included, rules_excluded = Player.getRules("module-limitation")
  local model_filter_factory_module = User.getModGlobalSetting("model_filter_factory_module")
  local factory = lua_recipe.factory
  local allowed = true
  local check_not_bypass = true
  local prototype = RecipePrototype(lua_recipe)
  local category = prototype:getCategory()
  if category == "rocket-building" then return true end
  if rules_excluded[category] == nil then category = "standard" end
  check_not_bypass = Player.checkRules(check_not_bypass, rules_excluded, category, EntityPrototype(factory.name):native(), false)
  if table.size(module.limitations) > 0 and check_not_bypass and model_filter_factory_module == true then
    allowed = false
    for _, recipe_name in pairs(module.limitations) do
      if lua_recipe.name == recipe_name then
        allowed = true
      end
    end
  end

  local allowed_effects = EntityPrototype(factory):getAllowedEffects()
  if allowed_effects ~= nil and model_filter_factory_module == true then
    for _, effect in pairs({"speed", "productivity", "consumption", "pollution"}) do
      if (Player.getModuleBonus(module.name, effect) ~= 0) and (not allowed_effects[effect]) then
        allowed = false
      end
    end
  end

  if factory.module_slots ==  0 then
    allowed = false
  end
  return allowed
end

-------------------------------------------------------------------------------
---Check beacon limitation module
---@param module table
---@param lua_recipe table
---@return boolean
function Player.checkBeaconLimitationModule(module, lua_recipe)
  local beacon = lua_recipe.beacon
  local allowed = true
  local model_filter_beacon_module = User.getModGlobalSetting("model_filter_beacon_module")

  if table.size(module.limitations) > 0 and model_filter_beacon_module == true then
    allowed = false
    for _, recipe_name in pairs(module.limitations) do
      if lua_recipe.name == recipe_name then
        allowed = true
      end
    end
  end

  local allowed_effects = EntityPrototype(beacon):getAllowedEffects()
  if allowed_effects ~= nil and model_filter_beacon_module == true then
    for _, effect in pairs({"speed", "productivity", "consumption", "pollution"}) do
      if (Player.getModuleBonus(module.name, effect) ~= 0) and (not allowed_effects[effect]) then
        allowed = false
      end
    end
  end

  if beacon.module_slots ==  0 then
    allowed = false
  end
  return allowed
end

-------------------------------------------------------------------------------
---Return list of productions
---@param category string
---@param lua_recipe table
---@return table
function Player.getProductionsCrafting(category, lua_recipe)
  local productions = {}
  local rules_included, rules_excluded = Player.getRules("production-crafting")
  if category == "crafting-handonly" then
    productions["character"] = game.entity_prototypes["character"]
  elseif lua_recipe.name ~= nil and lua_recipe.name == "water" then
    for key, lua_entity in pairs(Player.getOffshorePump()) do
      productions[lua_entity.name] = lua_entity
    end
  elseif lua_recipe.name ~= nil and lua_recipe.name == "water-viscous-mud" and lua_recipe.object_name ~= "LuaRecipePrototype" and lua_recipe.type ~= "recipe" then
    for key, lua_entity in pairs(Player.getOffshorePump("water-viscous-mud")) do
      productions[lua_entity.name] = lua_entity
    end
  elseif lua_recipe.name ~= nil and lua_recipe.name == "steam" then
    for key, lua_entity in pairs(Player.getBoilers()) do
      productions[lua_entity.name] = lua_entity
    end
  else
    for key, lua_entity in pairs(Player.getProductionMachines()) do
      local check = false
      if category ~= nil then
        if not(rules_included[category]) and not(rules_included[category]) then
          ---standard recipe
          if lua_entity.crafting_categories ~= nil and lua_entity.crafting_categories[category] then
            local recipe_ingredient_count = RecipePrototype(lua_recipe, "recipe"):getIngredientCount()
            local factory_ingredient_count = EntityPrototype(lua_entity):getIngredientCount()
            if factory_ingredient_count >= recipe_ingredient_count then
              check = true
            end
            ---resolve rule excluded
            check = Player.checkRules(check, rules_excluded, "standard", lua_entity, false)
          end
        else
          ---resolve rule included
          check = Player.checkRules(check, rules_included, category, lua_entity, true)
          ---resolve rule excluded
          check = Player.checkRules(check, rules_excluded, category, lua_entity, false)
        end
      else
        if lua_entity.group ~= nil and lua_entity.group.name == "production" then
          check = true
        end
      end
      ---resource filter
      if check then
        if lua_recipe.name ~= nil then
          local lua_entity_filter = Player.getEntityPrototype(lua_recipe.name)
          if lua_entity_filter ~= nil and lua_entity.resource_categories ~= nil and not(lua_entity.resource_categories[lua_entity_filter.resource_category]) then
            check = false
          end
        end
      end
      ---ok to add entity
      if check then
        productions[lua_entity.name] = lua_entity
      end
    end
  end
  return productions
end

-------------------------------------------------------------------------------
---Return list of modules
---@return table
function Player.getModules()
  local items = {}
  local filters = {}
  table.insert(filters,{filter="type",type="module",mode="or"})
  table.insert(filters,{filter="flag",flag="hidden",mode="and", invert=true})

  for _,item in pairs(game.get_filtered_item_prototypes(filters)) do
    table.insert(items,item)
  end
  return items
end

-------------------------------------------------------------------------------
---Return list of production machines
---@return table
function Player.getProductionMachines()
  local filters = {}
  table.insert(filters,{filter="crafting-machine",mode="and"})
  table.insert(filters,{filter="hidden",mode="and",invert=true})
  table.insert(filters,{filter="type", type="lab",mode="or"})
  table.insert(filters,{filter="type", type="mining-drill",mode="or"})
  table.insert(filters,{filter="type", type="rocket-silo",mode="or"})
  return game.get_filtered_entity_prototypes(filters)
end

-------------------------------------------------------------------------------
---Return list of energy machines
---@return table
function Player.getEnergyMachines()
    local filters = {}

  for _,type in pairs({"generator", "solar-panel", "boiler", "accumulator", "reactor", "offshore-pump", "seafloor-pump"}) do
    table.insert(filters, {filter="type", mode="or", invert=false, type=type})
  end
  return game.get_filtered_entity_prototypes(filters)
end

-------------------------------------------------------------------------------
---Return list of boilers
---@return table
function Player.getBoilers()
  local filters = {}
  table.insert(filters,{filter="type", type="boiler", mode="or"})
  table.insert(filters,{filter="flag", flag="hidden", mode="and", invert=true})

  return game.get_filtered_entity_prototypes(filters)
end

-------------------------------------------------------------------------------
---Return list of Offshore-Pump
---@return table
function Player.getOffshorePump(fluid_name)
  if fluid_name == nil then fluid_name = "water" end
  local filters = {}
  table.insert(filters,{filter="type", type="offshore-pump" ,mode="or"})
  local entities = game.get_filtered_entity_prototypes(filters)
  local offshore_pump = {}
  for key,entity in pairs(entities) do
    local fluidbox_prototype = EntityPrototype(entity):getFluidboxPrototype("output")
    if fluidbox_prototype:getFilter() ~= nil and fluidbox_prototype:getFilter().name == fluid_name then
      offshore_pump[key] = entity
    end
  end
  return offshore_pump
end

-------------------------------------------------------------------------------
---Return module bonus (default return: bonus = 0 )
---@param module string
---@param effect string
---@return number
function Player.getModuleBonus(module, effect)
  if module == nil then return 0 end
  local bonus = 0
  ---search module
  local module = Player.getItemPrototype(module)
  if module ~= nil and module.module_effects ~= nil and module.module_effects[effect] ~= nil then
    bonus = module.module_effects[effect].bonus
  end
  return bonus
end

-------------------------------------------------------------------------------
---Return recipe prototype
---@param name string
---@return LuaRecipe
function Player.getRecipePrototype(name)
  if name == nil then return nil end
  return game.recipe_prototypes[name]
end

-------------------------------------------------------------------------------
---Return recipe
---@param name string
---@return LuaRecipe
function Player.getRecipe(name)
  return Player.getForce().recipes[name]
end

-------------------------------------------------------------------------------
---Return resource recipe
---@param name string
---@return table
function Player.getRecipeEntity(name)
  local entity_prototype = EntityPrototype(name)
  local prototype = entity_prototype:native()
  local type = "item"
  if name == "crude-oil" then type = "entity" end
  --local ingredients = {{name=prototype.name, type=type, amount=1}}
  local ingredients = {}
  if entity_prototype:getMineableMiningFluidRequired() then
    local fluid_ingredient = {name=entity_prototype:getMineableMiningFluidRequired(), type="fluid", amount=entity_prototype:getMineableMiningFluidAmount()}
    table.insert(ingredients, fluid_ingredient)
  end
  local recipe = {}
  recipe.category = "extraction-machine"
  recipe.enabled = true
  recipe.energy = 1
  recipe.force = {}
  recipe.group = {name="helmod", order="zzzz"}
  recipe.subgroup = prototype.subgroup
  recipe.hidden = false
  if prototype.flags ~= nil then
    recipe.hidden = prototype.flags["hidden"] or false
  end
  recipe.ingredients = ingredients
  recipe.products = entity_prototype:getMineableMiningProducts()
  recipe.localised_description = prototype.localised_description
  recipe.localised_name = prototype.localised_name
  recipe.name = prototype.name
  recipe.prototype = {}
  recipe.valid = true
  return recipe
end

-------------------------------------------------------------------------------
---Return recipe
---@param name string
---@return table
function Player.getRecipeFluid(name)
  local fluid_prototype = FluidPrototype(name)
  local prototype = fluid_prototype:native()
  local products = {{name=prototype.name, type="fluid", amount=1}}
  local ingredients = {{name=prototype.name, type="fluid", amount=1}}
  if prototype.name == "steam" then
    ingredients = {{name="water", type="fluid", amount=1}}
  end
  local recipe = {}
  recipe.category = "chemistry"
  recipe.enabled = true
  recipe.energy = 1
  recipe.force = {}
  recipe.group = {name="helmod", order="zzzz"}
  recipe.subgroup = prototype.subgroup
  recipe.hidden = false
  recipe.ingredients = ingredients
  recipe.products = products
  recipe.localised_description = prototype.localised_description
  recipe.localised_name = prototype.localised_name
  recipe.name = prototype.name
  recipe.prototype = {}
  recipe.valid = true
  return recipe
end

-------------------------------------------------------------------------------
---Return recipe
---@param name string
---@return table
function Player.getRecipeRocket(name)
  ---Prepare launch = 15s
  local rocket_part_prototype = RecipePrototype("rocket-part"):native()
  local rocket_prototype = EntityPrototype("rocket-silo"):native()
  local item_prototype = ItemPrototype(name)
  local prototype = item_prototype:native()
  local products = prototype.rocket_launch_products
  local ingredients = rocket_part_prototype.ingredients
  for _,ingredient in pairs(ingredients) do
    ingredient.amount= ingredient.amount * rocket_prototype.rocket_parts_required
  end
  table.insert(ingredients, {name=name, type="item", amount=1, constant=true})
  local recipe = {}
  recipe.category = rocket_part_prototype.category
  recipe.enabled = true
  recipe.energy = rocket_part_prototype.energy * rocket_prototype.rocket_parts_required + 15
  recipe.force = {}
  --recipe.group = prototype.group
  recipe.group = {name="helmod", order="zzzz"}
  recipe.subgroup = prototype.subgroup
  recipe.hidden = false
  recipe.ingredients = ingredients
  recipe.products = products
  recipe.localised_description = prototype.localised_description
  recipe.localised_name = prototype.localised_name
  recipe.name = prototype.name
  recipe.prototype = {}
  recipe.valid = true
  return recipe
end

-------------------------------------------------------------------------------
---Return recipe
---@param name string
---@return table
function Player.getRecipeBurnt(name)
  local recipe_prototype = Player.getRecipePrototype(name)
  local recipe = {}
  recipe.category = recipe_prototype.category
  recipe.enabled = true
  recipe.energy = recipe_prototype.energy
  recipe.force = {}
  --recipe.group = prototype.group
  recipe.group = {name="helmod", order="zzzz"}
  recipe.subgroup = recipe_prototype.subgroup
  recipe.hidden = false
  recipe.ingredients = recipe_prototype.ingredients
  recipe.products = recipe_prototype.products
  recipe.localised_description = recipe_prototype.localised_description
  recipe.localised_name = recipe_prototype.localised_name
  recipe.name = recipe_prototype.name
  recipe.prototype = {}
  recipe.valid = true
  recipe.hidden_from_player_crafting = recipe_prototype.hidden_from_player_crafting
  return recipe
end

-------------------------------------------------------------------------------
---Return recipe
---@param name string
---@return table
function Player.getRecipeTechnology(name)
  local technology_prototype = Player.getTechnology(name)
  local recipe = {}
  recipe.category = "technology"
  recipe.enabled = true
  recipe.energy = technology_prototype.research_unit_energy/60
  recipe.force = technology_prototype.force
  recipe.group = {}
  recipe.subgroup = {}
  recipe.hidden = false
  recipe.ingredients = {}
  recipe.products = {}
  recipe.localised_description = technology_prototype.localised_description
  recipe.localised_name = technology_prototype.localised_name
  recipe.name = technology_prototype.name
  recipe.prototype = technology_prototype.prototype
  recipe.valid = true
  return recipe
end

-------------------------------------------------------------------------------
---Return list of recipes
---@param element_name string
---@param by_ingredient boolean
---@return table
function Player.searchRecipe(element_name, by_ingredient)
  local recipes = {}
  ---recherche dans les produits des recipes
  for key, recipe in pairs(Player.getRecipes()) do
    local elements = recipe.products or {}
    if by_ingredient == true then elements = recipe.ingredients or {} end
    for k, element in pairs(elements) do
      if element.name == element_name then
        table.insert(recipes,{name=recipe.name, type="recipe"})
      end
    end
  end
  ---recherche dans les resource
  for key, resource in pairs(Player.getResources()) do
    local elements = EntityPrototype(resource):getMineableMiningProducts()
    for key, element in pairs(elements) do
      if element.name == element_name then
        table.insert(recipes,{name=resource.name, type="resource"})
        break
      end
    end
  end
  ---recherche dans les fluids
  for key, fluid in pairs(Player.getFluidPrototypes()) do
    if fluid.name == element_name then
      table.insert(recipes,{name=fluid.name, type="fluid"})
    end
  end
  return recipes
end

-------------------------------------------------------------------------------
---Return entity prototypes
---@param filters table --{{filter="type", mode="or", invert=false type="transport-belt"}}
---@return table
function Player.getEntityPrototypes(filters)
  if filters ~= nil then
    return game.get_filtered_entity_prototypes(filters)
  end
  return game.entity_prototypes
end

-------------------------------------------------------------------------------
---Return entity prototype types
---@return table
function Player.getEntityPrototypeTypes()
  local types = {}
  for _,entity in pairs(game.entity_prototypes) do
    local type = entity.type
    types[type] = true
  end
  return types
end

-------------------------------------------------------------------------------
---Return entity prototype
---@param name string
---@return LuaEntityPrototype
function Player.getEntityPrototype(name)
  if name == nil then return nil end
  return game.entity_prototypes[name]
end

-------------------------------------------------------------------------------
---Return beacon production
---@return table
function Player.getProductionsBeacon()
  local items = {}
  local filters = {}
  table.insert(filters,{filter="type",type="beacon",mode="or"})
  table.insert(filters,{filter="hidden",invert=true,mode="and"})

  for _,item in pairs(game.get_filtered_entity_prototypes(filters)) do
    table.insert(items,item)
  end
  return items
end

-------------------------------------------------------------------------------
---Return generators
---@param type string
---@return table
function Player.getGenerators(type)
  if type == nil then type = "primary" end
  local items = {}
  local filters = {}
  if type == "primary" then
    table.insert(filters,{filter="type",type="generator",mode="or"})
    table.insert(filters,{filter="type",type="solar-panel",mode="or"})
  else
    table.insert(filters,{filter="type",type="boiler",mode="or"})
    table.insert(filters,{filter="type",type="accumulator",mode="or"})
  end

  for _,item in pairs(game.get_filtered_entity_prototypes(filters)) do
    table.insert(items,item)
  end
  return items
end

-------------------------------------------------------------------------------
---Return resources list
---@return table
function Player.getResources()
  local cache_resources = Cache.getData(Player.classname, "resources")
  if cache_resources ~= nil then return cache_resources end
  local items = {}
  for _,item in pairs(game.entity_prototypes) do
    if item.name ~= nil and item.resource_category ~= nil then
      table.insert(items,item)
    end
  end
  Cache.setData(Player.classname, "resources", items)
  return items
end

-------------------------------------------------------------------------------
---Return item prototypes
---@param filters table --{{filter="fuel-category", mode="or", invert=false,["fuel-category"]="chemical"}}
---@return table
function Player.getItemPrototypes(filters)
  if filters ~= nil then
    return game.get_filtered_item_prototypes(filters)
  end
  return game.item_prototypes
end

-------------------------------------------------------------------------------
---Return item prototype types
---@return table
function Player.getItemPrototypeTypes()
  local types = {}
  for _,entity in pairs(game.item_prototypes) do
    local type = entity.type
    types[type] = true
  end
  return types
end

-------------------------------------------------------------------------------
---Return item prototype
---@param name string
---@return LuaItemPrototype
function Player.getItemPrototype(name)
  if name == nil then return nil end
  return game.item_prototypes[name]
end

-------------------------------------------------------------------------------
---Return fluid prototypes
---@param filters table --{{filter="type", mode="or", invert=false type="transport-belt"}}
---@return table
function Player.getFluidPrototypes(filters)
  if filters ~= nil then
    return game.get_filtered_fluid_prototypes(filters)
  end
  return game.fluid_prototypes
end

-------------------------------------------------------------------------------
---Return fluid prototype types
---@return table
function Player.getFluidPrototypeTypes()
  local types = {}
  for _,entity in pairs(game.fluid_prototypes) do
    local type = entity.type
    types[type] = true
  end
  return types
end

-------------------------------------------------------------------------------
---Return fluid prototype subgroups
---@return table
function Player.getFluidPrototypeSubgroups()
  local types = {}
  for _,entity in pairs(game.fluid_prototypes) do
    local type = entity.subgroup.name
    types[type] = true
  end
  return types
end

-------------------------------------------------------------------------------
---Return fluid prototype
---@param name string
---@return LuaFluidPrototype
function Player.getFluidPrototype(name)
  if name == nil then return nil end
  return game.fluid_prototypes[name]
end

-------------------------------------------------------------------------------
---Return fluid fuel prototype
---@return table
function Player.getFluidFuelPrototypes()
  local filters = {}
  table.insert(filters, {filter="fuel-value", mode="or", invert=false, comparison=">", value=0})
  return Player.getFluidPrototypes(filters)
end

-------------------------------------------------------------------------------
---Return items logistic
---@param type string --belt, container or transport
---@return table
function Player.getItemsLogistic(type)
  local filters = {}
  if type == "inserter" then
    filters = {{filter="type", mode="or", invert=false, type="inserter"}}
  elseif type == "belt" then
    filters = {{filter="type", mode="or", invert=false, type="transport-belt"}}
  elseif type == "container" then
    filters = {{filter="type", mode="or", invert=false, type="container"}, {filter="minable", mode="and", invert=false}, {filter="type", mode="or", invert=false, type="logistic-container"}, {filter="minable", mode="and", invert=false}}
  elseif type == "transport" then
    filters = {{filter="type", mode="or", invert=false, type="cargo-wagon"}, {filter="type", mode="or", invert=false, type="logistic-robot"}, {filter="type", mode="or", invert=false, type="car"}}
  end
  return Player.getEntityPrototypes(filters)
end

-------------------------------------------------------------------------------
---Return default item logistic
---@param type string --belt, container or transport
---@return table
function Player.getDefaultItemLogistic(type)
  local default = User.getParameter(string.format("items_logistic_%s", type))
  if default == nil then 
    local logistics = Player.getItemsLogistic(type)
    if logistics ~= nil then
      default = first(logistics).name
      User.setParameter(string.format("items_logistic_%s", type), default)
    end
  end
  return default
end

-------------------------------------------------------------------------------
---Return fluids logistic
---@param type string --pipe, container or transport
---@return table
function Player.getFluidsLogistic(type)
  local filters = {}
  if type == "pipe" then
    filters = {{filter="type", mode="or", invert=false, type="pipe"}}
  elseif type == "container" then
    filters = {{filter="type", mode="or", invert=false, type="storage-tank"}, {filter="minable", mode="and", invert=false}}
  elseif type == "transport" then
    filters = {{filter="type", mode="or", invert=false, type="fluid-wagon"}}
  end
  return Player.getEntityPrototypes(filters)
end

-------------------------------------------------------------------------------
---Return default fluid logistic
---@param type string --pipe, container or transport
---@return table
function Player.getDefaultFluidLogistic(type)
  local default = User.getParameter(string.format("fluids_logistic_%s", type))
  if default == nil then 
    local logistics = Player.getFluidsLogistic(type)
    if logistics ~= nil then
      default = first(logistics).name
      User.setParameter(string.format("fluids_logistic_%s", type), default)
    end
  end
  return default
end

-------------------------------------------------------------------------------
---Return number
---@param number string
---@return number
function Player.parseNumber(number)
  if number == nil then return 0 end
  local value = string.match(number,"[0-9.]*",1)
  local power = string.match(number,"[0-9.]*([a-zA-Z]*)",1)
  if power == nil then
    return tonumber(value)
  elseif string.lower(power) == "kw" then
    return tonumber(value)*1000
  elseif string.lower(power) == "mw" then
    return tonumber(value)*1000*1000
  elseif string.lower(power) == "gw" then
    return tonumber(value)*1000*1000*1000
  elseif string.lower(power) == "kj" then
    return tonumber(value)*1000
  elseif string.lower(power) == "mj" then
    return tonumber(value)*1000*1000
  elseif string.lower(power) == "gj" then
    return tonumber(value)*1000*1000*1000
  end
end

return Player