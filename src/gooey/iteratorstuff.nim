import std/[macros, genasts]

iterator reversed*[T](oa: openArray[T]): T =
  for i in countDown(oa.high, 0):
    yield oa[i]

macro applyItBackwards*(tup: tuple, body: untyped): untyped =
  let typ = tup.getTypeImpl()
  result = newStmtList()
  for i, _ in typ:
    result.insert 0:
      genast(tup, i, body):
        if true:
          let it{.inject.} = tup[i]
          body
