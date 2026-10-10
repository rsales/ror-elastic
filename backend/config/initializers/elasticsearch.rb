# Keep Elasticsearch connection settings in one place for the API and ingestion tasks.
Elasticsearch::Model.client = Elasticsearch::Client.new(
  url: ENV.fetch('ELASTICSEARCH_URL', 'http://localhost:9200')
)
