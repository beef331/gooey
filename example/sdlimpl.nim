import sdl2_nim/sdl
import gooey
import gooey/[buttons, groups, layouts, sliders]

type
  Vec2 = tuple[x, y: float32]
  Vec3 = tuple[x, y, z: float32]


proc init(_: typedesc[Vec2], x, y: float32): Vec2 = (x, y)
proc init(_: typedesc[Vec3], x, y, z: float32): Vec3 = (x, y, z)


proc `+`(a, b: Vec2): Vec2 = (a.x + b.x, a.y + b.y)
proc `+`(a, b: Vec3): Vec3 = (a.x + b.x, a.y + b.y, a.z + b.z)

type
  Color = tuple[r,g,b,a: uint8]
  Element = ref object of UiElement[Vec2, Vec3]
    color: Color = (255, 255, 255, 255)
    texture: Texture

  UiState = object
    action: UiAction
    currentElement: Element
    input: UiInput
    inputPos: Vec2

  RenderTarget = object
    renderer: Renderer

  Button = ref object of ButtonBase[Element]
    hoveredColor: Color

proc onEnter*(button: Button, uiState: var UiState) = discard

proc onClick*(button: Button, uiState: var UiState) = buttons.onClick(button, uiState)


type
  App = ref object
    window: Window
    renderer: Renderer
    isRunning: bool
    uiState: UiState
    leftPressed: bool
    leftHeld: bool


proc inputLoop(app: App) =
  var e: Event
  if app.leftPressed:
    app.uiState.input = UiInput(kind: leftClick, isHeld: true)
  while pollEvent(addr e) != 0:
    case e.kind:
    of MouseMotion:
      app.uiState.inputPos = (float32 e.motion.x, float32 e.motion.y)
    of MouseButtonDown:
      app.leftPressed = e.button.button == 1
      app.uiState.input = UiInput(kind: leftClick)
    of MouseButtonUp:
      if app.leftPressed and e.button.button == 1:
        app.leftPressed = false
    else: discard


proc upload(element: Element, state: UiState, target: var RenderTarget) =
  let
    rect = Rect(x: cint element.pos.x, y: cint element.pos.y, w: cint element.size.x, h: cint element.size.y)
    col = element.color

  if element.texture.isNil:
    discard target.renderer.setRenderDrawColor(col.r, col.g, col.b, col.a)
    discard target.renderer.renderFillRect(addr rect)
    target.renderer.renderPresent()
  else:
    discard

proc makeGui(app: App): auto =
  (
    Button(
      pos: Vec3.init(10, 10, 0),
      anchor: {top, left},
      size: Vec2.init(100, 50),
      clickCb: proc() = echo("Hello")
    ),
  )


proc main() =
  discard init(InitVideo)
  var app = App()
  app.window = createWindow("gooey", WindowPosUndefined, WindowPosUndefined, 1280, 720, WindowResizable)
  app.renderer = app.window.createRenderer(-1, RendererAccelerated)
  app.isRunning = true
  let gui = makeGui(app)
  gui.layout(Vec3.init(0, 0, 0), Vec3.init(1280, 720, 0))
  var target = RenderTarget(renderer: app.renderer)

  while app.isRunning:
    discard app.renderer.setRenderDrawColor(0, 0, 0, 255)
    discard app.renderer.renderClear()
    app.inputLoop()
    gui.interact(app.uiState)
    gui.upload(app.uiState, target)
    app.renderer.renderPresent()



main()
