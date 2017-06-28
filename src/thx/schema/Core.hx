package thx.schema;

import thx.schema.SchemaDSL.*;
import thx.schema.SimpleSchema;
import thx.schema.SimpleSchema.*;
import thx.Nel;

class Core {
  public static function date(): Schema<String, Date>
    return unsafeStringParseSchema(
      Date.fromString,
      (v: Date) -> v.toString()
    );

  public static function dateTime(): Schema<String, DateTime>
    return unsafeStringParseSchema(
      thx.DateTime.fromString,
      (v: thx.DateTime) -> v.toString()
    );

  public static function dateTimeUtc(): Schema<String, DateTimeUtc>
    return unsafeStringParseSchema(
      thx.DateTimeUtc.fromString,
      (v: thx.DateTimeUtc) -> v.toString()
    );

  public static function json<JSON>(): Schema<String, JSON>
    return unsafeStringParseSchema(
      haxe.Json.parse,
      (v: JSON) -> haxe.Json.stringify(v)
    );

  public static function localDate(): Schema<String, LocalDate>
    return unsafeStringParseSchema(
      thx.LocalDate.fromString,
      (v: thx.LocalDate) -> v.toString()
    );

  public static function localMonthDay(): Schema<String, LocalMonthDay>
    return unsafeStringParseSchema(
      thx.LocalMonthDay.fromString,
      (v: thx.LocalMonthDay) -> v.toString()
    );

  public static function localYearMonth(): Schema<String, LocalYearMonth>
    return unsafeStringParseSchema(
      thx.LocalYearMonth.fromString,
      (v: thx.LocalYearMonth) -> v.toString()
    );

  public static function nel<Element>(elementSchema: Schema<String, Element>): Schema<String, Nel<Element>> {
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

  public static function readonlyArray<E, T>(elementSchema: Schema<E, T>): Schema<E, thx.ReadonlyArray<T>>
    return iso(
      array(elementSchema),
      (v: Array<T>) -> (v : thx.ReadonlyArray<T>),
      (v: thx.ReadonlyArray<T>) -> v.toArray()
    );

  public static function time(): Schema<String, Time>
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
