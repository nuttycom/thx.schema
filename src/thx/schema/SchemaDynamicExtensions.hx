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
  public static function parse<E, X, A>(schema: AnnotatedSchema<E, X, A>, err: String -> E, v: Dynamic): VNel<ParseError<E>, A> {
    return parse0(SPath.root, schema, err, v);
  }

  public static function parser<E, X, A>(schema: AnnotatedSchema<E, X, A>, err: String -> E): Dynamic -> VNel<ParseError<E>, A> {
    return parse0.bind(SPath.root, schema, err, _);
  }

  private static function parse0<E, X, A>(path: SPath, schema: AnnotatedSchema<E, X, A>, err: String -> E, v: Dynamic): VNel<ParseError<E>, A> {
    function failure(s: String) return new ParseError(err(s), path);
    function failNel(s: String) return failureNel(new ParseError(err(s), path));

    return switch schema.schema {
      case IntSchema:   parseInt(v).leftMapNel(failure);
      case FloatSchema: parseFloat(v).leftMapNel(failure);
      case StrSchema:   parseString(v).leftMapNel(failure);
      case BoolSchema:  parseBool(v).leftMapNel(failure);
      case ConstSchema(a):  successNel(a);

      case ObjectSchema(propSchema): parseObject(path, propSchema, err, v);
      case ArraySchema(elemSchema):  parseArrayIndexed(v, function(x, i) return parse0(path * i, elemSchema, err, x), failure);
      case MapSchema(elemSchema):    parseStringMap(v, function(x, s) return parse0(path / s, elemSchema, err, x), failure);

      case OneOfSchema(alternatives):
        if (alternatives.all.fn(_.isConstantAlt())) {
          // all of the alternatives are constant-valued, so there is no need to encode
          // on any data and we can use the identifier as a bare encoding rather
          // than an object key.
          parseString(v).leftMapNel(failure).flatMapV(
            function(s: String) {
              var id0 = s.toLowerCase();
              return switch alternatives.findOption.fn(_.id().toLowerCase() == id0) {
                case Some(Prism(id, altSchema, f, _)): parse0(path / id, altSchema, err, v).map(f);
                case None: failNel('Value ${v} cannot be mapped to any alternative among [${alternatives.map.fn(_.id()).join(", ")}]');
              }
            }
          );
        } else if (Types.isAnonymousObject(v)) {
          // The alternative is encoded as an object containing single field, where the
          // name of the field is the constructor and the body is parsed by the schema
          // for that alternative.
          var fields = Objects.fields(v);
          var alts = fields.flatMap(function(name) return alternatives.filter.fn(_.id() == name));

          switch alts {
            case [Prism(id, base, f, _)]:
              var baseParser = parse0.bind(path / id, base, err, _);
              var res = if (base.schema.isConstant()) parseNullableProperty(v, id, baseParser)
                        else parseProperty(v, id, baseParser, function(s: String) return new ParseError(err(s), path));

              res.map(f);

            case other:
              if (other.length == 0) {
                failNel('Could not match type identifier from among ${alternatives.map.fn(_.id())} in object with fields $fields.');
              } else {
                // throw here, because this is a programmer error, not a user error.
                throw new thx.Error('More than one alternative bound to the same schema at path ${path.toString()}!');
              }
          };
        } else {
          failNel('$v is not an anonymous object structure, as required for the representation of values of "oneOf" type.');
        };

      case ParseSchema(base, f, _): 
        parse0(path, base, err, v).flatMapV(
          function(a) return switch f(a) {
            case PSuccess(result): successNel(result);
            case PFailure(error, _):  failureNel(new ParseError(error, path));
          }
        );

      case LazySchema(base): 
        parse0(path, base(), err, v);
    };
  }

  private static function parseObject<E, X, O, A>(path: SPath, builder: ObjectBuilder<E, X, O, A>, err: String -> E, v: Dynamic): VNel<ParseError<E>, A> {
    // helper function used to unpack existential type I
    inline function go<I>(ps: PropSchema<E, X, O, I>, k: ObjectBuilder<E, X, O, I -> A>): VNel<ParseError<E>, A> {
      var parsedOpt: VNel<ParseError<E>, I> = switch ps {
        case Required(fieldName, valueSchema, _):
          parseOptionalProperty(v, fieldName, parse0.bind(path / fieldName, valueSchema, err, _)).flatMapV.fn(
            _.toSuccessNel(new ParseError(err('Value $v does not contain field $fieldName and no default was available.'), path))
          );

        case Optional(fieldName, valueSchema, _):
          parseOptionalProperty(v, fieldName, parse0.bind(path / fieldName, valueSchema, err, _));
      };

      return parsedOpt.ap(parseObject(path, k, err, v), Nel.semigroup());
    }

    return if (Types.isAnonymousObject(v)) {
      switch builder {
        case Pure(a): successNel(a);
        case Ap(s, k): go(s, k);
      };
    } else {
      failureNel(new ParseError(err('$v is not an anonymous object structure}).'), path));
    };
  }

  public static function renderDynamic<E, X, A>(schema: AnnotatedSchema<E, X, A>, value: A): Dynamic {
    return switch schema.schema {
      case IntSchema:   value;
      case FloatSchema: value;
      case StrSchema:   value;
      case BoolSchema:  value;
      case ConstSchema(v):  v;

      case ObjectSchema(propSchema):
        renderDynObject(propSchema, value);

      case ArraySchema(elemSchema):  
        value.map(renderDynamic.bind(elemSchema, _));

      case MapSchema(elemSchema):
        value.mapValues(renderDynamic.bind(elemSchema, _), new Map());

      case OneOfSchema(alternatives):
        var selected: Array<Map<String, Dynamic>> = alternatives.flatMap(
          function(alt) return switch alt {
            case Prism(id, base, _, g): g(value).map(function(b) return [ id => renderDynamic(base, b) ]).toArray();
          }
        );

        switch selected {
          case [m]: 
            if (alternatives.all.fn(_.isConstantAlt())) {
              m.keys().first(); // just return the key, the value will be unit
            } else {
              m.toObject();
            }

          case []: throw new thx.Error('None of ${alternatives.map.fn(_.id())} could convert the value $value to the base type ${schema.schema.stype()}');
          case xs: throw new thx.Error('Ambiguous value $value: multiple alternatives (all of ${xs.flatMap.fn(_.keys().toArray())}) claim to render to ${schema.schema.stype()}.');
        }

      case ParseSchema(base, _, g): 
        renderDynamic(base, g(value));

      case LazySchema(base): 
        renderDynamic(base(), value);
    }
  }

  public static function renderDynObject<E, X, A>(builder: ObjectBuilder<E, X, A, A>, value: A): Dynamic {
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
  private static function evalRO<E, X, O, A>(builder: ObjectBuilder<E, X, O, A>, value: O): Writer<Map<String, Dynamic>, A>
    return switch builder {
      case Pure(a): Writer.pure(a, wm);
      case Ap(s, k): goRO(s, k, value);
    };

  // should be inside renderObject, but haxe doesn't let you write corecursive
  // functions as inner functions
  private static function goRO<E, X, O, I, J>(ps: PropSchema<E, X, O, I>, k: ObjectBuilder<E, X, O, I -> J>, value: O): Writer<Map<String, Dynamic>, J> {
    var action: Writer<Map<String, Dynamic>, I> = switch ps {
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

class ParseError<E> {
  public var error(default, null): E;
  public var path(default, null): SPath;

  public function new(error: E, path: SPath) {
    this.error = error;
    this.path = path;
  }

  public function toString(): String {
    return '${path.toString()}: ${error}';
  }
}
