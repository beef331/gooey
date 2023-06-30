import gooey, mathtypes
import std/sugar

type
  DropDownBase*[Base, Button; T: enum] = ref object of Base
    buttons*: array[T, Button]
    active*: T
    onChange*: proc(val: T)
    watchValue*: proc(): T
    margin*: float32
    opened*: bool

proc isOver*[Base, Button, T](dropDown: DropDownBase[Base, Button, T], pos: Vec2): bool =
  if dropDown.isVisible:
    for btn in dropDown.buttons:
      if btn.isOver(pos):
        return true


proc layout*[Base, Button, T](
  dropDown: DropDownBase[Base, Button, T],
  parent: Base,
  offset: Vec3,
  state: UiState
) =
  mixin layout
  Base(dropDown).layout(parent, offset, state)
  var offset = typeof(offset).init(0, 0, 0)

  let active = dropDown.active
  if dropDown.buttons[active] != nil:
    dropDown.buttons[active].layout(dropDown, offset, state)
    offset.y += dropDown.margin + dropDown.buttons[active].layoutSize.y

  for ind, btn in dropDown.buttons.mpairs:
    if btn != nil:
      if ind != dropdown.active:
        btn.layout(dropDown, offset, state)
        offset.y += dropDown.margin + btn.layoutSize.y
      if btn.clickCb == nil:
        capture ind, btn:
          btn.clickCb = proc() =
            if dropDown.onChange != nil and dropDown.active != ind:
                dropDown.onChange(ind)
            dropDown.opened = not dropDown.opened
            dropDown.active = ind


proc interact*[Base, Button, T](
  dropDown: DropDownBase[Base, Button, T],
  state: var UiState,
) =
  mixin interact
  if dropDown.watchValue != nil:
    dropDown.active = dropDown.watchValue()

  if dropDown.isVisible:
    if dropDown.opened:
      for btn in dropDown.buttons:
        btn.interact(state)
    else:
      if dropDown.buttons[dropDown.active] != nil:
        dropDown.buttons[dropDown.active].interact(state)

proc upload*[Base, Button, T](
  dropDown: DropDownBase[Base, Button, T],
  state: UiState,
  target: var auto
) =
  mixin upload
  if dropDown.isVisible:
    if dropDown.opened:
      for button in dropDown.buttons:
        if button != nil:
          button.upload(state, target)
    else:
      if dropDown.buttons[dropDown.active] != nil:
        dropDown.buttons[dropDown.active].upload(state, target)
