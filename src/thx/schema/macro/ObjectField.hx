package thx.schema.macro;

import haxe.ds.Option;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import haxe.macro.Type;
import haxe.macro.TypeTools;
import thx.schema.macro.Error.*;
using thx.Options;
using thx.Strings;

class ObjectField {
  public var name: String;
  public var type: TypeReference;
  public function new(name: String, type: TypeReference) {
    this.name = name;
    this.type = type;
  }

  public function toString()
    return '$name: ${type.toString()}';
}
