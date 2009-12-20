tg-export: TG_BRANCHES ?= $(shell tg summary -t)
tg-export: __TG_SUBST_COMMA := ,
tg-export: __TG_SUBST_EMPTY :=
tg-export: __TG_SUBST_SPACE := $(__TG_SUBST_EMPTY) $(__TG_SUBST_EMPTY)
tg-export:
	test -d debian/patches && rm -r debian/patches || :
	tg export -b $(subst $(__TG_SUBST_SPACE),$(__TG_SUBST_COMMA),$(TG_BRANCHES)) --quilt debian/patches
.PHONY: tg-export
