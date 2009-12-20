#
# tg2quilt.mk - TopGit-to-quilt functionality for debian/rules files
#
# This make(1) snippet facilitates the conversion of TopGit branches to
# a quilt series.
#
# It is intended to be included from debian/rules files of TopGit-using
# packages after including the quilt rules, like so:
#
#   include /usr/share/quilt/quilt.make
#   -include /usr/share/topgit/tg2quilt.mk
#
# The leading dash is necessary for make not to die when the file is not
# installed. TopGit is not a build dependency (and does not need to be), and
# if the package is not installed, debian/rules can still be used normally.
#
# The snippet exports the following targets. These targets only perform the
# describe behaviour when invoked from a TopGit repository (`tg summary -t`
# returns a non-empty set); used outside, they simply output informational
# messages but do not cause errors.
#
#       tg-export: exports the TopGit patches into a quilt series under
#                  debian/patches.
#                    You may set TG_BRANCHES to a comma- or -space-separated
#                  subset of branches (but not comma-and-space-separated) to
#                  export (before including the file).
#                    If debian/patches/series already exists, the target
#                  will take note, blather a bit, and get out of the way.
#
#        tg-clean: cleans the source tree, just like the debian/rules clean
#                  target, and invokes tg-rmdir
#
#        tg-rmdir: tries to remove debian/patches, but only if there are no
#                  non-TopGit files under the directory.
#                    The heuristic is to find files that do not contain a line
#                  matchines /^tg:/, minus the series file. If any such files
#                  are found, an error occurs. Otherwise, the directory is
#                  removed. This means that edits to the series file are
#                  likely to vanish.
#
#  tg-cleanexport: recreates the debian/patches directory from scratch, using
#                  tg-rmdir and tg-export.
#
#   tg-forceclean: cleans the source tree, just like the debian/rules clean
#                  target, and forcefully removes the debian/patches
#                  directory in doing so. Yes, *force*-fully. WHAM!
#
# This file also hooks into the standard debian/rules and quilt targets such
# that tg-export is automatically invoked before quilt gets a chance to patch
# or unpatch the tree.
#
# The QUILT_PATCH_DIR variable can be set before including the file to override
# the default debian/patches location.
#
# More information, particularly for people working on TopGit-using packages,
# can be found in /usr/share/doc/topgit/HOWTO-tg2quilt.gz .
#
# Copyright © 2008 martin f. krafft <madduck@debian.org> Released under terms
# of the the Artistic Licence 2.0.
#

ifeq ($(shell tg summary -t),)
  # This is not a TopGit branch, so just blubber a bit.

  tg-export tg-clean tg-forceclean tg-rmdir tg-cleanexport:
	@echo "E: The $@ target only works from a TopGit repository." >&2
else

# We are in a TopGit branch, so let the fun begin.

ifdef PATCHES_DIR
	DUMMY := $(warning W: The $$PATCHES_DIR variable is deprecated, please use $$QUILT_PATCH_DIR instead.)
	DUMMY := $(warning W: Sleeping for 10 seconds so you can read this!)
	DUMMY := $(shell sleep 10)
	QUILT_PATCH_DIR := $(PATCHES_DIR)
endif

QUILT_PATCH_DIR ?= debian/patches
QUILT_STAMPFN ?= patch

# Hook tg-export into quilt's make(1) snippet such that it gets executed
# before quilt patches or unpatches.
$(QUILT_STAMPFN): tg-export
unpatch: __tg-temp-export
__tg-temp-export:
	@echo "Exporting TopGit branches to series so that quilt can clean up..." >&2
	$(MAKE) --no-print-directory -f debian/rules tg-export
.PHONY: __tg-temp-export

# Set some tg-export-specific variables, e.g. default TG_BRANCHES to all
# TopGit branches
tg-export: TG_BRANCHES ?= $(shell tg summary -t)
	# see make manual for this trick:
tg-export: __TG_COMMA := ,
tg-export: __TG_EMPTY :=
tg-export: __TG_SPACE := $(__TG_EMPTY) $(__TG_EMPTY)

ifeq ($(wildcard $(QUILT_PATCH_DIR)/series),)
  # The series file does not exist, so we proceed normally

  # tg-export will not work if the target dir already exists, so try to remove
  # it by calling tg-rmdir
  tg-export: tg-rmdir
	tg export -b $(subst $(__TG_SPACE),$(__TG_COMMA),$(TG_BRANCHES)) --quilt $(QUILT_PATCH_DIR)
else
  # The series file already exists, so assume there is nothing to do.
  tg-export:
	@echo "I: TopGit patch series already exists, nothing to do." >&2
	@echo "I: (invoke the \`tg-clean\` target to remove the series.)" >&2
	@echo "I: (you can ignore this message during a \`tg-clean\` run.)" >&2
endif

ifeq ($(wildcard $(QUILT_PATCH_DIR)),)
  # No patch directory, so nothing to do:
  tg-rmdir:
	@true

else
  # There is a patch directory, let's try to clean it out:
  tg-rmdir: __TG_FILES := $(shell find $(QUILT_PATCH_DIR) -type f -a -not -path \*/series \
                                    | xargs grep -l '^tg:')
  tg-rmdir:
	# remove all files whose contents matches /^tg:/
	test -n "$(__TG_FILES)" && rm $(__TG_FILES) || :
        # remove the series file
	test -f $(QUILT_PATCH_DIR)/series && rm $(QUILT_PATCH_DIR)/series || :
	# try to remove directories
	find $(QUILT_PATCH_DIR) -depth -type d -empty -execdir rmdir {} +
	# fail if the directory could not be removed and still exists
	@test ! -d $(QUILT_PATCH_DIR) || { \
	  echo "E: $(QUILT_PATCH_DIR) contains non-TopGit-generated files:" >&2; \
	  find $(QUILT_PATCH_DIR) -type f -printf 'E:   %P\n' >&2; \
	  false; \
	}
endif

# Make sure that we try to clean up the patches directory last
tg-clean: clean
	$(MAKE) --no-print-directory -f debian/rules tg-rmdir

tg-forceclean: clean
	test -d $(QUILT_PATCH_DIR) && rm -r $(QUILT_PATCH_DIR) || :

tg-cleanexport: tg-rmdir
	$(MAKE) --no-print-directory -f debian/rules tg-export

endif

.PHONY: tg-clean tg-export tg-forceclean tg-rmdir

# vim:ft=make:ts=8:noet
# -*- Makefile -*-, you silly Emacs! (shamelessly stolen from quilt)
