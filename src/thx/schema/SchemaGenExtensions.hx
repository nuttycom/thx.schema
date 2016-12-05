package thx.schema;

import thx.Options;
import thx.Nel;
import thx.Nothing;
import thx.Validation;
import thx.Validation.*;
import thx.fp.Dynamics;
import thx.schema.Schema;

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
  public static function exemplar<A>(schema: Schema<Nothing, A>): A {
    return switch schema {
      case FloatSchema:  0.0;
      case BoolSchema: false;
      case IntSchema:  0;
      case StrSchema:  "";
      case ConstSchema(a): a;

      case OneOfSchema(alternatives): switch alternatives.head() {
        case Prism(_, base, f, _): f(exemplar(base));
      }

      case ParseSchema(base, f, g): switch f(exemplar(base)) {
        case PSuccess(a): a;
        case PFailure(_, _): throw "Unreachable - one would have to construct an instance of the uninhabited Nothing type to get here.";
      }

      case ObjectSchema(propSchema):  objectExemplar(propSchema);
      case ArraySchema(elemSchema):   [exemplar(elemSchema)];
      case MapSchema(elemSchema):     ["" => exemplar(elemSchema)];
      case LazySchema(delay):         exemplar(delay());
    }
  } 

  public static function objectExemplar<O, A>(builder: ObjectBuilder<Nothing, O, A>): A {
    inline function go<I>(schema: PropSchema<Nothing, O, I>, k: ObjectBuilder<Nothing, O, I -> A>): A {
      var i: I = switch schema {
        case Required(_, s0, _): exemplar(s0);
        case Optional(_, s0, _): Some(exemplar(s0));
      };

      return objectExemplar(k)(i);
    }

    return switch builder {
      case Pure(a): a;
      case Ap(s, k): go(s, k);
    }
  }
}
