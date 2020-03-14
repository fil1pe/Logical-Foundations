define compile
	coqc $(2)/$(1).v -Q $(2) $(3)
endef

define compile_lf
	$(call compile,$(1),LogicalFoundations,LF)
endef

define compile_vfa
	$(call compile,$(1),VerifiedFunctionalAlgorithms,VFA)
endef

all: lf vfa
	@find . -name "*.aux" -type f -delete

lf:
	$(call compile_lf,Basics)
	$(call compile_lf,Induction)
	$(call compile_lf,Lists)
	$(call compile_lf,Poly)
	$(call compile_lf,Tactics)
	$(call compile_lf,Logic)
	$(call compile_lf,IndProp)
	$(call compile_lf,Maps)

vfa:
	$(call compile_vfa,Perm)
