# Reproducers for the fixes that only the PHP 5.4 extended targets have.
# An extended target must pass every case (FIXED); a normal 5.4 target must pass none
# (so the extra fixes stay in the extended variant). Other targets are skipped.
.PHONY: test-php54-extended

test-php54-extended:
	@targets="$(TEST_TARGETS)"; \
	[ -n "$$targets" ] || targets=$$(cd ../targets && find . -mindepth 2 -maxdepth 2 -type d | sed 's|^\./||' | sort -V); \
	for target in $$targets; do \
		case "$$target" in \
			*/php5.4-*-extended) expect=fixed ;; \
			*/php5.4-*) expect=unfixed ;; \
			*) continue ;; \
		esac; \
		echo "==> test-php54-extended $$target (expect $$expect)"; \
		php54-extended/run.sh $$target $$expect || exit 1; \
	done
