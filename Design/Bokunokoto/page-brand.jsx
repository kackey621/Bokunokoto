// Bokunokoto — Page direction · Brand sheet
// Single-page brand book showing the chosen direction in depth:
// hero, mark anatomy, app icon system, wordmark lockups, palette, type,
// and two in-context phone mocks.

const { useState } = React;

// ─────────────────────────────────────────────────────────────
// Tokens (mirrored from directions.jsx so this sheet stands alone)
// ─────────────────────────────────────────────────────────────
const P = {
  ink:   '#2A1B14',
  cocoa: '#4E2E22',
  coral: '#DD6F4F',
  honey: '#E8A06E',
  rose:  '#E5B5A4',
  cream: '#F8E3C8',
  paper: '#FDF3DF',
  mist:  '#E3D5BD',
};

const JP = "'Noto Serif JP', 'Hiragino Mincho ProN', serif";
const SANS = "'Hanken Grotesk', system-ui, -apple-system, sans-serif";

// ─────────────────────────────────────────────────────────────
// Mark — Page (folded letter). Imported here as a self-contained
// component so this file works standalone.
// ─────────────────────────────────────────────────────────────
function Mark({ size = 100, paperColor = P.paper, foldColor = P.cream, accentColor = P.coral, strokeColor = P.cocoa, withText = true, strokeWidth = 3 }) {
  return (
    <svg viewBox="0 0 100 100" width={size} height={size} aria-hidden style={{ display: 'block' }}>
      <path
        d="M 22 22 Q 22 18 26 18 L 62 18 Q 64 18 65.5 19.5 L 80.5 34.5 Q 82 36 82 38 L 82 78 Q 82 82 78 82 L 26 82 Q 22 82 22 78 Z"
        fill={paperColor} stroke={strokeColor} strokeWidth={strokeWidth} strokeLinejoin="round"
      />
      <path
        d="M 62 18 Q 64 18 65.5 19.5 L 80.5 34.5 Q 82 36 82 38 L 65 38 Q 62 38 62 35 Z"
        fill={foldColor} stroke={strokeColor} strokeWidth={strokeWidth} strokeLinejoin="round"
      />
      {withText && (
        <>
          <line x1="32" y1="54" x2="58" y2="54" stroke={strokeColor} strokeWidth={strokeWidth} strokeLinecap="round" opacity="0.85" />
          <line x1="32" y1="64" x2="70" y2="64" stroke={strokeColor} strokeWidth={strokeWidth} strokeLinecap="round" opacity="0.55" />
        </>
      )}
      <circle cx="68" cy="73" r="4" fill={accentColor} />
    </svg>
  );
}

// Minimal variant — no text lines, no signature. For very small sizes.
function MarkMini({ size = 32, paperColor = P.paper, foldColor = P.cream, strokeColor = P.cocoa, strokeWidth = 5 }) {
  return (
    <svg viewBox="0 0 100 100" width={size} height={size} aria-hidden style={{ display: 'block' }}>
      <path
        d="M 22 22 Q 22 18 26 18 L 62 18 Q 64 18 65.5 19.5 L 80.5 34.5 Q 82 36 82 38 L 82 78 Q 82 82 78 82 L 26 82 Q 22 82 22 78 Z"
        fill={paperColor} stroke={strokeColor} strokeWidth={strokeWidth} strokeLinejoin="round"
      />
      <path
        d="M 62 18 Q 64 18 65.5 19.5 L 80.5 34.5 Q 82 36 82 38 L 65 38 Q 62 38 62 35 Z"
        fill={foldColor} stroke={strokeColor} strokeWidth={strokeWidth} strokeLinejoin="round"
      />
    </svg>
  );
}

// ─────────────────────────────────────────────────────────────
// Small UI atoms
// ─────────────────────────────────────────────────────────────
function SectionLabel({ num, children }) {
  return (
    <div style={{ display: 'flex', alignItems: 'baseline', gap: 12, marginBottom: 18 }}>
      <span style={{ fontFamily: JP, fontSize: 13, color: P.cocoa, fontWeight: 500, letterSpacing: '0.06em' }}>
        {num}
      </span>
      <span style={{ fontSize: 11, letterSpacing: '0.22em', textTransform: 'uppercase', color: P.cocoa, fontWeight: 600 }}>
        {children}
      </span>
      <span style={{ flex: 1, height: 1, background: P.cocoa, opacity: 0.18 }} />
    </div>
  );
}

function Module({ children, style = {} }) {
  return (
    <section style={{
      background: P.paper,
      border: `1px solid ${P.mist}`,
      borderRadius: 18,
      padding: '40px 44px',
      ...style,
    }}>{children}</section>
  );
}

// ─────────────────────────────────────────────────────────────
// 1. Hero
// ─────────────────────────────────────────────────────────────
function Hero() {
  return (
    <Module style={{ padding: '56px 56px 48px', background: P.cream, borderColor: 'transparent', position: 'relative', overflow: 'hidden' }}>
      {/* small system label */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 36 }}>
        <div style={{ fontSize: 11, letterSpacing: '0.22em', textTransform: 'uppercase', color: P.cocoa, fontWeight: 600 }}>
          Bokunokoto · Brand Identity
        </div>
        <div style={{ fontSize: 11, letterSpacing: '0.16em', textTransform: 'uppercase', color: P.cocoa, fontWeight: 500, opacity: 0.65 }}>
          Direction 03 · Page
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr auto', gap: 32, alignItems: 'center' }}>
        <div>
          <div style={{ fontFamily: JP, fontSize: 168, fontWeight: 500, color: P.ink, lineHeight: 0.9, letterSpacing: '0.01em', marginLeft: -6 }}>
            僕のこと
          </div>
          <div style={{ fontFamily: SANS, fontSize: 28, fontWeight: 500, color: P.cocoa, letterSpacing: '-0.02em', marginTop: 24 }}>
            A letter, carefully shared.
          </div>
        </div>
        <Mark size={200} strokeWidth={3.5} />
      </div>

      <div style={{ fontFamily: SANS, fontSize: 17, lineHeight: 1.6, color: P.ink, opacity: 0.78, marginTop: 36, maxWidth: 720, textWrap: 'pretty' }}>
        Bokunokoto helps people share the parts of their lives that are hardest to talk about — disability,
        identity, grief, illness — with the few they trust. Each disclosure is a folded page passed by hand:
        deliberate, intimate, on the writer's terms.
      </div>
    </Module>
  );
}

// ─────────────────────────────────────────────────────────────
// 2. Mark + anatomy
// ─────────────────────────────────────────────────────────────
function MarkAnatomy() {
  return (
    <Module>
      <SectionLabel num="01">The Mark</SectionLabel>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 48, alignItems: 'center' }}>
        {/* construction */}
        <div style={{ position: 'relative', height: 360, background: P.cream, borderRadius: 12, display: 'flex', alignItems: 'center', justifyContent: 'center', overflow: 'hidden' }}>
          <svg width="320" height="320" style={{ position: 'absolute', opacity: 0.18 }}>
            <defs>
              <pattern id="g-anatomy" width="32" height="32" patternUnits="userSpaceOnUse">
                <path d="M 32 0 L 0 0 0 32" fill="none" stroke={P.cocoa} strokeWidth="0.6"/>
              </pattern>
            </defs>
            <rect width="320" height="320" fill="url(#g-anatomy)"/>
            <line x1="160" y1="0" x2="160" y2="320" stroke={P.cocoa} strokeWidth="0.6" strokeDasharray="3 4" opacity="0.5"/>
            <line x1="0" y1="160" x2="320" y2="160" stroke={P.cocoa} strokeWidth="0.6" strokeDasharray="3 4" opacity="0.5"/>
          </svg>
          <Mark size={240} strokeWidth={2.6} />

          {/* anatomy callout pins */}
          {[
            { x: '78%', y: '22%', label: 'A · Fold' },
            { x: '74%', y: '74%', label: 'B · Signature' },
            { x: '22%', y: '52%', label: 'C · Voice lines' },
          ].map((c, i) => (
            <div key={i} style={{ position: 'absolute', left: c.x, top: c.y, transform: 'translate(-50%, -50%)' }}>
              <div style={{ width: 6, height: 6, borderRadius: 99, background: P.coral, boxShadow: `0 0 0 4px ${P.paper}` }} />
              <div style={{ position: 'absolute', left: 12, top: -2, fontFamily: SANS, fontSize: 10, color: P.cocoa, letterSpacing: '0.08em', textTransform: 'uppercase', whiteSpace: 'nowrap', fontWeight: 600 }}>
                {c.label}
              </div>
            </div>
          ))}
        </div>

        {/* anatomy notes */}
        <div style={{ fontFamily: SANS, color: P.ink }}>
          <div style={{ fontSize: 22, fontWeight: 600, letterSpacing: '-0.02em', marginBottom: 18, textWrap: 'balance' }}>
            A folded page, signed in coral.
          </div>
          <div style={{ display: 'grid', gap: 18 }}>
            {[
              { l: 'A · Fold',         t: 'The folded corner is the act of disclosure — a personal page prepared for one reader, then handed over.' },
              { l: 'B · Signature',    t: 'A small coral dot marks every page. It is the writer\u2019s presence: only their words can sign it.' },
              { l: 'C · Voice lines',  t: 'Two short strokes inside the page — what is written, never spelled out. The mark holds the shape of a story without revealing it.' },
            ].map((row, i) => (
              <div key={i}>
                <div style={{ fontSize: 10, letterSpacing: '0.16em', textTransform: 'uppercase', color: P.coral, fontWeight: 700, marginBottom: 4 }}>
                  {row.l}
                </div>
                <div style={{ fontSize: 14.5, lineHeight: 1.55, color: P.ink, opacity: 0.82, textWrap: 'pretty' }}>
                  {row.t}
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* size scale */}
      <div style={{ marginTop: 36, paddingTop: 28, borderTop: `1px dashed ${P.mist}`, display: 'flex', alignItems: 'flex-end', gap: 32, flexWrap: 'wrap' }}>
        <div style={{ fontSize: 10, letterSpacing: '0.18em', textTransform: 'uppercase', color: P.cocoa, fontWeight: 600, opacity: 0.7, alignSelf: 'center' }}>
          Scale ↓
        </div>
        {[120, 80, 48, 32].map(sz => (
          <div key={sz} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 8 }}>
            <Mark size={sz} strokeWidth={sz < 50 ? 4 : 3} withText={sz >= 48} />
            <div style={{ fontFamily: SANS, fontSize: 10, color: P.cocoa, opacity: 0.7, letterSpacing: '0.06em' }}>{sz}px</div>
          </div>
        ))}
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 8 }}>
          <MarkMini size={20} strokeWidth={6} />
          <div style={{ fontFamily: SANS, fontSize: 10, color: P.cocoa, opacity: 0.7, letterSpacing: '0.06em' }}>20px · mini</div>
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 8 }}>
          <MarkMini size={14} strokeWidth={7} />
          <div style={{ fontFamily: SANS, fontSize: 10, color: P.cocoa, opacity: 0.7, letterSpacing: '0.06em' }}>14px · favicon</div>
        </div>
      </div>
    </Module>
  );
}

// ─────────────────────────────────────────────────────────────
// 3. App icon
// ─────────────────────────────────────────────────────────────
function AppIcon() {
  // 4 tile treatments
  const tiles = [
    { id: 'cocoa',  bg: P.cocoa, label: 'Cocoa · primary',  markProps: { paperColor: P.paper, foldColor: P.cream, accentColor: P.coral,  strokeColor: P.cocoa } },
    { id: 'paper',  bg: P.paper, label: 'Paper · light',    markProps: { paperColor: P.cream, foldColor: '#EFD9B6', accentColor: P.coral,  strokeColor: P.cocoa } },
    { id: 'coral',  bg: P.coral, label: 'Coral · seasonal', markProps: { paperColor: P.paper, foldColor: P.cream, accentColor: P.cocoa,  strokeColor: P.cocoa } },
    { id: 'cream',  bg: P.cream, label: 'Cream · soft',     markProps: { paperColor: P.paper, foldColor: '#EAD3B2', accentColor: P.coral,  strokeColor: P.cocoa } },
  ];
  const [active, setActive] = useState(0);
  const T = tiles[active];

  return (
    <Module>
      <SectionLabel num="02">App Icon</SectionLabel>
      <div style={{ display: 'grid', gridTemplateColumns: 'auto 1fr', gap: 56, alignItems: 'center' }}>
        {/* hero icon */}
        <div style={{
          width: 240, height: 240, borderRadius: 54, background: T.bg,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          boxShadow: '0 1px 0 rgba(255,255,255,0.4) inset, 0 24px 50px -16px rgba(40,20,10,0.4), 0 4px 12px rgba(40,20,10,0.18)',
          position: 'relative',
        }}>
          <Mark size={156} {...T.markProps} />
          <div style={{ position: 'absolute', inset: 0, borderRadius: 54, boxShadow: 'inset 0 0 0 1px rgba(0,0,0,0.06)', pointerEvents: 'none' }} />
        </div>

        <div>
          {/* tile selector */}
          <div style={{ fontFamily: SANS, fontSize: 10, letterSpacing: '0.18em', textTransform: 'uppercase', color: P.cocoa, fontWeight: 600, opacity: 0.7, marginBottom: 12 }}>
            Tile variants
          </div>
          <div style={{ display: 'flex', gap: 14, flexWrap: 'wrap', marginBottom: 32 }}>
            {tiles.map((t, i) => (
              <button key={t.id} onClick={() => setActive(i)} style={{
                width: 80, height: 80, borderRadius: 18, background: t.bg,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                border: 'none', cursor: 'pointer', padding: 0,
                outline: active === i ? `2.5px solid ${P.coral}` : 'none',
                outlineOffset: 4,
                boxShadow: '0 6px 14px -4px rgba(40,20,10,0.28), 0 1px 3px rgba(40,20,10,0.12)',
                transition: 'transform .15s',
              }}>
                <Mark size={52} {...t.markProps} />
              </button>
            ))}
          </div>

          {/* active tile label */}
          <div style={{ fontFamily: SANS, fontSize: 13, color: P.cocoa, fontWeight: 500, marginBottom: 28 }}>
            {T.label}
          </div>

          {/* size step-down */}
          <div style={{ fontFamily: SANS, fontSize: 10, letterSpacing: '0.18em', textTransform: 'uppercase', color: P.cocoa, fontWeight: 600, opacity: 0.7, marginBottom: 12 }}>
            iOS / Android sizes
          </div>
          <div style={{ display: 'flex', gap: 14, alignItems: 'flex-end' }}>
            {[
              { sz: 60, label: '180' },
              { sz: 48, label: '120' },
              { sz: 36, label: '87'  },
              { sz: 28, label: '64'  },
              { sz: 20, label: '40'  },
            ].map(s => (
              <div key={s.label} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6 }}>
                <div style={{
                  width: s.sz, height: s.sz, borderRadius: s.sz * 0.225, background: T.bg,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  boxShadow: '0 3px 8px -2px rgba(40,20,10,0.25)',
                }}>
                  {s.sz >= 28 ? <Mark size={Math.round(s.sz * 0.68)} {...T.markProps} /> : <MarkMini size={Math.round(s.sz * 0.62)} {...T.markProps} strokeWidth={6} />}
                </div>
                <div style={{ fontFamily: SANS, fontSize: 9, color: P.cocoa, opacity: 0.65, letterSpacing: '0.06em' }}>{s.label}px</div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </Module>
  );
}

// ─────────────────────────────────────────────────────────────
// 4. Wordmark / lockups
// ─────────────────────────────────────────────────────────────
function Wordmarks() {
  return (
    <Module>
      <SectionLabel num="03">Wordmark · Lockups</SectionLabel>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 24 }}>
        {/* primary stacked */}
        <div style={{ background: P.cream, borderRadius: 12, padding: '36px 32px', minHeight: 200, display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}>
          <div style={{ fontFamily: SANS, fontSize: 10, letterSpacing: '0.18em', textTransform: 'uppercase', color: P.cocoa, fontWeight: 600, opacity: 0.7 }}>
            01 · Primary stacked
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-start', gap: 16 }}>
            <Mark size={56} />
            <div style={{ fontFamily: JP, fontSize: 56, fontWeight: 500, color: P.ink, lineHeight: 1, letterSpacing: '0.02em' }}>
              僕のこと
            </div>
          </div>
        </div>

        {/* horizontal full */}
        <div style={{ background: P.cream, borderRadius: 12, padding: '36px 32px', minHeight: 200, display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}>
          <div style={{ fontFamily: SANS, fontSize: 10, letterSpacing: '0.18em', textTransform: 'uppercase', color: P.cocoa, fontWeight: 600, opacity: 0.7 }}>
            02 · Horizontal full
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 18 }}>
            <Mark size={62} />
            <div style={{ display: 'flex', flexDirection: 'column' }}>
              <div style={{ fontFamily: JP, fontSize: 42, fontWeight: 500, color: P.ink, lineHeight: 1 }}>
                僕のこと
              </div>
              <div style={{ fontFamily: SANS, fontSize: 14, color: P.cocoa, fontWeight: 500, letterSpacing: '0.04em', marginTop: 6 }}>
                Bokunokoto
              </div>
            </div>
          </div>
        </div>

        {/* horizontal compact */}
        <div style={{ background: P.cream, borderRadius: 12, padding: '36px 32px', minHeight: 160, display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}>
          <div style={{ fontFamily: SANS, fontSize: 10, letterSpacing: '0.18em', textTransform: 'uppercase', color: P.cocoa, fontWeight: 600, opacity: 0.7 }}>
            03 · Badge · for nav / pills
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '12px 18px', background: P.paper, borderRadius: 999, alignSelf: 'flex-start' }}>
            <Mark size={28} />
            <span style={{ fontFamily: JP, fontSize: 22, color: P.ink, lineHeight: 1 }}>僕のこと</span>
            <span style={{ width: 4, height: 4, borderRadius: 99, background: P.cocoa, opacity: 0.35 }} />
            <span style={{ fontFamily: SANS, fontSize: 13, color: P.cocoa, fontWeight: 500, letterSpacing: '0.04em' }}>Bokunokoto</span>
          </div>
        </div>

        {/* monogram */}
        <div style={{ background: P.cocoa, borderRadius: 12, padding: '36px 32px', minHeight: 160, display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}>
          <div style={{ fontFamily: SANS, fontSize: 10, letterSpacing: '0.18em', textTransform: 'uppercase', color: P.paper, fontWeight: 600, opacity: 0.7 }}>
            04 · Monogram · for small surfaces
          </div>
          <div style={{ display: 'flex', alignItems: 'flex-end', gap: 24 }}>
            <div style={{ fontFamily: SANS, fontSize: 64, fontWeight: 700, color: P.paper, letterSpacing: '-0.04em', lineHeight: 1 }}>
              BK<span style={{ color: P.coral }}>.</span>
            </div>
            <div style={{ marginBottom: 6, fontFamily: SANS, fontSize: 11, color: P.paper, opacity: 0.6, letterSpacing: '0.08em', textTransform: 'uppercase' }}>
              Bokunokoto
            </div>
          </div>
        </div>
      </div>
    </Module>
  );
}

// ─────────────────────────────────────────────────────────────
// 5. Color palette
// ─────────────────────────────────────────────────────────────
function Palette() {
  const swatches = [
    { name: 'Ink',    hex: P.ink,    role: 'Primary type · all-caps headers' },
    { name: 'Cocoa',  hex: P.cocoa,  role: 'Brand primary · icon tile · headings' },
    { name: 'Coral',  hex: P.coral,  role: 'Signature · CTA · key moments' },
    { name: 'Honey',  hex: P.honey,  role: 'Warm support · highlights' },
    { name: 'Rose',   hex: P.rose,   role: 'Soft accent · empty states' },
    { name: 'Cream',  hex: P.cream,  role: 'Surface · cards · folded plane' },
    { name: 'Paper',  hex: P.paper,  role: 'Background · page' },
    { name: 'Mist',   hex: P.mist,   role: 'Dividers · disabled · low-emphasis' },
  ];

  return (
    <Module>
      <SectionLabel num="04">Color</SectionLabel>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 14 }}>
        {swatches.map(s => {
          const isLight = [P.cream, P.paper, P.mist, P.rose, P.honey].includes(s.hex);
          const textOn = isLight ? P.ink : P.paper;
          return (
            <div key={s.name} style={{
              background: s.hex,
              borderRadius: 12,
              padding: 16,
              minHeight: 132,
              display: 'flex', flexDirection: 'column', justifyContent: 'space-between',
              boxShadow: isLight ? `inset 0 0 0 1px ${P.cocoa}18` : 'none',
            }}>
              <div style={{ fontFamily: SANS, fontSize: 16, fontWeight: 600, color: textOn, letterSpacing: '-0.01em' }}>
                {s.name}
              </div>
              <div>
                <div style={{ fontFamily: SANS, fontSize: 11, color: textOn, opacity: 0.7, lineHeight: 1.4, textWrap: 'pretty', marginBottom: 8 }}>
                  {s.role}
                </div>
                <div style={{ fontFamily: 'ui-monospace, monospace', fontSize: 11, color: textOn, opacity: 0.85, letterSpacing: '0.02em' }}>
                  {s.hex.toUpperCase()}
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {/* sample combinations */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 14, marginTop: 16 }}>
        {[
          { bg: P.paper, fg: P.cocoa, accent: P.coral, label: 'Default surface' },
          { bg: P.cocoa, fg: P.paper, accent: P.honey, label: 'Inverse / focus mode' },
          { bg: P.cream, fg: P.cocoa, accent: P.coral, label: 'Card / disclosure' },
        ].map((c, i) => (
          <div key={i} style={{ background: c.bg, color: c.fg, padding: '20px 22px', borderRadius: 12, fontFamily: SANS, boxShadow: c.bg === P.paper || c.bg === P.cream ? `inset 0 0 0 1px ${P.cocoa}15` : 'none' }}>
            <div style={{ fontFamily: JP, fontSize: 22, color: c.fg, marginBottom: 8 }}>僕のこと</div>
            <div style={{ fontSize: 13, opacity: 0.7, marginBottom: 14 }}>{c.label}</div>
            <div style={{ display: 'inline-flex', padding: '7px 14px', background: c.accent, color: c.bg === P.cocoa ? P.cocoa : P.paper, borderRadius: 999, fontSize: 12, fontWeight: 600 }}>
              Share
            </div>
          </div>
        ))}
      </div>
    </Module>
  );
}

// ─────────────────────────────────────────────────────────────
// 6. Typography
// ─────────────────────────────────────────────────────────────
function Type() {
  return (
    <Module>
      <SectionLabel num="05">Typography</SectionLabel>
      <div style={{ display: 'grid', gridTemplateColumns: '1.1fr 1fr', gap: 36 }}>
        {/* JP specimen */}
        <div style={{ background: P.cream, borderRadius: 12, padding: '32px 36px' }}>
          <div style={{ fontFamily: SANS, fontSize: 10, letterSpacing: '0.18em', textTransform: 'uppercase', color: P.cocoa, fontWeight: 600, opacity: 0.7, marginBottom: 18 }}>
            日本語 · Noto Serif JP
          </div>
          <div style={{ fontFamily: JP, fontSize: 100, fontWeight: 500, color: P.ink, lineHeight: 1, letterSpacing: '0.02em', marginBottom: 18 }}>
            僕のこと
          </div>
          <div style={{ fontFamily: JP, fontSize: 18, color: P.ink, lineHeight: 1.7, opacity: 0.8, textWrap: 'pretty' }}>
            僕のことを、信頼できる人にだけ。<br />
            自分のペースで、自分の言葉で。
          </div>
        </div>

        {/* Latin specimen */}
        <div style={{ background: P.cream, borderRadius: 12, padding: '32px 36px' }}>
          <div style={{ fontFamily: SANS, fontSize: 10, letterSpacing: '0.18em', textTransform: 'uppercase', color: P.cocoa, fontWeight: 600, opacity: 0.7, marginBottom: 18 }}>
            Latin · Hanken Grotesk
          </div>
          <div style={{ fontFamily: SANS, fontSize: 34, fontWeight: 600, color: P.ink, lineHeight: 1.1, letterSpacing: '-0.025em', marginBottom: 14, textWrap: 'balance' }}>
            Share what matters, with who matters.
          </div>
          <div style={{ fontFamily: SANS, fontSize: 14, color: P.ink, lineHeight: 1.6, opacity: 0.78, textWrap: 'pretty' }}>
            Each disclosure is folded carefully, addressed to a single reader,
            and held until you decide it is ready to be opened.
          </div>
        </div>
      </div>

      {/* type scale */}
      <div style={{ marginTop: 20, paddingTop: 24, borderTop: `1px dashed ${P.mist}`, display: 'flex', gap: 36, alignItems: 'baseline', flexWrap: 'wrap' }}>
        {[
          { name: 'Display',  fs: 56, fw: 600, ls: '-0.03em', sample: 'Aa' },
          { name: 'H1',       fs: 34, fw: 600, ls: '-0.02em', sample: 'Aa' },
          { name: 'H2',       fs: 24, fw: 600, ls: '-0.02em', sample: 'Aa' },
          { name: 'Body',     fs: 16, fw: 400, ls: '0',       sample: 'Aa' },
          { name: 'Caption',  fs: 12, fw: 500, ls: '0.04em',  sample: 'Aa' },
          { name: 'Label',    fs: 10, fw: 600, ls: '0.18em',  sample: 'AA', upper: true },
        ].map(t => (
          <div key={t.name} style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
            <span style={{ fontFamily: SANS, fontSize: t.fs, fontWeight: t.fw, letterSpacing: t.ls, color: P.ink, lineHeight: 1, textTransform: t.upper ? 'uppercase' : 'none' }}>
              {t.sample}
            </span>
            <span style={{ fontFamily: SANS, fontSize: 10, color: P.cocoa, opacity: 0.65, letterSpacing: '0.08em', textTransform: 'uppercase' }}>
              {t.name} · {t.fs}
            </span>
          </div>
        ))}
      </div>
    </Module>
  );
}

// ─────────────────────────────────────────────────────────────
// 7. In context — phone mocks
// ─────────────────────────────────────────────────────────────

// Home screen with the BK app installed
function PhoneHome() {
  // 4x6 grid of soft icon placeholders + BK highlighted
  const dummies = [
    '#B86A5A', '#7C8E78', '#6A7F95', '#A38855',
    '#8B7BA8', '#5F6F6E', '#C7976F', '#9F6E5E',
    '#7DA088', '#A88564', '#B0928A', '#7488A2',
    '#9C7AA4', '#6E8881', '#A28E68', '#7A8A6A',
  ];
  return (
    <IOSDevice width={300} height={612} dark={false}>
      {/* wallpaper */}
      <div style={{
        position: 'absolute', inset: 0,
        background: `radial-gradient(120% 100% at 30% 20%, ${P.honey} 0%, ${P.coral} 45%, ${P.cocoa} 100%)`,
      }} />
      {/* clock */}
      <div style={{ position: 'absolute', top: 64, left: 0, right: 0, textAlign: 'center', color: '#fff', textShadow: '0 2px 12px rgba(0,0,0,0.18)' }}>
        <div style={{ fontFamily: SANS, fontSize: 12, letterSpacing: '0.18em', textTransform: 'uppercase', opacity: 0.9, fontWeight: 500 }}>
          Wednesday, May 27
        </div>
        <div style={{ fontFamily: SANS, fontSize: 76, fontWeight: 300, lineHeight: 1, marginTop: 4, letterSpacing: '-0.04em' }}>
          9:41
        </div>
      </div>
      {/* icon grid */}
      <div style={{ position: 'absolute', bottom: 80, left: 0, right: 0, padding: '0 22px' }}>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 22 }}>
          {dummies.map((c, i) => (
            <div key={i} style={{
              aspectRatio: '1', borderRadius: 14, background: c, opacity: 0.92,
              boxShadow: '0 2px 6px rgba(0,0,0,0.18)',
            }} />
          ))}
          {/* BK icon — highlighted */}
          <div style={{ position: 'relative', display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
            <div style={{
              aspectRatio: '1', width: '100%', borderRadius: 14, background: P.cocoa,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              boxShadow: '0 4px 16px rgba(0,0,0,0.32), 0 0 0 2px rgba(255,255,255,0.5)',
            }}>
              <Mark size={38} paperColor={P.paper} foldColor={P.cream} accentColor={P.coral} strokeColor={P.cocoa} strokeWidth={3.5} />
            </div>
            <div style={{ position: 'absolute', top: 'calc(100% + 6px)', fontFamily: SANS, fontSize: 11, color: '#fff', whiteSpace: 'nowrap', fontWeight: 500, textShadow: '0 1px 3px rgba(0,0,0,0.3)' }}>
              僕のこと
            </div>
          </div>
        </div>
      </div>
    </IOSDevice>
  );
}

// In-app disclosure screen
function PhoneApp() {
  return (
    <IOSDevice width={300} height={612} dark={false}>
      <div style={{ background: P.paper, minHeight: '100%', paddingTop: 54, paddingBottom: 40, fontFamily: SANS, color: P.ink, display: 'flex', flexDirection: 'column' }}>
        {/* top bar */}
        <div style={{ padding: '12px 20px 8px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <Mark size={26} strokeWidth={3.5} />
          <span style={{ fontFamily: JP, fontSize: 17, color: P.ink, letterSpacing: '0.04em' }}>僕のこと</span>
          <div style={{ width: 26, height: 26, borderRadius: 99, background: P.cream, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 11, color: P.cocoa, fontWeight: 600 }}>
            R
          </div>
        </div>

        {/* greeting */}
        <div style={{ padding: '20px 22px 14px' }}>
          <div style={{ fontSize: 11, letterSpacing: '0.18em', textTransform: 'uppercase', color: P.coral, fontWeight: 700, marginBottom: 6 }}>
            New letter
          </div>
          <div style={{ fontSize: 22, fontWeight: 600, lineHeight: 1.2, letterSpacing: '-0.02em', textWrap: 'balance' }}>
            Tell Hana about your chronic pain.
          </div>
          <div style={{ fontSize: 12.5, color: P.ink, opacity: 0.65, marginTop: 8, lineHeight: 1.5, textWrap: 'pretty' }}>
            She'll only see what you choose to fold in. You can unsend it any time.
          </div>
        </div>

        {/* the page card */}
        <div style={{ margin: '6px 18px', padding: '18px 18px 14px', background: P.cream, borderRadius: 16, position: 'relative', overflow: 'hidden' }}>
          {/* folded corner accent */}
          <div style={{ position: 'absolute', top: 0, right: 0, width: 36, height: 36, background: '#EAD3B2', clipPath: 'polygon(100% 0, 100% 100%, 0 0)' }} />

          <div style={{ fontSize: 10, letterSpacing: '0.16em', textTransform: 'uppercase', color: P.cocoa, fontWeight: 700, opacity: 0.7, marginBottom: 10 }}>
            What Hana will read
          </div>

          {[
            { l: 'Diagnosis',         v: 'Fibromyalgia · 2022', shown: true },
            { l: 'On bad days',       v: 'I may cancel plans last-minute', shown: true },
            { l: 'What helps',        v: 'Quiet company. No fixing.', shown: true },
            { l: 'Medications',       v: 'Hidden', shown: false },
          ].map((r, i) => (
            <div key={i} style={{ paddingTop: 10, paddingBottom: 10, borderTop: i === 0 ? 'none' : `1px solid ${P.cocoa}10`, display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: 12 }}>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 10.5, color: P.cocoa, opacity: 0.65, letterSpacing: '0.04em', textTransform: 'uppercase', marginBottom: 2, fontWeight: 600 }}>
                  {r.l}
                </div>
                <div style={{ fontSize: 13.5, color: r.shown ? P.ink : P.ink + '55', lineHeight: 1.35, fontStyle: r.shown ? 'normal' : 'italic' }}>
                  {r.v}
                </div>
              </div>
              <div style={{ width: 28, height: 16, borderRadius: 999, background: r.shown ? P.coral : P.mist, position: 'relative', flexShrink: 0, marginTop: 4 }}>
                <div style={{ position: 'absolute', top: 2, left: r.shown ? 14 : 2, width: 12, height: 12, borderRadius: 99, background: P.paper, boxShadow: '0 1px 2px rgba(0,0,0,0.15)' }} />
              </div>
            </div>
          ))}
        </div>

        <div style={{ flex: 1 }} />

        {/* CTA */}
        <div style={{ padding: '0 18px' }}>
          <button style={{
            width: '100%', padding: '14px 16px', borderRadius: 14, border: 'none', cursor: 'pointer',
            background: P.coral, color: P.paper, fontFamily: SANS, fontSize: 15, fontWeight: 600, letterSpacing: '-0.01em',
            display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 10,
            boxShadow: '0 8px 20px -6px rgba(221,111,79,0.5)',
          }}>
            <Mark size={20} paperColor={P.paper} foldColor={P.cream} accentColor={P.cocoa} strokeColor={P.coral} strokeWidth={4} />
            <span>Fold &amp; send to Hana</span>
          </button>
          <div style={{ textAlign: 'center', fontSize: 11, color: P.ink, opacity: 0.55, marginTop: 8, fontFamily: SANS }}>
            Signed by you · withdrawable anytime
          </div>
        </div>
      </div>
    </IOSDevice>
  );
}

function InContext() {
  return (
    <Module style={{ background: P.cocoa, borderColor: 'transparent' }}>
      <div style={{ display: 'flex', alignItems: 'baseline', gap: 12, marginBottom: 32 }}>
        <span style={{ fontFamily: JP, fontSize: 13, color: P.paper, fontWeight: 500, letterSpacing: '0.06em' }}>06</span>
        <span style={{ fontSize: 11, letterSpacing: '0.22em', textTransform: 'uppercase', color: P.paper, fontWeight: 600 }}>In Context</span>
        <span style={{ flex: 1, height: 1, background: P.paper, opacity: 0.2 }} />
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, auto)', gap: 56, justifyContent: 'center', alignItems: 'flex-start' }}>
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 18 }}>
          <PhoneHome />
          <div style={{ fontFamily: SANS, fontSize: 11, color: P.paper, opacity: 0.7, letterSpacing: '0.14em', textTransform: 'uppercase', fontWeight: 600 }}>
            Home screen · installed
          </div>
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 18 }}>
          <PhoneApp />
          <div style={{ fontFamily: SANS, fontSize: 11, color: P.paper, opacity: 0.7, letterSpacing: '0.14em', textTransform: 'uppercase', fontWeight: 600 }}>
            New letter · share screen
          </div>
        </div>
      </div>
    </Module>
  );
}

// ─────────────────────────────────────────────────────────────
// Page composition
// ─────────────────────────────────────────────────────────────
function App() {
  return (
    <div style={{ minHeight: '100vh', background: '#EFE2CB', padding: '40px 32px 80px' }}>
      <div style={{ maxWidth: 1240, margin: '0 auto', display: 'flex', flexDirection: 'column', gap: 18 }}>
        {/* top breadcrumb */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '4px 8px 8px' }}>
          <a href="Bokunokoto Brand.html" style={{ fontFamily: SANS, fontSize: 12, color: P.cocoa, opacity: 0.7, textDecoration: 'none', letterSpacing: '0.04em' }}>
            ← All directions
          </a>
          <div style={{ fontFamily: SANS, fontSize: 11, color: P.cocoa, opacity: 0.6, letterSpacing: '0.2em', textTransform: 'uppercase', fontWeight: 600 }}>
            Brand sheet · v1
          </div>
        </div>

        <Hero />
        <MarkAnatomy />
        <AppIcon />
        <Wordmarks />
        <Palette />
        <Type />
        <InContext />

        {/* footer */}
        <div style={{ padding: '32px 16px 0', display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 32 }}>
          {[
            { l: 'Voice',    t: 'Plain, warm, never clinical. Write to one person at a time, never \u201cusers.\u201d' },
            { l: 'Pacing',   t: 'Pause before disclosure. The interface should never rush a sentence.' },
            { l: 'Promise',  t: 'You sign every page. You can unsend any page. We never read the words.' },
          ].map((f, i) => (
            <div key={i}>
              <div style={{ fontFamily: SANS, fontSize: 10, letterSpacing: '0.18em', textTransform: 'uppercase', color: P.coral, fontWeight: 700, marginBottom: 8 }}>
                {f.l}
              </div>
              <div style={{ fontFamily: SANS, fontSize: 14, color: P.cocoa, lineHeight: 1.55, textWrap: 'pretty' }}>
                {f.t}
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<App />);
