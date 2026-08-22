## 0.4.0

* `FrostedListTile` takes a `variant`: `plain` drops the `surfaceContainer`
  block for rows that sit on a surface their parent already draws (a taxonomy
  tree, a picker sheet). Selection and state layers still show; `filled` stays
  the default.
* Fix taps on an interactive child inside an interactive surface — a trailing
  icon button in a `FrostedListTile`, say — being swallowed by the parent. The
  surface now handles its tap under the content instead of through an ink layer
  stacked above it; the press still reads through the state layer and the shape
  morph.
* `FrostedBottomSheet` caps its height at the viewport instead of overflowing
  when its content is taller.
* `FrostedChip.filter` accepts an `avatar`, shown until the selection check
  replaces it.

## 0.3.0

* Add `FrostedExpandableFab` and `FrostedFabAction` — a FAB that fans secondary
  actions out above itself over a glass scrim, driveable through
  `FrostedExpandableFabState`.
* Export `FrostedMenuPanel` and `FrostedMenuEntry`.
* Add `destructive` to every `FrostedButton` variant, swapping the primary role
  for the error role.
* Add `radius` to `FrostedCard` and `FrostedRadius.stepDown`, so a nested card
  stays concentric with its container.
* Add `FrostedIconButtonSize` (small, medium, large) to `FrostedIconButton`.
* Add `title` to `FrostedBottomSheet`.
* Add `autofocus` to `FrostedTextField`.

