package thx.schema;

import haxe.ds.Option;

/**
 * A GADT describing the elements of a JSON-compatible Haxe object schema.
 * Generally, you shouldn't use the constructors of this type
 * directly, but instead use those provided as convenience methods in SchemaDSL.
 */
enum Schema<E, A> {
  BoolSchema:  Schema<E, Bool>;
  FloatSchema: Schema<E, Float>;
  IntSchema:   Schema<E, Int>;
  StrSchema:   Schema<E, String>;

  ObjectSchema<B>(propSchema: ObjectBuilder<E, B, B>): Schema<E, B>;
  ArraySchema<B>(elemSchema: Schema<E, B>): Schema<E, Array<B>>;
  MapSchema<B>(elemSchema: Schema<E, B>): Schema<E, Map<String, B>>; // interpret as a String-keyed map instead of an object value

  // schema for sum types
  OneOfSchema<B>(alternatives: Array<Alternative<E, B>>): Schema<E, B>;

  // This allows us to create schemas that impose more constraints on
  // the type of source data than merely being isomorphic to a primitive
  // value type.
  ParseSchema<B, C>(base: Schema<E, B>, f: B -> ParseResult<E, B, C>, g: C -> B): Schema<E, C>;

  // Schema that always parses to or generates a constant value. 
  ConstSchema<B>(value: B): Schema<E, B>;

  // Lazy wrapper for schema values to permit recursive schema definitions.
  LazySchema<B>(delay: Void -> Schema<E, B>): Schema<E, B>;
}

enum ParseResult<E, S, A> {
  PSuccess(result: A);
  PFailure(error: E, sourceData: S);
}

enum Alternative<E, A> {
  Prism<A, B>(id: String, base: Schema<E, B>, f: B -> A, g: A -> Option<B>): Alternative<E, A>;
}

enum PropSchema<E, O, A> {
  Required<B>(fieldName: String, valueSchema: Schema<E, B>, accessor: O -> B): PropSchema<E, O, B>;
  Optional<B>(fieldName: String, valueSchema: Schema<E, B>, accessor: O -> Option<B>): PropSchema<E, O, Option<B>>;
}

/** Free applicative construction of builder for a set of object properties. */
enum ObjectBuilder<E, O, A> {
  Pure(a: A);
  Ap<I>(s: PropSchema<E, O, I>, k: ObjectBuilder<E, O, I -> A>);
}

typedef HomObjectBuilder<E, A> = ObjectBuilder<E, A, A>;

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
