package thx.schema;

import thx.schema.SchemaDSL.*;
import thx.schema.SimpleSchema;
import thx.schema.SimpleSchema.*;
import thx.Nel;

class Core {
  public static function bigInt(): Schema<String, thx.BigInt>
    return unsafeStringParseSchema(
      thx.BigInt.fromString,
      (v: thx.BigInt) -> v.toString()
    );

  public static function date(): Schema<String, Date>
    return unsafeStringParseSchema(
      Date.fromString,
      (v: Date) -> v.toString()
    );

  public static function dateTime(): Schema<String, thx.DateTime>
    return unsafeStringParseSchema(
      thx.DateTime.fromString,
      (v: thx.DateTime) -> v.toString()
    );

  public static function dateTimeUtc(): Schema<String, thx.DateTimeUtc>
    return unsafeStringParseSchema(
      thx.DateTimeUtc.fromString,
      (v: thx.DateTimeUtc) -> v.toString()
    );

  public static function decimal(): Schema<String, thx.Decimal>
    return unsafeStringParseSchema(
      thx.Decimal.fromString,
      (v: thx.Decimal) -> v.toString()
    );

  public static function int64(): Schema<String, haxe.Int64>
    return unsafeStringParseSchema(
      haxe.Int64.parseString,
      (v: haxe.Int64) -> haxe.Int64.toStr(v)
    );

  public static function json<JSON>(): Schema<String, JSON>
    return unsafeStringParseSchema(
      haxe.Json.parse,
      (v: JSON) -> haxe.Json.stringify(v)
    );

  public static function localDate(): Schema<String, thx.LocalDate>
    return unsafeStringParseSchema(
      thx.LocalDate.fromString,
      (v: thx.LocalDate) -> v.toString()
    );

  public static function localMonthDay(): Schema<String, thx.LocalMonthDay>
    return unsafeStringParseSchema(
      thx.LocalMonthDay.fromString,
      (v: thx.LocalMonthDay) -> v.toString()
    );

  public static function localYearMonth(): Schema<String, thx.LocalYearMonth>
    return unsafeStringParseSchema(
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
    return unsafeStringParseSchema(
      thx.Path.fromString,
      (v: thx.Path) -> v.toString()
    );

  public static function queryString(): Schema<String, thx.QueryString>
    return unsafeStringParseSchema(
      thx.QueryString.parse,
      (v: thx.QueryString) -> v.toString()
    );

  public static function rational(): Schema<String, thx.Rational>
    return unsafeStringParseSchema(
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
    return unsafeStringParseSchema(
      thx.Time.fromString,
      (v: thx.Time) -> v.toString()
    );

  public static function url(): Schema<String, thx.Url>
    return unsafeStringParseSchema(
      thx.Url.fromString,
      (v: thx.Url) -> v.toString()
    );


  // utils
  static function unsafeStringParseSchema<T>(unsafeParse: String -> T, render: T -> String): Schema<String, T>
    return unsafeParseSchema(string(), unsafeParse, render);

  static function unsafeParseSchema<T, Serialized>(schema: Schema<String, Serialized>, unsafeParse: Serialized -> T, render: T -> Serialized) {
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
