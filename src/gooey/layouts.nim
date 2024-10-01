import gooey, mathtypes, iteratorstuff

type
  HorizontalLayoutBase*[Base, T] = ref object of Base
    children*: seq[T]
    margin*: float32
    rightToLeft*: bool
    align*: AnchorDirection = center

  VerticalLayoutBase*[Base, T] = ref object of Base
    children*: seq[T]
    margin*: float32
    bottomToTop: bool
    align*: AnchorDirection = center

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
  if horz.isVisible:
    horz.size = usedSize(horz)
    Base(horz).layout(parent, offset, state)
    var offset = typeof(offset).init(0, 0, 0)
    if horz.rightToLeft:
      for child in horz.children.reversed:
        if child.isVisible:
          let oldOffset = offset.y
          case horz.align:
          of center:
            offset.y += (horz.size.y - usedSize(child).y) / 2
          of bottom:
            offset.y += (horz.size.y - usedSize(child).y)
          else:
            discard
          child.layout(horz, offset, state)
          offset.x += horz.margin * state.scaling + child.layoutSize.x
          offset.y = oldOffset
    else:
      for child in horz.children:
        if child.isVisible():
          let oldOffset = offset.y
          case horz.align:
          of center:
            offset.y += (horz.size.y - usedSize(child).y) / 2
          of bottom:
            offset.y += (horz.size.y - usedSize(child).y)
          else:
            discard
          child.layout(horz, offset, state)
          offset.x += horz.margin * state.scaling + child.layoutSize.x
          offset.y = oldOffset


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
  if vert.isVisible:
    vert.size = usedSize(vert)
    Base(vert).layout(parent, offset, state)
    var offset = typeof(offset).init(0, 0, 0)
    if vert.bottomToTop:
      for child in vert.children.reversed:
        if child.isVisible:
          let oldOffset = offset.x
          case vert.align:
          of center:
            offset.x += (vert.size.x - usedSize(child).x) / 2
          of right:
            offset.x += (vert.size.x - usedSize(child).x)
          else:
            discard
          child.layout(vert, offset, state)
          offset.y += vert.margin * state.scaling + child.layoutSize.y
          offset.x = oldOffset
    else:
      for child in vert.children:
        if child.isVisible:
          let oldOffset = offset.x
          case vert.align:
          of center:
            offset.x += (vert.size.x - usedSize(child).x) / 2
          of right:
            offset.x += (vert.size.x - usedSize(child).x)
          else:
            discard
          child.layout(vert, offset, state)
          offset.y += vert.margin * state.scaling + child.layoutSize.y
          offset.x = oldOffset

proc interact*[Base, T](layout: Layout[Base, T], state: var UiState) =
  mixin interact
  if layout.isVisible:
    for x in layout.children:
      interact(x, state)


proc upload*[Base, T](horz: Layout[Base, T], state: UiState, target: var auto) =
  mixin upload
  if horz.isVisible:
    for child in horz.children:
      upload(child, state, target)
