package thx.schema;

import haxe.macro.Expr;

#if macro
import thx.schema.macro.Macros.*;
#end

class SchemaMaker {
  macro public static function makeEnum<E, T>(enumType: ExprOf<Enum<T>>, ?typeSchemas: Expr): Expr {
    return makeEnumSchema(enumType, typeSchemas);
  }
}
