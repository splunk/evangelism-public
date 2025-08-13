.PHONY: launch
launch:
	docker compose up --build

.PHONY: destroy
destroy:
	docker compose down -v

.PHONY: restart
restart: destroy launch
