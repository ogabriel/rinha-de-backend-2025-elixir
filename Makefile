# fast way to start test
# standalone way to do test

exec-%:
	docker compose exec $(subst exec-,,$@) sh

backend-up-build:
	docker compose up --build

backend-%:
	docker compose $(subst backend-,,$@)

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
	K6_WEB_DASHBOARD=true MAX_REQUESTS=550 k6 run ../rinha-de-backend-2025/rinha-test/rinha.js

start-test-low:
	K6_WEB_DASHBOARD=true MAX_REQUESTS=100 k6 run ../rinha-de-backend-2025/rinha-test/rinha.js

start-test-high:
	K6_WEB_DASHBOARD=true MAX_REQUESTS=1100 k6 run ../rinha-de-backend-2025/rinha-test/rinha.js
