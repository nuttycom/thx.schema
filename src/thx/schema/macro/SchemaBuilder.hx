package thx.schema.macro;

import haxe.macro.Context;
import haxe.macro.Expr;
using thx.Arrays;

class SchemaBuilder {
  public static function lookupSchema(typeReference: TypeReference, typeSchemas: Map<String, Expr>): Expr {
    var type = typeReference.toString();
    if(typeSchemas.exists(type)) {
      return typeSchemas.get(type);
    } else {
      var path = TypeBuilder.ensure(typeReference, typeSchemas);
      return macro $p{path};
    }
  }

  public static function generateSchema(typeReference: TypeReference, typeSchemas: Map<String, Expr>): Expr {
    return macro null;
  }

  public static function variableNameFromTypeParameter(p: String)
    return 'schema$p';
}
