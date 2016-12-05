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
  public static function lift<E, O, A>(s: PropSchema<E, O, A>): ObjectBuilder<E, O, A>
    return Ap(s, Pure(function(a: A) return a));

  //
  // Constructors for terminal schema elements
  //

  public static function bool<E>():   Schema<E, Bool>   return BoolSchema;
  public static function float<E>():  Schema<E, Float>  return FloatSchema;
  public static function int<E>():    Schema<E, Int>    return IntSchema;
  public static function string<E>(): Schema<E, String> return StrSchema;
  public static function constant<E, A>(a: A): Schema<E, A> return ConstSchema(a);

  public static function array<E, A>(elemSchema: Schema<E, A>): Schema<E, Array<A>>
    return ArraySchema(elemSchema);

  public static function map<E, A>(elemSchema: Schema<E, A>): Schema<E, Map<String, A>>
    return MapSchema(elemSchema);

  public static function object<E, A>(propSchema: ObjectBuilder<E, A, A>): Schema<E, A>
    return ObjectSchema(propSchema);

  public static function oneOf<E, A>(alternatives: Array<Alternative<E, A>>): Schema<E, A>
    return OneOfSchema(alternatives);

  public static function iso<E, A, B>(base: Schema<E, A>, f: A -> B, g: B -> A): Schema<E, B>
    return ParseSchema(base, function(a: A) return PSuccess(f(a)), g);

  public static function parse<E, A, B>(base: Schema<E, A>, f: A -> ParseResult<E, A, B>, g: B -> A): Schema<E, B>
    return ParseSchema(base, f, g);

  public static function lazy<E, A>(base: Void -> Schema<E, A>): Schema<E, A>
    return LazySchema(base);


  //
  // Constructors for oneOf alternatives
  //
  public static function alt<E, A, B>(id: String, base: Schema<E, B>, f: B -> A, g: A -> Option<B>): Alternative<E, A>
    return Prism(id, base, f, g);

  public static function constAlt<E, B>(id: String, b: B, equal: B -> B -> Bool): Alternative<E, B>
    return Prism(id, constant(b), identity, function(b0) return equal(b, b0).option(b));

  public static function constEnum<E, B : EnumValue>(id: String, b: B): Alternative<E, B>
    return constAlt(id, b, Type.enumEq);

  macro public static function makeAlt(id: haxe.macro.Expr.ExprOf<String>, rest: Array<haxe.macro.Expr>)
    return SchemaDSLM.makeVar(id, rest);

  public static function makeOptional<E, A>(s: Schema<E, A>): Schema<E, Option<A>>
    return oneOf([
      alt("some", s, function(a: A) return Some(a), thx.Functions.identity),
      constAlt("none", None, function(a: Option<A>, b: Option<A>) return a == b)
    ]);

  //
  // Constructors for object properties.
  //

  public static function required<E, O, A>(fieldName: String, valueSchema: Schema<E, A>, accessor: O -> A): ObjectBuilder<E, O, A>
    return lift(Required(fieldName, valueSchema, accessor));

  public static function optional<E, O, A>(fieldName: String, valueSchema: Schema<E, A>, accessor: O -> Option<A>): ObjectBuilder<E, O, Option<A>>
    return lift(Optional(fieldName, valueSchema, accessor));

  // Convenience constructor for a single-property object schema that simply wraps another schema.
  public static function wrap<E, A>(fieldName: String, valueSchema: Schema<E, A>): Schema<E, A>
    return object(required(fieldName, valueSchema, identity));

  //
  // Combinators for building complex schemas
  //
  inline static public function ap1<E, O, A, B>(
      f: A -> B,
      v1: ObjectBuilder<E, O, A>): ObjectBuilder<E, O, B>
    return v1.map(f);

  inline static public function ap2<E, O, A, B, C>(
      f: A -> B -> C,
      v1: ObjectBuilder<E, O, A>, v2: ObjectBuilder<E, O, B>): ObjectBuilder<E, O, C>
    return v2.ap(v1.map(Functions2.curry(f)));

  inline static public function ap3<E, O, A, B, C, D>(
      f: A -> B -> C -> D,
      v1: ObjectBuilder<E, O, A>, v2: ObjectBuilder<E, O, B>, v3: ObjectBuilder<E, O, C>): ObjectBuilder<E, O, D>
    return v3.ap(ap2(Functions3.curry(f), v1, v2));

  inline static public function ap4<E, O, A, B, C, D, F>(
      f: A -> B -> C -> D -> F,
      v1: ObjectBuilder<E, O, A>, v2: ObjectBuilder<E, O, B>, v3: ObjectBuilder<E, O, C>, v4: ObjectBuilder<E, O, D>): ObjectBuilder<E, O, F>
    return v4.ap(ap3(Functions4.curry(f), v1, v2, v3));

  inline static public function ap5<E, O, A, B, C, D, F, G>(
      f: A -> B -> C -> D -> F -> G,
      v1: ObjectBuilder<E, O, A>, v2: ObjectBuilder<E, O, B>, v3: ObjectBuilder<E, O, C>, v4: ObjectBuilder<E, O, D>, v5: ObjectBuilder<E, O, F>): ObjectBuilder<E, O, G>
    return v5.ap(ap4(Functions5.curry(f), v1, v2, v3, v4));

  inline static public function ap6<E, O, A, B, C, D, F, G, H>(
      f: A -> B -> C -> D -> F -> G -> H,
      v1: ObjectBuilder<E, O, A>, v2: ObjectBuilder<E, O, B>, v3: ObjectBuilder<E, O, C>, v4: ObjectBuilder<E, O, D>, v5: ObjectBuilder<E, O, F>,
      v6: ObjectBuilder<E, O, G>): ObjectBuilder<E, O, H>
    return v6.ap(ap5(Functions6.curry(f), v1, v2, v3, v4, v5));

  inline static public function ap7<E, O, A, B, C, D, F, G, H, I>(
      f: A -> B -> C -> D -> F -> G -> H -> I,
      v1: ObjectBuilder<E, O, A>, v2: ObjectBuilder<E, O, B>, v3: ObjectBuilder<E, O, C>, v4: ObjectBuilder<E, O, D>, v5: ObjectBuilder<E, O, F>,
      v6: ObjectBuilder<E, O, G>, v7: ObjectBuilder<E, O, H>): ObjectBuilder<E, O, I>
    return v7.ap(ap6(Functions7.curry(f), v1, v2, v3, v4, v5, v6));

  inline static public function ap8<E, O, A, B, C, D, F, G, H, I, J>(
      f: A -> B -> C -> D -> F -> G -> H -> I -> J,
      v1: ObjectBuilder<E, O, A>, v2: ObjectBuilder<E, O, B>, v3: ObjectBuilder<E, O, C>, v4: ObjectBuilder<E, O, D>, v5: ObjectBuilder<E, O, F>,
      v6: ObjectBuilder<E, O, G>, v7: ObjectBuilder<E, O, H>, v8: ObjectBuilder<E, O, I>): ObjectBuilder<E, O, J>
    return v8.ap(ap7(Functions8.curry(f), v1, v2, v3, v4, v5, v6, v7));

  inline static public function ap9<E, O, A, B, C, D, F, G, H, I, J, K>(
      f: A -> B -> C -> D -> F -> G -> H -> I -> J -> K,
      v1: ObjectBuilder<E, O, A>, v2: ObjectBuilder<E, O, B>, v3: ObjectBuilder<E, O, C>, v4: ObjectBuilder<E, O, D>, v5: ObjectBuilder<E, O, F>,
      v6: ObjectBuilder<E, O, G>, v7: ObjectBuilder<E, O, H>, v8: ObjectBuilder<E, O, I>, v9: ObjectBuilder<E, O, J>): ObjectBuilder<E, O, K>
    return v9.ap(ap8(Functions9.curry(f), v1, v2, v3, v4, v5, v6, v7, v8));
}
