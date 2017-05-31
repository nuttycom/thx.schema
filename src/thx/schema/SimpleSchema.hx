package thx.schema;

import haxe.ds.Option;

import thx.Functions;
import thx.Unit;
import thx.Functions.identity;
import thx.fp.Functions.const;
using thx.Bools;

import thx.schema.SchemaF;
import thx.schema.SchemaDSL.*;
using thx.schema.SchemaFExtensions;

typedef Schema<E, A> = AnnotatedSchema<E, Unit, A>

class SimpleSchema {
  //
  // Constructors for terminal schema elements
  //

  public static function liftS<E, A>(s: SchemaF<E, Unit, A>): Schema<E, A>
    return new AnnotatedSchema(unit, s);

  public static function bool<E>():   Schema<E, Bool>   return liftS(BoolSchema);
  public static function float<E>():  Schema<E, Float>  return liftS(FloatSchema);
  public static function int<E>():    Schema<E, Int>    return liftS(IntSchema);
  public static function string<E>(): Schema<E, String> return liftS(StrSchema);
  public static function any<E>():    Schema<E, thx.Any> return liftS(AnySchema);
  public static function constant<E, A>(a: A): Schema<E, A> return liftS(ConstSchema(a));

  public static function array<E, A>(elemSchema: Schema<E, A>): Schema<E, Array<A>>
    return liftS(ArraySchema(elemSchema));

  public static function dict<E, A>(requiredKeys: Array<String>, elemSchema: Schema<E, A>): Schema<E, Map<String, A>>
    return liftS(MapSchema(requiredKeys, elemSchema));

  public static function object<E, A>(propSchema: ObjectBuilder<E, Unit, A>): Schema<E, A>
    return liftS(ObjectSchema(propSchema));

  public static function oneOf<E, A>(alternatives: Array<Alternative<E, Unit, A>>): Schema<E, A>
    return liftS(OneOfSchema(alternatives));

  public static function lazy<E, A>(base: Void -> SchemaF<E, Unit, A>): Schema<E, A>
    return liftS(LazySchema(base));

  //
  // Constructors for oneOf alternatives
  //

  public static function alt<E, A, B>(id: String, base: AnnotatedSchema<E, Unit, B>, f: B -> A, g: A -> Option<B>): Alternative<E, Unit, A>
    return Prism(id, base, unit, f, g);

  macro public static function makeAlt(id: haxe.macro.Expr.ExprOf<String>, rest: Array<haxe.macro.Expr>)
    return SchemaDSLM.makeVar(id, rest);

  public static function constAlt<E, B>(id: String, b: B, equal: B -> B -> Bool): Alternative<E, Unit, B>
    return Prism(id, constant(b), unit, identity, function(b0) return equal(b, b0).option(b));

  public static function constEnum<E, B : EnumValue>(id: String, b: B): Alternative<E, Unit, B>
    return constAlt(id, b, Type.enumEq);

  public static function makeOptional<E, A>(s: Schema<E, A>): Schema<E, Option<A>>
    return oneOf([
      alt("some", s, function(a: A) return Some(a), thx.Functions.identity),
      constAlt("none", None, function(a: Option<A>, b: Option<A>) return a == b)
    ]);

  // Convenience constructor for a single-property object schema that simply wraps another schema.
  public static function wrap<E, A>(fieldName: String, valueSchema: Schema<E, A>): Schema<E, A>
    return object(required(fieldName, valueSchema, identity));
}
