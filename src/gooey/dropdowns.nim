import gooey, mathtypes
import std/sugar

type
  DropDownBase*[Base, Button; T: enum] = ref object of Base
    buttons*: array[T, Button]
    active*: T
    onChange*: proc(val: T)
    margin*: float32
    opened*: bool

proc setupCallbacks[Base, Button, T](dropDown: DropDownBase[Base, Button, T], old, newOne: T) =
  dropDown.buttons[old].clickCb = proc() =
    if dropDown.onChange != nil:
      dropDown.onChange(old)
    dropDown.setupCallbacks(dropDown.active, old)
    dropDown.opened = false
    dropDown.active = old
  dropDown.buttons[newOne].clickCb = proc() =
    dropDown.opened = not dropDown.opened


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

      if btn.clickCb.isNil:
        if ind != dropDown.active:
          capture ind, btn:
            btn.clickCb = proc() =
              if dropDown.onChange != nil:
                dropDown.onChange(ind)
              dropDown.setupCallbacks(dropDown.active, ind)
              dropDown.opened = false
              dropDown.active = ind
        else:
          btn.clickCb = proc() =
            dropDown.opened = not dropDown.opened


proc interact*[Base, Button, T](
  dropDown: DropDownBase[Base, Button, T],
  state: var UiState,
) =
  mixin interact
  if dropDown.opened:
    for btn in dropDown.buttons:
      btn.interact(state)
  else:
    dropDown.buttons[dropDown.active].interact(state)

proc upload*[Base, Button, T](
  dropDown: DropDownBase[Base, Button, T],
  state: UiState,
  target: var auto
) =
  mixin upload
  if dropDown.opened:
    for button in dropDown.buttons:
      if button != nil:
        button.upload(state, target)
  else:
    dropDown.buttons[dropDown.active].upload(state, target)
