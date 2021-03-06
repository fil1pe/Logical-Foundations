(** * Selection:  Selection Sort, With Specification and Proof of Correctness*)
(**
  This sorting algorithm works by choosing (and deleting) the smallest
  element, then doing it again, and so on.  It takes O(N^2) time.

  You should never* use a selection sort.  If you want a simple
  quadratic-time sorting algorithm (for small input sizes) you should
  use insertion sort.  Insertion sort is simpler to implement, runs
  faster, and is simpler to prove correct.   We use selection sort here
  only to illustrate the proof techniques.

     *Well, hardly ever.  If the cost of "moving" an element is _much_
  larger than the cost of comparing two keys, then selection sort is
  better than insertion sort.  But this consideration does not apply in our
  setting, where the elements are  represented as pointers into the
  heap, and only the pointers need to be moved.

  What you should really never use is bubble sort.  Bubble sort
  would be the wrong way to go.  Everybody knows that!
  https://www.youtube.com/watch?v=k4RRi_ntQc8
*)

(* ################################################################# *)
(** * The Selection-Sort Program  *)

Require Export Coq.Lists.List.
From VFA Require Import Perm.

(** Find (and delete) the smallest element in a list. *)

Fixpoint select (x: nat) (l: list nat) : nat * list nat :=
match l with
|  nil => (x, nil)
|  h::t => if x <=? h
               then let (j, l') := select x t in (j, h::l')
               else let (j,l') := select h t in (j, x::l')
end.

(** Now, selection-sort works by repeatedly extracting the smallest element,
   and making a list of the results. *)

(* Uncomment this function, and try it.
Fixpoint selsort l :=
match l with
| i::r => let (j,r') := select i r
               in j :: selsort r'
| nil => nil
end.
*)

(** _Error: Recursive call to selsort has principal argument equal
  to [r'] instead of [r]_.  That is, the recursion is not _structural_, since
  the list r' is not a structural sublist of (i::r).  One way to fix the
  problem is to use Coq's [Function] feature, and prove that
  [length(r')<length(i::r)].  Later in this chapter, we'll show that approach.

  Instead, here we solve this problem is by providing "fuel", an additional
  argument that has no use in the algorithm except to bound the
  amount of recursion.  The [n] argument, below, is the fuel. *)

Fixpoint selsort l n {struct n} :=
match l, n with
| x::r, S n' => let (y,r') := select x r
               in y :: selsort r' n'
| nil, _ => nil
| _::_, O => nil  (* Oops!  Ran out of fuel! *)
end.

(** What happens if we run out of fuel before we reach the end
   of the list?  Then WE GET THE WRONG ANSWER. *)

Example out_of_gas: selsort [3;1;4;1;5] 3 <> [1;1;3;4;5].
Proof.
simpl.
intro. inversion H.
Qed.

(** What happens if we have have too much fuel?  No problem. *)

Example too_much_gas: selsort [3;1;4;1;5] 10 = [1;1;3;4;5].
Proof.
simpl.
auto.
Qed.

(** The selection_sort algorithm provides just enough fuel. *)

Definition selection_sort l := selsort l (length l).

Example sort_pi: selection_sort [3;1;4;1;5;9;2;6;5;3;5] = [1;1;2;3;3;4;5;5;5;6;9].
Proof.
unfold selection_sort.
simpl.
reflexivity.
Qed.

(** Specification of correctness of a sorting algorithm:
   it rearranges the elements into a list that is totally ordered. *)

Inductive sorted: list nat -> Prop :=
 | sorted_nil: sorted nil
 | sorted_1: forall i, sorted (i::nil)
 | sorted_cons: forall i j l, i <= j -> sorted (j::l) -> sorted (i::j::l).

Definition is_a_sorting_algorithm (f: list nat -> list nat) :=
  forall al, Permutation al (f al) /\ sorted (f al).

(* ################################################################# *)
(** * Proof of Correctness of Selection sort *)

(** Here's what we want to prove. *)

Definition selection_sort_correct : Prop :=
    is_a_sorting_algorithm selection_sort.

(** We'll start by working on part 1, permutations. *)

(** **** Exercise: 3 stars (select_perm)  *)
Lemma select_perm: forall x l,
  let (y,r) := select x l in
   Permutation (x::l) (y::r).
Proof.

  (** NOTE: If you wish, you may [Require Import Multiset] and use the  multiset
    method, along with the theorem [contents_perm].  If you do,
    you'll still leave the statement of this theorem unchanged. *)

  intros x l; revert x.
  induction l; intros; simpl in *.

  apply Permutation_refl.
  destruct (x <=? a).
  - specialize (IHl x). destruct (select x l) eqn:eq.
    rewrite (perm_swap a). rewrite (perm_swap a).
    apply perm_skip. apply IHl.
  - specialize (IHl a). destruct (select a l) eqn:eq.
    rewrite (perm_swap x).
    apply perm_skip. apply IHl.

Qed.
(** [] *)

(** **** Exercise: 3 stars (selection_sort_perm)  *)
Lemma selsort_perm:
  forall n,
  forall l, length l = n -> Permutation l (selsort l n).
Proof.

(** NOTE: If you wish, you may [Require Import Multiset] and use the  multiset
  method, along with the theorem [same_contents_iff_perm]. *)

  intro n.
  induction n; intros l H.
  - destruct l. constructor. discriminate H.
  - destruct l. constructor.
    simpl. destruct (select n0 l) eqn:eq.
    pose proof select_perm as H0; specialize (H0 n0 l); rewrite eq in H0.
    eapply perm_trans. apply H0. apply perm_skip. apply IHn.
    apply Permutation_length in H0. simpl in H0. simpl in H. rewrite H in H0.
    injection H0. auto.

Qed.

Theorem selection_sort_perm:
  forall l, Permutation l (selection_sort l).
Proof.
  unfold selection_sort.
  intros.
  apply selsort_perm.
  reflexivity.
Qed.
(** [] *)

(** **** Exercise: 3 stars (select_smallest)  *)
Lemma select_smallest_aux:
  forall x al y bl,
    Forall (fun z => y <= z) bl ->
    select x al = (y,bl) ->
    y <= x.
Proof.
(* Hint: no induction needed in this lemma.
   Just use existing lemmas about select, along with [Forall_perm] *)

  intros.
  Check Forall_perm.
  pose proof select_perm; specialize (H1 x al); rewrite H0 in H1.
  Search Permutation.
  apply Permutation_sym in H1.
  eapply Forall_perm in H1.
  Search Forall.
  2: apply Forall_cons.
  3: apply H.
  2: simpl; omega.
  apply Forall_inv in H1.
  apply H1.

Qed.

Theorem select_smallest:
  forall x al y bl, select x al = (y,bl) ->
     Forall (fun z => y <= z) bl.
Proof.
  intros x al; revert x; induction al; intros; simpl in *.

  injection H; intros. rewrite <- H0. Search Forall. apply Forall_nil.

  bdestruct (x <=? a).

  1:    destruct (select x al) eqn:?H.
  2:    destruct (select a al) eqn:?H.
  1-2:  destruct bl; try (apply Forall_nil);
        injection H; intros;
        pose H1 as H5; apply select_smallest_aux in H5;
        pose H1 as H6; apply IHal in H6;
        try (apply Forall_cons);
        try (rewrite <- H3; rewrite <- H4; omega);
        try (rewrite <- H2; rewrite <- H4; apply H6);
        try (eapply IHal; apply H5).

Qed.
(** [] *)

(** **** Exercise: 3 stars (selection_sort_sorted)  *)
Lemma selection_sort_sorted_aux:
  forall  y bl,
   sorted (selsort bl (length bl)) ->
   Forall (fun z : nat => y <= z) bl ->
   sorted (y :: selsort bl (length bl)).
Proof.
 (* Hint: no induction needed.  Use lemmas selsort_perm and Forall_perm.*)

  intros.
  destruct (selsort bl (length bl)) eqn:?H. apply sorted_1.
  apply sorted_cons.
  2: apply H.
  eapply Forall_perm in H0.
  2: eapply selsort_perm; reflexivity.
  rewrite H1 in H0.
  Search Forall.
  apply Forall_inv in H0.
  apply H0.

Qed.

Lemma select_length: forall l al n n0,
  select n al = (n0, l) ->
  length al = length l.
Proof.
  intro.
  induction l; intros.
  - destruct al. reflexivity.
    simpl in H. destruct (n <=? n1).
    1:    destruct (select n al).
    2:    destruct (select n1 al).
    1-2:  discriminate H.
  - destruct al. simpl in H; discriminate H.
    simpl; apply eq_S.
    simpl in H; destruct (n <=? n1); eapply IHl.
    1:    destruct (select n al) eqn:?H.
    2:    destruct (select n1 al) eqn:?H.
    1-2:  rewrite H0;
          injection H; intros;
          rewrite H3, H1;
          reflexivity.
Qed.

Theorem selection_sort_sorted: forall al, sorted (selection_sort al).
Proof.
  intros.
  unfold selection_sort.
  (* Hint: do induction on the [length] of al.
      In the inductive case, use [select_smallest], [select_perm],
      and [selection_sort_sorted_aux]. *)

  remember (length al) as len. generalize dependent al.
  induction len; intros; destruct al; try (apply sorted_nil).
  simpl in Heqlen; injection Heqlen; intro H.
  rewrite Heqlen.
  simpl; destruct (select n al) eqn:?H.
  assert (length l = len). {
    rewrite H. symmetry. eapply select_length. apply H0.
  }
  apply select_smallest in H0.
  eapply Forall_perm in H0.
  2: apply selection_sort_perm.
  rewrite <- H.
  destruct (selsort l len) eqn:?H. apply sorted_1.
  unfold selection_sort in H0. rewrite H1 in H0. rewrite H2 in H0.
  apply sorted_cons.
  - apply Forall_inv in H0. apply H0.
  - rewrite <- H2. apply IHlen. symmetry. apply H1.
Qed.
(** [] *)

(** Now we wrap it all up.  *)

Theorem selection_sort_is_correct: selection_sort_correct.
Proof.
split. apply selection_sort_perm. apply selection_sort_sorted.
Qed.

(* ################################################################# *)
(** * Recursive Functions That are Not Structurally Recursive *)

(** [Fixpoint] in Coq allows for recursive functions where some
  parameter is structurally recursive: in every call, the argument
  passed at that parameter position is an immediate substructure
  of the corresponding formal parameter.  For recursive functions
  where that is not the case -- but for which you can still prove
  that they terminate -- you can use a more advanced feature of
  Coq, called [Function]. *)

Require Import Recdef.  (* needed for [Function] feature *)

Function selsort' l {measure length l} :=
match l with
| x::r => let (y,r') := select x r
               in y :: selsort' r'
| nil => nil
end.

(** When you use [Function] with [measure], it's your
  obligation to prove that the measure actually decreases,
  before you can use the function. *)

Proof.
intros.
pose proof (select_perm x r).
rewrite teq0 in H.
apply Permutation_length in H.
simpl in *; omega.
Defined.  (* Use [Defined] instead of [Qed], otherwise you
  can't compute with the function in Coq. *)

(** **** Exercise: 3 stars (selsort'_perm)  *)
Lemma selsort'_perm:
  forall n,
  forall l, length l = n -> Permutation l (selsort' l).
Proof.

(** NOTE: If you wish, you may [Require Import Multiset]
  and use the  multiset method, along with the
  theorem [same_contents_iff_perm]. *)

(** Important!  Don't unfold [selsort'], or in general, never
  unfold anything defined with [Function]. Instead, use the
  recursion equation [selsort'_equation] that is automatically
  defined by the [Function] command. *)

  intro.
  induction n; intros; rewrite selsort'_equation.
  - destruct l. constructor.
    simpl in H. discriminate H.
  - destruct l. constructor.
    destruct (select n0 l) eqn:?H.
    pose proof select_perm as H1; specialize (H1 n0 l); rewrite H0 in H1.
    eapply Permutation_trans. apply H1. apply perm_skip.
    apply Permutation_length in H1. simpl in H1. simpl in H. rewrite H in H1.
    apply IHn. injection H1. auto.

Qed.
(** [] *)

Eval compute in selsort' [3;1;4;1;5;9;2;6;5].

(** $Date$ *)
