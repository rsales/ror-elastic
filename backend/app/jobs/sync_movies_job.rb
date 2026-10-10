class SyncMoviesJob < ApplicationJob
  queue_as :default

  def perform(pages: nil, reset_index: false)
    Tmdb::SyncMoviesService.new(pages: pages, reset_index: reset_index).call
  end
end
