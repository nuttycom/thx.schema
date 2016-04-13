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
import thx.Functions.identity;
import thx.fp.Dynamics;
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

  ObjectSchema<B>(propSchema: ObjectBuilder<B, B>): Schema<B>;
  ArraySchema<B>(elemSchema: Schema<B>): Schema<Array<B>>;

  // schema for sum types
  OneOfSchema<B>(alternatives: Array<Alternative<B>>): Schema<B>;

  // This allows us to create schemas that parse to newtype wrappers
  IsoSchema<B, C>(base: Schema<B>, f: B -> C, g: C -> B): Schema<C>;
}

enum Alternative<A> {
  Prism<B>(id: String, base: Schema<B>, f: B -> A, g: A -> Option<B>);
}

enum PropSchema<O, A> {
  Required<B>(fieldName: String, valueSchema: Schema<B>, accessor: O -> B): PropSchema<O, B>;
  Optional<B>(fieldName: String, valueSchema: Schema<B>, accessor: O -> Option<B>): PropSchema<O, Option<B>>;
}

/** Free applicative construction of builder for a set of object properties. */
enum ObjectBuilder<O, A> {
  Pure(a: A);
  Ap<I>(s: PropSchema<O, I>, k: ObjectBuilder<O, I -> A>);
}

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

  //
  // Constructors for oneOf alternatives
  //

  public static function alt<A, B>(id: String, base: Schema<B>, f: B -> A, g: A -> Option<B>): Alternative<A>
    return Prism(id, base, f, g);

  //
  // Constructors for object properties. TODO: Create some intermediate typedefs to make 
  // a fluent interface for this construction.
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
    return SchemaExtensions.map(v1, f);

  inline static public function ap2<O, X, A, B, C>(
      f: A -> B -> C,
      v1: ObjectBuilder<O, A>, v2: ObjectBuilder<O, B>): ObjectBuilder<O, C>
    return SchemaExtensions.ap(v2, SchemaExtensions.map(v1, Functions2.curry(f)));

  inline static public function ap3<O, X, A, B, C, D>(
      f: A -> B -> C -> D,
      v1: ObjectBuilder<O, A>, v2: ObjectBuilder<O, B>, v3: ObjectBuilder<O, C>): ObjectBuilder<O, D>
    return SchemaExtensions.ap(v3, ap2(Functions3.curry(f), v1, v2));

  inline static public function ap4<O, X, A, B, C, D, E>(
      f: A -> B -> C -> D -> E,
      v1: ObjectBuilder<O, A>, v2: ObjectBuilder<O, B>, v3: ObjectBuilder<O, C>, v4: ObjectBuilder<O, D>): ObjectBuilder<O, E>
    return SchemaExtensions.ap(v4, ap3(Functions4.curry(f), v1, v2, v3));

  inline static public function ap5<O, X, A, B, C, D, E, F>(
      f: A -> B -> C -> D -> E -> F,
      v1: ObjectBuilder<O, A>, v2: ObjectBuilder<O, B>, v3: ObjectBuilder<O, C>, v4: ObjectBuilder<O, D>, v5: ObjectBuilder<O, E>): ObjectBuilder<O, F>
    return SchemaExtensions.ap(v5, ap4(Functions5.curry(f), v1, v2, v3, v4));

  inline static public function ap6<O, X, A, B, C, D, E, F, G>(
      f: A -> B -> C -> D -> E -> F -> G,
      v1: ObjectBuilder<O, A>, v2: ObjectBuilder<O, B>, v3: ObjectBuilder<O, C>, v4: ObjectBuilder<O, D>, v5: ObjectBuilder<O, E>,
      v6: ObjectBuilder<O, F>): ObjectBuilder<O, G>
    return SchemaExtensions.ap(v6, ap5(Functions6.curry(f), v1, v2, v3, v4, v5));

  inline static public function ap7<O, X, A, B, C, D, E, F, G, H>(
      f: A -> B -> C -> D -> E -> F -> G -> H,
      v1: ObjectBuilder<O, A>, v2: ObjectBuilder<O, B>, v3: ObjectBuilder<O, C>, v4: ObjectBuilder<O, D>, v5: ObjectBuilder<O, E>,
      v6: ObjectBuilder<O, F>, v7: ObjectBuilder<O, G>): ObjectBuilder<O, H>
    return SchemaExtensions.ap(v7, ap6(Functions7.curry(f), v1, v2, v3, v4, v5, v6));

  inline static public function ap8<O, X, A, B, C, D, E, F, G, H, I>(
      f: A -> B -> C -> D -> E -> F -> G -> H -> I,
      v1: ObjectBuilder<O, A>, v2: ObjectBuilder<O, B>, v3: ObjectBuilder<O, C>, v4: ObjectBuilder<O, D>, v5: ObjectBuilder<O, E>,
      v6: ObjectBuilder<O, F>, v7: ObjectBuilder<O, G>, v8: ObjectBuilder<O, H>): ObjectBuilder<O, I>
    return SchemaExtensions.ap(v8, ap7(Functions8.curry(f), v1, v2, v3, v4, v5, v6, v7));

  inline static public function ap9<O, X, A, B, C, D, E, F, G, H, I, J>(
      f: A -> B -> C -> D -> E -> F -> G -> H -> I -> J,
      v1: ObjectBuilder<O, A>, v2: ObjectBuilder<O, B>, v3: ObjectBuilder<O, C>, v4: ObjectBuilder<O, D>, v5: ObjectBuilder<O, E>,
      v6: ObjectBuilder<O, F>, v7: ObjectBuilder<O, G>, v8: ObjectBuilder<O, H>, v9: ObjectBuilder<O, I>): ObjectBuilder<O, J>
    return SchemaExtensions.ap(v9, ap8(Functions9.curry(f), v1, v2, v3, v4, v5, v6, v7, v8));
}

/**
 * A couple of useful interpreters for Schema values. This class is intended
 * to be imported via 'using'.
 */
class SchemaExtensions {
  public static function contramap<N, O, A>(o: ObjectBuilder<O, A>, f: N -> O): ObjectBuilder<N, A> {
    return switch o {
      case Pure(a): Pure(a);
      case Ap(s, k): Ap(contramapPS(s, f), contramap(k, f));
    }
  }

  public static function map<O, A, B>(s: ObjectBuilder<O, A>, f: A -> B): ObjectBuilder<O, B> {
    // helper function used to unpack existential type I
    inline function go<I>(s: PropSchema<O, I>, k: ObjectBuilder<O, I -> A>): ObjectBuilder<O, B> {
      return Ap(s, map(k, f.compose));
    }

    return switch s {
      case Pure(a): Pure(f(a));
      case Ap(s, k): go(s, k);
    };
  }

  public static function ap<O, A, B>(s: ObjectBuilder<O, A>, f: ObjectBuilder<O, A -> B>): ObjectBuilder<O, B> {
    // helper function used to unpack existential type I
    inline function go<I>(si: PropSchema<O, I>, ki: ObjectBuilder<O, I -> (A -> B)>): ObjectBuilder<O, B> {
      return Ap(si, ap(s, map(ki, flip)));
    }

    return switch f {
      case Pure(g): map(s, g);
      case Ap(fs, fk): go(fs, fk);
    };
  }

  public static function contramapPS<N, O, A>(s: PropSchema<O, A>, f: N -> O): PropSchema<N, A>
    return switch s {
      case Required(n, s, a): Required(n, s, a.compose(f));
      case Optional(n, s, a): Optional(n, s, a.compose(f));
    };

  public static function id<A>(a: Alternative<A>)
    return switch a {
      case Prism(id, _, _, _): id;
    };
}

class ParseError {
  public var message(default, null): String;
  public var path(default, null): SPath;

  public function new(message: String, path: SPath) {
    this.message = message;
    this.path = path;
  }

  public function toString(): String {
    return '${path.toString()}: ${message}';
  }
}
