package thx.schema.macro;

import haxe.macro.Context;
import haxe.macro.Expr;
import thx.schema.macro.Error.*;
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
      fatal('This method requires at least one argument that identifies a type whose schema needs to be generated');
    if(exprs.length > 2)
      fatal('This method takes at most 2 arguments');

    // here are passed things like Option or Either that gets interpreted as Option<T> or Either<L, R>
    // but also objects in the form of { field: Array<Option<String>> } which are very concrete and nested types
    typeSchema = UnboundSchemaType.fromExpr(exprs[0]);

    if(exprs.length == 2) {
      switch exprToTypeSchemas(exprs[1]) {
        case Some(schemas):
          typeSchemas = schemas;
        case None:
          fatal('The second argument is optional, when provided it needs to be a list of schemas');
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
    "Array" => macro thx.schema.SimpleSchema.array,
    "Bool" => macro thx.schema.SimpleSchema.bool,
    "Date" => macro thx.schema.Core.date,
    "Float" => macro thx.schema.SimpleSchema.float,
    "Int" => macro thx.schema.SimpleSchema.int,
    "Map" => macro thx.schema.SimpleSchema.dict,
    "Null" => macro thx.schema.SimpleSchema.makeNullable,
    "String" => macro thx.schema.SimpleSchema.string,

    "haxe.Int64" => macro thx.schema.Core.int64,
    "haxe.ds.Option" => macro thx.schema.SimpleSchema.makeOptional,

    // thx types
    "thx.Any" => macro thx.schema.SimpleSchema.any,
    "thx.BigInt" => macro thx.schema.SimpleSchema.bigInt,
    "thx.DateTime" => macro thx.schema.Core.dateTime,
    "thx.DateTimeUtc" => macro thx.schema.Core.dateTimeUtc,
    "thx.Decimal" => macro thx.schema.Core.decimal,
    "thx.LocalDate" => macro thx.schema.Core.localDate,
    "thx.LocalMonthDay" => macro thx.schema.Core.localMonthDay,
    "thx.LocalYearMonth" => macro thx.schema.Core.localYearMonth,
    "thx.Nel" => macro thx.schema.Core.nel,
    "thx.Path" => macro thx.schema.Core.path,
    "thx.QueryString" => macro thx.schema.Core.queryString,
    "thx.Rational" => macro thx.schema.Core.rational,
    "thx.ReadonlyArray" => macro thx.schema.Core.readonlyArray,
    "thx.Time" => macro thx.schema.Core.time,
    "thx.Url" => macro thx.schema.Core.url,
  ];

  static function exprToTypeSchemas(typeSchemas: Expr): Option<Map<String, Expr>> {
    var map = new Map();
    function typeToString(t) {
      return BoundSchemaType.fromType(t).toString();
    }
    function normalizeExpr(e) {
      return Context.getTypedExpr(Context.typeExpr(e));
    }
    switch typeSchemas.expr {
      case EConst(CIdent("null")):
      case EArrayDecl(arr):
        for(item in arr) {
          switch Context.typeof(item) {
            case TType(_.toString() => stype, [_, t]) if(stype == "thx.schema.Schema"):
              map.set(typeToString(t), normalizeExpr(item));
            case TFun(_, TType(_.toString() => stype, [_, t])) if(stype == "thx.schema.Schema"):
              map.set(typeToString(t), normalizeExpr(item));
            case _:
              None;
          }
        }
      case _:
        None;
    }
    return Some(map);
  }
}
