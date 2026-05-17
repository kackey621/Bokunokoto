// Bokunokoto brand canvas — three directions across icon, wordmark, mark,
// palette, and type. Layout: rows by asset type so the user can compare
// the same artifact across all three directions side-by-side.

const { useMemo } = React;

// =====================================================================
//  Cover card — direction headline (name, tagline, the symbol)
// =====================================================================

function CoverCard({ d }) {
  const Mark = d.Mark;
  const markProps = d.id === 'held'
    ? { strokeColor: d.primary, seedColor: d.accent }
    : d.id === 'bloom'
    ? {}
    : { paperColor: PALETTE.paper, foldColor: PALETTE.cream, accentColor: d.accent, strokeColor: PALETTE.ink };

  return (
    <div style={{
      width: '100%', height: '100%',
      background: d.bg, color: PALETTE.ink,
      fontFamily: `'${d.font}', system-ui, sans-serif`,
      padding: '36px 36px 32px',
      display: 'flex', flexDirection: 'column', justifyContent: 'space-between',
      boxSizing: 'border-box',
    }}>
      <div style={{ display: 'flex', alignItems: 'flex-start', gap: 24 }}>
        <div style={{ flexShrink: 0 }}><Mark size={88} {...markProps} /></div>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontSize: 11, letterSpacing: '0.18em', textTransform: 'uppercase', color: PALETTE.ink + 'aa', fontWeight: 600 }}>
            Direction · {String(DIRECTIONS.indexOf(d) + 1).padStart(2, '0')}
          </div>
          <div style={{ fontSize: 48, fontWeight: d.fontWeights.display, lineHeight: 1, marginTop: 10, letterSpacing: '-0.02em' }}>
            {d.name}
          </div>
          <div style={{ fontSize: 17, fontWeight: 400, marginTop: 12, color: PALETTE.ink + 'cc', lineHeight: 1.35, textWrap: 'pretty' }}>
            {d.tagline}
          </div>
        </div>
      </div>
      <div style={{ fontSize: 13.5, lineHeight: 1.55, color: PALETTE.ink + 'bb', maxWidth: 360, textWrap: 'pretty' }}>
        {d.description}
      </div>
    </div>
  );
}

// =====================================================================
//  App icon card — iOS-style rounded square with the mark inside
// =====================================================================

function AppIconCard({ d }) {
  const Mark = d.Mark;
  const markProps = d.id === 'held'
    ? { strokeColor: d.iconMarkColor, seedColor: d.iconSeedColor }
    : d.id === 'bloom'
    ? { colors: [PALETTE.coral, PALETTE.honey, PALETTE.cocoa] }
    : { paperColor: d.iconMarkColor, foldColor: '#e9dfc8', accentColor: d.iconSeedColor, strokeColor: d.iconBg };

  // a stamp-style background for D1 / D3 to give the icon depth on the canvas
  return (
    <div style={{
      width: '100%', height: '100%',
      background: '#efe2cb',
      display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
      gap: 18,
      fontFamily: `'${d.font}', system-ui, sans-serif`,
    }}>
      {/* large icon */}
      <div style={{
        width: 168, height: 168, borderRadius: 38,
        background: d.iconBg,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        boxShadow: '0 1px 0 rgba(255,255,255,0.5) inset, 0 12px 30px -10px rgba(20,18,12,0.35), 0 2px 6px rgba(20,18,12,0.12)',
        position: 'relative',
      }}>
        <Mark size={118} {...markProps} />
        {/* subtle inner stroke */}
        <div style={{ position: 'absolute', inset: 0, borderRadius: 38, boxShadow: 'inset 0 0 0 1px rgba(0,0,0,0.04)', pointerEvents: 'none' }} />
      </div>
      {/* mini icons row — shows scalability */}
      <div style={{ display: 'flex', gap: 10, alignItems: 'flex-end' }}>
        {[60, 44, 32, 22].map((sz) => (
          <div key={sz} style={{
            width: sz, height: sz, borderRadius: sz * 0.225,
            background: d.iconBg,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: '0 2px 6px rgba(20,18,12,0.18)',
          }}>
            <Mark size={Math.round(sz * 0.72)} {...markProps} />
          </div>
        ))}
      </div>
      <div style={{ fontSize: 11, letterSpacing: '0.16em', textTransform: 'uppercase', color: PALETTE.ink + '80', fontWeight: 500, marginTop: 4 }}>
        180 · 120 · 87 · 64 · 40 px
      </div>
    </div>
  );
}

// =====================================================================
//  Symbol / monogram card — the mark on its own, with a faint grid
// =====================================================================

function SymbolCard({ d }) {
  const Mark = d.Mark;
  const markProps = d.id === 'held'
    ? { strokeColor: d.primary, seedColor: d.accent }
    : d.id === 'bloom'
    ? {}
    : { paperColor: PALETTE.paper, foldColor: PALETTE.cream, accentColor: d.accent, strokeColor: PALETTE.ink };

  return (
    <div style={{
      width: '100%', height: '100%',
      background: d.bg,
      fontFamily: `'${d.font}', system-ui, sans-serif`,
      display: 'flex', flexDirection: 'column',
      padding: '24px 28px',
      boxSizing: 'border-box',
    }}>
      <div style={{ fontSize: 11, letterSpacing: '0.18em', textTransform: 'uppercase', color: PALETTE.ink + '90', fontWeight: 600 }}>
        Symbol
      </div>
      <div style={{ flex: 1, position: 'relative', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        {/* faint construction grid behind the mark */}
        <svg width="220" height="220" style={{ position: 'absolute', opacity: 0.16 }}>
          <defs>
            <pattern id={`grid-${d.id}`} width="22" height="22" patternUnits="userSpaceOnUse">
              <path d="M 22 0 L 0 0 0 22" fill="none" stroke={PALETTE.ink} strokeWidth="0.5"/>
            </pattern>
          </defs>
          <rect width="220" height="220" fill={`url(#grid-${d.id})`}/>
          <circle cx="110" cy="110" r="100" fill="none" stroke={PALETTE.ink} strokeWidth="0.5" strokeDasharray="2 3" opacity="0.6"/>
        </svg>
        <Mark size={170} {...markProps} />
      </div>
      <div style={{ display: 'flex', gap: 10, alignItems: 'center' }}>
        {/* mini mark variants — solid / outline / inverted */}
        <div style={{ padding: '10px 14px', background: PALETTE.paper, borderRadius: 8, display: 'flex', alignItems: 'center', gap: 10 }}>
          <Mark size={28} {...markProps} />
          <span style={{ fontSize: 11, color: PALETTE.ink + '88', fontWeight: 500 }}>on paper</span>
        </div>
        <div style={{ padding: '10px 14px', background: d.primary, borderRadius: 8, display: 'flex', alignItems: 'center', gap: 10 }}>
          {/* inverse: paper-on-primary */}
          {d.id === 'held' && <MarkHeld size={28} strokeColor={PALETTE.paper} seedColor={d.accent} />}
          {d.id === 'bloom' && <MarkBloom size={28} colors={[PALETTE.paper, PALETTE.cream, PALETTE.rose]} />}
          {d.id === 'page' && <MarkPage size={28} paperColor={PALETTE.paper} foldColor={PALETTE.cream} accentColor={d.accent} strokeColor={d.primary} />}
          <span style={{ fontSize: 11, color: PALETTE.paper + 'cc', fontWeight: 500 }}>inverse</span>
        </div>
      </div>
    </div>
  );
}

// =====================================================================
//  Wordmark card — primary lockup (僕のこと), supporting (Bokunokoto, BK)
// =====================================================================

function WordmarkCard({ d }) {
  const Mark = d.Mark;
  const markProps = d.id === 'held'
    ? { strokeColor: d.primary, seedColor: d.accent }
    : d.id === 'bloom'
    ? {}
    : { paperColor: PALETTE.paper, foldColor: PALETTE.cream, accentColor: d.accent, strokeColor: PALETTE.ink };

  // Type stacks:
  //   The kanji/hiragana renders in a serif/Mincho-style face to match the
  //   warmth of a humanist sans without flattening into a UI font. We pair
  //   Noto Serif JP with the Latin humanist sans.
  const jpFont = "'Noto Serif JP', 'Hiragino Mincho ProN', serif";

  return (
    <div style={{
      width: '100%', height: '100%',
      background: d.bg,
      fontFamily: `'${d.font}', system-ui, sans-serif`,
      padding: '28px 32px',
      display: 'flex', flexDirection: 'column', gap: 18,
      boxSizing: 'border-box',
    }}>
      <div style={{ fontSize: 11, letterSpacing: '0.18em', textTransform: 'uppercase', color: PALETTE.ink + '90', fontWeight: 600 }}>
        Wordmark · primary
      </div>

      {/* Primary lockup — symbol + 僕のこと */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 18 }}>
        <Mark size={64} {...markProps} />
        <div style={{
          fontFamily: jpFont,
          fontSize: 54, fontWeight: 500, lineHeight: 1,
          color: PALETTE.ink, letterSpacing: '0.02em',
        }}>
          僕のこと
        </div>
      </div>

      <div style={{ height: 1, background: PALETTE.ink + '15' }} />

      {/* Secondary — Bokunokoto */}
      <div>
        <div style={{ fontSize: 10, letterSpacing: '0.16em', textTransform: 'uppercase', color: PALETTE.ink + '70', fontWeight: 500, marginBottom: 6 }}>
          Romaji
        </div>
        <div style={{
          fontSize: 32, fontWeight: d.fontWeights.display,
          letterSpacing: '-0.025em', color: PALETTE.ink, lineHeight: 1,
        }}>
          Bokunokoto
        </div>
      </div>

      {/* BK monogram */}
      <div style={{ display: 'flex', alignItems: 'flex-end', gap: 20 }}>
        <div>
          <div style={{ fontSize: 10, letterSpacing: '0.16em', textTransform: 'uppercase', color: PALETTE.ink + '70', fontWeight: 500, marginBottom: 6 }}>
            Monogram
          </div>
          <div style={{
            fontSize: 44, fontWeight: 700, letterSpacing: '-0.04em',
            color: d.primary, lineHeight: 1,
          }}>
            BK<span style={{ color: d.accent }}>.</span>
          </div>
        </div>
        {/* horizontal mini-lockup */}
        <div style={{ marginLeft: 'auto', display: 'flex', alignItems: 'center', gap: 8, padding: '8px 12px', background: PALETTE.paper, borderRadius: 999 }}>
          <Mark size={20} {...markProps} />
          <span style={{ fontFamily: jpFont, fontSize: 16, color: PALETTE.ink }}>僕のこと</span>
          <span style={{ fontSize: 12, color: PALETTE.ink + '70', fontWeight: 500, letterSpacing: '0.04em' }}>Bokunokoto</span>
        </div>
      </div>
    </div>
  );
}

// =====================================================================
//  Palette card — six swatches with hex + role
// =====================================================================

function PaletteCard({ d }) {
  return (
    <div style={{
      width: '100%', height: '100%',
      background: d.bg,
      fontFamily: `'${d.font}', system-ui, sans-serif`,
      padding: '24px 28px',
      display: 'flex', flexDirection: 'column', gap: 16,
      boxSizing: 'border-box',
    }}>
      <div style={{ fontSize: 11, letterSpacing: '0.18em', textTransform: 'uppercase', color: PALETTE.ink + '90', fontWeight: 600 }}>
        Color · {d.name}
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 14, flex: 1 }}>
        {d.palette.map((c) => {
          const isLight = [PALETTE.paper, PALETTE.cream, PALETTE.mist, PALETTE.rose, PALETTE.honey].includes(c.hex);
          const textOn = isLight ? PALETTE.ink : PALETTE.paper;
          return (
            <div key={c.name} style={{
              background: c.hex,
              borderRadius: 8,
              padding: '12px 14px',
              display: 'flex', flexDirection: 'column', justifyContent: 'space-between',
              minHeight: 72,
              boxShadow: isLight ? 'inset 0 0 0 1px rgba(0,0,0,0.06)' : 'none',
            }}>
              <div style={{ fontSize: 13, fontWeight: 600, color: textOn, letterSpacing: '-0.01em' }}>
                {c.name}
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-end', gap: 8 }}>
                <div style={{ fontSize: 10, color: textOn + 'aa', letterSpacing: '0.02em', textWrap: 'balance' }}>
                  {c.role}
                </div>
                <div style={{ fontSize: 10.5, fontFamily: 'ui-monospace, monospace', color: textOn + 'cc', letterSpacing: '0.02em' }}>
                  {c.hex.toUpperCase()}
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}

// =====================================================================
//  Typography card — face name, sample, scale
// =====================================================================

function TypographyCard({ d }) {
  return (
    <div style={{
      width: '100%', height: '100%',
      background: d.bg,
      fontFamily: `'${d.font}', system-ui, sans-serif`,
      padding: '24px 28px',
      display: 'flex', flexDirection: 'column', gap: 16,
      boxSizing: 'border-box',
      color: PALETTE.ink,
    }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
        <div style={{ fontSize: 11, letterSpacing: '0.18em', textTransform: 'uppercase', color: PALETTE.ink + '90', fontWeight: 600 }}>
          Type
        </div>
        <div style={{ fontSize: 12, color: PALETTE.ink + '90', fontWeight: 500 }}>
          {d.font} · Noto Serif JP
        </div>
      </div>

      {/* Display sample */}
      <div style={{ fontFamily: "'Noto Serif JP', serif", fontSize: 60, lineHeight: 1, fontWeight: 500, letterSpacing: '0.02em', marginTop: -4 }}>
        僕のこと
      </div>

      {/* Headline sample */}
      <div style={{ fontSize: 22, fontWeight: d.fontWeights.display, lineHeight: 1.2, letterSpacing: '-0.02em', textWrap: 'balance' }}>
        Share what matters,<br/>with who matters.
      </div>

      {/* Body sample */}
      <div style={{ fontSize: 13, fontWeight: 400, lineHeight: 1.55, color: PALETTE.ink + 'cc', textWrap: 'pretty', maxWidth: 340 }}>
        Bokunokoto helps you tell trusted people about the parts of your life
        that are hardest to talk about — on your terms, at your pace.
      </div>

      {/* Type scale */}
      <div style={{ display: 'flex', gap: 18, marginTop: 'auto', alignItems: 'baseline', flexWrap: 'wrap' }}>
        <div><span style={{ fontSize: 28, fontWeight: 600, letterSpacing: '-0.02em' }}>Aa</span><span style={{ fontSize: 9, color: PALETTE.ink + '80', marginLeft: 4 }}>H1 · 32</span></div>
        <div><span style={{ fontSize: 20, fontWeight: 600, letterSpacing: '-0.02em' }}>Aa</span><span style={{ fontSize: 9, color: PALETTE.ink + '80', marginLeft: 4 }}>H2 · 22</span></div>
        <div><span style={{ fontSize: 15, fontWeight: 400 }}>Aa</span><span style={{ fontSize: 9, color: PALETTE.ink + '80', marginLeft: 4 }}>Body · 16</span></div>
        <div><span style={{ fontSize: 11, fontWeight: 500, letterSpacing: '0.06em', textTransform: 'uppercase' }}>Aa</span><span style={{ fontSize: 9, color: PALETTE.ink + '80', marginLeft: 4 }}>Caption · 12</span></div>
      </div>
    </div>
  );
}

// =====================================================================
//  Canvas composition
// =====================================================================

function App() {
  const sections = [
    { id: 'cover',    title: 'Brand direction',  subtitle: 'Three takes on Bokunokoto\u2019s identity — same warm earth palette, different metaphors.', Card: CoverCard,       w: 460, h: 280 },
    { id: 'icon',     title: 'App icon',          subtitle: 'iOS / Android, all sizes. 180px hero, plus 60 · 44 · 32 · 22 step-down preview.',          Card: AppIconCard,     w: 360, h: 400 },
    { id: 'symbol',   title: 'Symbol & monogram', subtitle: 'Standalone mark with construction grid, and on-color / inverse variants.',                  Card: SymbolCard,      w: 360, h: 360 },
    { id: 'wordmark', title: 'Wordmark',          subtitle: '\u50d5\u306e\u3053\u3068 as the hero, paired with Bokunokoto romaji and the BK monogram.', Card: WordmarkCard,    w: 460, h: 360 },
    { id: 'color',    title: 'Color palette',     subtitle: 'Six tokens — primary, accent, surface, type, support.',                                     Card: PaletteCard,     w: 360, h: 320 },
    { id: 'type',     title: 'Typography',        subtitle: 'Noto Serif JP for \u65e5\u672c\u8a9e + a humanist sans for Latin.',                          Card: TypographyCard,  w: 420, h: 380 },
  ];

  return (
    <DesignCanvas>
      {sections.map(({ id, title, subtitle, Card, w, h }) => (
        <DCSection key={id} id={id} title={title} subtitle={subtitle}>
          {DIRECTIONS.map((d) => (
            <DCArtboard key={d.id} id={`${id}-${d.id}`} label={`${String(DIRECTIONS.indexOf(d) + 1).padStart(2, '0')} · ${d.name}`} width={w} height={h}>
              <Card d={d} />
            </DCArtboard>
          ))}
        </DCSection>
      ))}
    </DesignCanvas>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<App />);
