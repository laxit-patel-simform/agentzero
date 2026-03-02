.PHONY: help list deploy doctor verify

help:
	@echo "AgentZero: Awesome Copilot PHP Agent Packs"
	@echo "Usage: make [command]"
	@echo ""
	@echo "Commands:"
	@echo "  list        List all available Agent Packs"
	@echo "  deploy      Deploy a pack (e.g., make deploy PACK=example-php-pack)"
	@echo "  doctor      Check local environment for dependencies"
	@echo "  verify      Run structural and integrity tests on all packs"

list:
	@./bin/agentzero.sh list

deploy:
	@./bin/agentzero.sh deploy $(PACK)

doctor:
	@./bin/agentzero.sh doctor

verify:
	@./bin/verify.sh
