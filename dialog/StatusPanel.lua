-------------------------------------------------------------------------------
-- Class to build pin tab dialog
--
-- @module StatusPanel
-- @extends #Form
--

StatusPanel = newclass(Form)

-------------------------------------------------------------------------------
-- On initialization
--
-- @function [parent=#StatusPanel] onInit
--
function StatusPanel:onInit()
  self.panelCaption = ({"helmod_status-tab-panel.title"})
  self.parameterLast = string.format("%s_%s",self.classname,"last")
end

-------------------------------------------------------------------------------
-- On before event
--
-- @function [parent=#StatusPanel] onBeforeEvent
--
-- @param #LuaEvent event
--
-- @return #boolean if true the next call close dialog
--
function StatusPanel:onBeforeEvent(event)
  local close = true
  if User.getParameter(self.parameterLast) == nil or User.getParameter(self.parameterLast) then
    close = false
  end
  User.setParameter(self.parameterLast, event.item1)
  return close
end

-------------------------------------------------------------------------------
-- On close dialog
--
-- @function [parent=#StatusPanel] onClose
--
function StatusPanel:onClose()
  User.setParameter(self.parameterLast,nil)
end

-------------------------------------------------------------------------------
-- Get or create info panel
--
-- @function [parent=#StatusPanel] getInfoPanel
--
function StatusPanel:getInfoPanel()
  local flow_panel, content_panel, menu_panel = self:getPanel()
  if content_panel["info-panel"] ~= nil and content_panel["info-panel"].valid then
    return content_panel["info-panel"]["scroll-panel"]
  end
  local mainPanel = ElementGui.addGuiFrameV(content_panel, "info-panel", helmod_frame_style.panel)
  return ElementGui.addGuiScrollPane(mainPanel, "scroll-panel", helmod_scroll_style.pin_tab)
end

-------------------------------------------------------------------------------
-- Get or create header panel
--
-- @function [parent=#StatusPanel] getHeaderPanel
--
function StatusPanel:getHeaderPanel()
  local flow_panel, content_panel, menu_panel = self:getPanel()
  if content_panel["header"] ~= nil and content_panel["header"].valid then
    return content_panel["header"]
  end
  return ElementGui.addGuiFrameH(content_panel, "header", helmod_frame_style.panel)
end

-------------------------------------------------------------------------------
-- On open
--
-- @function [parent=#StatusPanel] onOpen
--
-- @param #LuaEvent event
--
function StatusPanel:onOpen(event)
  self:updateHeader(event)
  self:getInfoPanel()
end

-------------------------------------------------------------------------------
-- On update
--
-- @function [parent=#StatusPanel] onUpdate
--
-- @param #LuaEvent event
--
function StatusPanel:onUpdate(event)
  self:updateInfo(event)
end

-------------------------------------------------------------------------------
-- Update information
--
-- @function [parent=#StatusPanel] updateInfo
--
-- @param #LuaEvent event
--
function StatusPanel:updateHeader(event)
  Logging:debug(self.classname, "updateHeader()", event)
  local header_panel = self:getHeaderPanel()
  local model = Model.getModel()

  ElementGui.addGuiButton(header_panel, self.classname.."=CLOSE", nil, "helmod_button_icon_close_red", nil, ({"helmod_button.close"}))
  ElementGui.addGuiButton(header_panel, self.classname.."=UPDATE", nil, "helmod_button_icon_refresh", nil, ({"helmod_result-panel.refresh-button"}))

end

-------------------------------------------------------------------------------
-- Update information
--
-- @function [parent=#StatusPanel] updateInfo
--
-- @param #LuaEvent event
--
function StatusPanel:updateInfo(event)
  Logging:debug(self.classname, "updateInfo()", event)
  local info_panel = self:getInfoPanel()
  local model = Model.getModel()

  info_panel.clear()

  local column = 2

  local resultTable = ElementGui.addGuiTable(info_panel,"list-data",column, "helmod_table-odd")
  --self:addProductionBlockHeader(resultTable)
  local elements = {}
  
  table.insert(elements, {name = "locomotive", type = "entity", value = #Player.getForce().get_trains()})
  
  local entities = {"logistic-robot", "construction-robot", "straight-rail", "curved-rail", "electric-furnace",
                    "assembling-machine-3", "chemical-plant", "oil-refinery", "beacon", "lab", "electric-mining-drill",
                    "express-transport-belt", "express-underground-belt", "express-splitter"
                    , "medium-electric-pole", "big-electric-pole"}
  for _, element in pairs(entities) do
    table.insert(elements, {name = element, type = "entity", value = Player.getForce().get_entity_count(element)})
  end
  
  for _, element in pairs(elements) do
    self:addProductionBlockRow(resultTable, element)
  end
end

-------------------------------------------------------------------------------
-- Add header data tab
--
-- @function [parent=#StatusPanel] addProductionBlockHeader
--
-- @param #LuaGuiElement itable container for element
--
function StatusPanel:addProductionBlockHeader(itable)
  Logging:debug(self.classname, "addProductionBlockHeader()", itable)
end

-------------------------------------------------------------------------------
-- Add row data tab
--
-- @function [parent=#StatusPanel] addProductionBlockRow
--
-- @param #LuaGuiElement guiTable
-- @param #table element
--
function StatusPanel:addProductionBlockRow(guiTable, element)
  Logging:debug(self.classname, "addProductionBlockRow()", guiTable, element)
  ElementGui.addGuiButtonSprite(guiTable, "element_"..element.name.."=", element.type, element.name, element.name, Player.getLocalisedName(element))
  ElementGui.addGuiLabel(guiTable, "value_"..element.name, element.value)

end

-------------------------------------------------------------------------------
-- On event
--
-- @function [parent=#StatusPanel] onEvent
--
-- @param #LuaEvent event
--
function StatusPanel:onEvent(event)
  Logging:debug(self.classname, "onEvent()", event)
  local model = Model.getModel()
end
