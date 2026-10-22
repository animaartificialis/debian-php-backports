# Test runner. Load public defaults first, then local overrides.
include .env.dist
-include .env
export

.DEFAULT_GOAL := test
.PHONY: test

-include */include.mk

test: test-install
