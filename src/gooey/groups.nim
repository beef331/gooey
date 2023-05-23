import gooey, mathtypes
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
  result = typeof(horz.size).init(float32(tupleLen(T) - 1) * horz.margin, 0f)
  for field in horz.entries.fields:
    let size = usedSize(field)
    result.x += size.x
    result.y = max(size.y, result.y)

proc layout*[Base, T](horz: HorizontalGroupBase[Base, T], parent: Base, offset, screenSize: Vec3) =
  mixin layout
  horz.size = usedSize(horz)
  Base(horz).layout(Base parent, offset, screenSize)
  var offset = typeof(offset).init(0, 0, 0)
  for field in horz.entries.fields:
    field.layout(Base(horz), offset, screenSize)
    offset.x += horz.margin + field.size.x

proc usedSize*[Base, T](vert: VerticalGroupBase[Base, T]): Vec2 =
  mixin usedSize
  result = typeof(vert.size).init(0f, float32(tupleLen(T) - 1) * vert.margin)
  for field in vert.entries.fields:
    let size = usedSize(field)
    result.x = max(size.x, result.x)
    result.y += size.x

proc layout*[Base, T](vert: VerticalGroupBase[Base, T], parent: Base, offset, screenSize: Vec3) =
  mixin layout
  vert.size = usedSize(vert)
  Base(vert).layout(Base parent, offset, screenSize)
  var offset = typeof(offset).init(0, 0, 0)
  for field in vert.entries.fields:
    field.layout(Base(vert), offset, screenSize)
    offset.y += vert.margin + field.layoutSize.y

proc interact*[Base, T](group: Group[Base, T], state: var UiState) =
  mixin interact
  interact(group.entries, state)

proc upload*[Base, T](group: Group[Base, T], state: UiState, target: var auto) =
  mixin upload
  upload(group.entries, state, target)
