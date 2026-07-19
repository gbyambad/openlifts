# OpenLifts developer tasks. Codegen output (*.g.dart, *.freezed.dart) is
# git-ignored, so a fresh clone must run `make setup` before the app compiles,
# and codegen must be re-run after editing any @riverpod / @freezed / Drift
# table. `make watch` does that continuously during development.
#
# Run `make` (or `make help`) to list targets.

.DEFAULT_GOAL := help
.PHONY: help setup get gen watch hooks format analyze test check run run-android run-ios clean

help: ## List available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	  | awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'

setup: get gen hooks ## Fresh-clone setup: deps + codegen + git hooks

get: ## Fetch Dart/Flutter dependencies
	flutter pub get

gen: ## Run codegen once (build_runner)
	dart run build_runner build --delete-conflicting-outputs

watch: ## Run codegen continuously (keep running during development)
	dart run build_runner watch --delete-conflicting-outputs

hooks: ## Activate the version-controlled git hooks (.githooks)
	git config core.hooksPath .githooks

format: ## Format all Dart sources
	dart format .

analyze: ## Static analysis (must be clean)
	flutter analyze

test: ## Run the test suite
	flutter test

check: format analyze test ## Format + analyze + test (the definition of done)

run: ## Launch the app on the default device
	flutter run

run-android: ## Boot the `openlifts` Android emulator and launch on it
	@flutter emulators --launch openlifts || true
	flutter run -d emulator-5554

run-ios: ## Launch on an iOS simulator
	flutter run -d ios

clean: ## Remove build artifacts and re-fetch dependencies
	flutter clean && flutter pub get
