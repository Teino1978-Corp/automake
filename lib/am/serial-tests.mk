## automake - create Makefile.in from Makefile.am
## Copyright (C) 2001-2014 Free Software Foundation, Inc.

## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2, or (at your option)
## any later version.

## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.

## You should have received a copy of the GNU General Public License
## along with this program.  If not, see <http://www.gnu.org/licenses/>.

## Obsolescent serial testsuite driver.

ifdef EXEEXT
## This is suboptimal, but we need to preserve the order of $(TESTS).
am.test-suite.cook-with-exeext.helper = \
    $(if $(filter $(am.all-progs), $1), $1$(EXEEXT), $1)
am.test-suite.cook-with-exeext = \
    $(strip $(foreach t, $1, $(call $0.helper, $t)))
else
am.test-suite.cook-with-exeext = $(strip $1)
endif

# TESTS can contain compiled programs, in which case we might have
# to account for $(EXEEXT) appending.  For matching purposes, we
# need to adjust XFAIL_TESTS as well.
am__cooked_tests = \
  $(call am.test-suite.cook-with-exeext, $(TESTS))
am__cooked_xfail_tests = \
  $(call am.test-suite.cook-with-exeext, $(XFAIL_TESTS))

.PHONY: check-TESTS
check-TESTS: $(am__cooked_tests)
	@failed=0; all=0; xfail=0; xpass=0; skip=0; \
	srcdir=$(srcdir); export srcdir; \
	list='$(am__cooked_tests)'; \
	$(am.test-suite.tty-colors); \
	is_xfail_test () { \
	  case " $(strip $(am__cooked_xfail_tests)) " in \
	    *" $$tst "*) return 0;; \
	    *) return 1;; \
	  esac; \
	}; \
	test -n "$$list" || exit 0; \
## Run the tests one by one in series, collecting their results.
	for tst in $$list; do \
	  if test -f ./$$tst; then dir=./; \
## For VPATH support.
	  else dir="$(srcdir)/"; fi; \
	  if $(TESTS_ENVIRONMENT) $${dir}$$tst $(AM_TESTS_FD_REDIRECT); then \
## Success.
	    all=`expr $$all + 1`; \
	    if is_xfail_test; then \
	      xpass=`expr $$xpass + 1`; \
	      failed=`expr $$failed + 1`; \
	      col=$$red; res=XPASS; \
	    else \
	      col=$$grn; res=PASS; \
	    fi; \
	  elif test $$? -ne 77; then \
## Failure.  Expected or unexpected?
	    all=`expr $$all + 1`; \
	    if is_xfail_test; then \
## Expected failure (XFAIL).
	      xfail=`expr $$xfail + 1`; \
	      col=$$lgn; res=XFAIL; \
	    else \
## Unexpected failure (FAIL).
	      failed=`expr $$failed + 1`; \
	      col=$$red; res=FAIL; \
	    fi; \
	  else \
## Test skipped.
	    skip=`expr $$skip + 1`; \
	    col=$$blu; res=SKIP; \
	  fi; \
## Report this single result on stdout.
	  echo "$${col}$$res$${std}: $$tst"; \
	done; \
## Done running the tests.  Will now have to display the global
## outcome, with proper formatting.
## Let's start preparing the banner.
	if test "$$all" -eq 1; then \
	  tests="test"; \
	  All=""; \
	else \
	  tests="tests"; \
	  All="All "; \
	fi; \
	if test "$$failed" -eq 0; then \
	  if test "$$xfail" -eq 0; then \
	    banner="$$All$$all $$tests passed"; \
	  else \
	    if test "$$xfail" -eq 1; then failures=failure; else failures=failures; fi; \
	    banner="$$All$$all $$tests behaved as expected ($$xfail expected $$failures)"; \
	  fi; \
	else \
	  if test "$$xpass" -eq 0; then \
	    banner="$$failed of $$all $$tests failed"; \
	  else \
	    if test "$$xpass" -eq 1; then passes=pass; else passes=passes; fi; \
	    banner="$$failed of $$all $$tests did not behave as expected ($$xpass unexpected $$passes)"; \
	  fi; \
	fi; \
## DASHES should contain the largest line of the banner.
	dashes="$$banner"; \
	skipped=""; \
	if test "$$skip" -ne 0; then \
	  if test "$$skip" -eq 1; then \
	    skipped="($$skip test was not run)"; \
	  else \
	    skipped="($$skip tests were not run)"; \
	  fi; \
	  test `echo "$$skipped" | wc -c` -le `echo "$$banner" | wc -c` || \
	    dashes="$$skipped"; \
	fi; \
	report=""; \
	if test "$$failed" -ne 0 && test -n "$(PACKAGE_BUGREPORT)"; then \
	  report="Please report to $(PACKAGE_BUGREPORT)"; \
	  test `echo "$$report" | wc -c` -le `echo "$$banner" | wc -c` || \
	    dashes="$$report"; \
	fi; \
	dashes=`echo "$$dashes" | sed s/./=/g`; \
	if test "$$failed" -eq 0; then \
	  col="$$grn"; \
	else \
	  col="$$red"; \
	fi; \
## Multi line coloring is problematic with "less -R", so we really need
## to color each line individually.
	echo "$${col}$$dashes$${std}"; \
	echo "$${col}$$banner$${std}"; \
	test -z "$$skipped" || echo "$${col}$$skipped$${std}"; \
	test -z "$$report" || echo "$${col}$$report$${std}"; \
	echo "$${col}$$dashes$${std}"; \
	test "$$failed" -eq 0 || exit 1