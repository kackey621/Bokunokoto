# ABC Shield (Screen Capture Prevention)

## Overview

The ABC Shield is a multi-layered defense system that prevents unauthorized reproduction of sensitive content displayed on screen.

## Three Layers

### Layer A: Rendering Pipeline (Video Stream Conversion)

Content is never rendered as standard DOM text. Instead:

1. **Data Fetch:** Encrypted content is retrieved from the Rails API
2. **In-Memory Decryption:** Content is decrypted only in JavaScript/Dart memory (never written to DOM)
3. **Canvas Rendering:** Text is drawn onto a hidden `<canvas>` element
4. **Video Conversion:** `canvas.captureStream(fps)` converts the canvas to a video stream
5. **Protected Playback:** The stream is fed to a `<video>` tag with `disablePictureInPicture` and `controlslist="nodownload"`

On native mobile apps, this is replaced by OS-level flags:

- **Android:** `FLAG_SECURE` — OS-level screenshot blackout
- **iOS:** `isSecureTextEntry` overlay + secure UIView techniques

### Layer B: Adaptive Watchdog (Capture Detection)

Real-time monitoring of the browser/app environment:

- **Screen Share Detection:** Monitor `navigator.mediaDevices.getDisplayMedia` attempts
- **Focus Monitoring:** `visibilitychange` and `blur` events trigger immediate content blackout when the user switches away
- **External Display Detection:** Changes in connected displays trigger content hiding

### Layer C: Environment Lock (Source Protection)

Prevent extraction of information from source code or developer tools:

- **Anti-Debugger:** Background `debugger` statement loop freezes tabs when DevTools open
- **Code Obfuscation:** Build-time variable/logic obfuscation
- **Input Interception:** Block `contextmenu`, `F12`, `Ctrl+U`, `Ctrl+Shift+I`, `PrintScreen` key events
- **Copy/Print Prevention:**
    ```css
    body {
      user-select: none;
      -webkit-touch-callout: none;
    }
    @media print {
      body { display: none; }
    }
    ```

## Dynamic Watermark

A transparent overlay displays the viewer's identity across the entire screen:

- **Content:** User ID hash + IP address + viewing timestamp
- **Rendering:** SVG pattern with `pointer-events: none` and low opacity (~0.05)
- **Purpose:** Physical camera photography deterrent — if someone photographs the screen, the watermark traces back to the viewer

## Application by Trust Level

| Level | Shield Applied |
|---|---|
| L0–L4 | CSS-only guards (copy/print prevention) |
| L5 | CSS guards + earphone requirement |
| L6 | CSS guards + dynamic watermark |
| L7–L8 | Full ABC Shield (video stream + watchdog + environment lock + watermark) |

## Platform Differences

| Feature | Flutter Web | Flutter Native (iOS/Android) |
|---|---|---|
| Screenshot block | JavaScript/CSS guards (best-effort) | OS-level `FLAG_SECURE` / secure view (definitive) |
| Video stream | Canvas → Video conversion | Not needed (OS handles it) |
| DevTools block | Anti-debugger loop | N/A (no DevTools in production apps) |
| Watermark | SVG overlay | Flutter widget overlay |

!!! note "Analog Hole"
    No software can prevent someone from photographing the screen with a separate device. The dynamic watermark + camera/GPS forensics (L7+) serve as **deterrence and traceability**, not absolute prevention.
