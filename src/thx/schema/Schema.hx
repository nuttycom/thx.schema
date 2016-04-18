package thx.schema;

import haxe.ds.Option;
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
