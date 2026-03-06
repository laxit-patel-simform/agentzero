.PHONY: help list deploy doctor verify

help:
	@echo "AgentZero: Awesome Copilot PHP Agents"
	@echo "Usage: make [command]"
	@echo ""
	@echo "Commands:"
	@echo "  list        List all available Agents"
	@echo "  deploy      Deploy an agent (e.g., make deploy AGENT=example-php-agent)"
	@echo "  doctor      Check local environment for dependencies"
	@echo "  verify      Run structural and integrity tests on all agents"

list:
	@./bin/agentzero.sh list

deploy:
	@./bin/agentzero.sh deploy $(AGENT)

doctor:
	@./bin/agentzero.sh doctor

verify:
	@./bin/verify.sh
