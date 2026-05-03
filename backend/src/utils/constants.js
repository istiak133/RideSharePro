// ============================================
// RideShare AI Pro — Constants
// All enums, magic numbers, config values
// ============================================

module.exports = {
  // User roles
  ROLES: {
    RIDER: 'rider',
    DRIVER: 'driver',
  },

  // User status
  USER_STATUS: {
    ACTIVE: 'active',
    BLOCKED: 'blocked',
  },

  // Driver status
  DRIVER_STATUS: {
    ONLINE: 'online',
    OFFLINE: 'offline',
    BREAK: 'break',
    BUSY: 'busy',
  },

  // Driver verification status
  VERIFICATION_STATUS: {
    PENDING: 'pending',
    APPROVED: 'approved',
    REJECTED: 'rejected',
  },

  // Ride status (lifecycle)
  RIDE_STATUS: {
    SCHEDULED: 'scheduled',
    SEARCHING_DRIVER: 'searching_driver',
    DRIVER_ASSIGNED: 'driver_assigned',
    DRIVER_ON_WAY: 'driver_on_way',
    ARRIVED: 'arrived',
    STARTED: 'started',
    COMPLETED: 'completed',
    CANCELLED: 'cancelled',
  },

  // Payment methods
  PAYMENT_METHOD: {
    CASH: 'cash',
    CARD: 'card',
  },

  // Payment status
  PAYMENT_STATUS: {
    PENDING: 'pending',
    COMPLETED: 'completed',
    FAILED: 'failed',
    DISPUTED: 'disputed',
  },

  // Ride request response
  RIDE_REQUEST_RESPONSE: {
    PENDING: 'pending',
    ACCEPTED: 'accepted',
    DECLINED: 'declined',
    EXPIRED: 'expired',
  },

  // Admin roles
  ADMIN_ROLES: {
    SUPER_ADMIN: 'super_admin',
    VERIFIER: 'verifier',
  },

  // Vehicle types (MVP = Car only)
  VEHICLE_TYPES: {
    CAR: 'car',
  },

  // Fare rules (default seed values)
  DEFAULT_FARE_RULES: {
    car: {
      base_fare: 80,
      distance_rate: 30,   // per km
      time_rate: 2,        // per minute
      minimum_fare: 100,
    },
  },

  // Commission split
  COMMISSION: {
    PLATFORM_PERCENTAGE: 25,  // 25%
    DRIVER_PERCENTAGE: 75,    // 75%
  },

  // OTP config
  OTP: {
    LENGTH: 4,                      // 4-digit OTP for pickup
    REGISTRATION_LENGTH: 6,         // 6-digit OTP for registration
    EXPIRY_MINUTES: 5,
    MAX_ATTEMPTS: 3,
    RATE_LIMIT_PER_HOUR: 5,
    IP_RATE_LIMIT_PER_HOUR: 50,
  },

  // Driver search config
  DRIVER_SEARCH: {
    INITIAL_RADIUS_KM: 5,
    EXPANDED_RADIUS_KM: 10,
    MAX_DRIVERS_TO_NOTIFY: 10,
    SEARCH_TIMEOUT_SECONDS: 120, // 2 minutes
    REQUEST_TIMEOUT_SECONDS: 30,
  },

  // Surge pricing thresholds
  SURGE: {
    THRESHOLDS: [
      { ratio: 3.0, multiplier: 2.5 },
      { ratio: 2.5, multiplier: 1.8 },
      { ratio: 2.0, multiplier: 1.5 },
      { ratio: 1.5, multiplier: 1.2 },
    ],
    MAX_MULTIPLIER: 3.0,
    CACHE_TTL_SECONDS: 60,
  },

  // Rating config
  RATING: {
    MIN_STARS: 1,
    MAX_STARS: 5,
    LOW_RATING_THRESHOLD: 4.0,    // below this = lower priority
    REVIEW_FLAG_THRESHOLD: 3.5,    // below this = admin review
  },

  // Settlement
  SETTLEMENT: {
    DEFAULT_PERIOD: 'weekly',       // 'weekly' or 'monthly'
    OVERDUE_DAYS: 7,
    TRUSTED_DRIVER_RATING: 4.7,
    TRUSTED_DRIVER_MONTHS: 6,
  },

  // Notification types
  NOTIFICATION_TYPES: {
    DRIVER_ACCEPTED: 'driver_accepted',
    DRIVER_ON_WAY: 'driver_on_way',
    DRIVER_ARRIVED: 'driver_arrived',
    RIDE_STARTED: 'ride_started',
    RIDE_COMPLETED: 'ride_completed',
    PAYMENT_CONFIRMED: 'payment_confirmed',
    NEW_RIDE_REQUEST: 'new_ride_request',
    RIDE_CANCELLED: 'ride_cancelled',
    DOCUMENT_APPROVED: 'document_approved',
    DOCUMENT_REJECTED: 'document_rejected',
    SCHEDULED_RIDE_REMINDER: 'scheduled_ride_reminder',
  },
};
