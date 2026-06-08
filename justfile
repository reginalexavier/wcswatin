# Show this help
help:
    @printf '\033[0;32mWCSWATIN - Available commands:\033[0m\n\n'
    @just --list --unsorted --list-heading '' --list-prefix '  '
    @printf "\n"

# Run deps, doc, check, and test
all: deps doc check test

# Install package dependencies
deps:
    Rscript -e "if (!require('pak', quietly = TRUE)) install.packages('pak', repos=c('https://r-lib.github.io/p/pak/stable', 'https://cran.r-project.org/')); pak::local_install_deps(dependencies = TRUE)"

# Install development dependencies
deps-dev:
    Rscript -e "if (!require('pak', quietly = TRUE)) install.packages('pak', repos=c('https://r-lib.github.io/p/pak/stable', 'https://cran.r-project.org/')); pak::local_install_dev_deps()"

# Install optional dependencies
deps-optional:
    Rscript -e "if (!require('pak', quietly = TRUE)) install.packages('pak', repos = c('https://r-lib.github.io/p/pak/stable', 'https://cran.r-project.org'))"
    Rscript -e "pak::pkg_install(c('urlchecker','withr','checkhelper','spelling','usethis','rhub','devtools'), ask = FALSE)"

# Run code linting
lint:
    Rscript -e "if (!require('lintr')) install.packages('lintr'); devtools::load_all('.', quiet = TRUE); lintr::lint_package()"

# Format code with styler
format:
    Rscript -e "if (!require('styler')) install.packages('styler'); styler::style_pkg()"
    air format .

# Load package for development
load:
    Rscript -e "devtools::load_all()"

# Generate documentation
doc:
    Rscript -e "devtools::document()"
    Rscript -e "codemetar::write_codemeta()"

# Run tests
test:
    Rscript -e "devtools::test(reporter = 'summary')"

# Run R CMD check
check:
    Rscript -e "devtools::check(args = c('--no-manual', '--as-cran'))"

# Run R CMD check like on CRAN
check-cran:
    Rscript -e "withr::with_options(list(repos = c(CRAN = 'https://cloud.r-project.org/')), {callr::default_repos(); rcmdcheck::rcmdcheck(args = c('--no-manual', '--as-cran'))})"

# Generate test coverage report
coverage:
    Rscript -e "if (!require('covr')) install.packages('covr'); covr::package_coverage()"

# Build package
build:
    Rscript -e "devtools::build()"

install:
    Rscript -e "devtools::install()"

# Render the CRAN-safe vignette
vignette:
    Rscript -e "rmarkdown::render('vignettes/wcswatin.Rmd')"

# Build pkgdown articles
articles:
    Rscript -e "if (!require('pkgdown', quietly = TRUE)) install.packages('pkgdown', repos='https://cran.r-project.org/')"
    Rscript -e "pkgdown::build_articles(lazy = FALSE, preview = FALSE)"

# Build vignettes and articles for visual inspection
vignettes: vignette articles

# Clean build artifacts
clean:
    Rscript -e "devtools::clean_dll()"
    rm -rf *.tar.gz
    rm -rf man/*.Rd~

# Run CI pipeline (deps, lint, check, test, coverage)
ci: deps lint check test coverage

# Prepare package for release/CRAN (clean, deps, doc, build, check-cran, test)
release: clean deps doc build check-cran test
    @echo "Package ready for release"

# Install pre-commit hooks
pci:
    pre-commit install

# Run pre-commit hooks on all files
pcr:
    pre-commit run --all-files

# Update pre-commit hooks to the latest versions
pcu:
    pre-commit autoupdate

# Clean pre-commit cache
pcc:
    pre-commit clean

# Render README.Rmd to markdown
knit-readme:
    Rscript -e "rmarkdown::render('README.Rmd', output_format = 'github_document')"

# Build pkgdown site
pkgdown-build:
    Rscript -e "if (!require('pkgdown', quietly = TRUE)) install.packages('pkgdown', repos='https://cran.r-project.org/')"
    Rscript -e "pkgdown::build_site_github_pages(new_process = FALSE, install = FALSE)"

# Check pkgdown
pkgdown-check:
    Rscript -e "pkgdown::check_pkgdown()"
