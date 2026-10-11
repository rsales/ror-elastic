class Api::HealthController < ApplicationController
  def show
    cluster = Movie.__elasticsearch__.client.cluster.health
    render json: { status: "ok", es: cluster["status"] || "unknown" }
  rescue StandardError => e
    Rails.logger.warn("[HealthController] Elasticsearch unreachable: #{e.class}: #{e.message}\n#{e.backtrace&.first(10)&.join("\n")}")
    render json: { status: "degraded", es: "unreachable" }, status: :service_unavailable
  end
end
