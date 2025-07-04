-------------------------------------------------------------------------------
---Description of the module.
---@class Product : Prototype
Product = newclass(Prototype,function(base, object)
  Prototype.init(base, object)
  base.classname = "HMProduct"
  base.belt_ratio = 45/0.09375
end)

Product.classname = "HMProduct"

-------------------------------------------------------------------------------
---Return localised name of Prototype
---@return string
function Product:getLocalisedName()
  if self.lua_prototype ~= nil then
    local localisedName = self.lua_prototype.name
    if self.lua_prototype.type == 0 or self.lua_prototype.type == "item" then
      local item = Player.getItemPrototype(self.lua_prototype.name)
      if item ~= nil then
        localisedName = item.localised_name
      end
    end
    if self.lua_prototype.type == 1 or self.lua_prototype.type == "fluid" then
      local item = Player.getFluidPrototype(self.lua_prototype.name)
      if item ~= nil then
        localisedName = item.localised_name
      end
    end
    return localisedName
  end
  return "unknow"
end

-------------------------------------------------------------------------------
---Return table key
---@return string
function Product:getTableKey()
  if self.lua_prototype ~= nil then
    if self.lua_prototype.type == 1 or self.lua_prototype.type == "fluid" then
      local T = self.lua_prototype.temperature
      if T ~= nil then
        return string.format("%s#%s", self.lua_prototype.name,T)
      end
      local Tmin = self.lua_prototype.minimum_temperature 
      local Tmax = self.lua_prototype.maximum_temperature
      if Tmin ~= nil or Tmax ~= nil then
        Tmin = Tmin or -1e300
        Tmax = Tmax or 1e300
        if Tmin < -1e300 and Tmax < 1e300 then
          return string.format("%s#inf#%s", self.lua_prototype.name, Tmax)
        end
        if Tmin > -1e300 and Tmax > 1e300 then
          return string.format("%s#%s#inf", self.lua_prototype.name, Tmin)
        end
        if Tmin > -1e300 and Tmax < 1e300 then
          return string.format("%s#%s#%s", self.lua_prototype.name, Tmin, Tmax)
        end
      end
    end
    if self.lua_prototype.quality == nil or self.lua_prototype.quality == "normal" then
      return self.lua_prototype.name
    end
    return string.format("%s#%s", self.lua_prototype.name,self.lua_prototype.quality or "normal")
  end
  return "unknow"
end

-------------------------------------------------------------------------------
---Has Burnt Result
---@return boolean
function Product:hasBurntResult()
  if self.lua_prototype ~= nil then
    if self.lua_prototype.type == 0 or self.lua_prototype.type == "item" then
      local item = Player.getItemPrototype(self.lua_prototype.name)
      return item.burnt_result ~= nil
    end
  end
  return false
end

-------------------------------------------------------------------------------
---Clone prototype model
---@return table
function Product:clone()
  local prototype = {
    type = self.lua_prototype.type or "item",
    name = self.lua_prototype.name,
    quality = self.lua_prototype.quality,
    quality_probality = self.lua_prototype.quality_probality,
    amount = self:getElementAmount(),
    spoil = self.lua_prototype.spoil,
    state = self.lua_prototype.state,
    temperature = self.lua_prototype.temperature,
    minimum_temperature  = self.lua_prototype.minimum_temperature,
    maximum_temperature  = self.lua_prototype.maximum_temperature,
    burnt = self.lua_prototype.burnt,
    constant = self.lua_prototype.constant
  }
  if prototype.spoil ~= nil then
    prototype.spoil_percent = prototype.spoil * 100
  end
  return prototype
end

-------------------------------------------------------------------------------
---Get amount of element
---@see http://lua-api.factorio.com/latest/Concepts.html#Product
---@return number
function Product:getElementAmount()
  local element = self.lua_prototype
  if element == nil then return 0 end

  local amount = element.amount
  if amount ~= nil then
    ---In 0.17, it seems probability can be used with just 'amount' and it
    ---doesn't need to use amount_min/amount_max
    if element.probability ~= nil then
      amount = amount * element.probability
    end
  else
    if element.probability ~= nil and element.amount_min ~= nil and  element.amount_max ~= nil then
      amount = ((element.amount_min + element.amount_max) * element.probability / 2)
    end
  end

  if element.extra_count_fraction ~= nil then
    local extra_count_fraction = element.extra_count_fraction or 0
    amount = amount + extra_count_fraction
  end

  return amount or 0
end

-------------------------------------------------------------------------------
---Get amount of element for bonus
---@return number
function Product:getBonusAmount()
  local element = self.lua_prototype
  if element == nil then return 0 end

  local catalyst_amount = element.catalyst_amount or 0
  local probability = element.probability or 1
  local amount = 0
  ---If amount not specified, amount_min, amount_max and probability must all be specified.
  ---Minimal amount of the item or fluid to give. Has no effect when amount is specified.
  ---Maximum amount of the item or fluid to give. Has no effect when amount is specified.
  if element.probability ~= nil and element.amount_min ~= nil and  element.amount_max ~= nil then
    amount = (element.amount_min + element.amount_max) / 2
  end

  if element.amount ~= nil then
    amount = element.amount
  end
  if amount >= catalyst_amount then
    return (amount - catalyst_amount) * probability
  end
  return 0
end

-------------------------------------------------------------------------------
---Get type of element (item or fluid)
---@return string
function Product:getType()
  if self.lua_prototype.type == 1 or self.lua_prototype.type == "fluid" then return "fluid" end
  return "item"
end

-------------------------------------------------------------------------------
---Get amount of element
---@param recipe RecipeData
---@return number
function Product:getBaseAmount(recipe)
  local amount = self:getElementAmount()
  local bonus_amount = self:getBonusAmount() ---if there are no catalyst amount = bonus_amount
  if recipe == nil then
    return amount
  end
  local ignored = 0
  if self.lua_prototype.ignored_by_productivity then
    ignored = self.lua_prototype.ignored_by_productivity or 0
  end
  local amount_by_productivity = bonus_amount - ignored
  -- value can not be negative
  if amount_by_productivity > 0 then
    return amount  + (bonus_amount - ignored) * self:getProductivityBonus(recipe)
  end
  return amount
end

-------------------------------------------------------------------------------
---Get amount of element
---@param recipe RecipeData
---@return number
function Product:getAmount(recipe)
  local amount = self:getBaseAmount(recipe)
  local quality_probality = 1
  if self.lua_prototype.quality_probality ~= nil then
    quality_probality = self.lua_prototype.quality_probality
  end
  return amount * quality_probality
end

-------------------------------------------------------------------------------
---Count product
---@param recipe RecipeData
---@return number
function Product:countProduct(recipe)
  local amount = self:getAmount(recipe)
  return amount * (recipe.count or 0)
end

-------------------------------------------------------------------------------
---Count product
---@param recipe RecipeData
---@return number
function Product:countLimitProduct(recipe)
  local amount = self:getAmount(recipe)
  return amount * (recipe.count_limit or 0)
end

-------------------------------------------------------------------------------
---Count product
---@param recipe RecipeData
---@return number
function Product:countDeepProduct(recipe)
  local amount = self:getAmount(recipe)
  return amount * (recipe.count_deep or 0)
end

-------------------------------------------------------------------------------
---Get amount of element
---@param recipe RecipeData
---@return number
function Product:getDrainedAmount(recipe)
  local amount = self:getElementAmount()
  local drain = 1
  if recipe.type == "technology" and recipe.factory ~= nil then
    local machine = EntityPrototype(recipe.factory)
    -- science_pack_drain_rate_percent = percent value
    drain = machine:getSciencePackDrainRatePercent() / 100
  end
  return amount * drain
end
-------------------------------------------------------------------------------
---Count ingredient
---@param recipe RecipeData
---@return number
function Product:countIngredient(recipe)
  local amount = self:getDrainedAmount(recipe)
  return amount * (recipe.count or 0)
end

-------------------------------------------------------------------------------
---Count ingredient
---@param recipe RecipeData
---@return number
function Product:countLimitIngredient(recipe)
  local amount = self:getDrainedAmount(recipe)
  return amount * (recipe.count_limit or 0)
end

-------------------------------------------------------------------------------
---Count ingredient
---@param recipe RecipeData
---@return number
function Product:countDeepIngredient(recipe)
  local amount = self:getElementAmount()
  return amount * (recipe.count_deep or 0)
end

-------------------------------------------------------------------------------
---Count container
---@param count number
---@param container string
---@param time number
---@return number
function Product:countContainer(count, container, time)
  if count == nil then return 0 end
  if self.lua_prototype.type == 0 or self.lua_prototype.type == "item" then
    local entity_prototype = EntityPrototype(container)
    if entity_prototype:getType() == "inserter" then
      local inserter_capacity = entity_prototype:getInserterCapacity()
      local inserter_speed = entity_prototype:getInserterRotationSpeed()
      ---temps pour 360� t=360/360*inserter_speed
      local inserter_time = 1 / inserter_speed
      return count * inserter_time / (inserter_capacity * (time or 1))
    elseif entity_prototype:getType() == "transport-belt" then
      ---ratio = item_per_s / speed_belt (blue belt)
      local belt_speed = entity_prototype:getBeltSpeed()
      return count / (belt_speed * self.belt_ratio * (time or 1))
    elseif entity_prototype:getType() == "rocket-silo" then
      local item_prototype = ItemPrototype(self.lua_prototype.name)
      local rocket_capacity = math.floor(item_prototype:geRocketCapacity())
      if rocket_capacity < 1 then
        return 0
      end
      return count / rocket_capacity
    elseif entity_prototype:getType() ~= "logistic-robot" then
      local cargo_wagon_size = entity_prototype:getInventorySize(1)
      if cargo_wagon_size == nil then return 0 end
      if entity_prototype:getInventorySize(2) ~= nil and entity_prototype:getInventorySize(2) > entity_prototype:getInventorySize(1) then
        cargo_wagon_size = entity_prototype:getInventorySize(2)
      end
      local stack_size = ItemPrototype(self.lua_prototype.name):stackSize()
      if cargo_wagon_size * stack_size == 0 then return 0 end
      return count / (cargo_wagon_size * stack_size)
    else
      local cargo_wagon_size = entity_prototype:native().max_payload_size + (Player.getForce().worker_robots_storage_bonus or 0 )
      return count / cargo_wagon_size
    end
  end
  if self.lua_prototype.type == 1 or self.lua_prototype.type == "fluid" then
    local entity_prototype = EntityPrototype(container)
    if entity_prototype:getType() == "valve"  then
      local flow_rate = entity_prototype:getValveFlowRate()
      if flow_rate == nil or flow_rate == 0 then return 0 end
      return count / flow_rate
    elseif entity_prototype:getType() == "pump" or entity_prototype:getType() == "offshore-pump"  then
      local flow_rate = entity_prototype:getPumpingSpeed()
      if flow_rate == nil or flow_rate == 0 then return 0 end
      return count / flow_rate
    elseif entity_prototype:getType() == "pipe" then
      -- obsolete but that do no error for laster version, no need migration
      return 0
    else
      local cargo_wagon_size = EntityPrototype(container):getFluidCapacity()
      if cargo_wagon_size == 0 then return 0 end
      return count / cargo_wagon_size
    end
  end
end

-------------------------------------------------------------------------------
---Get the productivity bonus of the recipe
---@param recipe table
---@return number
function Product:getProductivityBonus(recipe)
  if recipe.time == nil or recipe.isluaobject or recipe.factory == nil or recipe.factory.effects == nil then return 0 end
  local productivity = recipe.factory.effects.productivity
  local capped_time = recipe.time / recipe.factory.speed
  local factory_speed = recipe.factory.speed_total or 1
  local adjusted_time = recipe.time / factory_speed
  local speed_adjustment = capped_time / adjusted_time
  productivity = productivity * speed_adjustment

  return productivity
end

-------------------------------------------------------------------------------
---@param other Product
---@return boolean
function Product:match(other)
  if other == nil then return false end
  return self.lua_prototype.name == other.name and self.lua_prototype.type == other.type and self.lua_prototype.quality == other.quality
end

-------------------------------------------------------------------------------
---Return spoil
---@return number|nil
function Product:getSpoil()
  if self.lua_prototype ~= nil then
    if self.lua_prototype.spoil then
      return self.lua_prototype.spoil
    end
    local item_prototype = ItemPrototype(self.lua_prototype)
    if item_prototype:getSpoilTicks() > 0 then
      self.lua_prototype.spoil = 1
      return self.lua_prototype.spoil
    end
  end
  return nil
end