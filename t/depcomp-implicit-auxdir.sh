#! /bin/sh
# Copyright (C) 2000-2012 Free Software Foundation, Inc.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Make sure a top-level depcomp file is found when
# AC_CONFIG_AUX_DIR is not specified.

. ./defs || exit 1

mkdir lib src

cat >> configure.ac << 'END'
AC_PROG_RANLIB
AC_PROG_CC
AM_PROG_AR
AC_CONFIG_FILES([lib/Makefile src/Makefile])
AC_OUTPUT
END

# Files required because we are using '--gnu'.
: > INSTALL
: > NEWS
: > README
: > COPYING
: > AUTHORS
: > ChangeLog

cat > Makefile.am << 'END'
SUBDIRS = lib src
END

cat > lib/Makefile.am << 'END'
pkgdata_DATA =
noinst_LIBRARIES = libfoo.a
libfoo_a_SOURCES = foo.c
END

cat > lib/foo.c << 'END'
int foo (void) { return 0; }
END

cat > src/Makefile.am << 'END'
pkgdata_DATA =
END

: > ar-lib

$ACLOCAL
$AUTOMAKE --gnu

: