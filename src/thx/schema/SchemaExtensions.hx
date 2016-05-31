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
  public static function id<A>(a: Alternative<A>)
    return switch a {
      case Prism(id, _, _, _): id;
    };

  public static function stype<A>(schema: Schema<A>): SType 
    return switch schema {
      case BoolSchema:  BoolSType;
      case FloatSchema: FloatSType;
      case IntSchema:   IntSType;
      case StrSchema:   StrSType;
      case UnitSchema:  UnitSType;
      case ObjectSchema(propSchema): ObjectSType;
      case ArraySchema(elemSchema):  ArraySType;
      case OneOfSchema(alternatives): OneOfSType;
      case IsoSchema(base, f, g): stype(base);
      case LazySchema(base): stype(base());
    };
}

class ObjectSchemaExtensions {
  public static function contramap<N, O, A>(o: ObjectBuilder<O, A>, f: N -> O): ObjectBuilder<N, A> {
    return switch o {
      case Pure(a): Pure(a);
      case Ap(s, k): Ap(PropSchemaExtensions.contramap(s, f), contramap(k, f));
    }
  }

  public static function map<O, A, B>(o: ObjectBuilder<O, A>, f: A -> B): ObjectBuilder<O, B> {
    return switch o {
      case Pure(a): Pure(f(a));
      case Ap(s, k): Ap(s, map(k, f.compose));
    };
  }

  public static function ap<O, A, B>(o: ObjectBuilder<O, A>, f: ObjectBuilder<O, A -> B>): ObjectBuilder<O, B> {
    return switch f {
      case Pure(g): map(o, g);
      case Ap(s, k): Ap(s, ap(o, map(k, flip)));
    };
  }
}

class PropSchemaExtensions {
  public static function contramap<N, O, A>(s: PropSchema<O, A>, f: N -> O): PropSchema<N, A>
    return switch s {
      case Required(n, s, a): Required(n, s, a.compose(f));
      case Optional(n, s, a): Optional(n, s, a.compose(f));
    };
}

