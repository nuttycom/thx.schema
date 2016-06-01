package thx.schema;

import haxe.ds.Option;
import thx.schema.SPath;

import thx.Maps;
import thx.Objects;
import thx.Nel;
import thx.Strings;
import thx.Types;
import thx.Unit;
import thx.Validation;
import thx.Validation.*;
import thx.fp.Dynamics;
import thx.fp.Dynamics.*;
import thx.fp.Functions.*;
import thx.fp.Writer;

using thx.Arrays;
using thx.Eithers;
using thx.Functions;
using thx.Iterators;
using thx.Maps;
using thx.Options;
using thx.Validation.ValidationExtensions;

import thx.schema.Schema;
import thx.schema.SchemaDSL.*;
using thx.schema.SchemaExtensions;

class SchemaDynamicExtensions {
  public static function parse<A>(schema: Schema<A>, v: Dynamic): VNel<ParseError, A> {
    return parse0(schema, v, SPath.root);
  }

  public static function parser<A>(schema: Schema<A>): Dynamic -> VNel<ParseError, A> {
    return parse.bind(schema, _);
  }

  private static function parse0<A>(schema: Schema<A>, v: Dynamic, path: SPath): VNel<ParseError, A> {
    return switch schema {
      case IntSchema:   parseInt(v).leftMapNel(errAt(path));
      case FloatSchema: parseFloat(v).leftMapNel(errAt(path));
      case StrSchema:   parseString(v).leftMapNel(errAt(path));
      case BoolSchema:  parseBool(v).leftMapNel(errAt(path));
      case UnitSchema:  successNel(unit);

      case ObjectSchema(propSchema): parseObject(propSchema, v, path);
      case ArraySchema(elemSchema):  parseArrayIndexed(v, function(x, i) return parse0(elemSchema, x, path * i), errAt(path));
      case MapSchema(elemSchema):    parseStringMap(v, function(x, s) return parse0(elemSchema, x, path / s), errAt(path));

      case OneOfSchema(alternatives):
        // The alternative is encoded as an object containing single field, where the
        // name of the field is the constructor and the body is parsed by the schema
        // for that alternative.
        if (Types.isAnonymousObject(v)) {
          var fields = Objects.fields(v);
          var alts = fields.flatMap(function(name) return alternatives.filter.fn(_.id() == name));

          switch alts {
            case [Prism(id, base, f, g)]:
              var parser = if (isConstant(base)) parseNullableProperty else parseProperty.bind(_, _, _, ParseError.new.bind(_, path));
              parser(v, id, parse0.bind(base, _, path / id)).map(f);

            case other:
              if (other.length == 0) {
                fail('Could not match type identifier from among ${alternatives.map.fn(_.id())} in object with fields $fields.', path);
              } else {
                // throw here, because this is a programmer error, not a user error.
                throw new thx.Error('More than one alternative bound to the same schema at path ${path.toString()}!');
              }
          };
        } else {
          fail('$v is not an anonymous object structure, as required for the representation of values of "oneOf" type.', path);
        };

      case IsoSchema(base, f, _): 
        parse0(base, v, path).map(f);

      case LazySchema(base): 
        parse0(base(), v, path);
    };
  }

  private static function parseObject<O, A>(builder: ObjectBuilder<O, A>, v: Dynamic, path: SPath): VNel<ParseError, A> {
    // helper function used to unpack existential type I
    inline function go<I>(schema: PropSchema<O, I>, k: ObjectBuilder<O, I -> A>): VNel<ParseError, A> {
      var parsedOpt: VNel<ParseError, I> = switch schema {
        case Required(fieldName, valueSchema, _):
          parseOptionalProperty(v, fieldName, parse0.bind(valueSchema, _, path / fieldName)).flatMapV.fn(
            _.toSuccessNel(new ParseError('Value $v does not contain field $fieldName and no default was available.', path))
          );

        case Optional(fieldName, valueSchema, _):
          parseOptionalProperty(v, fieldName, parse0.bind(valueSchema, _, path / fieldName));
      };

      return parsedOpt.ap(parseObject(k, v, path), Nel.semigroup());
    }

    return if (Types.isAnonymousObject(v)) {
      switch builder {
        case Pure(a): successNel(a);
        case Ap(s, k): go(s, k);
      };
    } else {
      fail('$v is not an anonymous object structure}).', path);
    };
  }

  public static function isConstant<A>(schema: Schema<A>): Bool {
    return switch schema {
      case UnitSchema: true;
      case IsoSchema(base, _, _): isConstant(base);
      case _: false;
    }
  }

  inline static public function errAt<A>(path: SPath): String -> ParseError
    return ParseError.new.bind(_, path);

  inline static public function fail<A>(message: String, path: SPath): VNel<ParseError, A>
    return failureNel(new ParseError(message, path));

  public static function renderDynamic<A>(schema: Schema<A>, value: A): Dynamic {
    return switch schema {
      case IntSchema:   value;
      case FloatSchema: value;
      case StrSchema:   value;
      case BoolSchema:  value;
      case UnitSchema:  value;

      case ObjectSchema(propSchema):
        renderDynObject(propSchema, value);

      case ArraySchema(elemSchema):  
        value.map(renderDynamic.bind(elemSchema, _));

      case MapSchema(elemSchema):
        value.mapValues(renderDynamic.bind(elemSchema, _), new Map());

      case OneOfSchema(alternatives):
        var selected: Array<Map<String, Dynamic>> = alternatives.flatMap(
          function(alt) return switch alt {
            case Prism(id, base, f, g): 
              g(value).map(function(b) return [ id => renderDynamic(base, b) ]).toArray();
          }
        );

        switch selected {
          case []: 
            throw new thx.Error('None of ${alternatives.map.fn(_.id())} could convert the value $value to the base type ${schema.stype()}');

          case other: 
            other.head().toObject();
            //'Ambiguous value $value: multiple alternatives for ${schema.metadata().title} (all of ${other.map(Render.renderUnsafe)}) claim to be valid renderings.';
        }

      case IsoSchema(base, _, g): 
        renderDynamic(base, g(value));

      case LazySchema(base): 
        renderDynamic(base(), value);
    }
  }

  public static function renderDynObject<A>(builder: ObjectBuilder<A, A>, value: A): Dynamic {
    var m: Map<String, Dynamic> = evalRO(builder, value).runLog();
    return m.toObject();
  }

  // This value will be reused a bunch, so no need to re-create it all the time.
  private static var wm(default, never): Monoid<Map<String, Dynamic>> = {
    zero: (new Map(): Map<String, Dynamic>),
    append: function(m0: Map<String, Dynamic>, m1: Map<String, Dynamic>) {
      return m1.keys().reduce(
        function(acc: Map<String, Dynamic>, k: String) {
          acc[k] = m1[k];
          return acc;
        },
        m0
      );
    }
  };

  // should be inside renderObject, but haxe doesn't let you write corecursive
  // functions as inner functions
  private static function evalRO<O, X>(builder: ObjectBuilder<O, X>, value: O): Writer<Map<String, Dynamic>, X>
    return switch builder {
      case Pure(a): Writer.pure(a, wm);
      case Ap(s, k): goRO(s, k, value);
    };

  // should be inside renderObject, but haxe doesn't let you write corecursive
  // functions as inner functions
  private static function goRO<O, I, J>(schema: PropSchema<O, I>, k: ObjectBuilder<O, I -> J>, value: O): Writer<Map<String, Dynamic>, J> {
    var action: Writer<Map<String, Dynamic>, I> = switch schema {
      case Required(field, valueSchema, accessor):
        var i0 = accessor(value);
        Writer.tell([ field => renderDynamic(valueSchema, i0) ], wm) >>
        Writer.pure(i0, wm);

      case Optional(field, valueSchema, accessor):
        var i0 = accessor(value);
        Writer.tell(i0.cata(new Map(), function(v0) return [ field => renderDynamic(valueSchema, v0) ]), wm) >>
        Writer.pure(i0, wm);
    }

    return action.ap(evalRO(k, value));
  }
}

class ParseError {
  public var message(default, null): String;
  public var path(default, null): SPath;

  public function new(message: String, path: SPath) {
    this.message = message;
    this.path = path;
  }

  public function toString(): String {
    return '${path.toString()}: ${message}';
  }
}
