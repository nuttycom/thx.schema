package thx.schema;

import thx.schema.SchemaDSL.*;
import thx.schema.SimpleSchema;
import thx.schema.SimpleSchema.*;
using thx.schema.SchemaFExtensions;

class SchemaSchema {
  public static function sPathSchema<E>(toError: String -> E): Schema<E, SPath> return parse(
    string(), 
    function(s: String) return SPath.parse(s).mapError(toError), 
    function(p: SPath) return p.render()
  );

  public static function parseErrorSchema<E, V>(errSchema: Schema<E, V>, toError: String -> E): Schema<E, ParseError<V>> {
    return object(
      ap2(
        ParseError.new,
        required("error", errSchema, function(e: ParseError<V>) return e.error),
        required("path", sPathSchema(toError), function(e: ParseError<V>) return e.path)
      )
    );
  }
}
