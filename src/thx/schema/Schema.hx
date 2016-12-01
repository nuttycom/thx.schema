package thx.schema;

import haxe.ds.Option;

/**
 * A GADT describing the elements of a JSON-compatible Haxe object schema.
 * Generally, you shouldn't use the constructors of this type
 * directly, but instead use those provided as convenience methods in SchemaDSL.
 */
enum Schema<A, E> {
  BoolSchema:  Schema<Bool, E>;
  FloatSchema: Schema<Float, E>;
  IntSchema:   Schema<Int, E>;
  StrSchema:   Schema<String, E>;

  ObjectSchema<B>(propSchema: ObjectBuilder<B, B, E>): Schema<B, E>;
  ArraySchema<B>(elemSchema: Schema<B, E>): Schema<Array<B>, E>;
  MapSchema<B>(elemSchema: Schema<B, E>): Schema<Map<String, B>, E>; // interpret as a String-keyed map instead of an object value

  // schema for sum types
  OneOfSchema<B>(alternatives: Array<Alternative<B, E>>): Schema<B, E>;

  // This allows us to create schemas that impose more constraints on
  // the type of source data than merely being isomorphic to a primitive
  // value type.
  ParseSchema<B, C>(base: Schema<B, E>, f: B -> ParseResult<B, C, E>, g: C -> B): Schema<C, E>;

  // Schema that always parses to or generates a constant value. 
  ConstSchema<B>(value: B): Schema<B, E>;

  // Lazy wrapper for schema values to permit recursive schema definitions.
  LazySchema<B>(delay: Void -> Schema<B, E>): Schema<B, E>;
}

enum ParseResult<S, A, E> {
  PSuccess(result: A);
  PFailure(error: E, sourceData: S);
}

enum Alternative<A, E> {
  Prism<A, B>(id: String, base: Schema<B, E>, f: B -> A, g: A -> Option<B>): Alternative<A, E>;
}

enum PropSchema<O, A, E> {
  Required<B>(fieldName: String, valueSchema: Schema<B, E>, accessor: O -> B): PropSchema<O, B, E>;
  Optional<B>(fieldName: String, valueSchema: Schema<B, E>, accessor: O -> Option<B>): PropSchema<O, Option<B>, E>;
}

/** Free applicative construction of builder for a set of object properties. */
enum ObjectBuilder<O, A, E> {
  Pure(a: A);
  Ap<I>(s: PropSchema<O, I, E>, k: ObjectBuilder<O, I -> A, E>);
}

typedef HomObjectBuilder<A, E> = ObjectBuilder<A, A, E>;

enum SType {
  BoolSType;
  FloatSType;
  IntSType;
  StrSType;
  ConstSType;
  ObjectSType;
  ArraySType;
  MapSType;
  OneOfSType;
}
