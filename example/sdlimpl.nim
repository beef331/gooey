import sdl2_nim/sdl, gooey
import pixie except Rect
import gooey/[buttons, groups, layouts, sliders, dropdowns]
import std/[tables, sugar, strutils]

type
  Vec2 = tuple[x, y: float32]
  Vec3 = tuple[x, y, z: float32]


proc init(_: typedesc[Vec2], x, y: float32): Vec2 = (x, y)
proc init(_: typedesc[Vec3], x, y, z: float32): Vec3 = (x, y, z)


proc `+`(a, b: Vec2): Vec2 = (a.x + b.x, a.y + b.y)
proc `+`(a, b: Vec3): Vec3 = (a.x + b.x, a.y + b.y, a.z + b.z)

proc reverseLerp(a: float32, slice: Slice[float32]): float32 = clamp((a - slice.a) / (slice.a - slice.b), 0, 1)

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
    scaling: float32
    screenSize: Vec2

  RenderTarget = object
    renderer: Renderer

  Label = ref object of Element
    text: string

  Button = ref object of ButtonBase[Element]
    baseColor: Color
    hoveredColor: Color = (127, 127, 127, 255)
    label: Label

  Slider[T] = ref object of HorizontalSliderBase[Element, T]
    slideBar: Element

  HGroup[T] = ref object of HorizontalGroupBase[Element, T]
  VGroup[T] = ref object of VerticalGroupBase[Element, T]

  HLayout[T] = ref object of HorizontalLayoutBase[Element, T]
  VLayout[T] = ref object of VerticalLayoutBase[Element, T]

  Layouts[T] = HLayout[T] or VLayout[T]

  Groups[T] = HGroup[T] or VGroup[T]

  DropDown[T] = ref object of DropDownBase[Element, Button, T]


  FontProps = object
    size: Vec2
    text: string

  App = ref object
    window: Window
    renderer: Renderer
    isRunning: bool
    uiState: UiState
    leftPressed: bool
    leftHeld: bool


var
  fontTextureCache: Table[FontProps, Texture]
  refCount: Table[Texture, int]
  defaultFont = readFont"./example/SimplySans-Bold.ttf"

proc makeTexture(s: string, size: Vec2, renderer: Renderer): Texture =
  let props = FontProps(size: size, text: s)
  if props in fontTextureCache:
    fontTextureCache[props]
  else:
    var
      tex = renderer.createTexture(PIXELFORMAT_RGBA32, TEXTUREACCESS_STREAMING, cint size.x, cint size.y)
      image = newImage(int size.x, int size.y)
      font = defaultFont
    assert tex != nil
    font.size = size.y
    var layout = font.layoutBounds(s)
    while layout.x + 1 >= size.x or layout.y + 1 >= size.y:
      font.size -= 1
      layout = font.layoutBounds(s)

    font.paint = rgb(255, 255, 255)
    image.fillText(font, s, bounds = vec2(size.x, size.y), hAlign = CenterAlign, vAlign = MiddleAlign)
    var
      pitch: cint
      pixels: ptr UncheckedArray[ColorRGBX]

    discard tex.lockTexture(nil, cast[ptr pointer](pixels.addr), pitch.addr)
    copyMem(pixels, image.data[0].addr, image.data.len * 4)
    discard tex.setTextureBlendMode(BlendModeBlend)
    tex.unlockTexture()
    fontTextureCache[props] = tex
    refCount[tex] = 0
    tex

proc upload(element: Element, state: UiState, target: var RenderTarget) =
  if element.isVisible:
    let
      rect = Rect(x: cint element.layoutPos.x, y: cint element.layoutPos.y, w: cint element.layoutSize.x, h: cint element.layoutSize.y)
      col = element.color

    if element.texture.isNil:
      discard target.renderer.setRenderDrawColor(col.r, col.g, col.b, col.a)
      discard target.renderer.renderFillRect(addr rect)
    else:
      discard element.texture.setTextureColorMod(col.r, col.g, col.b)
      discard target.renderer.renderCopy(element.texture, nil, addr rect)

proc upload(label: Label, state: UiState, target: var RenderTarget) =
  if 0 notin [label.layoutSize.x, label.layoutSize.y]:
    let orig = label.texture
    label.texture = makeTexture(label.text, label.layoutSize, target.renderer)
    if label.texture != orig:
      if orig != nil:
        dec refCount[orig]
        if refCount[orig] <= 0:
          refCount.del(orig)
          for x, y in fontTextureCache:
            if y == orig:
              fontTextureCache.del(x)
              break
          orig.destroyTexture()
      inc refCount[label.texture]

  Element(label).upload(state, target)

# Button
proc upload(button: Button, state: UiState, target: var RenderTarget) =
  Element(button).upload(state, target)
  if button.label != nil:
    button.label.upload(state, target)

proc layout(button: Button, parent: Element, offset: Vec3, state: UiState) =
  buttons.layout(button, parent, offset, state)
  if button.label != nil:
    button.label.size = button.size
    button.label.layout(button, (0f, 0f, 0f), state)

proc onEnter(button: Button, uiState: var UiState) =
  button.flags.incl {hovered}
  button.baseColor = button.color
  button.color = button.hoveredColor

proc onExit(button: Button, uiState: var UiState) =
  button.color = button.baseColor

proc onClick(button: Button, uiState: var UiState) = buttons.onClick(button, uiState)

# Slider

proc upload[T](slider: Slider[T], state: UiState, target: var RenderTarget) =
  Element(slider).upload(state, target)
  let slideSize = Vec2.init(slider.percentage * slider.layoutSize.x, slider.layoutSize.y)
  if slider.slideBar.isNil:
    slider.slideBar = Element(color: (255, 0, 0, 255))
  slider.slideBar.layoutSize = slideSize

  Element(slider.slideBar).upload(state, target)

proc layout[T](slider: Slider[T], parent: Element, offset: Vec3, state: UiState) =
  sliders.layout(slider, parent, offset, state)
  let slideSize = Vec2.init(slider.percentage * slider.layoutSize.x, slider.layoutSize.y)
  if slider.slideBar.isNil:
    slider.slideBar = Element(color: (255, 0, 0, 255))
  slider.slideBar.layout(Element(slider), Vec3.init(0, 0, 0), state)

proc onEnter(slider: Slider, uiState: var UiState) =
  slider.flags.incl {hovered}

proc onDrag(slider: Slider, uiState: var UiState) = sliders.onDrag(slider, uiState)

proc onExit(slider: Slider, uiState: var UiState) = slider.flags.excl {hovered}


# DropDowns

proc upload(dropDown: DropDown, state: UiState, target: var RenderTarget) =
  dropdowns.upload(dropDown, state, target)

proc layout[T](dropDown: DropDown[T], parent: Element, offset: Vec3, state: UiState) =
  if dropDown.buttons[T.low].isNil:
    for ind, button in dropDown.buttons.mpairs:
      button = Button(hoveredColor: (127, 127, 127, 255), size: dropDown.size, label: Label(text: $ind, color: (255, 0, 0, 255)))
  dropdowns.layout(dropDown, parent, offset, state)

proc interact(dropDown: DropDown, state: var UiState) =
  dropdowns.interact(dropDown, state)


# Groups

proc interact[T](group: Groups[T], uiState: var UiState) =
  groups.interact(group, uiState)

proc layout[T](group: Groups[T], parent: Element, offset: Vec3, state: UiState) =
  groups.layout(group, parent, offset, state)

proc upload[T](group: Groups[T], state: UiState, target: var RenderTarget) =
  groups.upload(group, state, target)

# Layouts

proc interact[T](layout: Layouts[T], uiState: var UiState) =
  layouts.interact(layout, uiState)

proc layout[T](layout: Layouts[T], parent: Element, offset: Vec3, state: UiState) =
  layouts.layout(layout, parent, offset, state)

proc upload[T](layout: Layouts[T], state: UiState, target: var RenderTarget) =
  layouts.upload(layout, state, target)

# Usage

proc inputLoop(app: App) =
  var e: Event
  if app.leftPressed:
    app.leftPressed = false
    app.leftHeld = true
  while pollEvent(addr e) != 0:
    case e.kind
    of MouseMotion:
      app.uiState.inputPos = (float32 e.motion.x, float32 e.motion.y)
    of MouseButtonDown:
      app.leftPressed = e.button.button == 1
    of MouseButtonUp:
      if e.button.button == 1:
        app.leftPressed = false
        app.leftHeld = false
    of WindowEvent:
      case e.window.event.WindowEventID
      of WindowEventSizeChanged, WindowEventResized:
        let
          x = float32 e.window.data1
          y = float32(9 / 16 * x)
        app.uiState.screenSize = (x, y)
        app.window.setWindowSize(cint x, cint y)
        app.uiState.scaling = x / 1280

      else:
        discard

    else: discard

type Colors = enum
  Red
  Green
  Blue
  Yellow
  Orange
  Purple

proc makeGui(app: App): auto =
  let grid = VLayout[HLayout[Button]](pos: Vec3.init(100, 100, 0), anchor: {top, left}, margin: 5)
  for y in 0..2:
    let horz = HLayout[Button](margin: 5)
    for x in 0..2:
      capture x, y:
        horz.children.add Button(
          label: Label(
            color: (0, 0, 0, 255),
            text: "$#,$#" % [$x, $y]
            ),
          size: Vec2.init(40, 40),
          clickCb: (proc() = echo x, " ", y)
        )
    grid.children.add horz

  let
    myLabel = Label(
      color: (0, 255, 127, 255),
      text: "Huh",
      anchor: {bottom, right},
      size: Vec2.init(100, 50)
    )

    slider = Slider[float32](
      rng: 1f..5f,
      pos: (10, 10, 0),
      size: (100, 30),
      color: (123, 155, 200, 255),
      slideBar: Element(color: (62, 88, 170, 255)),
      anchor: {bottom, left},
      onChange: proc(f: float32) =
        myLabel.size.y = f * 50
        myLabel.size.x = f * 100
    )

  (
    Button(
      pos: Vec3.init(10, 10, 0),
      anchor: {top, left},
      size: Vec2.init(100, 50),
      clickCb: proc() = echo("Hello"),
      label: Label(text: "Hello", color: (0, 0, 0, 255))
    ),
    Label(text: "Hmmm", anchor: {bottom, right}, size: Vec2.init(300, 200)),
    myLabel,
    slider,
    HGroup[(Label, Button)](
      pos: (10, 10, 0),
      anchor: {top, right},
      entries: (
        Label(text: "Test:", size: (100, 50)),
        Button(
          size: (100, 50),
          color: (99, 64, 99, 255),
          hoveredColor: (188, 124, 188, 255),
          label: Label(text: "Really!", color: (0, 35, 127, 255)))
        )
    ),
    HGroup[(Label, Button)](
      pos: (10, 80, 0),
      anchor: {top, right},
      rightToLeft: true,
      entries: (
        Label(text: "Test:", size: (100, 50)),
        Button(
          size: (100, 50),
          color: (99, 64, 99, 255),
          hoveredColor: (188, 124, 188, 255),
          label: Label(text: "Really!", color: (0, 35, 127, 255)))
        )
    ),
    VGroup[(Label, Label)](
      pos: (0, 10, 0),
      anchor: {bottom},
      entries: (
        Label(text: "Hmm:", size: (100, 50)),
        Label(text: "Yes!", size: (100, 50)),
      )
    ),
    VGroup[(Label, Label)](
      pos: (0, 100, 0),
      anchor: {bottom},
      bottomToTop: true,
      entries: (
        Label(text: "Hmm:", size: (100, 50)),
        Label(text: "Yes!", size: (100, 50)),
      )
    ),
    Label(
      anchor: {left},
      color: (0, 255, 0, 255),
      text: "Eh?!",
      size: (100, 50)
    ),
    Label(
      anchor: {right},
      color: (255, 0, 0, 255),
      text: "Eh?!",
      size: (100, 50)
    ),
    Label(
      anchor: {top},
      color: (255, 0, 255, 255),
      text: "Eh?!",
      size: (100, 50)
    ),
    Label(
      anchor: {center},
      color: (127, 255, 255, 255),
      text: "Eh?!",
      size: (100, 50)
    ),
    DropDown[Colors](
      pos: Vec3.init(0, 50, 0),
      margin: 5,
      size: Vec2.init(200, 50),
      anchor: {top},
      onChange: (proc(c: Colors) = echo c),
      visible: proc(): bool = slider.value > 3.3f
    ),
    grid

  )

proc main() =
  discard init(InitVideo)
  var app = App()
  app.window = createWindow("gooey", WindowPosUndefined, WindowPosUndefined, 1280, 720, WindowResizable)
  app.renderer = app.window.createRenderer(-1, RendererAccelerated)
  app.uiState.screenSize = (1280f, 720f)
  discard app.renderer.setRenderDrawBlendMode(BLENDMODE_NONE)
  app.isRunning = true
  let gui = makeGui(app)
  var target = RenderTarget(renderer: app.renderer)

  while app.isRunning:
    discard app.renderer.setRenderDrawColor(0, 0, 0, 255)
    discard app.renderer.renderClear()
    app.inputLoop()
    if app.leftPressed:
      app.uiState.input = UiInput(kind: leftClick)
    elif app.leftHeld:
      app.uiState.input = UiInput(kind: leftClick, isHeld: true)
    else:
      reset app.uiState.input

    gui.interact(app.uiState)
    gui.layout(Vec3.init(0, 0, 0), app.uiState)
    gui.upload(app.uiState, target)
    app.renderer.renderPresent()

main()
