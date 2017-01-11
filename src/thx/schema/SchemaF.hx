package thx.schema;

import haxe.ds.Option;
import thx.Unit;
import thx.schema.SchemaFExtensions;

typedef Const<A, B> = A;

/**
 * A GADT describing the elements of a JSON-compatible Haxe object schema.
 * Generally, you shouldn't use the constructors of this type
 * directly, but instead use those provided as convenience methods in SimpleSchema.
 */
enum SchemaF<E, X, A> {
  BoolSchema:  SchemaF<E, X, Bool>;
  FloatSchema: SchemaF<E, X, Float>;
  IntSchema:   SchemaF<E, X, Int>;
  StrSchema:   SchemaF<E, X, String>;

  // schema that always parses to or generates a constant value. 
  ConstSchema<B>(value: B): SchemaF<E, X, B>;

  // we need a schema that can represent the idea that, in parsing, the
  // parser simply passes the value being parsed unmodified to the resulting
  // object constructor. In order to do so, we have to wrap it in a type
  // that makes this explicit, and thx.Any does the trick.
  AnySchema: SchemaF<E, X, thx.Any>;

  ObjectSchema<B>(propSchema: ObjectBuilder<E, X, B>): SchemaF<E, X, B>;
  ArraySchema<B>(elemSchema: AnnotatedSchema<E, X, B>): SchemaF<E, X, Array<B>>;
  MapSchema<B>(elemSchema: AnnotatedSchema<E, X, B>): SchemaF<E, X, Map<String, B>>; // interpret as a String-keyed map instead of an object value

  // schema for sum types
  OneOfSchema<B>(alternatives: Array<Alternative<E, X, B>>): SchemaF<E, X, B>;

  // this allows us to create schemas that impose more constraints on
  // the type of source data than merely being isomorphic to a primitive
  // value type.
  ParseSchema<B, C>(base: SchemaF<E, X, B>, f: B -> ParseResult<E, B, C>, g: C -> B): SchemaF<E, X, C>;

  // lazy wrapper for schema values to permit recursive schema definitions.
  LazySchema<B>(delay: Void -> SchemaF<E, X, B>): SchemaF<E, X, B>;
}

class AnnotatedSchema<E, X, A> {
  public var annotation(default, null): X;
  public var schema(default, null): SchemaF<E, X, A>;

  public function new(annotation: X, schema: SchemaF<E, X, A>) {
    this.annotation = annotation;
    this.schema = schema;
  }

  // FIXME: This should take SPath -> X -> Y
  public function mapAnnotation<Y>(f: X -> Y): AnnotatedSchema<E, Y, A> {
    return new AnnotatedSchema(f(annotation), SchemaFExtensions.mapAnnotation(schema, f));
  }
  
  public function mapError<F>(f: E -> F): AnnotatedSchema<F, X, A> {
    return new AnnotatedSchema(annotation, SchemaFExtensions.mapError(schema, f));
  }
}

enum ParseResult<E, S, A> {
  PSuccess(result: A);
  PFailure(error: E, sourceData: S);
}

enum Alternative<E, X, A> {
  Prism<A, B>(id: String, base: AnnotatedSchema<E, X, B>, f: B -> A, g: A -> Option<B>): Alternative<E, X, A>;
}

enum PropSchema<E, X, O, A> {
  Required<B>(fieldName: String, valueSchema: AnnotatedSchema<E, X, B>, accessor: O -> B, dflt: Option<B>): PropSchema<E, X, O, B>;
  Optional<B>(fieldName: String, valueSchema: AnnotatedSchema<E, X, B>, accessor: O -> Option<B>): PropSchema<E, X, O, Option<B>>;
}

/** Free applicative construction of builder for a set of object properties. */
enum PropsBuilder<E, X, O, A> {
  Pure(a: A);
  Ap<I>(s: PropSchema<E, X, O, I>, k: PropsBuilder<E, X, O, I -> A>);
}

typedef ObjectBuilder<E, X, A> = PropsBuilder<E, X, A, A>;

enum SType {
  BoolSType;
  FloatSType;
  IntSType;
  StrSType;
  AnySType;
  ConstSType;
  ObjectSType;
  ArraySType;
  MapSType;
  OneOfSType;
}
