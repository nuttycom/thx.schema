package thx.schema.macro;

import haxe.macro.Expr;
import thx.schema.macro.Error.*;
import thx.schema.macro.Types;
import haxe.ds.Option;

class Arguments {
  /**
   *  Generates a schema from the type passed as the first argument.
   *  @param typeRef
   *  @param ?typeSchemas
   *  @param ?identifier
   */
  public static function parseArguments(exprs: Array<Expr>) {
    var typeSchema  = null,
        typeSchemas = new Map();

    if(exprs.length == 0)
      fatal('this method requires at least one argument that identifies a type whose schema needs to be generated');
    if(exprs.length > 2)
      fatal('this method takes at most 2 arguments');

    // here are passed things like Option or Either that gets interpreted as Option<T> or Either<L, R>
    // but also objects in the form of { field: Array<Option<String>> } which are very concrete and nested types
    typeSchema = UnboundSchemaType.fromExpr(exprs[0]);

    if(exprs.length == 2) {
      switch exprToTypeSchemas(exprs[1]) {
        case Some(schemas):
          typeSchemas = schemas;
        case None:
          fatal('the second argument is optional, when provided it needs to be a list of schemas');
      }
    }

    var map: Map<String, Expr> = new Map();
    thx.Maps.merge(map, [defaultTypeSchemas, typeSchemas]);

    return {
      typeSchema: typeSchema,
      typeSchemas: map
    };
  }

  // TODO !!! allow registering new types?
  static var defaultTypeSchemas = [
    "String" => macro thx.schema.SimpleSchema.string,
    "Bool" => macro thx.schema.SimpleSchema.bool,
    "Float" => macro thx.schema.SimpleSchema.float,
    "Int" => macro thx.schema.SimpleSchema.int,
    "Array" => macro thx.schema.SimpleSchema.array,
    "haxe.ds.Option" => macro thx.schema.SimpleSchema.makeOptional,
    "Null" => macro thx.schema.SimpleSchema.makeNullable
  ];

  static function exprToTypeSchemas(expr: Expr): Option<Map<String, Expr>> {
    return None; // TODO !!!
  }
}
