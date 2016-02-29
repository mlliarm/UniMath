Require Import UniMath.Foundations.Basics.PartD.
Require Import UniMath.Foundations.Basics.Propositions.
Require Import UniMath.Foundations.Basics.Sets.

Require Import UniMath.CategoryTheory.total2_paths.
Require Import UniMath.CategoryTheory.precategories.
Require Import UniMath.CategoryTheory.functor_categories.
Require Import UniMath.CategoryTheory.UnicodeNotations.
Require Import UniMath.CategoryTheory.colimits.colimits.
Require Import UniMath.CategoryTheory.category_hset.
Require Import UniMath.CategoryTheory.category_hset_structures.
Require Import UniMath.CategoryTheory.limits.initial.
Require Import UniMath.CategoryTheory.FunctorAlgebras.
Require Import UniMath.CategoryTheory.limits.FunctorsPointwiseProduct.
Require Import UniMath.CategoryTheory.limits.FunctorsPointwiseCoproduct.
Require Import UniMath.CategoryTheory.limits.products.
Require Import UniMath.CategoryTheory.limits.coproducts.
Require Import UniMath.CategoryTheory.limits.terminal.
Require Import UniMath.CategoryTheory.colimits.chains.

Local Notation "# F" := (functor_on_morphisms F) (at level 3).
Local Notation "[ C , D , hs ]" := (functor_precategory C D hs).

(* Proofs that various polynomial functors are omega cocontinuous *)
Section polynomial_functors.

Variables (C : precategory) (hsC : has_homsets C).
Variables (D : precategory) (hsD : has_homsets D).
Variables (E : precategory) (hsE : has_homsets E).

(* The constant functor is omega cocontinuous *)
Section constant_functor.

Variable (x : D).

Lemma omega_cocont_constant_functor : omega_cocont (constant_functor C D x).
Proof.
intros c L ccL HcL y ccy; simpl.
simple refine (tpair _ _ _).
- simple refine (tpair _ _ _).
  + apply (coconeIn ccy 0).
  + abstract (simpl; intro n; rewrite id_left;
              destruct ccy as [f Hf]; simpl in *;
              induction n; [apply idpath|];
              now rewrite IHn, <- (Hf n (S n) (idpath _)), id_left).
- abstract (simpl; intro p; apply subtypeEquality;
              [ intros f; apply impred; intro; apply hsD
              | now simpl; destruct p as [p H]; rewrite <- (H 0), id_left]).
Defined.

End constant_functor.

(* The identity functor is omega cocontinuous *)
Section identity_functor.

Lemma omega_cocont_functor_identity : omega_cocont (functor_identity C).
Proof.
intros c L ccL HcL.
apply (preserves_colimit_identity hsC _ _ _ HcL).
Defined.

End identity_functor.

(* Functor composition preserves omega cocontinuity *)
Section functor_comp.

Lemma omega_cocont_functor_composite (F : functor C D) (G : functor D E) :
  omega_cocont F -> omega_cocont G -> omega_cocont (functor_composite F G).
Proof.
intros hF hG c L cc.
apply (preserves_colimit_comp hsE); [apply hF|apply hG].
Defined.

End functor_comp.

(* The functor "x * F" is omega_cocont. This is only proved for set at the
   moment as it needs that the category is cartesian closed *)
Section constprod_functor.

Variables (x : HSET).

Definition constprod_functor : functor HSET HSET :=
  product_functor HSET HSET ProductsHSET (constant_functor HSET HSET x)
                                         (functor_identity HSET).

Definition flip {A B C : UU} (f : A -> B -> C) : B -> A -> C := fun x y => f y x.

Lemma paireta {A B : UU} (p : A × B) : p = (pr1 p,, pr2 p).
Proof.
destruct p; apply idpath.
Defined.

(* TODO: Opacification *)
Lemma omega_cocontConstProdFunctor : omega_cocont constprod_functor.
Proof.
intros hF c L ccL HcL cc.
simple refine (tpair _ _ _).
- simple refine (tpair _ _ _).
  + simpl; apply uncurry, flip.
    apply (colimArrow (mk_ColimCocone _ _ _ ccL) (hset_fun_space x HcL)).
    simple refine (mk_cocone _ _).
    * simpl; intro n; apply flip, curry, (pr1 cc).
    * abstract (destruct cc as [f hf]; simpl; intros m n e;
                rewrite <- (hf m n e); destruct e; simpl;
                repeat (apply funextfun; intro); apply idpath).
  + cbn.
    abstract (
    destruct cc as [f hf]; simpl; intro n;
    apply funextfun; intro p; rewrite (paireta p);
    generalize (colimArrowCommutes (mk_ColimCocone hF c L ccL) _
                 (mk_cocone _ (omega_cocontConstProdFunctor_subproof
                               hF c L ccL HcL (f,,hf))) n);
    unfold flip, curry, colimIn; simpl; intro H;
    now rewrite <- (toforallpaths _ _ _ (toforallpaths _ _ _ H (pr2 p)) (pr1 p))).
- abstract (
  intro p; unfold uncurry; simpl; apply subtypeEquality; simpl;
  [ intro g; apply impred; intro t;
    simple refine (let ff : HSET ⟦(x × dob hF t)%set,HcL⟧ := _ in _);
    [ simpl; apply (pr1 cc)
    | apply (@has_homsets_HSET _ HcL _ ff) ]
  | destruct p as [t p]; simpl;
    apply funextfun; intro xc; destruct xc as [x' c']; simpl;
    simple refine (let g : HSET⟦colim (mk_ColimCocone hF c L ccL),
                                hset_fun_space x HcL⟧ := _ in _);
    [ simpl; apply flip, curry, t
    | rewrite <- (colimArrowUnique _ _ _ g); [apply idpath | ];
      destruct cc as [f hf]; simpl in *;
      now intro n; simpl; rewrite <- (p n) ]
  ]).
Defined.

End constprod_functor.

(* The functor "x + F" is omega_cocont.
   Assumes that the category has coproducts *)
Section constcoprod_functor.

Variables (x : C) (PC : Coproducts C).

Definition constcoprod_functor : functor C C :=
  coproduct_functor C C PC (constant_functor C C x) (functor_identity C).

Lemma omega_cocontConstCoprodFunctor : omega_cocont constcoprod_functor.
Proof.
intros hF c L ccL HcL cc.
simple refine (tpair _ _ _).
- simple refine (tpair _ _ _).
  + eapply CoproductArrow.
    * exact (CoproductIn1 _ (PC x (dob hF 0)) ;; pr1 cc 0).
    * simple refine (let ccHcL : cocone hF HcL := _ in _).
      { simple refine (mk_cocone _ _).
        - intros n; exact (CoproductIn2 _ (PC x (dob hF n)) ;; pr1 cc n).
        - abstract (
            intros m n e; destruct e; simpl;
            destruct cc as [f hf]; simpl in *; unfold coproduct_functor_ob in *;
            rewrite <- (hf m _ (idpath _)), !assoc; apply cancel_postcomposition;
            now unfold coproduct_functor_mor; rewrite CoproductOfArrowsIn2). }
      apply (pr1 (pr1 (ccL HcL ccHcL))).
  + abstract (
    destruct cc as [f hf]; simpl in *; unfold coproduct_functor_ob in *;
    simpl; intro n; unfold coproduct_functor_mor in *;
    rewrite precompWithCoproductArrow; apply pathsinv0, CoproductArrowUnique;
    [ rewrite id_left; induction n; [apply idpath|];
      now rewrite <- IHn, <- (hf n _ (idpath _)), assoc,
                  CoproductOfArrowsIn1, id_left
    | rewrite <- (hf n _ (idpath _)); destruct ccL; destruct t; simpl in *;
      rewrite p0; apply maponpaths, hf]).
- abstract (
  destruct cc as [f hf]; simpl in *; unfold coproduct_functor_ob in *;
  intro t; apply subtypeEquality; simpl;
  [ intro g; apply impred; intro; apply hsC
  | destruct t; destruct ccL; unfold coproduct_functor_mor in *; destruct t0; simpl;
    apply CoproductArrowUnique;
    [ now rewrite <- (p 0), assoc, CoproductOfArrowsIn1, id_left
    | simple refine (let temp : Σ x0 : C ⟦ c, HcL ⟧, ∀ v : nat,
         coconeIn L v ;; x0 = CoproductIn2 C (PC x (dob hF v)) ;; f v := _ in _);
         [ apply (tpair _ (CoproductIn2 C (PC x c) ;; t));
          now intro n; rewrite <- (p n), !assoc, CoproductOfArrowsIn2|];
      apply (maponpaths pr1 (p0 temp))]]).
Defined.

End constcoprod_functor.

End polynomial_functors.

Require Import UniMath.CategoryTheory.ProductPrecategory.
Require Import UniMath.CategoryTheory.equivalences.
Require Import UniMath.CategoryTheory.AdjunctionHomTypesWeq.

(* The functor "* : C^2 -> C" is omega cocont *)
Section binprod_functor.

Variable C : precategory.
Variables (PC : Products C).

Definition binproduct_functor_data : functor_data (product_precategory C C) C.
Proof.
mkpair.
- intros p.
  apply (ProductObject _ (PC (pr1 p) (pr2 p))).
- simpl; intros p q f.
  apply (ProductOfArrows _ (PC (pr1 q) (pr2 q)) (PC (pr1 p) (pr2 p)) (pr1 f) (pr2 f)).
Defined.

Definition binproduct_functor : functor (product_precategory C C) C.
Proof.
mkpair.
- apply binproduct_functor_data.
- split.
  + intro x; simpl.
    apply pathsinv0, Product_endo_is_identity.
    * now rewrite ProductOfArrowsPr1, id_right.
    * now rewrite ProductOfArrowsPr2, id_right.
  + now intros x y z f g; simpl; rewrite ProductOfArrows_comp.
Defined.

(* This is difficult to prove *)
Lemma omega_cocont_binproduct_functor : omega_cocont binproduct_functor.
Admitted.

End binprod_functor.

(* The delta functor C -> C^2 mapping x to (x,x) is omega_cocont *)
Section delta_functor.

Variable C : precategory.

Definition delta_functor_data : functor_data C (product_precategory C C).
Proof.
mkpair.
- intro x; apply (prodcatpair x x).
- intros x y f; simpl; apply (prodcatmor f f).
Defined.

Definition delta_functor : functor C (product_precategory C C).
Proof.
mkpair.
- exact delta_functor_data.
- split.
  + intro x; apply idpath.
  + intros x y z f g; apply idpath.
Defined.

(* Todo: show that delta_functor is left adjoint to product and the use general fact *)
Lemma cocont_delta_functor (PC : Products C) : is_cocont delta_functor.
Proof.
apply left_adjoint_cocont, (tpair _ (binproduct_functor _ PC)).
mkpair.
- split.
  + mkpair.
    * simpl; intro x.
      apply (ProductArrow _ _ (identity x) (identity x)).
    * abstract (intros p q f; simpl;
                now rewrite precompWithProductArrow, id_right, postcompWithProductArrow, id_left).
  + mkpair.
    * simpl; intro x; split; [ apply ProductPr1 | apply ProductPr2 ].
    * abstract (intros p q f; unfold prodcatmor, compose; simpl;
                now rewrite ProductOfArrowsPr1, ProductOfArrowsPr2).
- split; simpl; intro x.
  + unfold prodcatmor, compose; simpl.
    now rewrite ProductPr1Commutes, ProductPr2Commutes.
  + rewrite postcompWithProductArrow, !id_left.
    apply pathsinv0, Product_endo_is_identity; [ apply ProductPr1Commutes | apply ProductPr2Commutes ].
Defined.

Lemma omega_cocont_delta_functor (PC : Products C) : omega_cocont delta_functor.
Proof.
intros c L ccL.
apply (cocont_delta_functor PC).
Defined.

End delta_functor.

(* The functor "+ : C^2 -> C" is cocont *)
Section bincoprod_functor.

Variable C : precategory.
Variables (PC : Coproducts C).

Definition bincoproduct_functor_data : functor_data (product_precategory C C) C.
Proof.
mkpair.
- intros p.
  apply (CoproductObject _ (PC (pr1 p) (pr2 p))).
- simpl; intros p q f.
  apply (CoproductOfArrows _ (PC (pr1 p) (pr2 p)) (PC (pr1 q) (pr2 q)) (pr1 f) (pr2 f)).
Defined.

Definition bincoproduct_functor : functor (product_precategory C C) C.
Proof.
mkpair.
- apply bincoproduct_functor_data.
- split.
  + intro x; simpl.
    apply pathsinv0, Coproduct_endo_is_identity.
    * now rewrite CoproductOfArrowsIn1, id_left.
    * now rewrite CoproductOfArrowsIn2, id_left.
  + now intros x y z f g; simpl; rewrite CoproductOfArrows_comp.
Defined.

(* TODO: opacify *)
Lemma cocont_bincoproducts_functor : is_cocont bincoproduct_functor.
Proof.
apply left_adjoint_cocont, (tpair _ (delta_functor _)).
mkpair.
- split.
  + mkpair.
    * simpl; intro p; set (x := pr1 p); set (y := pr2 p).
      split; [ apply (CoproductIn1 _ (PC x y)) | apply (CoproductIn2 _ (PC x y)) ].
    * abstract (intros p q f; unfold prodcatmor, compose; simpl;
                now rewrite CoproductOfArrowsIn1, CoproductOfArrowsIn2).
  + mkpair.
    * intro x; apply (CoproductArrow _ _ (identity x) (identity x)).
    * abstract (intros p q f; simpl;
                now rewrite precompWithCoproductArrow, postcompWithCoproductArrow,
                            id_right, id_left).
- split; simpl; intro x.
  + rewrite precompWithCoproductArrow, !id_right.
    apply pathsinv0, Coproduct_endo_is_identity;
      [ apply CoproductIn1Commutes | apply CoproductIn2Commutes ].
  + unfold prodcatmor, compose; simpl.
    now rewrite CoproductIn1Commutes, CoproductIn2Commutes.
Defined.

Lemma omega_cocont_bincoproduct_functor: omega_cocont bincoproduct_functor.
Proof.
intros c L ccL; apply cocont_bincoproducts_functor.
Defined.

End bincoprod_functor.

(* A pair of functors (F,G) : A * B -> C * D is omega_cocont if F and G are *)
Section pair_functor.

Variables A B C D : precategory.
Variables (F : functor A C) (G : functor B D).

Definition pair_functor_data : functor_data (product_precategory A B) (product_precategory C D).
Proof.
mkpair.
- intro x; apply (prodcatpair (F (pr1 x)) (G (pr2 x))).
- intros x y f; simpl; apply (prodcatmor (# F (pr1 f)) (# G (pr2 f))).
Defined.

Definition pair_functor : functor (product_precategory A B) (product_precategory C D).
Proof.
mkpair.
- exact pair_functor_data.
- split.
  + intro x; simpl; rewrite !functor_id; apply idpath.
  + intros x y z f g; simpl; rewrite !functor_comp; apply idpath.
Defined.

(* Lemma cocont_pair_functor (HF : is_cocont F) (HG : is_cocont G) : *)
(*   is_cocont pair_functor. *)
(* Admitted. *)

Lemma omega_cocont_pair_functor (HF : omega_cocont F) (HG : omega_cocont G) :
  omega_cocont pair_functor.
Admitted.

End pair_functor.

(* Should go to ProductPrecategory.v *)
(* The functor "F * G : A * B -> C * D" is cocont *)
(* Section product_of_functors. *)

(* Variable A B C D : precategory. *)
(* Variables (F : functor A C) (G : functor B D). *)

(* Definition product_of_functors : functor (product_precategory A B) (product_precategory C D). *)
(* Admitted. *)

(* End product_of_functors. *)

Section rightkanextension.

Require Import UniMath.CategoryTheory.whiskering.
Require Import UniMath.CategoryTheory.RightKanExtension.

Variables C D E : precategory.
Variables (K : functor C D).

(* Lemma foo : has_limits D -> GlobalRightKanExtensionExists K. *)

(* has_limits D *)
Lemma cocont_pre_composition_functor (hsD : has_homsets D) (hsE : has_homsets E) :
  is_cocont (pre_composition_functor _ _ E hsD hsE K).
Admitted. (* will be a simple consequence of foo *)

Lemma omega_cocont_pre_composition_functor (hsD : has_homsets D) (hsE : has_homsets E) :
  omega_cocont (pre_composition_functor _ _ E hsD hsE K).
Proof.
intros c L ccL.
apply cocont_pre_composition_functor.
Defined.

End rightkanextension.

(* Lists as the colimit of a chain given by the list functor: F(X) = 1 + A * X *)
Section lists.

Variable A : HSET.

(* F(X) = A * X *)
Definition stream : functor HSET HSET := constprod_functor A.

(* F(X) = 1 + (A * X) *)
Definition listFunctor : functor HSET HSET :=
  functor_composite stream (constcoprod_functor _ unitHSET CoproductsHSET).

Lemma omega_cocont_listFunctor : omega_cocont listFunctor.
Proof.
apply (omega_cocont_functor_composite _ _ _ has_homsets_HSET).
- apply omega_cocontConstProdFunctor.
- apply (omega_cocontConstCoprodFunctor _ has_homsets_HSET).
Defined.

Lemma listFunctor_Initial :
  Initial (precategory_FunctorAlg listFunctor has_homsets_HSET).
Proof.
apply (colimAlgInitial _ _ _ omega_cocont_listFunctor
                       InitialHSET (ColimCoconeHSET _ _)).
Defined.

Definition List : HSET :=
  (* colim (ColimCoconeHSET nat_graph (initChain InitialHSET listFunctor)). *)
  alg_carrier _ (InitialObject listFunctor_Initial).
Opaque List.
Let List_mor : HSET⟦listFunctor List,List⟧ :=
  alg_map _ (InitialObject listFunctor_Initial).
Opaque List_mor.
Let List_alg : algebra_ob listFunctor :=
  InitialObject listFunctor_Initial.
Opaque List_alg.

Definition nil_map : HSET⟦unitHSET,List⟧.
Proof.
simpl; intro x.
apply List_mor, inl, x.
Defined.

Definition nil : pr1 List := nil_map tt.

Definition cons_map : HSET⟦(A × List)%set,List⟧.
Proof.
intros xs.
apply List_mor, (inr xs).
Defined.

Definition cons : pr1 A × pr1 List -> pr1 List := cons_map.

(* Get recursion/iteration scheme: *)

(*    x : X           f : A × X -> X *)
(* ------------------------------------ *)
(*       foldr x f : List A -> X *)

Definition mk_listAlgebra (X : HSET) (x : pr1 X)
  (f : HSET⟦(A × X)%set,X⟧) : algebra_ob listFunctor.
Proof.
set (x' := λ (_ : unit), x).
apply (tpair _ X (sumofmaps x' f) : algebra_ob listFunctor).
Defined.

Definition foldr_map (X : HSET) (x : pr1 X) (f : HSET⟦(A × X)%set,X⟧) :
  algebra_mor _ List_alg (mk_listAlgebra X x f).
Proof.
apply (InitialArrow listFunctor_Initial (mk_listAlgebra X x f)).
Defined.
Opaque foldr_map.

Definition foldr (X : HSET) (x : pr1 X)
  (f : pr1 A × pr1 X -> pr1 X) : pr1 List -> pr1 X.
Proof.
apply (foldr_map _ x f).
Defined.
Opaque foldr.

(* Maybe quantify over "λ _ : unit, x" instead of nil? *)
Lemma foldr_nil (X : hSet) (x : X) (f : pr1 A × X -> X) : foldr X x f nil = x.
Proof.
assert (F := maponpaths (fun x => CoproductIn1 _ _ ;; x)
                        (algebra_mor_commutes _ _ _ (foldr_map X x f))).
apply (toforallpaths _ _ _ F tt).
Qed.

Lemma foldr_cons (X : hSet) (x : X) (f : pr1 A × X -> X)
                 (a : pr1 A) (l : pr1 List) :
  foldr X x f (cons (a,,l)) = f (a,,foldr X x f l).
Proof.
assert (F := maponpaths (fun x => CoproductIn2 _ _ ;; x)
                        (algebra_mor_commutes _ _ _ (foldr_map X x f))).
assert (Fal := toforallpaths _ _ _ F (a,,l)).
clear F.
(* apply Fal. *) (* This doesn't work here. why? *)
unfold compose in Fal.
simpl in Fal.
apply Fal.
Qed. (* This Qed is slow! *)

(* This defines the induction principle for lists using foldr *)
Section list_induction.

Variables (P : pr1 List -> UU) (PhSet : forall l, isaset (P l)).
Variables (P0 : P nil)
          (Pc : forall (a : pr1 A) (l : pr1 List), P l -> P (cons (a,,l))).

Let P' : UU := Σ l, P l.
Let P0' : P' := (nil,, P0).
Let Pc' : pr1 A × P' -> P' :=
  λ ap : pr1 A × P', cons (pr1 ap,, pr1 (pr2 ap)),,Pc (pr1 ap) (pr1 (pr2 ap)) (pr2 (pr2 ap)).

Definition P'HSET : HSET.
Proof.
apply (tpair _ P').
abstract (apply (isofhleveltotal2 2); [ apply setproperty | intro x; apply PhSet ]).
Defined.

Lemma isalghom_pr1foldr :
  is_algebra_mor _ List_alg List_alg (fun l => pr1 (foldr P'HSET P0' Pc' l)).
Proof.
apply CoproductArrow_eq_cor.
- apply funextfun; intro x; destruct x; apply idpath.
- apply funextfun; intro x; destruct x as [a l].
  apply (maponpaths pr1 (foldr_cons P'HSET P0' Pc' a l)).
Qed.

Definition pr1foldr_algmor : algebra_mor _ List_alg List_alg :=
  tpair _ _ isalghom_pr1foldr.

Lemma pr1foldr_algmor_identity : identity _ = pr1foldr_algmor.
Proof.
now rewrite <- (InitialEndo_is_identity _ listFunctor_Initial pr1foldr_algmor).
Qed.

Lemma listInd l : P l.
Proof.
assert (H : pr1 (foldr P'HSET P0' Pc' l) = l).
  apply (toforallpaths _ _ _ (!pr1foldr_algmor_identity) l).
rewrite <- H.
apply (pr2 (foldr P'HSET P0' Pc' l)).
Defined.

End list_induction.

Lemma listIndProp (P : pr1 List -> UU) (HP : forall l, isaprop (P l)) :
  P nil -> (forall a l, P l → P (cons (a,, l))) -> forall l, P l.
Proof.
intros Pnil Pcons.
apply listInd; try assumption.
intro l; apply isasetaprop, HP.
Defined.

Require Import UniMath.Foundations.NumberSystems.NaturalNumbers.

Definition natHSET : HSET.
Proof.
exists nat.
abstract (apply isasetnat).
Defined.

Definition length : pr1 List -> nat :=
  foldr natHSET 0 (fun x => S (pr2 x)).

Definition map (f : pr1 A -> pr1 A) : pr1 List -> pr1 List :=
  foldr _ nil (λ xxs : pr1 A × pr1 List, cons (f (pr1 xxs),, pr2 xxs)).

Lemma length_map (f : pr1 A -> pr1 A) : forall xs, length (map f xs) = length xs.
Proof.
apply listIndProp.
- intros l; apply isasetnat.
- apply idpath.
- simpl; unfold map, length; simpl; intros a l Hl.
  simpl.
  now rewrite !foldr_cons, <- Hl.
Qed.

End lists.

Opaque List.
(* Opaque foldr. *) (* makes "cbn" and "compute" in the computation below fail *)

(* Some examples of computations with lists over nat *)
Section nat_examples.

Definition cons_nat a l : pr1 (List natHSET) := cons natHSET (a,,l).

Infix "::" := cons_nat.
Notation "[]" := (nil natHSET) (at level 0, format "[]").

Definition testlist : pr1 (List natHSET) := 5 :: 2 :: [].

Definition testlistS : pr1 (List natHSET) :=
  map natHSET S testlist.

Definition sum : pr1 (List natHSET) -> nat :=
  foldr natHSET natHSET 0 (fun xy => pr1 xy + pr2 xy).

Eval vm_compute in length _ (nil natHSET).
Eval vm_compute in length _ testlist.
Eval vm_compute in length _ testlistS.
Eval vm_compute in sum testlist.
Eval vm_compute in sum testlistS.

Goal length _ testlist = 2.
vm_compute.
Restart.
cbn.
Restart.
compute.  (* does not work when foldr is opaque with "Opaque foldr." *)
Restart.
cbv.   (* does not work when foldr is opaque with "Opaque foldr." *)
Restart.
native_compute.
Abort.

Goal (forall l, length _ (2 :: l) = S (length _ l)).
simpl.
intro l.
try apply idpath. (* this doesn't work *)
unfold length, cons_nat.
rewrite foldr_cons. cbn.
apply idpath.
Abort.

(* Time Eval vm_compute in nil natHSET.  (* This crashes my computer by using up all memory *) *)

End nat_examples.

(* Inductive list A : UU := *)
(*   | nilA : list A *)
(*   | consA : A -> list A -> list A. *)

(* Fixpoint lengthA (A : UU) (xs : list A) : nat := match xs with *)
(*   | nilA _ => 0 *)
(*   | consA _ _ xs' => S (lengthA _ xs') *)
(*   end. *)

(* Goal (forall l, lengthA nat (consA _ 2 l) = S (lengthA nat l)). *)
(* intro l. *)
(* apply idpath. *)
(* Abort. *)

Section lambdacalculus.

Section temp.
Variables (C D : precategory) (PC : Products C) (HD : Coproducts D).

Definition sum_of_functors (F G : functor C D) : functor C D.
eapply functor_composite.
  eapply delta_functor.
eapply functor_composite.
  eapply pair_functor.
  (* eapply product_of_functors. *)
    apply F.
    apply G.
apply bincoproduct_functor.
apply HD.
Defined.

Lemma omega_cocont_sum_of_functors (F G : functor C D) (hsD : has_homsets D)
  (HF : omega_cocont F) (HG : omega_cocont G) : omega_cocont (sum_of_functors F G).
Proof.
apply (omega_cocont_functor_composite _ _ _ hsD).
  apply (omega_cocont_delta_functor _ PC).
apply (omega_cocont_functor_composite _ _ _ hsD).
  apply (omega_cocont_pair_functor _ _ _ _ _ _ HF HG).
apply omega_cocont_bincoproduct_functor.
Defined.

End temp.

Definition option_functor : [HSET,HSET,has_homsets_HSET].
Proof.
apply coproduct_functor.
apply CoproductsHSET.
apply (constant_functor _ _ unitHSET).
apply functor_identity.
Defined.

(* TODO: define sum of omega cocont functors *)
Definition LambdaFunctor : functor [HSET,HSET,has_homsets_HSET] [HSET,HSET,has_homsets_HSET].
Proof.
eapply sum_of_functors.
  apply (Coproducts_functor_precat _ _ CoproductsHSET).
  apply (constant_functor [HSET, HSET, has_homsets_HSET] [HSET, HSET, has_homsets_HSET] (functor_identity HSET)).
eapply sum_of_functors.
  apply (Coproducts_functor_precat _ _ CoproductsHSET).
  (* app *)
  eapply functor_composite.
    apply delta_functor.
    apply binproduct_functor.
    apply (Products_functor_precat _ _ ProductsHSET).
(* lam *)
apply (pre_composition_functor _ _ _ _ _ option_functor).
Defined.

(* Bad approach *)
(* Definition Lambda : functor [HSET,HSET,has_homsets_HSET] [HSET,HSET,has_homsets_HSET]. *)
(* Proof. *)
(* eapply functor_composite. *)
(*   apply delta_functor. *)
(* eapply functor_composite. *)
(*   eapply product_of_functors. *)
(*     apply functor_identity. *)
(*     apply delta_functor. *)
(* eapply functor_composite. *)
(*   eapply product_of_functors. *)
(*     apply (constant_functor [HSET, HSET, has_homsets_HSET] [HSET, HSET, has_homsets_HSET] (functor_identity HSET)). *)
(*     eapply product_of_functors. *)
(*       apply delta_functor. *)

Lemma omega_cocont_LambdaFunctor : omega_cocont LambdaFunctor.
Proof.
apply omega_cocont_sum_of_functors.
  apply (Products_functor_precat _ _ ProductsHSET).
  apply functor_category_has_homsets.
  apply omega_cocont_constant_functor.
  apply functor_category_has_homsets.
apply omega_cocont_sum_of_functors.
  apply (Products_functor_precat _ _ ProductsHSET).
  apply functor_category_has_homsets.
  apply omega_cocont_functor_composite.
  apply functor_category_has_homsets.
  apply omega_cocont_delta_functor.
  apply (Products_functor_precat _ _ ProductsHSET).
  apply omega_cocont_binproduct_functor.
apply omega_cocont_pre_composition_functor.
Defined.

End lambdacalculus.