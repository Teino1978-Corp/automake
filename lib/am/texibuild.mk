## automake - create Makefile.in from Makefile.am
## Copyright (C) 1994-2014 Free Software Foundation, Inc.

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

TEXI2DVI = texi2dvi
TEXI2PDF = $(TEXI2DVI) --pdf --batch
DVIPS = dvips
MAKEINFOHTML = $(MAKEINFO) --html
AM_MAKEINFOHTMLFLAGS ?= $(AM_MAKEINFOFLAGS)

define am.texi.build.dvi-or-pdf
	$1$(am.cmd.ensure-target-dir-exists) && \
	TEXINPUTS="$(am__TEXINFO_TEX_DIR)$(PATH_SEPARATOR)$$TEXINPUTS" \
## Must set MAKEINFO like this so that version.texi will be found even
## if it is in srcdir.
	MAKEINFO='$(MAKEINFO) $(AM_MAKEINFOFLAGS) $(MAKEINFOFLAGS) \
	                      -I $(@D) -I $(srcdir)/$(@D)' \
## texi2dvi and  texi2pdf don't silence everything with -q, redirect
## to /dev/null instead.  We still want -q ($(AM_V_TEXI_QUIETOPTS))
## because it turns on batch mode.
## Use '--build-dir' so that TeX and Texinfo auxiliary files and build
## by-products are left in there, instead of cluttering the current
## directory (see automake bug#11146).  Use a different build-dir for
## each file (as well as distinct build-dirs for PDF and DVI files) to
## avoid hitting a Texinfo bug that could cause a low-probability racy
## failure when doing parallel builds; see:
## http://lists.gnu.org/archive/html/automake-patches/2012-06/msg00073.html
	$2 $(AM_V_TEXI_QUIETOPTS) --build-dir=$3 \
	   -o $@ $< $(AM_V_TEXI_DEVNULL_REDIRECT)
endef

define am.texi.build.info
	$(if $1,,$(AM_V_at)$(am.cmd.ensure-target-dir-exists))
## If the texinfo file has some minor mistakes which cause makeinfo
## to fail, the info files are not removed.
	$(AM_V_MAKEINFO)$(MAKEINFO) $(AM_MAKEINFOFLAGS) $(MAKEINFOFLAGS) \
	                --no-split -I $(@D) -I $(srcdir)/$(@D) -o $@-t $<
	$(AM_V_at)mv -f $@-t $@
endef

define am.texi.build.html
	$(AM_V_MAKEINFO)$(am.cmd.ensure-target-dir-exists) \
## When --split (the default) is used, makeinfo will output a
## directory.  However it will not update the time stamp of a
## previously existing directory, and when the names of the nodes
## in the manual change, it may leave unused pages.  Our fix
## is to build under a temporary name, and replace the target on
## success.
	  && { test ! -d $(@:.html=.htp) || rm -rf $(@:.html=.htp); } \
	  || exit 1; \
	if $(MAKEINFOHTML) $(AM_MAKEINFOHTMLFLAGS) $(MAKEINFOFLAGS) \
	                    -I $(@D) -I $(srcdir)/$(@D) \
			    -o $(@:.html=.htp) $<; \
	then \
	  rm -rf $@ && mv $(@:.html=.htp) $@; \
	else \
## on failure, remove the temporary directory before exiting.
	  rm -rf $(@:.html=.htp) $@; exit 1; \
	fi
endef

%.info: %.texi
	$(call am.texi.build.info,$(am.texi.info-in-srcdir))
%.dvi: %.texi
	$(call am.texi.build.dvi-or-pdf,$(AM_V_TEXI2DVI),$(TEXI2DVI),$(@:.dvi=.t2d))
%.pdf: %.texi
	$(call am.texi.build.dvi-or-pdf,$(AM_V_TEXI2PDF),$(TEXI2PDF),$(@:.pdf=.t2p))
%.html: %.texi
	$(call am.texi.build.html)

## The way to make PostScript, for those who want it.
%.ps: %.dvi
	$(AM_V_DVIPS)TEXINPUTS="$(am__TEXINFO_TEX_DIR)$(PATH_SEPARATOR)$$TEXINPUTS" \
	$(DVIPS) $(AM_V_TEXI_QUIETOPTS) -o $@ $<