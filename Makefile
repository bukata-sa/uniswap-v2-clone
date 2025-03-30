.PHONY: foundry
foundry:
	foundryup --version v0.3.0

.PHONY: foundry-refresh
foundry-refresh: foundry
	git submodule deinit -f .
	git submodule update --init --recursive

.PHONY: build
build:
	forge build