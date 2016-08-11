package thx.schema;

import haxe.ds.Option;
import haxe.ds.StringMap;
import thx.Unit;

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
  UnitSchema: Schema<Unit>;

  ObjectSchema<B, X>(propSchema: ObjectBuilder<B, X>): Schema<B>;
  ArraySchema<B>(elemSchema: Schema<B>): Schema<Array<B>>;
  MapSchema<B>(elemSchema: Schema<B>): Schema<Map<String, B>>; // interpret as a String-keyed map instead of an object value

  // schema for sum types
  OneOfSchema<B>(alternatives: Array<Alternative<B>>): Schema<B>;

  // This allows us to create schemas that parse to newtype wrappers
  IsoSchema<B, C>(base: Schema<B>, f: B -> C, g: C -> B): Schema<C>;

  // Lazy wrapper for schema values to permit recursive schema definitions.
  LazySchema<B>(delay: Void -> Schema<B>): Schema<B>;
}

enum Alternative<A> {
  Prism<A, B>(id: String, base: Schema<B>, f: B -> A, g: A -> Option<B>): Alternative<A>;
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

typedef HomObjectBuilder<A> = ObjectBuilder<A, A>;

enum SType {
  BoolSType;
  FloatSType;
  IntSType;
  StrSType;
  UnitSType;
  ObjectSType;
  ArraySType;
  MapSType;
  OneOfSType;
}
