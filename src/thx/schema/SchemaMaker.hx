package thx.schema;

import haxe.macro.Expr;

#if macro
import thx.schema.macro.Macros.*;
#end

class SchemaMaker {
  macro public static function makeEnum<E, T>(enumType: ExprOf<Enum<T>>, ?typeSchemas: Expr): Expr {
    return makeEnumSchema(enumType, schemas, typeSchemas);
  }

  macro public static function registerSchema<E, T>(name: String, schema: Expr) {
    schemas.set(name, schema);
    return schema;
  }

#if macro
  static var schemas = [
    "String" => macro thx.schema.SimpleSchema.string(),
    "Bool" => macro thx.schema.SimpleSchema.bool(),
    "Float" => macro thx.schema.SimpleSchema.float(),
    "Int" => macro thx.schema.SimpleSchema.int(),
    "Array" => macro thx.schema.SimpleSchema.array,
    "thx.Either" => macro thx.schema.SimpleSchema.core.either,
    "haxe.ds.Option" => macro thx.schema.SimpleSchema.makeOptional,
    "Null" => macro thx.schema.SimpleSchema.makeNullable
  ];
#end
}
