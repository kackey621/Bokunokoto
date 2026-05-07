# Accessibility Implementation Guide

## WCAG 2.1 AA Compliance Checklist

### Color & Contrast
- [x] All text colors have minimum 4.5:1 contrast ratio against background
- [x] UI component borders/outlines have 3:1 contrast ratio minimum
- [x] Color is not the only way to convey information (use icons, patterns, text)
- [x] Focus indicators clearly visible (minimum 2px, high contrast)

**Implementation:**
- Primary text: #1F2937 on #FFFFFF (17:1 ratio)
- Secondary text: #6B7280 on #FFFFFF (7:1 ratio)
- Focus color: #6366F1 with 3px outline
- Level badges use color + icon + text

### Interactive Elements
- [x] All clickable elements minimum 48dp (Material Design standard)
- [x] Touch targets have minimum 8dp padding
- [x] Buttons have visible focus state
- [x] No keyboard trap - all features accessible via Tab/Enter

**Implementation:**
- Button height: 48dp
- Minimum tap target: 44x44dp
- Icon buttons: 48x48dp total
- List items: 56dp height minimum

### Screen Reader Support
- [x] Semantic HTML structure (Scaffold, AppBar, FloatingActionButton)
- [x] Images have descriptive alt text / Semantic labels
- [x] Form labels associated with inputs
- [x] Headings properly nested (h1 → h2 → h3)
- [x] List items marked as such (ListView with semantic)

**Flutter Implementation:**
```dart
Semantics(
  label: 'Symbol: Private information',
  button: false,
  child: SymbolBadge(symbolType: 'lock'),
)
```

### Screen Reader Announcements
- QR Code: "QR code image, open in camera app to scan"
- Content Cards: "Title, Level 3, by User Name. Login required"
- Symbols: "Symbol: Lock meaning Private information"
- Countdown: "Time until unlock: 2 hours 30 minutes remaining"
- Level Badge: "This content requires trust level 3 or higher"

### Audio Output (Earphone-Only for L5+)
- [x] Detect audio route (speaker, earpiece, earphone)
- [x] Use MethodChannel to access AudioManager (Android) / AVAudioSession (iOS)
- [x] Fallback message if speaker-only: "For privacy, please connect earphones"
- [x] Allow user to override with warning

### Haptic Feedback Patterns
- Level-up event: Double-tap pattern (50ms, 50ms pause, 50ms)
- NFC handshake: Notification pattern (100ms solid)
- Urgent alert: Steady vibration (200ms)
- Success: Single tap (80ms)

**Flutter Implementation:**
```dart
import 'package:flutter_vibrate/flutter_vibrate.dart';

Vibrate.feedback(FeedbackType.heavy);
await Vibrate.vibrate(duration: 100);
```

### Keyboard Navigation
- [x] Tab order logical (top-to-bottom, left-to-right)
- [x] Visible focus indicators on all interactive elements
- [x] No reliance on mouse-only actions
- [x] Page/Home/End keys work as expected
- [x] Escape key closes modals

**Flutter Web:**
- FocusableActionDetector for keyboard events
- Focus traversal policies with FocusScopeNode
- MaterialButton/ElevatedButton default focus handling

### Text & Language
- [x] Plain language - avoid jargon without explanation
- [x] Short paragraphs and bullet points
- [x] Clear headings that describe content
- [x] Links have descriptive text (not "click here")
- [x] Language markup for screen readers (lang attribute on root)

**Onboarding Copy Examples:**
- "What's your name?" (not "Provide authentication credentials")
- "Your relationship to the discloser" (explain relationship means friend/family/colleague)
- "Why do you need access?" (open-ended, clear purpose)

### Testing Procedures

#### VoiceOver (iOS)
1. Enable Settings > Accessibility > VoiceOver
2. Swipe right/left to navigate
3. Double-tap to activate
4. Rotate two fingers (magic tap) for context menu
5. Check: all content read, proper pronunciation, logical order

#### TalkBack (Android)
1. Enable Settings > Accessibility > TalkBack
2. Swipe right/left to navigate
3. Double-tap to activate
4. Swipe down then right (read from top) to navigate
5. Check: all content announced, descriptions make sense

#### Keyboard-Only
1. Disable mouse/trackpad
2. Tab through all interactive elements
3. Enter/Space activates buttons
4. Arrow keys in lists
5. Escape closes dialogs

#### Color Contrast Audit
Tools: WAVE, Axe DevTools, Stark
- Check: text on backgrounds, buttons, form states, focus indicators
- Target: 4.5:1 for normal text, 3:1 for large text (18pt+)

### Accessibility Metrics (to track)

**VoiceOver Success Rate:** Users completing profile setup without frustration
**TalkBack Success Rate:** Users navigating content list and opening items
**Keyboard Navigation:** 100% of features accessible via Tab/Enter
**Color Contrast:** 100% compliance with WCAG AA (4.5:1 minimum)
**Response Time:** Screen reader announcement latency <500ms

### Device-Specific Implementation

#### Android
```kotlin
// Enforce minimum tap target size
val button = Button(context)
button.minimumHeight = 48.dpToPx()
button.minimumWidth = 48.dpToPx()

// Audio route detection
val audioManager = context.getSystemService(Context.AUDIO_SERVICE)
val isSpeakerOn = audioManager.isSpeakerphoneOn
```

#### iOS
```swift
// Audio route monitoring
let audioSession = AVAudioSession.sharedInstance()
let currentRoute = audioSession.currentRoute

// Haptic feedback
let impact = UIImpactFeedbackGenerator(style: .heavy)
impact.impactOccurred()
```

### Documentation & Training
- Label all custom components with semantic meaning
- Document symbol colors and meanings
- Include alt text in image assets
- Provide keyboard shortcuts in help
- Test with actual screen reader users (not just automated tools)
