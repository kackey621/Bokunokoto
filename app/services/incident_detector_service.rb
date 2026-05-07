class IncidentDetectorService
  RAPID_ACCESS_THRESHOLD = 10 # accesses per minute
  GEO_JUMP_THRESHOLD = 500 # km in 1 hour
  GEOS_WINDOW = 1.hour

  def self.analyze_user_activity(vault, user)
    service = new(vault, user)
    service.detect_anomalies
  end

  def initialize(vault, user)
    @vault = vault
    @user = user
    @recent_logs = AuditLog.where(user_id: user.id, vault_id: vault.id)
                            .where('occurred_at > ?', 1.day.ago)
                            .order(occurred_at: :desc)
  end

  def detect_anomalies
    incidents = []
    incidents.concat(detect_rapid_access)
    incidents.concat(detect_geo_jump)
    incidents.concat(detect_gps_denials)
    incidents.concat(detect_auth_failures)
    incidents
  end

  private

  def detect_rapid_access
    last_hour = @recent_logs.where('occurred_at > ?', 1.hour.ago)
    if last_hour.count > RAPID_ACCESS_THRESHOLD
      [create_incident(
        "rapid_access",
        "High-frequency access detected",
        Incident::SEVERITIES[ :medium ],
        { access_count: last_hour.count }
      )]
    else
      []
    end
  end

  def detect_geo_jump
    incidents = []
    logs_with_geo = @recent_logs.where.not(latitude: nil, longitude: nil)
                                 .limit(10)

    logs_with_geo.each_cons(2) do |prev_log, curr_log|
      next if (curr_log.occurred_at - prev_log.occurred_at) > GEOS_WINDOW

      distance = haversine_distance(
        prev_log.latitude, prev_log.longitude,
        curr_log.latitude, curr_log.longitude
      )

      if distance > GEO_JUMP_THRESHOLD
        incidents << create_incident(
          "geo_jump",
          "Geographic anomaly: #{distance.round}km jump detected",
          Incident::SEVERITIES[ :high ],
          { distance_km: distance.round, from: "#{prev_log.latitude},#{prev_log.longitude}",
            to: "#{curr_log.latitude},#{curr_log.longitude}" }
        )
      end
    end

    incidents
  end

  def detect_gps_denials
    recent_denials = @recent_logs.where(action: "gps_denied")
                                  .where("occurred_at > ?", 24.hours.ago)

    if recent_denials.count > 3
      [create_incident(
        "gps_denial",
        "Multiple GPS access denials",
        Incident::SEVERITIES[ :medium ],
        { denial_count: recent_denials.count }
      )]
    else
      []
    end
  end

  def detect_auth_failures
    recent_failures = @recent_logs.where(action: "auth_failed")
                                   .where("occurred_at > ?", 1.hour.ago)

    if recent_failures.count > 5
      [create_incident(
        "auth_failure",
        "Multiple authentication failures",
        Incident::SEVERITIES[ :high ],
        { failure_count: recent_failures.count }
      )]
    else
      []
    end
  end

  def create_incident(type, description, severity, context)
    Incident.create!(
      vault: @vault,
      user: @user,
      incident_type: type,
      description: description,
      severity: severity,
      context: context
    )
  end

  def haversine_distance(lat1, lon1, lat2, lon2)
    earth_radius = 6371 # km

    lat1_rad = degrees_to_radians(lat1)
    lat2_rad = degrees_to_radians(lat2)
    delta_lat = degrees_to_radians(lat2 - lat1)
    delta_lon = degrees_to_radians(lon2 - lon1)

    a = Math.sin(delta_lat / 2) ** 2 +
        Math.cos(lat1_rad) * Math.cos(lat2_rad) * Math.sin(delta_lon / 2) ** 2
    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))

    earth_radius * c
  end

  def degrees_to_radians(degrees)
    degrees * Math::PI / 180
  end
end
