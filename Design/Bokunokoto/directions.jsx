// Three brand directions for Bokunokoto.
// Shared design DNA:
//   Warm earth palette — cream paper, slate ink, terracotta, sage
//   Humanist sans typography (one face per direction)
//   Universal/culturally neutral with 僕のこと as the hero lockup
//
// Each direction tilts ONE accent into the lead role, and pairs it with a
// distinct symbol metaphor:
//   1. HELD — a cradled opening (slate-led)
//   2. BLOOM — overlapping petals (terracotta-led)
//   3. PAGE — a folded letter / journaled corner (sage-led)

// Warm earth palette — pushed toward peach / honey / cocoa for a kinder,
// friendlier feel. No cool tones; the deepest color is a warm brown, not a
// blue-slate. Every neutral leans peachy.
const PALETTE = {
  ink:        '#2A1B14',  // warm near-black for type
  cocoa:      '#4E2E22',  // deep warm brown — primary in D1 (replaces slate)
  coral:      '#DD6F4F',  // warm coral-clay — primary in D2
  honey:      '#E8A06E',  // warm honey / soft amber
  rose:       '#E5B5A4',  // soft warm rose
  moss:       '#94986A',  // warm olive-moss — primary in D3 (replaces sage)
  cream:      '#F8E3C8',  // peachy cream surface
  paper:      '#FDF3DF',  // warm off-white background
  mist:       '#E3D5BD',  // warm dim neutral
};

// --- Symbol marks -----------------------------------------------------------
// All marks are drawn in a 100×100 viewBox so they compose at any size.
// They use currentColor for the primary stroke/fill so the same component
// can paint correctly on either a light or dark background.

// D1 — HELD: two cupped strokes meeting at the bottom, like a pair of hands
// gently holding something between them. The two arcs read as two beings
// forming a shared space — friendship / care / relationship — with a small
// warm seed resting at the bottom of the cradle.
function MarkHeld({ size = 100, seedColor = PALETTE.coral, strokeColor = 'currentColor' }) {
  return (
    <svg viewBox="0 0 100 100" width={size} height={size} aria-hidden>
      {/* left hand — sweeps down-right to meet at the bottom-center */}
      <path
        d="M 20 30 Q 22 70 50 80"
        fill="none"
        stroke={strokeColor}
        strokeWidth="12"
        strokeLinecap="round"
      />
      {/* right hand — sweeps down-left to meet at the bottom-center */}
      <path
        d="M 80 30 Q 78 70 50 80"
        fill="none"
        stroke={strokeColor}
        strokeWidth="12"
        strokeLinecap="round"
      />
      {/* warm seed resting in the cradle */}
      <circle cx="50" cy="62" r="9" fill={seedColor} />
    </svg>
  );
}

// D2 — BLOOM: three softly overlapping petals (ovals rotated 120°) arranged
// around a shared centre. Conveys progressive disclosure — each layer adds
// without erasing the one beneath.
function MarkBloom({ size = 100, colors = [PALETTE.coral, PALETTE.honey, PALETTE.cocoa] }) {
  const [a, b, c] = colors;
  // ovals share centre (50,50); each rotated 60° apart. Rounder/fatter than
  // before for a warmer, more flower-like read.
  return (
    <svg viewBox="0 0 100 100" width={size} height={size} aria-hidden>
      <g style={{ mixBlendMode: 'multiply' }}>
        <ellipse cx="50" cy="50" rx="18" ry="32" fill={a} transform="rotate(0 50 50)" opacity="0.9" />
        <ellipse cx="50" cy="50" rx="18" ry="32" fill={b} transform="rotate(60 50 50)" opacity="0.9" />
        <ellipse cx="50" cy="50" rx="18" ry="32" fill={c} transform="rotate(120 50 50)" opacity="0.9" />
      </g>
    </svg>
  );
}

// D3 — PAGE: a folded letter. A rectangular page silhouette with the
// top-right corner folded in, revealing a small mark inside. Quiet, intimate.
function MarkPage({ size = 100, paperColor = PALETTE.paper, foldColor = PALETTE.cream, accentColor = PALETTE.coral, strokeColor = PALETTE.cocoa }) {
  return (
    <svg viewBox="0 0 100 100" width={size} height={size} aria-hidden>
      {/* page body — softer rounded corners */}
      <path
        d="M 22 22 Q 22 18 26 18 L 62 18 Q 64 18 65.5 19.5 L 80.5 34.5 Q 82 36 82 38 L 82 78 Q 82 82 78 82 L 26 82 Q 22 82 22 78 Z"
        fill={paperColor}
        stroke={strokeColor}
        strokeWidth="3"
        strokeLinejoin="round"
      />
      {/* folded corner — a triangular plane */}
      <path
        d="M 62 18 Q 64 18 65.5 19.5 L 80.5 34.5 Q 82 36 82 38 L 65 38 Q 62 38 62 35 Z"
        fill={foldColor}
        stroke={strokeColor}
        strokeWidth="3"
        strokeLinejoin="round"
      />
      {/* short hand-written lines inside */}
      <line x1="32" y1="54" x2="58" y2="54" stroke={strokeColor} strokeWidth="3" strokeLinecap="round" opacity="0.85" />
      <line x1="32" y1="64" x2="70" y2="64" stroke={strokeColor} strokeWidth="3" strokeLinecap="round" opacity="0.55" />
      {/* warm signature dot */}
      <circle cx="68" cy="73" r="4" fill={accentColor} />
    </svg>
  );
}

// --- Direction tokens -------------------------------------------------------

const DIRECTIONS = [
  {
    id: 'held',
    name: 'Held',
    tagline: 'Two hands, one held thing',
    description: 'A pair of soft strokes cupped together — friendship, care, a space made by another. Cocoa-led and grounded, with a coral seed at the center.',
    font: 'Manrope',
    fontWeights: { display: 600, body: 400, caption: 500 },
    primary: PALETTE.cocoa,
    accent: PALETTE.coral,
    onPrimary: PALETTE.paper,
    bg: PALETTE.cream,
    Mark: MarkHeld,
    // Icon composition: cream tile, cocoa mark, coral seed
    iconBg: PALETTE.cream,
    iconMarkColor: PALETTE.cocoa,
    iconSeedColor: PALETTE.coral,
    palette: [
      { name: 'Ink',     hex: PALETTE.ink,    role: 'Primary type' },
      { name: 'Cocoa',   hex: PALETTE.cocoa,  role: 'Brand · primary' },
      { name: 'Coral',   hex: PALETTE.coral,  role: 'Accent · signal' },
      { name: 'Honey',   hex: PALETTE.honey,  role: 'Warm support' },
      { name: 'Cream',   hex: PALETTE.cream,  role: 'Surface' },
      { name: 'Paper',   hex: PALETTE.paper,  role: 'Background' },
    ],
  },
  {
    id: 'bloom',
    name: 'Bloom',
    tagline: 'Layers, slowly unfolding',
    description: 'Progressive disclosure made visible — coral, honey and cocoa petals laid over each other, none erasing the one beneath. The warmest of the three.',
    font: 'DM Sans',
    fontWeights: { display: 600, body: 400, caption: 500 },
    primary: PALETTE.coral,
    accent: PALETTE.cocoa,
    onPrimary: PALETTE.paper,
    bg: PALETTE.paper,
    Mark: MarkBloom,
    iconBg: PALETTE.paper,
    iconMarkColor: null,  // bloom paints its own colors
    iconSeedColor: null,
    palette: [
      { name: 'Ink',     hex: PALETTE.ink,    role: 'Primary type' },
      { name: 'Coral',   hex: PALETTE.coral,  role: 'Brand · primary' },
      { name: 'Honey',   hex: PALETTE.honey,  role: 'Petal · light' },
      { name: 'Cocoa',   hex: PALETTE.cocoa,  role: 'Petal · deep' },
      { name: 'Rose',    hex: PALETTE.rose,   role: 'Soft accent' },
      { name: 'Paper',   hex: PALETTE.paper,  role: 'Surface' },
    ],
  },
  {
    id: 'page',
    name: 'Page',
    tagline: 'A letter, carefully shared',
    description: 'Each disclosure is a folded page passed to someone you trust. Editorial and intimate, warm cocoa ink on peachy paper, signed with coral.',
    font: 'Hanken Grotesk',
    fontWeights: { display: 600, body: 400, caption: 500 },
    primary: PALETTE.cocoa,
    accent: PALETTE.coral,
    onPrimary: PALETTE.paper,
    bg: PALETTE.paper,
    Mark: MarkPage,
    // Icon composition: cocoa tile, paper page, coral signature
    iconBg: PALETTE.cocoa,
    iconMarkColor: PALETTE.paper,
    iconSeedColor: PALETTE.coral,
    palette: [
      { name: 'Ink',     hex: PALETTE.ink,    role: 'Primary type' },
      { name: 'Cocoa',   hex: PALETTE.cocoa,  role: 'Brand · primary' },
      { name: 'Coral',   hex: PALETTE.coral,  role: 'Signature' },
      { name: 'Honey',   hex: PALETTE.honey,  role: 'Warm support' },
      { name: 'Paper',   hex: PALETTE.paper,  role: 'Page' },
      { name: 'Cream',   hex: PALETTE.cream,  role: 'Fold · surface' },
    ],
  },
];

Object.assign(window, { DIRECTIONS, PALETTE, MarkHeld, MarkBloom, MarkPage });
