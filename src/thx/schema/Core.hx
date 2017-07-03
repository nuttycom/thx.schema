package thx.schema;

import thx.schema.SchemaDSL.*;
import thx.schema.SimpleSchema;
import thx.schema.SimpleSchema.*;
import thx.Nel;

class Core {
  public static function bigInt(): Schema<String, thx.BigInt>
    return catchStringParseSchema(
      thx.BigInt.fromString,
      (v: thx.BigInt) -> v.toString()
    );

  public static function date(): Schema<String, Date>
    return catchStringParseSchema(
      Date.fromString,
      (v: Date) -> v.toString()
    );

  public static function dateTime(): Schema<String, thx.DateTime>
    return catchStringParseSchema(
      thx.DateTime.fromString,
      (v: thx.DateTime) -> v.toString()
    );

  public static function dateTimeUtc(): Schema<String, thx.DateTimeUtc>
    return catchStringParseSchema(
      thx.DateTimeUtc.fromString,
      (v: thx.DateTimeUtc) -> v.toString()
    );

  public static function decimal(): Schema<String, thx.Decimal>
    return catchStringParseSchema(
      thx.Decimal.fromString,
      (v: thx.Decimal) -> v.toString()
    );

  public static function int64(): Schema<String, haxe.Int64>
    return catchStringParseSchema(
      haxe.Int64.parseString,
      (v: haxe.Int64) -> haxe.Int64.toStr(v)
    );

  public static function json<JSON>(): Schema<String, JSON>
    return catchStringParseSchema(
      haxe.Json.parse,
      (v: JSON) -> haxe.Json.stringify(v)
    );

  public static function localDate(): Schema<String, thx.LocalDate>
    return catchStringParseSchema(
      thx.LocalDate.fromString,
      (v: thx.LocalDate) -> v.toString()
    );

  public static function localMonthDay(): Schema<String, thx.LocalMonthDay>
    return catchStringParseSchema(
      thx.LocalMonthDay.fromString,
      (v: thx.LocalMonthDay) -> v.toString()
    );

  public static function localYearMonth(): Schema<String, thx.LocalYearMonth>
    return catchStringParseSchema(
      thx.LocalYearMonth.fromString,
      (v: thx.LocalYearMonth) -> v.toString()
    );

  public static function nel<Element>(elementSchema: Schema<String, Element>): Schema<String, thx.Nel<Element>> {
    return liftS(
      ParseSchema(
        array(elementSchema).schema,
        (a: Array<Element>) -> switch Nel.fromArray(a) {
          case Some(nel):
            PSuccess(nel);
          case None:
            PFailure('the value you are parsing to a Nel looks like it is empty', a);
        },
        (nel: Nel<Element>) -> nel.toArray().unsafe()
      )
    );
  }

  public static function path(): Schema<String, thx.Path>
    return catchStringParseSchema(
      thx.Path.fromString,
      (v: thx.Path) -> v.toString()
    );

  public static function queryString(): Schema<String, thx.QueryString>
    return catchStringParseSchema(
      thx.QueryString.parse,
      (v: thx.QueryString) -> v.toString()
    );

  public static function rational(): Schema<String, thx.Rational>
    return catchStringParseSchema(
      thx.Rational.fromString,
      (v: thx.Rational) -> v.toString()
    );

  public static function readonlyArray<E, T>(elementSchema: Schema<E, T>): Schema<E, thx.ReadonlyArray<T>>
    return iso(
      array(elementSchema),
      (v: Array<T>) -> (v : thx.ReadonlyArray<T>),
      (v: thx.ReadonlyArray<T>) -> v.toArray()
    );

  public static function time(): Schema<String, thx.Time>
    return catchStringParseSchema(
      thx.Time.fromString,
      (v: thx.Time) -> v.toString()
    );

  public static function url(): Schema<String, thx.Url>
    return catchStringParseSchema(
      thx.Url.fromString,
      (v: thx.Url) -> v.toString()
    );

  public static function intMap<T>(elementSchema: Schema<String, T>): Schema<String, Map<Int, T>>
    return catchParseSchema(
      thx.schema.SimpleSchema.dict(elementSchema),
      function(m: Map<String, T>): Map<Int, T> {
        var imap = new Map();
        for(k in m.keys()) {
          if(!thx.Ints.canParse(k)) throw "Unable to parse key `$k` to Int";
          var ik = thx.Ints.parse(k);
          imap.set(ik, m.get(k));
        }
        return imap;
      },
      function(m: Map<Int, T>): Map<String, T> {
        var smap = new Map();
        for(ik in m.keys())
          smap.set('$ik', m.get(ik));
        return smap;
      }
    );

  public static function map<Key, Element>(keySchema: Schema<String, Key>, elementSchema: Schema<String, Element>): Schema<String, Map<Key, Element>> {
    if(untyped keySchema.schema == thx.schema.SchemaF.StrSchema) {
      return cast thx.schema.SimpleSchema.dict(elementSchema);
    } else if(untyped keySchema.schema == thx.schema.SchemaF.IntSchema) {
      return cast thx.schema.Core.intMap(elementSchema);
    } else {
      return throw 'Map schema at the moment can only have String or Int keys.';
    }
  }

  // utils
  static function catchStringParseSchema<T>(unsafeParse: String -> T, render: T -> String): Schema<String, T>
    return catchParseSchema(string(), unsafeParse, render);

  static function catchParseSchema<T, Serialized>(schema: Schema<String, Serialized>, unsafeParse: Serialized -> T, render: T -> Serialized) {
    return liftS(
      ParseSchema(
        schema.schema,
        (v: Serialized) -> try {
          PSuccess(unsafeParse(v));
        } catch(e: Dynamic) {
          PFailure(thx.Error.fromDynamic(e).message, v);
        },
        render
      )
    );
  }
}
