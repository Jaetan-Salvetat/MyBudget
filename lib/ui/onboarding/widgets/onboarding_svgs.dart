class OnboardingSvgs {
  OnboardingSvgs._();

  static const String reste = '''
<svg width="260" height="260" viewBox="0 0 260 260" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="ob1" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="{{primary}}" stop-opacity="0.18" />
      <stop offset="100%" stop-color="{{secondary}}" stop-opacity="0.30" />
    </linearGradient>
  </defs>
  <circle cx="130" cy="130" r="118" fill="url(#ob1)" />
  <circle cx="130" cy="130" r="118" fill="none"
          stroke="{{income}}" stroke-width="6"
          stroke-dasharray="555 741" stroke-linecap="round"
          transform="rotate(-90 130 130)" />
  <circle cx="130" cy="130" r="118" fill="none"
          stroke="{{onSurface08}}" stroke-width="6"
          stroke-dasharray="186 741" stroke-dashoffset="-555"
          stroke-linecap="round"
          transform="rotate(-90 130 130)" />
</svg>
''';

  static const String lock = '''
<svg width="260" height="260" viewBox="0 0 260 260" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="lk1" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="{{primary}}" stop-opacity="0.16" />
      <stop offset="100%" stop-color="{{secondary}}" stop-opacity="0.28" />
    </linearGradient>
  </defs>
  <rect x="40" y="40" width="180" height="180" rx="40" fill="url(#lk1)"
        stroke="{{borderBright}}" stroke-width="1" />
</svg>
''';
}
