package thx.schema;

import haxe.ds.Option;

import thx.Functions;
import thx.Unit;
import thx.Functions.identity;
import thx.fp.Functions.const;
using thx.Bools;

import thx.schema.Schema;
using thx.schema.SchemaExtensions;

class SchemaDSL {
  public static function lift<O, A, E>(s: PropSchema<O, A, E>): ObjectBuilder<O, A, E>
    return Ap(s, Pure(function(a: A) return a));

  //
  // Constructors for terminal schema elements
  //

  public static function bool<E>():   Schema<Bool, E>   return BoolSchema;
  public static function float<E>():  Schema<Float, E>  return FloatSchema;
  public static function int<E>():    Schema<Int, E>    return IntSchema;
  public static function string<E>(): Schema<String, E> return StrSchema;

  public static function array<A, E>(elemSchema: Schema<A, E>): Schema<Array<A>, E>
    return ArraySchema(elemSchema);

  public static function map<A, E>(elemSchema: Schema<A, E>): Schema<Map<String, A>, E>
    return MapSchema(elemSchema);

  public static function object<A, E>(propSchema: ObjectBuilder<A, A, E>): Schema<A, E>
    return ObjectSchema(propSchema);

  public static function oneOf<A, E>(alternatives: Array<Alternative<A, E>>): Schema<A, E>
    return OneOfSchema(alternatives);

  public static function iso<A, B, E>(base: Schema<A, E>, f: A -> B, g: B -> A): Schema<B, E>
    return ParseSchema(base, function(a: A) return PSuccess(f(a)), g);

  public static function parse<A, B, E>(base: Schema<A, E>, f: A -> ParseResult<A, B, E>, g: B -> A): Schema<B, E>
    return ParseSchema(base, f, g);

  public static function lazy<A, E>(base: Void -> Schema<A, E>): Schema<A, E>
    return LazySchema(base);

  public static function constant<A, E>(a: A): Schema<A, E>
    return ConstSchema(a);

  //
  // Constructors for oneOf alternatives
  //
  public static function alt<A, B, E>(id: String, base: Schema<B, E>, f: B -> A, g: A -> Option<B>): Alternative<A, E>
    return Prism(id, base, f, g);

  public static function constAlt<B, E>(id: String, b: B, equal: B -> B -> Bool): Alternative<B, E>
    return Prism(id, constant(b), identity, function(b0) return equal(b, b0).option(b));

  public static function constEnum<B : EnumValue, E>(id: String, b: B): Alternative<B, E>
    return constAlt(id, b, Type.enumEq);

  macro public static function makeAlt(id: haxe.macro.Expr.ExprOf<String>, rest: Array<haxe.macro.Expr>)
    return SchemaDSLM.makeVar(id, rest);

  public static function makeOptional<A, E>(s: Schema<A, E>): Schema<Option<A>, E>
    return oneOf([
      alt("some", s, function(a: A) return Some(a), thx.Functions.identity),
      constAlt("none", None, function(a: Option<A>, b: Option<A>) return a == b)
    ]);

  //
  // Constructors for object properties.
  //

  public static function required<O, A, E>(fieldName: String, valueSchema: Schema<A, E>, accessor: O -> A): ObjectBuilder<O, A, E>
    return lift(Required(fieldName, valueSchema, accessor));

  public static function optional<O, A, E>(fieldName: String, valueSchema: Schema<A, E>, accessor: O -> Option<A>): ObjectBuilder<O, Option<A>, E>
    return lift(Optional(fieldName, valueSchema, accessor));

  // Convenience constructor for a single-property object schema that simply wraps another schema.
  public static function wrap<A, E>(fieldName: String, valueSchema: Schema<A, E>): Schema<A, E>
    return object(required(fieldName, valueSchema, identity));

  //
  // Combinators for building complex schemas
  //
  inline static public function ap1<O, E, A, B>(
      f: A -> B,
      v1: ObjectBuilder<O, A, E>): ObjectBuilder<O, B, E>
    return v1.map(f);

  inline static public function ap2<O, E, A, B, C>(
      f: A -> B -> C,
      v1: ObjectBuilder<O, A, E>, v2: ObjectBuilder<O, B, E>): ObjectBuilder<O, C, E>
    return v2.ap(v1.map(Functions2.curry(f)));

  inline static public function ap3<O, E, A, B, C, D>(
      f: A -> B -> C -> D,
      v1: ObjectBuilder<O, A, E>, v2: ObjectBuilder<O, B, E>, v3: ObjectBuilder<O, C, E>): ObjectBuilder<O, D, E>
    return v3.ap(ap2(Functions3.curry(f), v1, v2));

  inline static public function ap4<O, E, A, B, C, D, F>(
      f: A -> B -> C -> D -> F,
      v1: ObjectBuilder<O, A, E>, v2: ObjectBuilder<O, B, E>, v3: ObjectBuilder<O, C, E>, v4: ObjectBuilder<O, D, E>): ObjectBuilder<O, F, E>
    return v4.ap(ap3(Functions4.curry(f), v1, v2, v3));

  inline static public function ap5<O, E, A, B, C, D, F, G>(
      f: A -> B -> C -> D -> F -> G,
      v1: ObjectBuilder<O, A, E>, v2: ObjectBuilder<O, B, E>, v3: ObjectBuilder<O, C, E>, v4: ObjectBuilder<O, D, E>, v5: ObjectBuilder<O, F, E>): ObjectBuilder<O, G, E>
    return v5.ap(ap4(Functions5.curry(f), v1, v2, v3, v4));

  inline static public function ap6<O, E, A, B, C, D, F, G, H>(
      f: A -> B -> C -> D -> F -> G -> H,
      v1: ObjectBuilder<O, A, E>, v2: ObjectBuilder<O, B, E>, v3: ObjectBuilder<O, C, E>, v4: ObjectBuilder<O, D, E>, v5: ObjectBuilder<O, F, E>,
      v6: ObjectBuilder<O, G, E>): ObjectBuilder<O, H, E>
    return v6.ap(ap5(Functions6.curry(f), v1, v2, v3, v4, v5));

  inline static public function ap7<O, E, A, B, C, D, F, G, H, I>(
      f: A -> B -> C -> D -> F -> G -> H -> I,
      v1: ObjectBuilder<O, A, E>, v2: ObjectBuilder<O, B, E>, v3: ObjectBuilder<O, C, E>, v4: ObjectBuilder<O, D, E>, v5: ObjectBuilder<O, F, E>,
      v6: ObjectBuilder<O, G, E>, v7: ObjectBuilder<O, H, E>): ObjectBuilder<O, I, E>
    return v7.ap(ap6(Functions7.curry(f), v1, v2, v3, v4, v5, v6));

  inline static public function ap8<O, E, A, B, C, D, F, G, H, I, J>(
      f: A -> B -> C -> D -> F -> G -> H -> I -> J,
      v1: ObjectBuilder<O, A, E>, v2: ObjectBuilder<O, B, E>, v3: ObjectBuilder<O, C, E>, v4: ObjectBuilder<O, D, E>, v5: ObjectBuilder<O, F, E>,
      v6: ObjectBuilder<O, G, E>, v7: ObjectBuilder<O, H, E>, v8: ObjectBuilder<O, I, E>): ObjectBuilder<O, J, E>
    return v8.ap(ap7(Functions8.curry(f), v1, v2, v3, v4, v5, v6, v7));

  inline static public function ap9<O, E, A, B, C, D, F, G, H, I, J, K>(
      f: A -> B -> C -> D -> F -> G -> H -> I -> J -> K,
      v1: ObjectBuilder<O, A, E>, v2: ObjectBuilder<O, B, E>, v3: ObjectBuilder<O, C, E>, v4: ObjectBuilder<O, D, E>, v5: ObjectBuilder<O, F, E>,
      v6: ObjectBuilder<O, G, E>, v7: ObjectBuilder<O, H, E>, v8: ObjectBuilder<O, I, E>, v9: ObjectBuilder<O, J, E>): ObjectBuilder<O, K, E>
    return v9.ap(ap8(Functions9.curry(f), v1, v2, v3, v4, v5, v6, v7, v8));
}
