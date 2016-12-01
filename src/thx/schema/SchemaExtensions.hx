package thx.schema;

import haxe.ds.Option;

import thx.Functions.identity;
import thx.fp.Functions.flip;

using thx.Arrays;
using thx.Functions;
using thx.Options;

import thx.schema.Schema;

/**
 * A couple of useful interpreters for Schema values. This class is intended
 * to be imported via 'using'.
 */
class SchemaExtensions {
  public static function id<A, E>(a: Alternative<A, E>)
    return switch a {
      case Prism(id, _, _, _): id;
    };

  public static function stype<A, E>(schema: Schema<A, E>): SType
    return switch schema {
      case BoolSchema:  BoolSType;
      case FloatSchema: FloatSType;
      case IntSchema:   IntSType;
      case StrSchema:   StrSType;
      case ConstSchema(_):  ConstSType;
      case ObjectSchema(propSchema):  ObjectSType;
      case ArraySchema(elemSchema):   ArraySType;
      case MapSchema(elemSchema):     MapSType;
      case OneOfSchema(alternatives): OneOfSType;
      case ParseSchema(base, f, g): stype(base);
      case LazySchema(base): stype(base());
    };

  public static function isConstant<A, E>(schema: Schema<A, E>): Bool
    return switch schema {
      case ConstSchema(_): true;
      case ParseSchema(s0, _, _): isConstant(s0);
      case LazySchema(fs): isConstant(fs());
      case _: false;
    };

  public static function mapError<A, E, F>(schema: Schema<A, E>, e: E -> F): Schema<A, F> {
    return switch schema {
      case BoolSchema:  BoolSchema;
      case FloatSchema: FloatSchema;
      case IntSchema:   IntSchema;
      case StrSchema:   StrSchema;
      case ConstSchema(a):  ConstSchema(a);
      case ObjectSchema(propSchema):  ObjectSchema(ObjectSchemaExtensions.mapError(propSchema, e));
      case ArraySchema(elemSchema):   ArraySchema(mapError(elemSchema, e));
      case MapSchema(elemSchema):     MapSchema(mapError(elemSchema, e));
      case OneOfSchema(alternatives): OneOfSchema(alternatives.map(AlternativeExtensions.mapError.bind(_, e)));
      case ParseSchema(base, f, g):   
        ParseSchema(
          mapError(base, e), 
          function(b) return switch f(b) {
            case PSuccess(result): PSuccess(result);
            case PFailure(error, sourceData): PFailure(e(error), sourceData);
          },
          g
        );
      case LazySchema(base): 
        LazySchema(function() return mapError(base(), e));
    };
  }
}

class ObjectSchemaExtensions {
  public static function contramap<N, O, A, E>(o: ObjectBuilder<O, A, E>, f: N -> O): ObjectBuilder<N, A, E>
    return switch o {
      case Pure(a): Pure(a);
      case Ap(s, k): Ap(PropSchemaExtensions.contramap(s, f), contramap(k, f));
    }

  public static function map<O, A, B, E>(o: ObjectBuilder<O, A, E>, f: A -> B): ObjectBuilder<O, B, E>
    return switch o {
      case Pure(a): Pure(f(a));
      case Ap(s, k): Ap(s, map(k, f.compose));
    };

  public static function ap<O, A, B, E>(o: ObjectBuilder<O, A, E>, f: ObjectBuilder<O, A -> B, E>): ObjectBuilder<O, B, E>
    return switch f {
      case Pure(g): map(o, g);
      case Ap(s, k): Ap(s, ap(o, map(k, flip)));
    };

  public static function mapError<O, A, E, F>(o: ObjectBuilder<O, A, E>, e: E -> F): ObjectBuilder<O, A, F>
    return switch o {
      case Pure(g): Pure(g);
      case Ap(s, k): Ap(PropSchemaExtensions.mapError(s, e), mapError(k, e));
    };
}

class PropSchemaExtensions {
  public static function contramap<N, O, A, E>(s: PropSchema<O, A, E>, f: N -> O): PropSchema<N, A, E>
    return switch s {
      case Required(n, s, a): Required(n, s, a.compose(f));
      case Optional(n, s, a): Optional(n, s, a.compose(f));
    };

  public static function mapError<O, A, E, F>(s: PropSchema<O, A, E>, e: E -> F): PropSchema<O, A, F>
    return switch s {
      case Required(n, s, a): Required(n, SchemaExtensions.mapError(s, e), a);
      case Optional(n, s, a): Optional(n, SchemaExtensions.mapError(s, e), a);
    }
}

class AlternativeExtensions {
  public static function id<A, E>(alt: Alternative<A, E>): String
    return switch alt {
      case Prism(id, _, _, _): id;
    };

  public static function isConstantAlt<A, E>(alt: Alternative<A, E>): Bool
    return switch alt {
      case Prism(_, s, _, _): SchemaExtensions.isConstant(s);
    };

  public static function mapError<A, E, F>(alt: Alternative<A, E>, e: E -> F): Alternative<A, F> 
    return switch alt {
      case Prism(id, s, f, g): Prism(id, SchemaExtensions.mapError(s, e), f, g);
    };
}
