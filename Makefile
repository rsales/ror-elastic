.PHONY: up down logs backend frontend kibana elastic

up:
	docker compose up -d

down:
	docker compose down

logs:
	docker compose logs -f

backend:
	cd backend && rails s

frontend:
	cd frontend && pnpm dev --port 3001

elastic:
	open http://localhost:9200

kibana:
	open http://localhost:5601