.PHONY: all lint format load check doc install test clean build coverage vignettes deps deps-dev ci release pcr pci pcc knit-readme help

BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m # No Color

help: ## Show this help
	@echo "$(GREEN)WCSWATIN - Available commands:$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(BLUE)%-15s$(NC) %s\n", $$1, $$2}'
	@echo ""


all: ## Run deps, doc, check, and test
		deps doc check test


deps: ## Install package dependencies
		Rscript -e "if (!require('devtools')) install.packages('devtools'); devtools::install_deps(dependencies = TRUE)"

deps-dev: ## Install development dependencies
		Rscript -e "if (!require('devtools')) install.packages('devtools'); devtools::install_dev_deps()"


lint: ## Run code linting
		Rscript -e "if (!require('lintr')) install.packages('lintr'); lintr::lint_package()"

format: ## Format code with styler
		Rscript -e "if (!require('styler')) install.packages('styler'); styler::style_pkg()"
		air format .


load: ## Load package for development
		Rscript -e "devtools::load_all()"

doc: ## Generate documentation
		Rscript -e "devtools::document()"
		Rscript -e "codemetar::write_codemeta()"


test: ## Run tests
		Rscript -e "devtools::test(reporter = 'summary')"

check: ## Run R CMD check
		Rscript -e "devtools::check(error_on = 'warning')"

coverage: ## Generate test coverage report
		Rscript -e "if (!require('covr')) install.packages('covr'); covr::package_coverage()"


build: ## Build package
		Rscript -e "devtools::build()"

install:
		Rscript -e "devtools::install()"

vignettes: ## Build vignettes
		Rscript -e "devtools::build_vignettes()"


clean: ## Clean build artifacts
		Rscript -e "devtools::clean_dll()"
		rm -rf *.tar.gz
		rm -rf man/*.Rd~

ci: deps lint check test coverage ## Run CI pipeline (deps, lint, check, test, coverage)

release: clean deps doc build check test ## Prepare package for release
		@echo "Package ready for release"

pci: ## Install pre-commit hooks
		pre-commit install

pcr: ## Run pre-commit hooks on all files
		pre-commit run --all-files

pcu: ## Update pre-commit hooks to the latest versions
		pre-commit autoupdate

pcc: ## Clean pre-commit cache
		pre-commit clean

knit-readme: ## Render README.Rmd to markdown
		Rscript -e "rmarkdown::render('README.Rmd', output_format = 'github_document')"

pkgdown: ## Package down check
		Rscript -e "pkgdown::check_pkgdown()"
