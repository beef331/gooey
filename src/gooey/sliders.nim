import gooey, mathtypes

type
  Slideable = concept s, type S
    lerp(s, s, float32) is S

  HorizontalSliderBase*[Base, T] = ref object of Base
    value*: T
    rng*: Slice[T]
    watchValue*: proc(): T
    percentage*: float32
    onChange*: proc(a: T)

proc layout*[Base, T](slider: HorizontalSliderBase[Base, T], parent: Base, offset: Vec3, state: UiState) =
  mixin layout
  Base(slider).layout(parent, offset, state)
  if slider.watchValue != nil:
    slider.value = slider.watchValue()
  slider.percentage = slider.value.reverseLerp(slider.rng)

proc interact*[Base, T](slider: HorizontalSliderBase[Base, T], state: var UiState) =
  mixin reverselerp
  gooey.interact(slider, state)

proc onEnter*[Base, T](slider: HorizontalSliderBase[Base, T], uiState: var UiState) = discard

proc onDrag*[Base, T](slider: HorizontalSliderBase[Base, T], uiState: var UiState) =
  mixin lerp
  slider.percentage = uiState.inputPos.x - slider.layoutPos.x
  slider.percentage = (slider.percentage / slider.layoutSize.x)
  let newVal = lerp(slider.rng.a, slider.rng.b, slider.percentage)
  if slider.value != newVal:
    slider.value = newVal
    slider.percentage = slider.value.reverseLerp(slider.rng)
    if slider.onChange != nil:
      slider.onChange(slider.value)
