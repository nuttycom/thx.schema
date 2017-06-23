package thx.schema.macro;

import haxe.ds.Option;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import haxe.macro.Type;
import haxe.macro.TypeTools;
import thx.schema.macro.Error.*;
using thx.Options;

abstract TypeReference(TypeReferenceImpl) from TypeReferenceImpl to TypeReferenceImpl {
  public static function fromExpr(expr: Expr) {
    return switch Context.typeof(expr) {
      case TType(_.get() => kind, p):
        var nameFromKind = Macros.extractTypeNameFromKind(kind.name);
        switch fromTypeName(nameFromKind) {
          case Some(typeReference):
            typeReference;
          case None:
            var nameFromExpr = ExprTools.toString(expr);
            switch fromTypeName(nameFromExpr) {
              case Some(typeReference):
                typeReference;
              case None:
                fatal('Cannot find a type for $nameFromExpr, if you are building a schema for an abstract you have to pass the full path');
            }
        }
      case TAnonymous(_.get() => t):
        var fields = t.fields.map(function(field) {
          var nameFromKind = Macros.extractTypeNameFromKind(TypeTools.toString(field.type));
          var type = switch fromTypeName(nameFromKind) {
            case Some(typeReference):
              typeReference;
            case None:
              fatal('Cannot find a type for $nameFromKind');
          }
          return new Field(field.name, type);
        });
        Object(fields);
      case other:
        fatal('unable to build a schema for $other');
    }
  }

  static function fromEnumType(t: EnumType): TypeReference
    return Path(new Path(t.pack, t.module, t.name, t.params.map(p -> p.name), TKEnum));

  static function fromClassType(t: ClassType): TypeReference
    return Path(new Path(t.pack, t.module, t.name, t.params.map(p -> p.name), TKEnum));

  static function fromAbstractType(t: AbstractType): TypeReference
    return Path(new Path(t.pack, t.module, t.name, t.params.map(p -> p.name), TKEnum));

  static function fromAnonType(t: AnonType): TypeReference {
    var fields = t.fields.map(field -> new Field(field.name, fromType(field.type)));
    return Object(fields);
  }

  public static function fromType(type: Type): TypeReference {
    return switch fromTypeOption(type) {
      case Some(type): type;
      case None: fatal('unable to find type: ${type}');
    }
  }

  public static function fromTypeOption(type: Type): Option<TypeReference> {
    return switch type {
      case TEnum(_.get() => t, p):
        Some(fromEnumType(t));
      case TInst(_.get() => t, p):
        Some(fromClassType(t));
      case TAbstract(_.get() => t, p):
        Some(fromAbstractType(t));
      case TAnonymous(_.get() => t):
        Some(fromAnonType(t));
      case _:
        None;
    }
  }

  public static function fromTypeName(typeName: String): Option<TypeReference> {
    return (try {
      Some(Context.getType(typeName));
    } catch(e: Dynamic) {
      None;
    }).flatMap(fromTypeOption);
  }

  static var nextId = 0;
  static var anonymMap: Map<String, Int> = new Map();
  public function toString() return switch this {
    case Path(path):
      path.toString();
    case Object(fields):
      objectToString(fields);
  }

  public function toIdentifier() return switch this {
    case Path(path): path.toIdentifier();
    case Object(fields):
      var key = objectToString(fields);
      if(!anonymMap.exists(key)) {
        anonymMap.set(key, ++nextId);
      }
      var id = anonymMap.get(key);
      '__anonymous__$id';
  }

  static function objectToString(fields)
    return '{ ${fields.map(field -> field.toString()).join(", ")} }';
}

enum TypeReferenceImpl {
  Path(path: Path);
  Object(fields: Array<Field>);
}

class Field {
  public var name: String;
  public var type: TypeReference;
  public function new(name: String, type: TypeReference) {
    this.name = name;
    this.type = type;
  }

  public function toString()
    return '$name: ${type.toString()}';
}

enum TypeKind {
  TKEnum;
  TKClass;
  TKAbstract;
}

class Path {
  public var module: String;
  public var pack: Array<String>;
  public var type: String;
  public var params: Array<String>;
  public var typeKind: TypeKind;
  public function new(pack: Array<String>, module: String, type: String, params: Array<String>, typeKind: TypeKind) {
    this.pack = pack;
    this.module = module.split(".").pop();
    this.type = type;
    this.params = params;
    this.typeKind = typeKind;
  }

  public function hasParams()
    return params.length > 0;

  public function countParams()
    return params.length;

  function parts()
    return pack.concat(module != type && module != "StdTypes" ? [module] : []).concat([type]);

  public function toString()
    return parts().join(".");

  public function toIdentifier()
    return parts().join("_");
}
