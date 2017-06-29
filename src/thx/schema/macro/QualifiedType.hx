package thx.schema.macro;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
using thx.Strings;

class QualifiedType<T> {
  public var pack(default, null): Array<String>;
  public var module(default, null): String;
  public var name(default, null): String;
  public var params(default, null): Array<T>;
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
    return Context.getType(toString());

  public function toComplexType(f: T -> ComplexType): ComplexType {
    return TPath({
      pack: pack,
      name: module,
      sub: name,
      params: params.map(f).map(TPType)
    });
  }
}
