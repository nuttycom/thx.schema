package thx.schema.macro;

import haxe.ds.Option;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.TypeTools;
using thx.Options;

class Macros {
  public static function extractEnumConstructorsFromType(t: Type): Array<{ name: String, field: EnumField }> {
    var e = TypeTools.getEnum(t);
    return e.names.map(name -> { name: name, field: e.constructs.get(name) });
  }

  public static function extractTypeFromEnumQName(s: String): Option<Type> {
    return extractTypeNameFromEnum(s).map(Context.getType);
  }

  public static function extractTypeNameFromEnum(s: String): Option<String> {
    var pattern = ~/^Enum[<](.+)[>]$/;
    return if(pattern.match(s)) {
      Some(pattern.matched(1));
    } else {
      None;
    }
  }

  public static function extractEnumTypeFromExpression(e: Expr): Option<Type> {
    var et = Context.typeof(e);
    return switch et {
      case TType(_.get() => t, _):
        extractTypeFromEnumQName(t.name);
      case _:
        None;
    };
  }


  public static function extractEnumTypeNameFromExpression(e: Expr): Option<String> {
    var et = Context.typeof(e);
    return switch et {
      case TType(_.get() => t, _):
        extractTypeNameFromEnum(t.name);
      case _:
        None;
    };
  }

  public static function makeEnumSchema(e: Expr) {
    var tenum = extractEnumTypeFromExpression(e);
    var constructors: Array<Expr> = switch tenum {
      case Some(enm):
        var nenum = extractEnumTypeNameFromExpression(e).getOrFail("strange");
        var list = extractEnumConstructorsFromType(enm);
        list.map(function(item): Expr {
          var cons = nenum.split(".").concat([item.name]);
          // TODO get constructor arguments and switch
          return macro thx.schema.SimpleSchema.constEnum($v{item.name}, $p{cons});
        });
      case None:
        Context.error('unable to resolve $e', Context.currentPos());
        [];
    }

    return macro function() return thx.schema.SimpleSchema.oneOf([$a{constructors}]);
  }
}
