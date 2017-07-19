package thx.schema;

import haxe.ds.Option;

import thx.Functions;
import thx.Unit;
import thx.Functions.identity;
import thx.fp.Functions.const;

import thx.schema.SchemaF;
using thx.schema.SchemaFExtensions;

class SchemaDSL {
  //
  // Constructors for derived schema that are independent of metadata type
  //

  public static function iso<E, X, A, B>(base: AnnotatedSchema<E, X, A>, f: A -> B, g: B -> A): AnnotatedSchema<E, X, B>
    return new AnnotatedSchema(base.annotation, ParseSchema(base.schema, function(a: A) return PSuccess(f(a)), g));

  public static function parse<E, X, A, B>(base: AnnotatedSchema<E, X, A>, f: A -> ParseResult<E, A, B>, g: B -> A): AnnotatedSchema<E, X, B>
    return new AnnotatedSchema(base.annotation, ParseSchema(base.schema, f, g));

  //
  // Constructors for object properties.
  //

  inline public static function liftPS<E, X, O, A>(s: PropSchema<E, X, O, A>): PropsBuilder<E, X, O, A>
    return Ap(s, Pure(function(a: A) return a));

  inline public static function requiredS<E, X, O, A>(fieldName: String, valueSchema: AnnotatedSchema<E, X, A>, accessor: O -> A): PropSchema<E, X, O, A>
    return Required(fieldName, valueSchema, accessor, None);

  inline public static function required<E, X, O, A>(fieldName: String, valueSchema: AnnotatedSchema<E, X, A>, accessor: O -> A): PropsBuilder<E, X, O, A>
    return liftPS(requiredS(fieldName, valueSchema, accessor));

  public static function optional<E, X, O, A>(fieldName: String, valueSchema: AnnotatedSchema<E, X, A>, accessor: O -> Option<A>): PropsBuilder<E, X, O, Option<A>>
    return liftPS(Optional(fieldName, valueSchema, accessor));

  public static function property<E, X, O, A>(fieldName: String, valueSchema: AnnotatedSchema<E, X, A>, accessor: O -> A, dflt: A): PropsBuilder<E, X, O, A>
    return liftPS(Required(fieldName, valueSchema, accessor, Some(dflt)));

  //
  // Combinators for building complex schemas
  //

  inline static public function ap1<E, X, O, A, B>(
      f: A -> B,
      v1: PropsBuilder<E, X, O, A>): PropsBuilder<E, X, O, B>
    return v1.map(f);

  inline static public function ap2<E, X, O, A, B, C>(
      f: A -> B -> C,
      v1: PropsBuilder<E, X, O, A>, v2: PropsBuilder<E, X, O, B>): PropsBuilder<E, X, O, C>
    return v2.ap(v1.map(Functions2.curry(f)));

  inline static public function ap3<E, X, O, A, B, C, D>(
      f: A -> B -> C -> D,
      v1: PropsBuilder<E, X, O, A>, v2: PropsBuilder<E, X, O, B>, v3: PropsBuilder<E, X, O, C>): PropsBuilder<E, X, O, D>
    return v3.ap(ap2(Functions3.curry(f), v1, v2));

  inline static public function ap4<E, X, O, A, B, C, D, F>(
      f: A -> B -> C -> D -> F,
      v1: PropsBuilder<E, X, O, A>, v2: PropsBuilder<E, X, O, B>, v3: PropsBuilder<E, X, O, C>, v4: PropsBuilder<E, X, O, D>): PropsBuilder<E, X, O, F>
    return v4.ap(ap3(Functions4.curry(f), v1, v2, v3));

  inline static public function ap5<E, X, O, A, B, C, D, F, G>(
      f: A -> B -> C -> D -> F -> G,
      v1: PropsBuilder<E, X, O, A>, v2: PropsBuilder<E, X, O, B>, v3: PropsBuilder<E, X, O, C>, v4: PropsBuilder<E, X, O, D>, v5: PropsBuilder<E, X, O, F>
      ): PropsBuilder<E, X, O, G>
    return v5.ap(ap4(Functions5.curry(f), v1, v2, v3, v4));

  inline static public function ap6<E, X, O, A, B, C, D, F, G, H>(
      f: A -> B -> C -> D -> F -> G -> H,
      v1: PropsBuilder<E, X, O, A>, v2: PropsBuilder<E, X, O, B>, v3: PropsBuilder<E, X, O, C>, v4: PropsBuilder<E, X, O, D>, v5: PropsBuilder<E, X, O, F>,
      v6: PropsBuilder<E, X, O, G>): PropsBuilder<E, X, O, H>
    return v6.ap(ap5(Functions6.curry(f), v1, v2, v3, v4, v5));

  inline static public function ap7<E, X, O, A, B, C, D, F, G, H, I>(
      f: A -> B -> C -> D -> F -> G -> H -> I,
      v1: PropsBuilder<E, X, O, A>, v2: PropsBuilder<E, X, O, B>, v3: PropsBuilder<E, X, O, C>, v4: PropsBuilder<E, X, O, D>, v5: PropsBuilder<E, X, O, F>,
      v6: PropsBuilder<E, X, O, G>, v7: PropsBuilder<E, X, O, H>): PropsBuilder<E, X, O, I>
    return v7.ap(ap6(Functions7.curry(f), v1, v2, v3, v4, v5, v6));

  inline static public function ap8<E, X, O, A, B, C, D, F, G, H, I, J>(
      f: A -> B -> C -> D -> F -> G -> H -> I -> J,
      v1: PropsBuilder<E, X, O, A>, v2: PropsBuilder<E, X, O, B>, v3: PropsBuilder<E, X, O, C>, v4: PropsBuilder<E, X, O, D>, v5: PropsBuilder<E, X, O, F>,
      v6: PropsBuilder<E, X, O, G>, v7: PropsBuilder<E, X, O, H>, v8: PropsBuilder<E, X, O, I>): PropsBuilder<E, X, O, J>
    return v8.ap(ap7(Functions8.curry(f), v1, v2, v3, v4, v5, v6, v7));

  inline static public function ap9<E, X, O, A, B, C, D, F, G, H, I, J, K>(
      f: A -> B -> C -> D -> F -> G -> H -> I -> J -> K,
      v1: PropsBuilder<E, X, O, A>, v2: PropsBuilder<E, X, O, B>, v3: PropsBuilder<E, X, O, C>, v4: PropsBuilder<E, X, O, D>, v5: PropsBuilder<E, X, O, F>,
      v6: PropsBuilder<E, X, O, G>, v7: PropsBuilder<E, X, O, H>, v8: PropsBuilder<E, X, O, I>, v9: PropsBuilder<E, X, O, J>): PropsBuilder<E, X, O, K>
    return v9.ap(ap8(Functions9.curry(f), v1, v2, v3, v4, v5, v6, v7, v8));

  inline static public function ap10<E, X, O, A, B, C, D, F, G, H, I, J, K, L>(
      f: A -> B -> C -> D -> F -> G -> H -> I -> J -> K -> L,
      v1: PropsBuilder<E, X, O, A>, v2: PropsBuilder<E, X, O, B>, v3: PropsBuilder<E, X, O, C>, v4: PropsBuilder<E, X, O, D>, v5: PropsBuilder<E, X, O, F>,
      v6: PropsBuilder<E, X, O, G>, v7: PropsBuilder<E, X, O, H>, v8: PropsBuilder<E, X, O, I>, v9: PropsBuilder<E, X, O, J>, v10: PropsBuilder<E, X, O, K>): PropsBuilder<E, X, O, L>
    return v10.ap(ap9(Functions10.curry(f), v1, v2, v3, v4, v5, v6, v7, v8, v9));

  inline static public function ap11<E, X, O, A, B, C, D, F, G, H, I, J, K, L, M>(
      f: A -> B -> C -> D -> F -> G -> H -> I -> J -> K -> L -> M,
      v1: PropsBuilder<E, X, O, A>, v2: PropsBuilder<E, X, O, B>, v3: PropsBuilder<E, X, O, C>, v4: PropsBuilder<E, X, O, D>, v5: PropsBuilder<E, X, O, F>,
      v6: PropsBuilder<E, X, O, G>, v7: PropsBuilder<E, X, O, H>, v8: PropsBuilder<E, X, O, I>, v9: PropsBuilder<E, X, O, J>, v10: PropsBuilder<E, X, O, K>,
      v11: PropsBuilder<E, X, O, L>): PropsBuilder<E, X, O, M>
    return v11.ap(ap10(Functions11.curry(f), v1, v2, v3, v4, v5, v6, v7, v8, v9, v10));

  inline static public function ap12<E, X, O, A, B, C, D, F, G, H, I, J, K, L, M, N>(
      f: A -> B -> C -> D -> F -> G -> H -> I -> J -> K -> L -> M -> N,
      v1: PropsBuilder<E, X, O, A>, v2: PropsBuilder<E, X, O, B>, v3: PropsBuilder<E, X, O, C>, v4: PropsBuilder<E, X, O, D>, v5: PropsBuilder<E, X, O, F>,
      v6: PropsBuilder<E, X, O, G>, v7: PropsBuilder<E, X, O, H>, v8: PropsBuilder<E, X, O, I>, v9: PropsBuilder<E, X, O, J>, v10: PropsBuilder<E, X, O, K>,
      v11: PropsBuilder<E, X, O, L>, v12: PropsBuilder<E, X, O, M>): PropsBuilder<E, X, O, N>
    return v12.ap(ap11(Functions12.curry(f), v1, v2, v3, v4, v5, v6, v7, v8, v9, v10, v11));

  inline static public function ap13<E, X, O, A, B, C, D, F, G, H, I, J, K, L, M, N, P>(
      f: A -> B -> C -> D -> F -> G -> H -> I -> J -> K -> L -> M -> N -> P,
      v1: PropsBuilder<E, X, O, A>, v2: PropsBuilder<E, X, O, B>, v3: PropsBuilder<E, X, O, C>, v4: PropsBuilder<E, X, O, D>, v5: PropsBuilder<E, X, O, F>,
      v6: PropsBuilder<E, X, O, G>, v7: PropsBuilder<E, X, O, H>, v8: PropsBuilder<E, X, O, I>, v9: PropsBuilder<E, X, O, J>, v10: PropsBuilder<E, X, O, K>,
      v11: PropsBuilder<E, X, O, L>, v12: PropsBuilder<E, X, O, M>, v13: PropsBuilder<E, X, O, N>): PropsBuilder<E, X, O, P>
    return v13.ap(ap12(Functions13.curry(f), v1, v2, v3, v4, v5, v6, v7, v8, v9, v10, v11, v12));
}
