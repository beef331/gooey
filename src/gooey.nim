import gooey/mathtypes

type
  InteractDirection* = enum
    horizontal, vertical

  AnchorDirection* = enum
    left, right, top, bottom, center

  UiFlag* = enum
    onlyVisual
    enabled
    hovered

  UiElement*[SizeVec: Vec2, PosVec: Vec3] = ref object of RootObj # refs allow closures to work
    size*, layoutSize*: SizeVec
    pos*, layoutPos*: PosVec
    flags*: set[UiFlag]
    anchor*: set[AnchorDirection]
    visible*: proc(): bool

  Element* = concept e
    e is UiElement[auto, auto]


  UiAction* = enum
    nothing
    overElement
    interacted
    inputing

  UiInputKind* = enum
    nothing
    textInput
    leftClick
    rightClick

  UiInput* = object
    isHeld*: bool
    case kind*: UiInputKind
    of textInput:
      str*: string
    of leftClick, rightClick, nothing:
      discard

  UiState* {.explain.} = concept s
    s.action is UiAction
    s.currentElement is UiElement[auto, auto]
    s.input is UiInput
    s.inputPos is Vec2
    s.screenSize is Vec2
    s.scaling is float32

proc onlyUiElems*(t: typedesc[tuple]): bool =
  var val: t
  for field in fields(val):
    when field is tuple:
      when not onlyUiElems(field):
        return false
    else:
      when field isnot UiElement[auto, auto]:
        return false
  true

type UiElements* = concept type Ui
  onlyUiElems(Ui)

template named*[S, P](ui: UiElement[S, P], name: untyped): untyped =
  ## Template to allow aliasing constructor for an ergonomic API
  let name = ui
  name


proc isVisible*[S, P](ui: UiElement[S, P]): bool = ui.visible.isNil or ui.visible()
proc isVisible*[T: Element](ui: T): bool = ui.visible.isNil or ui.visible()

proc isOver[S, P](ui: UiElement[S, P], pos: Vec2): bool =
  pos.x in ui.layoutPos.x .. ui.layoutSize.x + ui.layoutPos.x and
  pos.y in ui.layoutPos.y .. ui.layoutSize.y + ui.layoutPos.y and
  ui.isVisible()

proc usedSize*[T: Element](ui: T): auto = ui.size


proc layout*[S, P](ui: UiElement[S, P], parent: UiElement[S, P], offset: P,  uiState: UiState) =
  let
    screenSize = uiState.screenSize
    scaling = uiState.scaling
    offset =
      if parent != nil:
        parent.layoutPos + offset
      else:
        offset
    pos = P.init(ui.pos.x * scaling, ui.pos.y * scaling, ui.pos.z)

  ui.layoutSize = S.init(ui.size.x * scaling, ui.size.y * scaling)

  ui.layoutPos =
    if ui.anchor == {top, left}:
      P.init(pos.x + offset.x, pos.y + offset.y, 0)
    elif ui.anchor == {top}:
      P.init(screenSize.x / 2 - pos.x + offset.x - ui.layoutSize.x / 2, pos.y + offset.y, 0)
    elif ui.anchor == {top, right}:
      P.init(screenSize.x - pos.x + offset.x - ui.layoutSize.x, pos.y + offset.y, 0)
    elif ui.anchor == {right}:
      P.init(screenSize.x - pos.x + offset.x - ui.layoutSize.x, screenSize.y / 2 - pos.y + offset.y - ui.layoutSize.y / 2, 0)
    elif ui.anchor == {bottom, right}:
      P.init(screenSize.x - pos.x + offset.x - ui.layoutSize.x, screenSize.y - pos.y + offset.y - ui.layoutSize.y, 0)
    elif ui.anchor == {bottom}:
      P.init(screenSize.x / 2 - pos.x + offset.x - ui.layoutSize.x / 2, screenSize.y - pos.y + offset.y - ui.layoutSize.y, 0)
    elif ui.anchor == {bottom, left}:
      P.init(pos.x + offset.x, screenSize.y - pos.y + offset.y - ui.layoutSize.y, 0)
    elif ui.anchor == {left}:
      P.init(pos.x + offset.x, screenSize.y / 2 - pos.y + offset.y - ui.layoutSize.y / 2, 0)
    elif ui.anchor == {center}:
      P.init(screenSize.x / 2 - pos.x + offset.x - ui.layoutSize.x / 2, screenSize.y / 2 - pos.y + offset.y - ui.layoutSize.y / 2, 0)
    elif ui.anchor == {}:
      pos + offset
    else:
      raise (ref AssertionDefect)(msg: "Invalid anchor: " & $ui.anchor)

proc layout*[T: UiElements; Y: UiElement](ui: T, parent: Y, offset: Vec3, state: UiState) =
  mixin layout
  for field in ui.fields:
    layout(field, parent, offset, state)

proc layout*[T: UiElements](ui: T, offset: Vec3, state: UiState) =
  mixin layout
  for field in ui.fields:
    layout(field, default(typeof(field)), offset, state)

proc onEnter(ui: Element, state: var UiState) = discard
proc onClick(ui: Element, state: var UiState) = discard
proc onHover(ui: Element, state: var UiState) = discard
proc onExit(ui: Element, state: var UiState) = discard
proc onDrag(ui: Element, state: var UiState) = discard
proc onTextInput(ui: Element, state: var UiState) = discard

import std/macros

macro requiresConvToElement(code: typed): untyped =
  if not code[0].getImpl.params[1][^2].sameType(getType(Element)):
    result = newStmtList(code, newLit false)
  else:
    result = newLit true


proc interact*[T: Element](ui: T, state: var UiState) =
  mixin onClick, onEnter, onHover, onExit, interact, onDrag
  type Base = UiElement[typeof(ui.size), typeof(ui.pos)]
  if state.action == nothing:
    if isOver(Base ui, state.inputPos):
      if not requiresConvToElement onEnter(ui, state):
        state.action = overElement
        state.currentElement = ui
  if state.currentElement == typeof(state.currentElement)(ui):
    if isOver(Base ui, state.inputPos):
      if state.input.kind == leftClick:
        if state.input.isHeld:
          discard requiresConvToElement onDrag(ui, state)
        else:
          discard requiresConvToElement onClick(ui, state)
          reset state.input  # Consume it
      discard requiresConvToElement onHover(ui, state)
      if state.input.kind == textInput:
        discard requiresConvToElement onTextInput(ui, state)
    else:
      discard requiresConvToElement onExit(ui, state)
      state.action = nothing
      state.currentElement = nil

proc interact*[Ui: UiElements](ui: Ui, state: var UiState) =
  mixin interact
  for field in ui.fields:
    if field.isVisible:
      interact(field, state)

proc upload*[Ui: UiElements; T](ui: Ui, state: UiState, target: var T) =
  mixin upload
  for field in ui.fields:
    if field.isVisible:
      upload(field, state, target)
