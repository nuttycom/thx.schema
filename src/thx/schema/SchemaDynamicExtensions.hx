package thx.schema;

import thx.Options;
import thx.Nel;
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

class SchemaDynamicExtensions {
  public static function parse<A>(schema: Schema<A>, v: Dynamic): VNel<String, A> {
    // helper function used to unpack existential type I
    return switch schema {
      case IntSchema:   Dynamics.parseInt(v);
      case FloatSchema: Dynamics.parseFloat(v);
      case StrSchema:   Dynamics.parseString(v);
      case BoolSchema:  Dynamics.parseBool(v);
      case ObjectSchema(propSchema): parseObject(propSchema, v);
      case ArraySchema(elemSchema):  Dynamics.parseArray(v, parse.bind(elemSchema, _));
      case CoYoneda(base, f):        parse(base, v).map(f);
    };
  }

  public static function parseObject<A>(builder: ObjectBuilder<A>, ob: {}): VNel<String, A> {
    // helper function used to unpack existential type I
    inline function go<I>(schema: PropSchema<I>, k: ObjectBuilder<I -> A>): VNel<String, A> {
      var parsed: VNel<String, I> = switch schema {
        case Required(fieldName, valueSchema):
          nnNel(ob.getPath(fieldName), 'Property "$fieldName" was not found in $ob').flatMapV(parse.bind(valueSchema, _));

        case Optional(fieldName, valueSchema):
          Options.ofValue(ob.getPath(fieldName)).traverseValidation(parse.bind(valueSchema, _));
      };

      return parsed.ap(parseObject(k, ob), Nel.semigroup());
    }

    return switch builder {
      case Pure(a): successNel(a);
      case Ap(s, k): go(s, k);
    };
  }
}
