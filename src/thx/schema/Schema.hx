package thx.schema;

import haxe.ds.Option;

import thx.Options;
import thx.Monoid;
import thx.Nel;
import thx.Validation;
import thx.Validation.*;
import thx.Unit;
import thx.Ints;
import thx.Floats;
import thx.fp.Functions.flip;
import thx.fp.Writer;

using thx.Arrays;
using thx.Functions;
using thx.Iterators;
using thx.Maps;
using thx.Options;
using thx.Objects;

/**
 * A GADT describing the elements of a JSON-compatible Haxe object schema.
 * Generally, you shouldn't use the constructors of this type
 * directly, but instead use those provided as convenience methods in SchemaDSL.
 */
enum Schema<A> {
  BoolSchema: Schema<Bool>;
  FloatSchema: Schema<Float>;
  IntSchema: Schema<Int>;
  StrSchema: Schema<String>;

  ObjectSchema<B>(propSchema: ObjectBuilder<B>): Schema<B>;
  ArraySchema<B>(elemSchema: Schema<B>): Schema<Array<B>>;

  // It is a little awkward to add this to the schema algebra, but we need a 
  // prism to be able to create schemas that parse to newtype wrappers.
  CoYoneda<B, C>(base: Schema<B>, f: B -> C): Schema<C>;
  //Prism<B, C>(base: Schema<B>, f: B -> Option<C>, g: C -> B): Schema<C>;
}

enum PropSchema<A> {
  Required<B>(fieldName: String, valueSchema: Schema<B>): PropSchema<B>;
  Optional<B>(fieldName: String, valueSchema: Schema<B>): PropSchema<Option<B>>;
}

/** Free applicative construction of builder for a set of object properties. */
enum ObjectBuilder<A> {
  Pure(a: A);
  Ap<I>(s: PropSchema<I>, k: ObjectBuilder<I -> A>);
}

class SchemaDSL {
  public static function lift<A>(s: PropSchema<A>): ObjectBuilder<A>
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

  public static function object<A>(propSchema: ObjectBuilder<A>): Schema<A>
    return ObjectSchema(propSchema);

  public static function mapped<A, B>(base: Schema<A>, f: A -> B): Schema<B>
    return CoYoneda(base, f);

  //
  // Constructors for object properties. TODO: Create some intermediate typedefs to make 
  // a fluent interface for this construction.
  //

  public static function required<A>(fieldName: String, valueSchema: Schema<A>): ObjectBuilder<A>
    return lift(Required(fieldName, valueSchema));

  public static function optional<A>(fieldName: String, valueSchema: Schema<A>): ObjectBuilder<Option<A>>
    return lift(Optional(fieldName, valueSchema));

  //
  // Combinators for building complex schemas
  //

  inline static public function ap2<X, A, B, C>(
      f: A -> B -> C, 
      v1: ObjectBuilder<A>, v2: ObjectBuilder<B>): ObjectBuilder<C>
    return SchemaExtensions.ap(v2, SchemaExtensions.map(v1, Functions2.curry(f)));

  inline static public function ap3<X, A, B, C, D>(
      f: A -> B -> C -> D, 
      v1: ObjectBuilder<A>, v2: ObjectBuilder<B>, v3: ObjectBuilder<C>): ObjectBuilder<D>
    return SchemaExtensions.ap(v3, ap2(Functions3.curry(f), v1, v2));

  inline static public function ap4<X, A, B, C, D, E>(
      f: A -> B -> C -> D -> E,
      v1: ObjectBuilder<A>, v2: ObjectBuilder<B>, v3: ObjectBuilder<C>, v4: ObjectBuilder<D>): ObjectBuilder<E>
    return SchemaExtensions.ap(v4, ap3(Functions4.curry(f), v1, v2, v3));

  inline static public function ap5<X, A, B, C, D, E, F>(
      f: A -> B -> C -> D -> E -> F,
      v1: ObjectBuilder<A>, v2: ObjectBuilder<B>, v3: ObjectBuilder<C>, v4: ObjectBuilder<D>, v5: ObjectBuilder<E>): ObjectBuilder<F>
    return SchemaExtensions.ap(v5, ap4(Functions5.curry(f), v1, v2, v3, v4));

  inline static public function ap6<X, A, B, C, D, E, F, G>(
      f: A -> B -> C -> D -> E -> F -> G,
      v1: ObjectBuilder<A>, v2: ObjectBuilder<B>, v3: ObjectBuilder<C>, v4: ObjectBuilder<D>, v5: ObjectBuilder<E>, v6: ObjectBuilder<F>): ObjectBuilder<G>
    return SchemaExtensions.ap(v6, ap5(Functions6.curry(f), v1, v2, v3, v4, v5));

  inline static public function ap7<X, A, B, C, D, E, F, G, H>(
      f: A -> B -> C -> D -> E -> F -> G -> H,
      v1: ObjectBuilder<A>, v2: ObjectBuilder<B>, v3: ObjectBuilder<C>, v4: ObjectBuilder<D>, v5: ObjectBuilder<E>, v6: ObjectBuilder<F>, v7: ObjectBuilder<G>): ObjectBuilder<H>
    return SchemaExtensions.ap(v7, ap6(Functions7.curry(f), v1, v2, v3, v4, v5, v6));

  inline static public function ap8<X, A, B, C, D, E, F, G, H, I>(
      f: A -> B -> C -> D -> E -> F -> G -> H -> I,
      v1: ObjectBuilder<A>, v2: ObjectBuilder<B>, v3: ObjectBuilder<C>, v4: ObjectBuilder<D>, v5: ObjectBuilder<E>, v6: ObjectBuilder<F>, v7: ObjectBuilder<G>, v8: ObjectBuilder<H>): ObjectBuilder<I>
    return SchemaExtensions.ap(v8, ap7(Functions8.curry(f), v1, v2, v3, v4, v5, v6, v7));
}

/**
 * A couple of useful interpreters for Schema values. This class is intended
 * to be imported via 'using'.
 */
class SchemaExtensions {
  public static function map<A, B>(s: ObjectBuilder<A>, f: A -> B): ObjectBuilder<B> {
    // helper function used to unpack existential type I
    inline function go<I>(s: PropSchema<I>, k: ObjectBuilder<I -> A>): ObjectBuilder<B> {
      return Ap(s, map(k, f.compose));
    }

    return switch s {
      case Pure(a): Pure(f(a));
      case Ap(s, k): go(s, k);
    };
  }

  public static function ap<A, B>(s: ObjectBuilder<A>, f: ObjectBuilder<A -> B>): ObjectBuilder<B> {
    // helper function used to unpack existential type I
    inline function go<I>(si: PropSchema<I>, ki: ObjectBuilder<I -> (A -> B)>): ObjectBuilder<B> {
      return Ap(si, ap(s, map(ki, flip)));
    }

    return switch f {
      case Pure(g): map(s, g);
      case Ap(fs, fk): go(fs, fk);
    };
  }

  public static function parse<A>(schema: Schema<A>, v: Dynamic): VNel<String, A> {
    // helper function used to unpack existential type I
    return switch schema {
      case IntSchema:
        switch Type.typeof(v) {
          case TInt :   successNel(cast v);
          case TClass(name) :
            switch Type.getClassName(Type.getClass(v)) {
              case "String" if (Ints.canParse(v)) : successNel(Ints.parse(cast v));
              case other: failureNel('Cannot parse an integer value from $v (type resolved to $other)');
            };

          case other: failureNel('Cannot parse an integer value from $v (type resolved to $other)');
        }

      case FloatSchema:
        return switch Type.typeof(v) {
          case TInt :   successNel(cast v);
          case TFloat : successNel(cast v);
          case TClass(name) :
            switch Type.getClassName(Type.getClass(v)) {
              case "String" if (Floats.canParse(v)) : successNel(Floats.parse(cast v));
              case other: failureNel('Cannot parse a floating-point value from $v (type resolved to $other)');
            };
          case other: failureNel('Cannot parse a floating-point value from $v (type resolved to $other)');
        };

      case StrSchema:
        return switch Type.typeof(v) {
          case TClass(name) :
            switch Type.getClassName(Type.getClass(v)) {
              case "String": successNel(cast v);
              case other: failureNel('$v is not a String value (type resolved to $other)');
            };
          case other: failureNel('$v is not a String value (type resolved to $other)');
        };

      case BoolSchema:
        return switch Type.typeof(v) {
          case TBool: successNel(cast v);
          case TClass(name) :
            switch Type.getClassName(Type.getClass(v)) {
              case "String" if (Bools.canParse(v)) : successNel(Bools.parse(cast v));
              case other: failureNel('Cannot parse a boolean value from $v (type resolved to $other)');
            };
          case other: failureNel('Cannot parse a boolean value from $v (type resolved to $other)');
        };

      case ObjectSchema(propSchema):
        parseObject(propSchema, v);

      case ArraySchema(elemSchema): 
        return switch Type.typeof(v) {
          case TClass(name) :
            switch Type.getClassName(Type.getClass(v)) {
              case "Array": (v: Array<Dynamic>).traverseValidation(parse.bind(elemSchema, _), Nel.semigroup());
              case other: failureNel('$v is not array-valued (type resolved to $other)');
            };
          case other: failureNel('$v is not array-valued (type resolved to $other)');
        };

      case CoYoneda(base, f): 
        parse(base, v).map(f);
    };
  }

  public static function parseProperty<A>(ob: {}, name: String, f: Dynamic -> VNel<String, A>): VNel<String, A>
    return nnNel(ob.getPath(name), 'Property "$name" was not found.').flatMapV(f);

  public static function parseOptionalProperty<A>(ob: {}, name: String, f: Dynamic -> VNel<String, A>): VNel<String, Option<A>> {
    var property = ob.getPath(name);
    return if (property != null) f(property).map(function(a) return Some(a)) else successNel(None);
  }

  public static function parseObject<A>(builder: ObjectBuilder<A>, ob: {}): VNel<String, A> {
    // helper function used to unpack existential type I
    inline function go<I>(schema: PropSchema<I>, k: ObjectBuilder<I -> A>): VNel<String, A> {
      var parsed: VNel<String, I> = switch schema {
        case Required(fieldName, valueSchema):
          nnNel(ob.getPath(fieldName), 'Property "$fieldName" was not found in $ob').flatMapV(parse.bind(valueSchema, _));

        case Optional(fieldName, valueSchema):
          Options.ofValue(ob.getPath(fieldName)).traverseValidation(parse.bind(valueSchema, _));
      };

      return parsed.ap(parseObject(k, ob), Nel.semigroup());
    }

    return switch builder {
      case Pure(a): successNel(a);
      case Ap(s, k): go(s, k);
    };
  }

  /**
   * Transform the schema to a generator for example values of the specified type. 
   * TODO: Schema<A> -> Gen<A>
   */
  public static function exemplar<A>(schema: Schema<A>): A {
    return switch schema {
      case IntSchema:  0;
      case FloatSchema:  0.0;
      case BoolSchema: false;
      case StrSchema:  "";

      case ObjectSchema(propSchema):  objectExemplar(propSchema);
      case ArraySchema(elemSchema):   [exemplar(elemSchema)];
      case CoYoneda(base, f): f(exemplar(base));
    }
  } 

  public static function objectExemplar<A>(builder: ObjectBuilder<A>): A {
    inline function go<I>(schema: PropSchema<I>, k: ObjectBuilder<I -> A>): A {
      var i: I = switch schema {
        case Required(_, s0): exemplar(s0);
        case Optional(_, s0): Some(exemplar(s0));
      };

      return objectExemplar(k)(i);
    }

    return switch builder {
      case Pure(a): a;
      case Ap(s, k): go(s, k);
    }
  }
}
