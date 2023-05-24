import gooey, mathtypes, iteratorstuff
import std/typetraits

type
  HorizontalGroupBase*[Base, T] = ref object of Base
    entries*: T
    margin*: float32
    rightToLeft*: bool

  VerticalGroupBase*[Base, T] = ref object of Base
    entries*: T
    margin*: float32
    bottomToTop*: bool

  Group[Base, T] = VerticalGroupBase[Base, T] or HorizontalGroupBase[Base, T]

proc usedSize*[Base, T](horz: HorizontalGroupBase[Base, T]): Vec2 =
  mixin usedSize
  result = typeof(horz.size).init(0f, 0f)
  for field in horz.entries.fields:
    if field.isVisible:
      let size = usedSize(field)
      result.x += size.x + horz.margin
      result.y = max(size.y, result.y)

proc layout*[Base, T](horz: HorizontalGroupBase[Base, T], parent: Base, offset: Vec3, state: UiState) =
  mixin layout
  horz.size = usedSize(horz)
  Base(horz).layout(Base parent, offset, state)
  var offset = typeof(offset).init(0, 0, 0)
  if horz.rightToLeft:
    applyItBackwards(horz.entries):
      if it.isVisible:
        it.layout(Base(horz), offset, state)
        offset.x += horz.margin * state.scaling + it.layoutSize.x
  else:
    for field in horz.entries.fields:
      if field.isVisible:
        field.layout(Base(horz), offset, state)
        offset.x += horz.margin * state.scaling + field.layoutSize.x

proc usedSize*[Base, T](vert: VerticalGroupBase[Base, T]): Vec2 =
  mixin usedSize
  result = typeof(vert.size).init(0f, 0f)
  result.y = (tupleLen(T) - 1) * vert.margin
  for field in vert.entries.fields:
    let size = usedSize(field)
    result.x = max(size.x, result.x)
    result.y += size.y + vert.margin

proc layout*[Base, T](vert: VerticalGroupBase[Base, T], parent: Base, offset: Vec3, state: UiState) =
  mixin layout
  vert.size = usedSize(vert)
  Base(vert).layout(Base parent, offset, state)
  var offset = typeof(offset).init(0, 0, 0)
  if vert.bottomToTop:
    applyItBackwards(vert.entries):
      if it.isVisible:
        it.layout(Base(vert), offset, state)
        offset.y += vert.margin * state.scaling + it.layoutSize.y
  else:
    for field in vert.entries.fields:
      if field.isVisible:
        field.layout(Base(vert), offset, state)
        offset.y += vert.margin * state.scaling + field.layoutSize.y

proc interact*[Base, T](group: Group[Base, T], state: var UiState) =
  mixin interact
  interact(group.entries, state)

proc upload*[Base, T](group: Group[Base, T], state: UiState, target: var auto) =
  mixin upload
  upload(group.entries, state, target)
