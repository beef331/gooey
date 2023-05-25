import gooey, mathtypes, iteratorstuff

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
  mixin usedSize
  result = typeof(horz.size).init(0, 0)
  var added = false
  for i, child in horz.children:
    if child.isVisible():
      added = true
      let size = child.usedSize()
      result.x += size.x + horz.margin
      result.y = max(size.y, result.y)
  if added:
    result.x -= horz.margin

proc layout*[Base, T](horz: Horz[Base, T], parent: Base, offset: Vec3, state: UiState) =
  mixin layout
  horz.size = usedSize(horz)
  Base(horz).layout(parent, offset, state)
  var offset = typeof(offset).init(0, 0, 0)
  if horz.rightToLeft:
    for child in horz.children.reversed:
      if child.isVisible:
        child.layout(horz, offset, state)
        offset.x += horz.margin * state.scaling + child.layoutSize.x
  else:
    for child in horz.children:
      if child.isVisible():
        child.layout(horz, offset, state)
        offset.x += horz.margin * state.scaling + child.layoutSize.x

proc usedSize*[Base, T](vert: Vert[Base, T]): Vec2 =
  mixin usedSize
  result = typeof(vert.size).init(0, 0f)
  var added = false
  for child in vert.children:
    if child.isVisible():
      added = true
      let size = child.usedSize()
      result.x = max(size.x, result.x)
      result.y += size.y + vert.margin
  result.y -= vert.margin

proc layout*[Base, T](vert: Vert[Base, T], parent: Base, offset: Vec3, state: UiState) =
  mixin layout
  vert.size = usedSize(vert)
  Base(vert).layout(parent, offset, state)
  var offset = typeof(offset).init(0, 0, 0)
  if vert.bottomToTop:
     for child in vert.children.reversed:
      if child.isVisible:
        child.layout(vert, offset, state)
        offset.y += vert.margin * state.scaling + child.layoutSize.y
  else:
    for child in vert.children:
      if child.isVisible:
        child.layout(vert, offset, state)
        offset.y += vert.margin * state.scaling + child.layoutSize.y

proc interact*[Base, T](layout: Layout[Base, T], state: var UiState) =
  mixin interact
  for x in layout.children:
    interact(x, state)


proc upload*[Base, T](horz: Layout[Base, T], state: UiState, target: var auto) =
  mixin upload
  for child in horz.children:
    upload(child, state, target)
