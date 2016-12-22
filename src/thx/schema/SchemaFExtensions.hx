package thx.schema;

import haxe.ds.Option;

import thx.Functions.identity;
import thx.fp.Functions.flip;

using thx.Arrays;
using thx.Functions;
using thx.Options;

import thx.schema.SchemaF;

/**
 * A couple of useful interpreters for SchemaF values. This class is intended
 * to be imported via 'using'.
 */
class SchemaFExtensions {
  public static function id<E, X, A>(a: Alternative<E, X, A>)
    return switch a {
      case Prism(id, _, _, _): id;
    };

  public static function stype<E, X, A>(schema: SchemaF<E, X, A>): SType
    return switch schema {
      case BoolSchema:  BoolSType;
      case FloatSchema: FloatSType;
      case IntSchema:   IntSType;
      case StrSchema:   StrSType;
      case AnySchema:   AnySType;
      case ConstSchema(_):  ConstSType;
      case ObjectSchema(propSchema):  ObjectSType;
      case ArraySchema(elemSchema):   ArraySType;
      case MapSchema(elemSchema):     MapSType;
      case OneOfSchema(alternatives): OneOfSType;
      case ParseSchema(base, f, g): stype(base);
      case LazySchema(base): stype(base()); // could diverge?
    };

  public static function isConstant<E, X, A>(schema: SchemaF<E, X, A>): Bool
    return switch schema {
      case ConstSchema(_): true;
      case ParseSchema(s0, _, _): isConstant(s0);
      case LazySchema(fs): isConstant(fs()); // could diverge?
      case _: false;
    };

  public static function mapAnnotation<E, X, Y, A>(schema: SchemaF<E, X, A>, f: X -> Y): SchemaF<E, Y, A> {
    return switch schema {
      case BoolSchema:  BoolSchema;
      case FloatSchema: FloatSchema;
      case IntSchema:   IntSchema;
      case StrSchema:   StrSchema;
      case AnySchema:   AnySchema;
      case ConstSchema(a):  ConstSchema(a);
      case ObjectSchema(propSchema):  ObjectSchema(ObjectSchemaExtensions.mapAnnotation(propSchema, f));
      case ArraySchema(elemSchema):   ArraySchema(elemSchema.mapAnnotation(f));
      case MapSchema(elemSchema):     MapSchema(elemSchema.mapAnnotation(f));
      case OneOfSchema(alternatives): OneOfSchema(alternatives.map(AlternativeExtensions.mapAnnotation.bind(_, f)));
      case ParseSchema(base, p, q):   ParseSchema(mapAnnotation(base, f), p, q);
      case LazySchema(base):          LazySchema(function() return mapAnnotation(base(), f));
    }
  }

  public static function mapError<E, F, X, A>(schema: SchemaF<E, X, A>, e: E -> F): SchemaF<F, X, A> {
    return switch schema {
      case BoolSchema:  BoolSchema;
      case FloatSchema: FloatSchema;
      case IntSchema:   IntSchema;
      case StrSchema:   StrSchema;
      case AnySchema:   AnySchema;
      case ConstSchema(a):  ConstSchema(a);
      case ObjectSchema(propSchema):  ObjectSchema(ObjectSchemaExtensions.mapError(propSchema, e));
      case ArraySchema(elemSchema):   ArraySchema(elemSchema.mapError(e));
      case MapSchema(elemSchema):     MapSchema(elemSchema.mapError(e));
      case OneOfSchema(alternatives): OneOfSchema(alternatives.map(AlternativeExtensions.mapError.bind(_, e)));
      case ParseSchema(base, f, g):   ParseSchema(mapError(base, e), function(b) return ParseResultExtensions.mapError(f(b), e), g);
      case LazySchema(base):          LazySchema(function() return mapError(base(), e));
    };
  }
}

class ParseResultExtensions {
  public static function map<E, S, A, B>(r: ParseResult<E, S, A>, f: A -> B): ParseResult<E, S, B> 
    return switch r {
      case PSuccess(result): PSuccess(f(result));
      case PFailure(error, sourceData): PFailure(error, sourceData);
    };

  public static function mapError<E, F, S, A>(r: ParseResult<E, S, A>, f: E -> F): ParseResult<F, S, A>
    return switch r {
      case PSuccess(result): PSuccess(result);
      case PFailure(error, sourceData): PFailure(f(error), sourceData);
    };
}

class ObjectSchemaExtensions {
  public static function contramap<E, X, N, O, A>(o: PropsBuilder<E, X, O, A>, f: N -> O): PropsBuilder<E, X, N, A>
    return switch o {
      case Pure(a): Pure(a);
      case Ap(s, k): Ap(PropSchemaExtensions.contramap(s, f), contramap(k, f));
    }

  public static function map<E, X, O, A, B>(o: PropsBuilder<E, X, O, A>, f: A -> B): PropsBuilder<E, X, O, B>
    return switch o {
      case Pure(a): Pure(f(a));
      case Ap(s, k): Ap(s, map(k, f.compose));
    };

  public static function dimap<E, X, N, O, A, B>(o: PropsBuilder<E, X, O, A>, f: N -> O, g: A -> B): PropsBuilder<E, X, N, B>
    return map(contramap(o, f), g);

  public static function ap<E, X, O, A, B>(o: PropsBuilder<E, X, O, A>, f: PropsBuilder<E, X, O, A -> B>): PropsBuilder<E, X, O, B>
    return switch f {
      case Pure(g): map(o, g);
      case Ap(s, k): Ap(s, ap(o, map(k, flip)));
    };

  public static function mapAnnotation<E, X, Y, O, A>(o: PropsBuilder<E, X, O, A>, f: X -> Y): PropsBuilder<E, Y, O, A>
    return switch o {
      case Ap(s, k): Ap(PropSchemaExtensions.mapAnnotation(s, f), mapAnnotation(k, f));
      case Pure(g): Pure(g);
    };

  public static function mapError<E, F, X, O, A>(o: PropsBuilder<E, X, O, A>, e: E -> F): PropsBuilder<F, X, O, A>
    return switch o {
      case Pure(g): Pure(g);
      case Ap(s, k): Ap(PropSchemaExtensions.mapError(s, e), mapError(k, e));
    };
}

class PropSchemaExtensions {
  public static function contramap<E, X, N, O, A>(s: PropSchema<E, X, O, A>, f: N -> O): PropSchema<E, X, N, A>
    return switch s {
      case Required(n, s, a, d): Required(n, s, a.compose(f), d);
      case Optional(n, s, a): Optional(n, s, a.compose(f));
    };

  public static function mapAnnotation<E, X, Y, O, A>(s: PropSchema<E, X, O, A>, f: X -> Y): PropSchema<E, Y, O, A>
    return switch s {
      case Required(n, s, a, d): Required(n, s.mapAnnotation(f), a, d);
      case Optional(n, s, a): Optional(n, s.mapAnnotation(f), a);
    }

  public static function mapError<E, F, X, O, A>(s: PropSchema<E, X, O, A>, e: E -> F): PropSchema<F, X, O, A>
    return switch s {
      case Required(n, s, a, d): Required(n, s.mapError(e), a, d);
      case Optional(n, s, a): Optional(n, s.mapError(e), a);
    }
}

class AlternativeExtensions {
  public static function id<E, X, A>(alt: Alternative<E, X, A>): String
    return switch alt {
      case Prism(id, _, _, _): id;
    };

  public static function isConstantAlt<E, X, A>(alt: Alternative<E, X, A>): Bool
    return switch alt {
      case Prism(_, s, _, _): SchemaFExtensions.isConstant(s.schema);
    };

  public static function mapAnnotation<E, X, Y, A>(alt: Alternative<E, X, A>, f: X -> Y): Alternative<E, Y, A> 
    return switch alt {
      case Prism(id, s, p, q): Prism(id, s.mapAnnotation(f), p, q);
    };

  public static function mapError<E, F, X, A>(alt: Alternative<E, X, A>, e: E -> F): Alternative<F, X, A> 
    return switch alt {
      case Prism(id, s, f, g): Prism(id, s.mapError(e), f, g);
    };
}

