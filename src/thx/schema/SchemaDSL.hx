package thx.schema;

import haxe.ds.Option;
import thx.Functions;
import thx.Unit;
import thx.Functions.identity;
import thx.fp.Functions.const;

import thx.schema.Schema;
using thx.schema.SchemaExtensions;

class SchemaDSL {
  public static function lift<O, A>(s: PropSchema<O, A>): ObjectBuilder<O, A>
    return Ap(s, Pure(function(a: A) return a));

  //
  // Constructors for terminal schema elements
  //

  public static var bool(default, never): Schema<Bool> = BoolSchema;
  public static var float(default, never): Schema<Float> = FloatSchema;
  public static var int(default, never): Schema<Int> = IntSchema;
  public static var string(default, never): Schema<String> = StrSchema;

  public static function array<A>(elemSchema: Schema<A>): Schema<Array<A>>
    return ArraySchema(elemSchema);

  public static function object<A>(propSchema: ObjectBuilder<A, A>): Schema<A>
    return ObjectSchema(propSchema);

  public static function oneOf<A>(alternatives: Array<Alternative<A>>): Schema<A>
    return OneOfSchema(alternatives);

  public static function iso<A, B>(base: Schema<A>, f: A -> B, g: B -> A): Schema<B>
    return IsoSchema(base, f, g);

  public static function constant<A>(a: A): Schema<A>
    return iso(UnitSchema, const(a), const(unit));

  //
  // Constructors for oneOf alternatives
  //

  public static function alt<A, B>(id: String, base: Schema<B>, f: B -> A, g: A -> Option<B>): Alternative<A>
    return Prism(id, base, f, g);

  //
  // Constructors for object properties. 
  //

  public static function required<O, A>(fieldName: String, valueSchema: Schema<A>, accessor: O -> A): ObjectBuilder<O, A>
    return lift(Required(fieldName, valueSchema, accessor));

  public static function optional<O, A>(fieldName: String, valueSchema: Schema<A>, accessor: O -> Option<A>): ObjectBuilder<O, Option<A>>
    return lift(Optional(fieldName, valueSchema, accessor));

  // Convenience constructor for a single-property object schema that simply wraps another schema.
  public static function wrap<A>(fieldName: String, valueSchema: Schema<A>): Schema<A>
    return object(required(fieldName, valueSchema, identity));

  //
  // Combinators for building complex schemas
  //
  inline static public function ap1<O, X, A, B>(
      f: A -> B,
      v1: ObjectBuilder<O, A>): ObjectBuilder<O, B>
    return v1.map(f);

  inline static public function ap2<O, X, A, B, C>(
      f: A -> B -> C,
      v1: ObjectBuilder<O, A>, v2: ObjectBuilder<O, B>): ObjectBuilder<O, C>
    return v2.ap(v1.map(Functions2.curry(f)));

  inline static public function ap3<O, X, A, B, C, D>(
      f: A -> B -> C -> D,
      v1: ObjectBuilder<O, A>, v2: ObjectBuilder<O, B>, v3: ObjectBuilder<O, C>): ObjectBuilder<O, D>
    return v3.ap(ap2(Functions3.curry(f), v1, v2));

  inline static public function ap4<O, X, A, B, C, D, E>(
      f: A -> B -> C -> D -> E,
      v1: ObjectBuilder<O, A>, v2: ObjectBuilder<O, B>, v3: ObjectBuilder<O, C>, v4: ObjectBuilder<O, D>): ObjectBuilder<O, E>
    return v4.ap(ap3(Functions4.curry(f), v1, v2, v3));

  inline static public function ap5<O, X, A, B, C, D, E, F>(
      f: A -> B -> C -> D -> E -> F,
      v1: ObjectBuilder<O, A>, v2: ObjectBuilder<O, B>, v3: ObjectBuilder<O, C>, v4: ObjectBuilder<O, D>, v5: ObjectBuilder<O, E>): ObjectBuilder<O, F>
    return v5.ap(ap4(Functions5.curry(f), v1, v2, v3, v4));

  inline static public function ap6<O, X, A, B, C, D, E, F, G>(
      f: A -> B -> C -> D -> E -> F -> G,
      v1: ObjectBuilder<O, A>, v2: ObjectBuilder<O, B>, v3: ObjectBuilder<O, C>, v4: ObjectBuilder<O, D>, v5: ObjectBuilder<O, E>,
      v6: ObjectBuilder<O, F>): ObjectBuilder<O, G>
    return v6.ap(ap5(Functions6.curry(f), v1, v2, v3, v4, v5));

  inline static public function ap7<O, X, A, B, C, D, E, F, G, H>(
      f: A -> B -> C -> D -> E -> F -> G -> H,
      v1: ObjectBuilder<O, A>, v2: ObjectBuilder<O, B>, v3: ObjectBuilder<O, C>, v4: ObjectBuilder<O, D>, v5: ObjectBuilder<O, E>,
      v6: ObjectBuilder<O, F>, v7: ObjectBuilder<O, G>): ObjectBuilder<O, H>
    return v7.ap(ap6(Functions7.curry(f), v1, v2, v3, v4, v5, v6));

  inline static public function ap8<O, X, A, B, C, D, E, F, G, H, I>(
      f: A -> B -> C -> D -> E -> F -> G -> H -> I,
      v1: ObjectBuilder<O, A>, v2: ObjectBuilder<O, B>, v3: ObjectBuilder<O, C>, v4: ObjectBuilder<O, D>, v5: ObjectBuilder<O, E>,
      v6: ObjectBuilder<O, F>, v7: ObjectBuilder<O, G>, v8: ObjectBuilder<O, H>): ObjectBuilder<O, I>
    return v8.ap(ap7(Functions8.curry(f), v1, v2, v3, v4, v5, v6, v7));

  inline static public function ap9<O, X, A, B, C, D, E, F, G, H, I, J>(
      f: A -> B -> C -> D -> E -> F -> G -> H -> I -> J,
      v1: ObjectBuilder<O, A>, v2: ObjectBuilder<O, B>, v3: ObjectBuilder<O, C>, v4: ObjectBuilder<O, D>, v5: ObjectBuilder<O, E>,
      v6: ObjectBuilder<O, F>, v7: ObjectBuilder<O, G>, v8: ObjectBuilder<O, H>, v9: ObjectBuilder<O, I>): ObjectBuilder<O, J>
    return v9.ap(ap8(Functions9.curry(f), v1, v2, v3, v4, v5, v6, v7, v8));
}
