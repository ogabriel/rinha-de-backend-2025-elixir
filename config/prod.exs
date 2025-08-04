import Config

config :rinha,
  default_processor: "http://payment-processor-default:8080",
  fallback_processor: "http://payment-processor-fallback:8080"
