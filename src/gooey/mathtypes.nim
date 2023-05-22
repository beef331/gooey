type
  Vec3* = concept vec, type V
    vec.x is float32
    vec.y is float32
    vec.z is float32
    not compiles(vec.w)
    V.init(float32, float32, float32)
    vec + vec is V

  Vec2* = concept vec, type V
    vec.x is float32
    vec.y is float32
    not compiles(vec.z)
    V.init(float32, float32)
    vec + vec is V
