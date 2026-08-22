/// How much matter the glass carries.
///
/// Drives backdrop blur strength and how much of the underlying content
/// reads through.
///
/// - [ultraThin]: barely there. Use for badges, dynamic-island-style chips.
/// - [thin]: lightweight chrome. Use for slim tab bars or floating pills.
/// - [regular]: default. Use for tab bars, top app bars, side toolbars.
/// - [thick]: chrome that must stay legible. Use for bottom sheets and
///   sticky headers under busy content.
/// - [ultraThick]: maximum readability. Use for dialogs that must read on
///   any background.
enum FrostedGlassLevel { ultraThin, thin, regular, thick, ultraThick }

/// How the glass tints itself.
///
/// - [auto]: follows the ambient [Brightness] — dark veil in dark themes,
///   light veil in light themes.
/// - [light]: forces a white-ish veil regardless of theme.
/// - [dark]: forces a dark veil regardless of theme. Useful for chrome
///   floating above photographic content.
enum FrostedGlassTone { auto, light, dark }

/// How the glass sits in space.
///
/// - [none]: no shadow. Use when the glass is attached to an edge or to
///   another element.
/// - [floating]: soft ambient grounding. Default for free-standing chrome.
/// - [lifted]: stronger shadow. Use for modals or sheets that hover above
///   a dimmed scrim.
enum FrostedGlassElevation { none, floating, lifted }

/// Which sides of the glass carry the hairline border.
///
/// A surface flush against a screen edge must leave that side out: the
/// hairline would sit on the device border and read as a bright halo rather
/// than as the lip of the material.
///
/// Flutter cannot stroke a non-uniform border under a rounded radius, so any
/// subset other than [all] or [none] requires [BorderRadius.zero].
enum FrostedGlassEdge {
  top,
  bottom,
  left,
  right;

  /// Every side. The default, for free-standing glass.
  static const Set<FrostedGlassEdge> all = <FrostedGlassEdge>{
    top,
    bottom,
    left,
    right,
  };

  /// No side at all, for glass that covers the whole viewport.
  static const Set<FrostedGlassEdge> none = <FrostedGlassEdge>{};
}
