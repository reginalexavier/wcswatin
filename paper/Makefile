# Uses the official openjournals/inara Docker image for JOSS paper compilation


.PHONY: help paper view clean shell all

# Settings
DOCKER_IMAGE := openjournals/inara
JOSS_DIR := .
USER_ID := $(shell id -u)
GROUP_ID := $(shell id -g)

# Detect operating system for opening PDFs
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Linux)
	OPEN_CMD := xdg-open
endif
ifeq ($(UNAME_S),Darwin)
	OPEN_CMD := open
endif
ifeq ($(OS),Windows_NT)
	OPEN_CMD := start
endif

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[0;33m
NC := \033[0m # No Color

help: ## Shows this help message
	@echo "$(BLUE)wcswatin-paper - Makefile$(NC)"
	@echo ""
	@echo "$(GREEN)Available commands:$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(BLUE)Examples:$(NC)"
	@echo "  make paper    # Compiles the JOSS paper"
	@echo "  make clean    # Removes generated files"
	@echo ""

paper: ## Compiles the JOSS paper using Docker
	@echo "$(BLUE)Compiling JOSS paper...$(NC)"
	@if [ ! -f "$(JOSS_DIR)/paper.md" ]; then \
		echo "$(YELLOW)Error: $(JOSS_DIR)/paper.md not found!$(NC)"; \
		exit 1; \
	fi
	@docker run --rm \
		--volume $(PWD)/$(JOSS_DIR):/data \
		--user $(USER_ID):$(GROUP_ID) \
		--env JOURNAL=joss \
		$(DOCKER_IMAGE)
	@if [ -f "$(JOSS_DIR)/paper.pdf" ]; then \
		echo "$(GREEN) Paper compiled successfully!$(NC)"; \
		echo "$(GREEN)  File: $(JOSS_DIR)/paper.pdf$(NC)"; \
	else \
		echo "$(YELLOW) Compilation failed. Check errors above.$(NC)"; \
		exit 1; \
	fi

check: ## Verifies if the paper is in correct format
	@echo "$(BLUE)Checking paper format...$(NC)"
	@if [ ! -f "$(JOSS_DIR)/paper.md" ]; then \
		echo "$(YELLOW) paper.md not found$(NC)"; \
		exit 1; \
	else \
		echo "$(GREEN) paper.md found$(NC)"; \
	fi
	@if [ ! -f "$(JOSS_DIR)/paper.bib" ]; then \
		echo "$(YELLOW) paper.bib not found$(NC)"; \
		exit 1; \
	else \
		echo "$(GREEN) paper.bib found$(NC)"; \
	fi
	@if grep -q "^title:" "$(JOSS_DIR)/paper.md"; then \
		echo "$(GREEN) YAML metadata found$(NC)"; \
	else \
		echo "$(YELLOW) YAML metadata missing$(NC)"; \
		exit 1; \
	fi
	@echo "$(GREEN) Basic format is correct$(NC)"

wc: ## Counts words in the paper (requires pandoc)
	@if [ ! -f "$(JOSS_DIR)/paper.md" ]; then \
		echo "$(YELLOW)Error: $(JOSS_DIR)/paper.md not found!$(NC)"; \
		exit 1; \
	fi
	@echo "$(BLUE)Counting words in paper...$(NC)"
	@if command -v pandoc >/dev/null 2>&1; then \
		WORD_COUNT=$$(pandoc $(JOSS_DIR)/paper.md -t plain --strip-comments 2>/dev/null | wc -w | tr -d ' '); \
		echo "$(GREEN)Words: $$WORD_COUNT$(NC)"; \
		echo ""; \
		if [ $$WORD_COUNT -lt 250 ]; then \
			echo "$(YELLOW) Warning: Paper is below recommended minimum (250 words)$(NC)"; \
			NEEDED=$$((250 - $$WORD_COUNT)); \
			echo "$(YELLOW)  Approximately $$NEEDED words needed$(NC)"; \
		elif [ $$WORD_COUNT -gt 1000 ]; then \
			echo "$(YELLOW) Warning: Paper is above recommended maximum (1000 words)$(NC)"; \
			EXCESS=$$(($$WORD_COUNT - 1000)); \
			echo "$(YELLOW)  Approximately $$EXCESS words over limit$(NC)"; \
		else \
			echo "$(GREEN) Word count is within JOSS limit (250-1000)$(NC)"; \
		fi; \
		echo ""; \
		echo "$(BLUE)Distribution by section:$(NC)"; \
		grep -E '^#+ ' $(JOSS_DIR)/paper.md | while read line; do \
			echo "  $$line"; \
		done; \
	else \
		echo "$(YELLOW) Pandoc not found. Using approximate count...$(NC)"; \
		WORD_COUNT=$$(grep -v '^---' $(JOSS_DIR)/paper.md | grep -v '^$$' | wc -w | tr -d ' '); \
		echo "$(GREEN)Words (approximate): $$WORD_COUNT$(NC)"; \
		echo "$(YELLOW)For accurate count, install pandoc:$(NC)"; \
		echo "  Ubuntu/Debian: sudo apt-get install pandoc"; \
		echo "  macOS: brew install pandoc"; \
	fi

view: ## Opens the paper PDF in the default viewer
	@if [ ! -f "$(JOSS_DIR)/paper.pdf" ]; then \
		echo "$(YELLOW) PDF not found. Run 'make paper' first.$(NC)"; \
		exit 1; \
	fi
	@echo "$(BLUE)Opening $(JOSS_DIR)/paper.pdf...$(NC)"
	@$(OPEN_CMD) $(JOSS_DIR)/paper.pdf 2>/dev/null || \
		(echo "$(YELLOW) Could not open PDF automatically.$(NC)" && \
		 echo "$(YELLOW)  Open manually: $(JOSS_DIR)/paper.pdf$(NC)")

clean: ## Removes PDF and temporary JOSS files
	@echo "$(BLUE)Cleaning generated files...$(NC)"
	@rm -f $(JOSS_DIR)/paper.pdf
	@rm -f $(JOSS_DIR)/paper.jats
	@rm -rf $(JOSS_DIR)/jats/
	@echo "$(GREEN) Files removed$(NC)"

shell: ## Opens an interactive shell in the Docker container
	@echo "$(BLUE)Starting shell in container...$(NC)"
	@docker run --rm -it \
		--volume $(PWD)/$(JOSS_DIR):/data \
		--user $(USER_ID):$(GROUP_ID) \
		--env JOURNAL=joss \
		--entrypoint /bin/sh \
		$(DOCKER_IMAGE)

docker-pull: ## Updates the JOSS Docker image
	@echo "$(BLUE)Updating Docker image...$(NC)"
	@docker pull $(DOCKER_IMAGE)
	@echo "$(GREEN) Image updated$(NC)"

docker-info: ## Shows information about the Docker image
	@echo "$(BLUE)Docker image information:$(NC)"
	@docker images $(DOCKER_IMAGE)
	@echo ""
	@docker inspect $(DOCKER_IMAGE) | grep -A 5 "Created"

all: check paper ## Verifies and compiles the paper

paper-view: paper view ## Compiles and opens the PDF automatically
.DEFAULT_GOAL := help
