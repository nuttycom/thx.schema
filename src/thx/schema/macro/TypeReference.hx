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

abstract TypeReference(TypeReferenceImpl) from TypeReferenceImpl to TypeReferenceImpl {
  public static function fromExpr(expr: Expr) {
    return switch Context.typeof(expr) {
      case TType(_.get() => kind, p):
        var nameFromKind = extractTypeNameFromKind(kind.name);
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
          var nameFromKind = extractTypeNameFromKind(TypeTools.toString(field.type));
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
    return Path(new Path(t.pack, t.module, t.name, t.params.map(p -> p.name), false));

  static function fromClassType(t: ClassType): TypeReference {
    return Path(new Path(t.pack, t.module, t.name, t.params.map(p -> p.name), false));
  }

static function fromClassTypeParameter(t: ClassType): TypeReference {
    // trace("TINST pack: " + t.pack, "module: " + t.module, "name: " + t.name, "params: " + t.params.map(p -> p.name));
    var parts = t.module.split(".");
    var pack = t.pack.copy();
    var module = parts.pop() + "." + pack.pop();
    var type = t.name;
    return Path(new Path(pack, module, type, [], true));
  }

  static function fromAbstractType(t: AbstractType): TypeReference
    return Path(new Path(t.pack, t.module, t.name, t.params.map(p -> p.name), false));

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
        switch t.kind {
          case KTypeParameter(_):
            Some(fromClassTypeParameter(t));
          case _:
            Some(fromClassType(t));
        }
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

  public function toStringTypeWithParameters() return switch this {
    case Path(path):
      path.toStringTypeWithParameters();
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
      '__Anonymous__$id';
  }

  public function parameters(): Array<String>
    return switch this {
      case Path(p): p.params;
      case Object(_): [];
    };

  static function objectToString(fields: Array<Field>)
    return '{ ${fields.map(field -> field.toString()).join(", ")} }';

  public function asType(): Type {
    return switch this {
      case Path(p): p.asType();
      case Object(f): fieldsToType(f);
    };
  }

  public function asComplexType(): ComplexType {
    return switch this {
      case Path(p): p.asComplexType();
      case Object(f): fieldsToComplexType(f);
    };
  }

  static function fieldsToComplexType(fields: Array<Field>): ComplexType {
    return ComplexType.TAnonymous(fields.map(field -> {
      pos: Context.currentPos(),
      name: field.name,
      meta: null,
      kind: FieldType.FVar(field.type.asComplexType(), null),
      doc: null,
      access: null,
    }));
  }

  static function fieldsToType(fields: Array<Field>): Type {
    return Type.TAnonymous(createRef({
      fields: [], // TODO
      status: AClosed
    }));
  }

  static function createRef<T>(t: T): Ref<T> {
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

  public static function extractTypeNameFromKind(s: String): String {
    var pattern = ~/^(?:Enum|Class|Abstract)[<](.+)[>]$/;
    return if(pattern.match(s)) {
      pattern.matched(1);
    } else {
      fatal("Unable to extract type name from kind: " + s);
    }
  }
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

// TODO REMOVE???
// enum TypeKind {
//   TKEnum;
//   TKClass;
//   TKAbstract;
// }

// class TypeParemter {
//   public var module: String;
//   public var pack: Array<String>;
//   public var type: String;
//   public var paramter: Stirng;
//   public function new(pack: Array<String>, module: String, type: String, parameter: String) {
//     this.pack = pack;
//     this.module = module.split(".").pop();
//     this.type = type;
//     this.params = params;
//     this.paramter = parameter;
//   }
// }

class Path {
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
