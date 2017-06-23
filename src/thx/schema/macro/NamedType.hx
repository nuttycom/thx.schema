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

class NamedType {
  public var module: String;
  public var pack: Array<String>;
  public var type: String;
  public var params: Array<String>;
  // public var typeKind: TypeKind;
  public var isTypeParamter: Bool;
  public function new(pack: Array<String>, module: String, type: String, params: Array<String>, isTypeParamter: Bool/*, typeKind: TypeKind*/) {
    this.pack = pack;
    if(isTypeParamter)
      this.module = module; // TODO magic
    else
      this.module = module.split(".").pop();
    this.type = type;
    this.params = params;
    this.isTypeParamter = isTypeParamter;
    // this.typeKind = typeKind;
  }

  public function hasParams()
    return params.length > 0;

  public function countParams()
    return params.length;

  public function parts() {
    return pack.concat(module != type && module != "StdTypes" ? [module, type] : [type]);
  }

  public function toString()
    return parts().join(".");

  public function toStringTypeWithParameters()
    return toString() + if(hasParams()) {
      "<" + params.join(", ") + ">";
    } else {
      "";
    }

  public function toIdentifier()
    return parts().join("_").upperCaseFirst();

  public function asType(): Type
    return Context.getType(toString());

  public function asComplexType(): ComplexType {
    if(isTypeParamter) {
      return TPath({
        pack: [],
        name: type,
        params: []
      });
    } else {
      return TPath({
        pack: pack,
        name: module,
        sub: type,
        params: params.map(TypeReference.paramAsComplexType).map(TPType)
      });
    }
  }
}
