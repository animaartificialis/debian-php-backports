.PHONY: test-install

# Install test: the stock package is unpatched, the patched package upgrades it and works.
test-install:
	@targets="$(TEST_TARGETS)"; \
	[ -n "$$targets" ] || targets=$$(cd ../targets && find . -mindepth 2 -maxdepth 2 -type d | sed 's|^\./||' | sort -V); \
	for target in $$targets; do \
		echo "==> test-install $$target"; \
		install/run.sh $$target || exit 1; \
	done
