package thx.schema;

import haxe.ds.Option;
import thx.schema.SPath;

import thx.Maps;
import thx.Objects;
import thx.Nel;
import thx.Strings;
import thx.Types;
import thx.Tuple;
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

import thx.schema.SchemaF;
import thx.schema.SimpleSchema.*;
using thx.schema.SchemaFExtensions;

class SchemaDynamicExtensions {
  public static function parseDynamic<E, X, A>(schema: AnnotatedSchema<E, X, A>, err: String -> E, v: Dynamic): VNel<ParseError<E>, A> {
    return parseDynamic0(schema.schema, SPath.root, err, v);
  }

  public static function parseDynamicAt<E, X, A>(schema: AnnotatedSchema<E, X, A>, path: SPath, err: String -> E, v: Dynamic): VNel<ParseError<E>, A> {
    return parseDynamic0(schema.schema, path, err, v);
  }

  public static function dparser<E, X, A>(schema: AnnotatedSchema<E, X, A>, err: String -> E): Dynamic -> VNel<ParseError<E>, A> {
    return parseDynamicAt.bind(schema, SPath.root, err, _);
  }

  static function parseDynamic0<E, X, A>(schemaf: SchemaF<E, X, A>, path: SPath, err: String -> E, v: Dynamic): VNel<ParseError<E>, A> {
    function failure(s: String) return new ParseError(err(s), path);
    function failNel(s: String) return failureNel(new ParseError(err(s), path));

    return switch schemaf {
      case IntSchema:   parseInt(v).leftMapNel(failure);
      case FloatSchema: parseFloat(v).leftMapNel(failure);
      case StrSchema:   parseString(v).leftMapNel(failure);
      case BoolSchema:  parseBool(v).leftMapNel(failure);
      case AnySchema:   successNel(v);
      case ConstSchema(a):  successNel(a);

      case ObjectSchema(propSchema): parseObject(path, propSchema, err, v);
      case ArraySchema(elemSchema):  parseArrayIndexed(v, function(x, i) return parseDynamicAt(elemSchema, path * i, err, x), failure);
      case MapSchema(elemSchema):    parseStringMap(v, function(x, s) return parseDynamicAt(elemSchema, path / s, err, x), failure);

      case OneOfSchema(alternatives):
        if (alternatives.all.fn(_.isConstantAlt())) {
          // all of the alternatives are constant-valued, so there is no need to encode
          // on any data and we can use the identifier as a bare encoding rather
          // than an object key.
          parseString(v).leftMapNel(failure).flatMapV(
            function(s: String) {
              var id0 = s.toLowerCase();
              return switch alternatives.findOption.fn(_.id().toLowerCase() == id0) {
                case Some(Prism(id, altSchema, _, f, _)): parseDynamicAt(altSchema, path / id, err, v).map(f);
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
            case [Prism(id, base, _, f, _)]:
              var baseParser = parseDynamicAt.bind(base, path / id, err, _);
              var res = if (base.schema.isConstant()) parseNullableProperty(v, id, baseParser)
                        else parseProperty(v, id, baseParser, function(s: String) return new ParseError(err(s), path));

              res.map(f);

            case other:
              if (other.length == 0) {
                failNel('Could not match type identifier from among ${alternatives.map.fn(_.id())} in object with fields $fields.');
              } else {
                // throw here, because this is a programmer error, not a user error.
                throw new thx.Error('More than one alternative bound to the same schema at path ${path.render()}!');
              }
          };
        } else {
          failNel('$v is not an anonymous object structure, as required for the representation of values of "oneOf" type.');
        };

      case ParseSchema(base, f, _):
        parseDynamic0(base, path, err, v).flatMapV(
          function(a) return switch f(a) {
            case PSuccess(result): successNel(result);
            case PFailure(error, _):  failureNel(new ParseError(error, path));
          }
        );

      case MetaSchema(prop, ms, sf, _):
        parseProperty(v, prop, parseDynamic.bind(ms, err, _), ParseError.new.bind(_, path).compose(err)).flatMapV(
          mv -> parseObject(path, sf(mv), err, v)
        );

      case LazySchema(base):
        parseDynamic0(base(), path, err, v);
    };
  }

  private static function parseObject<E, X, O, A>(path: SPath, builder: PropsBuilder<E, X, O, A>, err: String -> E, v: Dynamic): VNel<ParseError<E>, A> {
    // helper function used to unpack existential type I
    inline function go<I>(ps: PropSchema<E, X, O, I>, k: PropsBuilder<E, X, O, I -> A>): VNel<ParseError<E>, A> {
      var parsedOpt: VNel<ParseError<E>, I> = switch ps {
        case Required(fieldName, valueSchema, _, dflt):
          parseOptionalProperty(v, fieldName, parseDynamicAt.bind(valueSchema, path / fieldName, err, _)).flatMapV.fn(
            _.orElse(dflt).toLazySuccessNel(() -> new ParseError(err('Value $v does not contain field $fieldName and no default was available.'), path))
          );

        case Optional(fieldName, valueSchema, _):
          parseOptionalProperty(v, fieldName, parseDynamicAt.bind(valueSchema, path / fieldName, err, _));
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
    return renderDynamic0(schema.schema, value);
  }

  public static function renderDynamic0<E, X, A>(schemaf: SchemaF<E, X, A>, value: A): Dynamic {
    return switch schemaf {
      case IntSchema:   value;

      case FloatSchema: 
        if (Math.isFinite(value)) value
        else if (Math.isNaN(value)) "NaN"
        else if (value > 0) "Inf";
        else "-Inf";

      case StrSchema:   value;
      case BoolSchema:  value;
      case AnySchema:   value;
      case ConstSchema(v): {};

      case ObjectSchema(propSchema):
        renderDynObject(propSchema, value);

      case ArraySchema(elemSchema):
        value.map(renderDynamic.bind(elemSchema, _));

      case MapSchema(elemSchema):
        value.tuples().reduce(function(o, t) {
          Reflect.setField(o, t.left, renderDynamic(elemSchema, t.right));
          return o;
        }, {});
      case OneOfSchema(alternatives):
        var useConstantSchema = alternatives.all.fn(_.isConstantAlt());
        var selected: Array<Tuple<String, Dynamic>> = alternatives.filterMap(
          function(alt) return switch alt {
            case Prism(id, base, _, _, g):
              g(value).map(function(b) return Tuple2.of(id, if (useConstantSchema) id else [id => renderDynamic(base, b)].toObject()));
          }
        );

        switch selected {
          case [m]: m._1;
          case []: throw new thx.Error('None of ${alternatives.map.fn(_.id())} could convert the value $value to the base type ${schemaf.stype()}');
          case xs: throw new thx.Error('Ambiguous value $value: multiple alternatives (all of ${xs.map.fn(_._1)}) claim to render to ${schemaf.stype()}.');
        }

      case ParseSchema(base, _, g):
        renderDynamic0(base, g(value));

      case LazySchema(base):
        renderDynamic0(base(), value);

      case MetaSchema(metaProp, ms, sf, g):
        function objSchema<B, C>(metaSchema: AnnotatedSchema<E, X, B>, valueProps: ObjectBuilder<E, X, C>): ObjectBuilder<E, X, { meta: B, value: C }> {
          return SchemaDSL.ap2(
            (m: B, v: C) -> { meta: m, value: v },
            SchemaDSL.required(metaProp, metaSchema, (v: { meta: B, value: C }) -> v.meta),
            valueProps.contramap((v: { meta: B, value: C }) -> v.value)
          );
        }

        var metadata = g(value);
        var metaValue = { meta: metadata, value: value };
        renderDynObject(objSchema(ms, sf(metadata)), metaValue);
    }
  }

  public static function renderDynObject<E, X, A>(builder: ObjectBuilder<E, X, A>, value: A): Dynamic {
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
  private static function evalRO<E, X, O, A>(builder: PropsBuilder<E, X, O, A>, value: O): Writer<Map<String, Dynamic>, A>
    return switch builder {
      case Pure(a): Writer.pure(a, wm);
      case Ap(s, k): goRO(s, k, value);
    };

  // should be inside renderObject, but haxe doesn't let you write corecursive
  // functions as inner functions
  private static function goRO<E, X, O, I, J>(ps: PropSchema<E, X, O, I>, k: PropsBuilder<E, X, O, I -> J>, value: O): Writer<Map<String, Dynamic>, J> {
    var action: Writer<Map<String, Dynamic>, I> = switch ps {
      case Required(field, valueSchema, accessor, _):
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
