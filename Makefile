.PHONY: help list deploy doctor verify

help:
	@echo "SimPrompt: Awesome Copilot PHP Agent Packs"
	@echo "Usage: make [command]"
	@echo ""
	@echo "Commands:"
	@echo "  list        List all available Agent Packs"
	@echo "  deploy      Deploy a pack (e.g., make deploy PACK=example-php-pack)"
	@echo "  doctor      Check local environment for dependencies"
	@echo "  verify      Run structural and integrity tests on all packs"

list:
	@./bin/simprompt.sh list

deploy:
	@./bin/simprompt.sh deploy $(PACK)

doctor:
	@./bin/simprompt.sh doctor

verify:
	@./bin/verify.sh
