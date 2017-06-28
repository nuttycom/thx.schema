package thx.schema;

import thx.schema.SchemaDSL.*;
import thx.schema.SimpleSchema;
import thx.schema.SimpleSchema.*;
import thx.Nel;

class Core {
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

  public static function time(): Schema<String, Time>
    return unsafeStringParseSchema(
      thx.Time.fromString,
      (v: thx.Time) -> v.toString()
    );

  public static function json<JSON>(): Schema<String, JSON>
    return unsafeStringParseSchema(
      haxe.Json.parse,
      (v: JSON) -> haxe.Json.stringify(v)
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
