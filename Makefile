.PHONY: all lint format load check doc install test clean build coverage vignettes deps deps-dev ci release help

# Default target
all: deps doc check test

# Dependencies management
deps:
		Rscript -e "if (!require('devtools')) install.packages('devtools'); devtools::install_deps(dependencies = TRUE)"

deps-dev:
		Rscript -e "if (!require('devtools')) install.packages('devtools'); devtools::install_dev_deps()"

# Code quality
lint:
		Rscript -e "if (!require('lintr')) install.packages('lintr'); lintr::lint_package()"

format:
		Rscript -e "if (!require('styler')) install.packages('styler'); styler::style_pkg()"

# Development
load:
		Rscript -e "devtools::load_all()"

doc:
		Rscript -e "devtools::document()"

# Testing and checking
test:
		Rscript -e "devtools::test(reporter = 'summary')"

check:
		Rscript -e "devtools::check(error_on = 'warning')"

coverage:
		Rscript -e "if (!require('covr')) install.packages('covr'); covr::package_coverage()"

# Building and installation
build:
		Rscript -e "devtools::build()"

install:
		Rscript -e "devtools::install()"

vignettes:
		Rscript -e "devtools::build_vignettes()"

# Cleanup
clean:
		Rscript -e "devtools::clean_dll()"
		rm -rf *.tar.gz
		rm -rf man/*.Rd~

# CI/CD targets
ci: deps lint check test coverage

release: clean deps doc build check
		@echo "Package ready for release"

# Help
help:
		@echo "Available targets:"
		@echo "  all       - Run deps, doc, check, and test"
		@echo "  deps      - Install package dependencies"
		@echo "  deps-dev  - Install development dependencies"
		@echo "  lint      - Run code linting"
		@echo "  format    - Format code with styler"
		@echo "  load      - Load package for development"
		@echo "  check     - Run R CMD check"
		@echo "  doc       - Generate documentation"
		@echo "  install   - Install package"
		@echo "  test      - Run tests"
		@echo "  coverage  - Generate test coverage report"
		@echo "  build     - Build package"
		@echo "  vignettes - Build vignettes"
		@echo "  clean     - Clean build artifacts"
		@echo "  ci        - Run CI pipeline (deps, lint, check, test, coverage)"
		@echo "  release   - Prepare package for release"
		@echo "  help      - Show this help"
