package thx.schema.macro;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import thx.schema.macro.Error.*;
import haxe.ds.Option;
using thx.Options;

class Arguments {
  /**
   *  Generates a schema from the type passed as the first argument.
   *  @param typeRef
   *  @param ?typeSchemas
   *  @param ?identifier
   */
  public static function parseArguments(exprs: Array<Expr>) {
    var typeRef = null,
        typeSchemas = new Map(),
        identifier = null;

    if(exprs.length == 0)
      fatal('this method requires at least one argument that identifies a type whose schema needs to be generated');
    if(exprs.length > 3)
      fatal('this method takes at most 3 arguments');

    typeRef = TypeReference.fromExpr(exprs[0]);

    if(exprs.length == 1) {
      identifier = typeRef.toIdentifier();
    } else if(exprs.length == 2) {
      switch exprToTypeSchemas(exprs[1]) {
        case Some(schemas):
          typeSchemas = schemas;
          identifier = typeRef.toIdentifier();
        case None:
          switch exprToIdentifier(exprs[1]) {
            case Some(id):
              identifier = id;
            case None:
              fatal('the second argument is optional and can be either a list of schemas or an identiefier');
          }
      }
    } else if(exprs.length == 3) {
      switch exprToTypeSchemas(exprs[1]) {
        case Some(schemas):
          typeSchemas = schemas;
        case None:
          fatal('the second argument should be a list of schemas');
      }
      switch exprToIdentifier(exprs[2]) {
        case Some(id):
          identifier = id;
        case None:
          fatal('the third argument should be an identiefier');
      }
    }

    return {
      typeRef: typeRef,
      typeSchemas: typeSchemas,
      identifier: identifier
    };
  }

  static function exprToTypeSchemas(expr: Expr): Option<Map<String, Expr>> {
    return None; // TODO !!!
  }

  static function exprToIdentifier(expr: Expr): Option<String> {
    return switch expr.expr {
      case EConst(CIdent(ident)): Some(ident);
      case _: None;
    };
  }
}
