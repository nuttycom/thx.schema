package thx.schema.macro;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import haxe.macro.Type;
import haxe.macro.TypeTools;
import thx.schema.macro.Error.*;
import haxe.ds.Option;
using thx.Options;
using thx.Strings;

class Utils {
  public static function extractTypeNameFromKind(s: String): String {
    var pattern = ~/^(?:Enum|Class|Abstract)[<](.+)[>]$/;
    return if(pattern.match(s)) {
      pattern.matched(1);
    } else {
      fatal("Unable to extract type name from kind: " + s);
    }
  }

  public static function createRef<T>(t: T): Ref<T> {
    return {
      get: function (): T {
        return t;
      },
      toString: function (): String {
        return Std.string(t);
      }
    };
  }

  public static function paramAsComplexType(p: String): ComplexType {
    return TPath({
      pack: [],
      name: p,
      params: []
    });
  }

  public static function paramAsType(p: String): Type {
    return throw "TODO NOT IMPLEMENTED";
  }

  public static function keepVariables(f: ClassField): Bool {
    return switch f.kind {
      case FVar(AccCall, AccCall): f.meta.has(":isVar");
      case FVar(AccCall, _): true;
      case FVar(AccNormal, _) | FVar(AccNo, _): true;
      case _: false;
    }
  }
}
