# NTP Time Sync (BK Time)

## Purpose

BK Time prevents users from manipulating their device clock to bypass time-locked content (greeting cards, scheduled disclosures). The system maintains its own trusted clock independent of the device's OS settings.

## Protocol

### Formula

$$T_{BK} = T_{Rails\_NTP} + (T_{Uptime\_Now} - T_{Uptime\_Sync})$$

| Variable | Description |
|---|---|
| $T_{BK}$ | BK system internal clock |
| $T_{Rails\_NTP}$ | UTC time from Rails NTP endpoint at last sync |
| $T_{Uptime\_Now}$ | Device uptime counter (monotonic, unaffected by clock changes) |
| $T_{Uptime\_Sync}$ | Device uptime counter at the moment of last sync |

### Why This Works

The device's **uptime counter** (e.g., `SystemClock.elapsedRealtime()` on Android, `ProcessInfo.systemUptime` on iOS) increments regardless of user clock changes. By anchoring to the server's trusted time and measuring elapsed time via uptime, the client maintains an accurate clock that cannot be spoofed by changing the OS time settings.

## Rails NTP Endpoint

```ruby
# app/controllers/api/v1/ntp_controller.rb
class Api::V1::NtpController < ApplicationController
  def sync
    render json: {
      utc_time: Time.now.utc.iso8601(6),
      timestamp: Time.now.to_f
    }
  end
end
```

## Flutter Client Implementation

```dart
class BKTime {
  late double _serverTimestamp;
  late double _localUptimeAtSync;

  Future<void> sync() async {
    final response = await dio.get('/api/v1/ntp/sync');
    _serverTimestamp = response.data['timestamp'];
    _localUptimeAtSync = _getDeviceUptime();
  }

  DateTime get now {
    final elapsed = _getDeviceUptime() - _localUptimeAtSync;
    final bkTimestamp = _serverTimestamp + elapsed;
    return DateTime.fromMillisecondsSinceEpoch(
      (bkTimestamp * 1000).toInt(),
      isUtc: true,
    );
  }

  double _getDeviceUptime() {
    // Platform channel to native uptime API
    // Android: SystemClock.elapsedRealtime()
    // iOS: ProcessInfo.processInfo.systemUptime
  }
}
```

## Sync Schedule

| Event | Action |
|---|---|
| App launch | Sync immediately |
| Every 30 minutes | Background re-sync |
| Before time-locked content unlock | Forced re-sync |
| Network reconnect | Forced re-sync |

## Time-Lock Enforcement

When a greeting card or scheduled content has `unlock_at` set:

1. Client checks `BKTime.now >= content.unlock_at`
2. If not yet unlocked: display countdown using BK Time
3. If unlocked: decrypt and display content
4. The server **also** validates the time on API requests — even if the client is compromised, the server will not return content before `unlock_at`

## Timezone Override

Vault owners can specify that content unlocks at a specific timezone regardless of the viewer's location:

```json
{
  "unlock_at": "2026-12-25T09:00:00Z",
  "timezone_override": "Asia/Tokyo"
}
```

The countdown display adjusts to show the target timezone, while the actual enforcement remains UTC-based.

## Preload Protocol

For greeting cards, encrypted content is **silently downloaded** before the unlock time:

1. Rails sends FCM silent push notification to trigger download
2. Flutter client downloads encrypted payload and stores in secure storage
3. Download timestamp (UTC) and viewer's timezone are recorded in audit logs
4. At unlock time, the client decrypts locally using a key fetched from the server
5. First-open timestamp and face snapshot are sent to audit logs
