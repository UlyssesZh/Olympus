local ui = {}

ui.hovering = nil
ui.dragging = nil
ui.draggingCounter = 0

function ui.update()
    local root = ui.root
    
    root:update()
    root:layout()

    root:layoutLate()
    root:updateLate()

end


function ui.draw()
    local root = ui.root
    
    root:draw()
end


function ui.mousemoved(x, y, dx, dy, istouch)
    local ui = ui
    local root = ui.root
    if not root then
        return
    end

    local hoveringPrev = ui.hovering
    local hoveringNext = root:getChildAt(x, y)
    ui.hovering = hoveringNext
    
    if hoveringPrev ~= hoveringNext then
        if hoveringPrev then
            hoveringPrev:onEnter()
        end
        if hoveringNext then
            hoveringNext:onLeave()
        end
    end

    local dragging = ui.dragging
    if dragging then
        dragging:onDrag(x, y, dx, dy)
    end
end

function ui.mousepressed(x, y, button, istouch)
    local ui = ui
    local root = ui.root
    if not root then
        return
    end

    ui.draggingCounter = ui.draggingCounter + 1

    local hovering = root:getChildAt(x, y)
    if hovering then
        if ui.dragging == nil or ui.dragging == hovering then
            ui.dragging = hovering
            hovering:onPress(x, y, button, true)
        else
            hovering:onPress(x, y, button, false)
        end
    end
end

function ui.mousereleased(x, y, button, istouch)
    local ui = ui
    local root = ui.root
    if not root then
        return
    end

    ui.draggingCounter = ui.draggingCounter - 1

    local dragging = ui.dragging
    if dragging then
        if ui.draggingCounter == 0 then
            ui.dragging = nil
            dragging:onRelease(x, y, button, true)
            if dragging == root:getChildAt(x, y) then
                dragging:onClick(x, y, button)
            end
        else
            dragging:onRelease(x, y, button, true)
        end
    else
        local hovering = root:getChildAt(x, y)
        if hovering then
            hovering:onRelease(x, y, button, false)
        end
    end
end


return ui