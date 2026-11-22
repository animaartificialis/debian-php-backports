# Reproducers for the six larger PHP 5.4 fixes that the -compat targets leave out.
# A normal 5.4 target must pass every case (FIXED); a -compat target must pass none.
# Other targets are skipped.
.PHONY: test-php54-extended

test-php54-extended:
	@targets="$(TEST_TARGETS)"; \
	[ -n "$$targets" ] || targets=$$(cd ../targets && find . -mindepth 2 -maxdepth 2 -type d | sed 's|^\./||' | sort -V); \
	for target in $$targets; do \
		case "$$target" in \
			*/php5.4-*-compat) expect=unfixed ;; \
			*/php5.4-*) expect=fixed ;; \
			*) continue ;; \
		esac; \
		echo "==> test-php54-extended $$target (expect $$expect)"; \
		php54-extended/run.sh $$target $$expect || exit 1; \
	done
