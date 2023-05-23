import gooey, mathtypes

type
  HorizontalLayoutBase*[Base, T] = ref object of Base
    children*: seq[T]
    margin*: float32
    rightToLeft*: bool

  VerticalLayoutBase*[Base, T] = ref object of Base
    children*: seq[T]
    margin*: float32
    bottomToTop: bool

  Horz[Base, T] = HorizontalLayoutBase[Base, T]
  Vert[Base, T] = VerticalLayoutBase[Base, T]


  Layout[Base, T] = Vert[Base, T] or Horz[Base, T]

proc usedSize*[Base, T](horz: Horz[Base, T]): Vec2 =
  result = typeof(horz.size).init(horz.margin * float32 horz.children.high, 0)
  for child in horz.children:
    let size = child.usedSize()
    result.x += size.x
    result.y = max(size.y, result.y)

proc layout*[Base, T](horz: Horz[Base, T], parent: Base, offset: Vec3, state: UiState) =
  horz.size = usedSize(horz)
  Base(horz).layout(parent, offset, state)
  var offset = typeof(offset).init(0, 0, 0)
  for child in horz.children:
    child.layout(horz, offset, state)
    offset.x += horz.margin + child.layoutSize.x

proc usedSize*[Base, T](vert: Vert[Base, T]): Vec2 =
  result = typeof(vert.size).init(0, vert.margin * float32 vert.children.high)
  result.y = vert.margin * float32 vert.children.high
  for child in vert.children:
    let size = child.usedSize()
    result.x = max(size.x, result.x)
    result.y += size.y

proc layout*[Base, T](vert: Vert[Base, T], parent: Base, offset: Vec3, state: UiState) =
  vert.size = usedSize(vert)
  Base(vert).layout(parent, offset, state)
  var offset = typeof(offset).init(0, 0, 0)
  for child in vert.children:
    child.layout(vert, offset, state)
    offset.y += vert.margin + child.layoutSize.y

proc interact*[Base, T](horz: HorizontalLayoutBase[Base, T], state: var UiState) =
  mixin interact
  for x in horz.children:
    interact(x, state)

proc interact*[Base, T](vert: VerticalLayoutBase[Base, T], state: var UiState) =
  mixin interact
  for x in vert.children:
    interact(x, state)

proc upload*[Base, T](horz: Layout[Base, T], state: UiState, target: var auto) =
  mixin upload
  for child in horz.children:
    upload(child, state, target)
