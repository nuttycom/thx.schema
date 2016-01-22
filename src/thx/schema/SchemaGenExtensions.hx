package thx.schema;

import thx.Options;
import thx.Nel;
import thx.Validation;
import thx.Validation.*;
import thx.fp.Dynamics;

using thx.Arrays;
using thx.Functions;
using thx.Iterators;
using thx.Maps;
using thx.Options;
using thx.Objects;

class SchemaGenExtensions {
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
