# Targets are named <release>/<php>, e.g. debian8-jessie/php5.6-debian.
TARGETS := $(shell cd targets && find . -mindepth 2 -maxdepth 2 -type d | sed 's|^\./||' | sort -V)

.PHONY: help list test

help:
	@echo "make list                     list all build targets"
	@echo "make build-<release>/<php>    build the image and the packages into dist/<release>/<php>/"
	@echo "make image-<release>/<php>    build only the builder image"
	@echo "make fetch-patches-<target>   refresh a target's Sury patch from packages.sury.org"
	@echo "make test                     install test of built packages in a clean container"

list:
	@printf '%s\n' $(TARGETS)

# Pattern rules cannot take a stem containing '/', so define the rules per target.
define target_rules
.PHONY: build-$(1) image-$(1) fetch-patches-$(1)
build-$(1):
	build/build.sh $(1) all
image-$(1):
	build/build.sh $(1) image
fetch-patches-$(1):
	build/fetch-sury-patches.sh $(1)
endef
$(foreach t,$(TARGETS),$(eval $(call target_rules,$(t))))

test:
	$(MAKE) -C tests
