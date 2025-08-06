# fast way to start test
# standalone way to do test

backend-%:
	docker compose $(subst backend-,,$@)

backend-up-build:
	docker compose up --build

processor-%:
	docker compose -f ../rinha-de-backend-2025/payment-processor/docker-compose.yml $(subst processor-,,$@)

reset:
	make processor-down
	make backend-down

test:
	make backend-up
	make processor-up
	make start-test

start-test:
	K6_WEB_DASHBOARD=true k6 run ../rinha-de-backend-2025/rinha-test/rinha.js

start-test-low:
	MAX_REQUESTS=100 K6_WEB_DASHBOARD=true k6 run ../rinha-de-backend-2025/rinha-test/rinha.js
