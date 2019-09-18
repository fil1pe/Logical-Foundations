all:
	coqc Basics.v -Q . LF
	coqc Induction.v -Q . LF
	coqc Lists.v -Q . LF
	coqc Poly.v -Q . LF
	coqc Tactics.v -Q . LF
	coqc Logic.v -Q . LF
