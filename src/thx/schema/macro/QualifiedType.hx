package thx.schema.macro;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import haxe.macro.Type;
import haxe.macro.TypeTools;
import thx.schema.macro.Error.*;
import thx.schema.macro.Utils.*;
import haxe.ds.Option;
using thx.Options;
using thx.Strings;

class QualifiedType<T> {
  public var pack: Array<String>;
  public var module: String;
  public var name: String;
  public var params: Array<T>;
  public function new(pack: Array<String>, module: String, name: String, params: Array<T>) {
    this.pack = pack;
    this.module = module.split(".").pop();
    this.name = name;
    this.params = params;
  }

  public function hasParams()
    return params.length > 0;

  public function countParams()
    return params.length;

  public function parts() {
    return pack.concat(module != name && module != "StdTypes" ? [module, name] : [name]);
  }

  public function toString()
    return parts().join(".");

  public function toIdentifier()
    return parts().join("_").upperCaseFirst();

  public function toType(): Type
    return Context.getType(toString()); // TODO !!! sufficient?

  public function toComplexType(f: T -> ComplexType): ComplexType {
    return TPath({
      pack: pack,
      name: module,
      sub: name,
      params: params.map(f).map(TPType)
    });
  }
}
