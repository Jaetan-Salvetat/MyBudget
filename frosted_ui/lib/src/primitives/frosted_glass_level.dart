enum FrostedGlassLevel { ultraThin, thin, regular, thick, ultraThick }

enum FrostedGlassTone { auto, light, dark }

enum FrostedGlassElevation { none, resting, floating, lifted }

enum FrostedGlassEdge {
  top,
  bottom,
  left,
  right;

  static const Set<FrostedGlassEdge> all = <FrostedGlassEdge>{
    top,
    bottom,
    left,
    right,
  };

  static const Set<FrostedGlassEdge> none = <FrostedGlassEdge>{};
}
