package thx.schema.macro;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import haxe.macro.Type;
import haxe.macro.TypeTools;
import thx.schema.macro.Error.*;
import thx.schema.macro.Types.SantasLittleHelpers.*;
import haxe.ds.Option;
using thx.Arrays;
using thx.Options;
using thx.Strings;

class UnboundSchemaType {
  public static function createQualified(type: QualifiedType<String>)
    return new UnboundSchemaType(QualifiedType(type));

  public static function createAnon(obj: AnonObject)
    return new UnboundSchemaType(AnonObject(obj));

  public static function createAnonFromFields(fields: Array<AnonField>)
    return new UnboundSchemaType(AnonObject(new AnonObject(fields)));

  public static function fromTypeName(typeName: String): Option<UnboundSchemaType> {
    return (try {
      Some(Context.getType(typeName));
    } catch(e: Dynamic) {
      None;
    }).map(fromType);
  }

  // this is meant to be derived from the first argument of `Generic.schema(Option)`.
  public static function fromExpr(expr: Expr): UnboundSchemaType {
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
          var type = switch BoundSchemaType.fromTypeName(nameFromKind) {
            case Some(typeReference):
              typeReference;
            case None:
              fatal('Cannot find a type for $nameFromKind');
          }
          return new AnonField(field.name, type);
        });
        UnboundSchemaType.createAnonFromFields(fields);
      case other:
        fatal('unable to build a schema for $other');
    }
  }

  public static function fromType(type: Type): UnboundSchemaType {
    return switch type {
      case TEnum(_.get() => t, p):
        fromEnumType(t);
      case TInst(_.get() => t, p):
        fromClassType(t);
      case TAbstract(_.get() => t, p):
        fromAbstractType(t);
      case TAnonymous(_.get() => t):
        fromAnonType(t);
      case _:
        throw 'unable to convert type to UnboundSchemaType: $type';
    }
  }

  static function fromEnumType(t: EnumType): UnboundSchemaType
    return createQualified(new QualifiedType(t.pack, t.module, t.name, t.params.map(p -> p.name)));

  static function fromClassType(t: ClassType): UnboundSchemaType
    return createQualified(new QualifiedType(t.pack, t.module, t.name, t.params.map(p -> p.name)));

  static function fromAbstractType(t: AbstractType): UnboundSchemaType
    return createQualified(new QualifiedType(t.pack, t.module, t.name, t.params.map(p -> p.name)));

  static function fromAnonType(t: AnonType): UnboundSchemaType {
    var fields = t.fields.map(field -> new AnonField(field.name, BoundSchemaType.fromType(field.type)));
    return createAnonFromFields(fields);
  }

  public static function paramAsComplexType(p: String): ComplexType {
    return TPath({
      pack: [],
      name: p,
      params: []
    });
  }

  public var type: UnboundSchemaTypeImpl;
  public function new(type: UnboundSchemaTypeImpl) {
    this.type = type;
  }

  public function toBoundSchemaType(): BoundSchemaType {
    return switch type {
      case QualifiedType(type):
        var ntype: QualifiedType<BoundSchemaType> = new QualifiedType(
          type.pack,
          type.module,
          type.name,
          type.params
            .map(LocalParam)
            .map(BoundSchemaType.new)
        );
        BoundSchemaType.createQualified(ntype);
      case AnonObject(obj):
        BoundSchemaType.createAnon(obj);
    };
  }

  // public function toString() return switch this {
  //   case Path(path):
  //     path.toString();
  //   case Object(fields):
  //     objectToString(fields);
  // }
    // public function toString(): String return switch type {
    //   case QualifiedType(type):
    //   case AnonObject(obj):
    // }

  // public function toStringTypeWithParameters() return switch this {
  //   case Path(path):
  //     path.toStringTypeWithParameters();
  //   case Object(fields):
  //     objectToString(fields);
  // }

  public function toIdentifier() return switch type {
    case QualifiedType(type): type.toIdentifier();
    case AnonObject(obj): obj.toIdentifier();
  }

  public function parameters(): Array<String>
    return switch type {
      case QualifiedType(type): type.params;
      case AnonObject(obj): [];
    };

  // static function objectToString(fields: Array<ObjectField>)
  //   return '{ ${fields.map(field -> field.toString()).join(", ")} }';

  // public function toType(): Type {
  //   return switch this {
  //     case Path(p): p.toType();
  //     case Object(f): fieldsToType(f);
  //   };
  // }

  static function stringParamAsComplexType(p: String)
    return TPath({ name: p, pack: [], params: [] });

  public function toComplexType(): ComplexType {
    return switch type {
      case QualifiedType(type): type.toComplexType(stringParamAsComplexType);
      case AnonObject(obj): obj.toComplexType();
    };
  }

  public function toType(): Type {
    return throw "NOT IMPLEMENTED";
  }

  public function toString(): String
    return switch type {
      case QualifiedType(type): type.toString();
      case AnonObject(obj): obj.toString();
    };
}

// this is the type for things inside object literals used like this: Generic.schema({ name: Option<String> })
// and also it is used when looking up schemas during generation
class BoundSchemaType {
  public static function createQualified(type: QualifiedType<BoundSchemaType>)
    return new BoundSchemaType(QualifiedType(type));

  public static function createAnon(obj: AnonObject)
    return new BoundSchemaType(AnonObject(obj));

  public static function createAnonFromFields(fields: Array<AnonField>)
    return new BoundSchemaType(AnonObject(new AnonObject(fields)));

  public static function fromTypeName(typeName: String): Option<BoundSchemaType> {
    return (try {
      Some(Context.getType(typeName));
    } catch(e: Dynamic) {
      None;
    }).map(fromType);
  }

  public static function createLocalParam(param: String)
    return new BoundSchemaType(LocalParam(param));

  public static function fromType(type: Type): BoundSchemaType {
    return switch type {
      case TEnum(_.get() => t, p):
        fromEnumType(t);
      case TInst(_.get() => t, p):
        fromClassType(t);
      case TAbstract(_.get() => t, p):
        fromAbstractType(t);
      case TAnonymous(_.get() => t):
        fromAnonType(t);
      case _:
        throw 'unable to convert type to BoundSchemaType: $type';
    }
  }

  // TODO !!!
  static function fromEnumType(t: EnumType): BoundSchemaType
    return createQualified(new QualifiedType(t.pack, t.module, t.name, t.params.map(p -> fromType(p.t))));

  // TODO !!!
  static function fromClassType(t: ClassType): BoundSchemaType
    return createQualified(new QualifiedType(t.pack, t.module, t.name, t.params.map(p -> fromType(p.t))));

  // TODO !!!
  static function fromAbstractType(t: AbstractType): BoundSchemaType
    return createQualified(new QualifiedType(t.pack, t.module, t.name, t.params.map(p -> fromType(p.t))));

  // TODO !!!
  static function fromAnonType(t: AnonType): BoundSchemaType {
    var fields = t.fields.map(field -> new AnonField(field.name, BoundSchemaType.fromType(field.type)));
    return createAnonFromFields(fields);
  }

  public var type: BoundSchemaTypeImpl;
  public function new(type: BoundSchemaTypeImpl) {
    this.type = type;
  }

  public function toComplexType(): ComplexType {
    return throw "NOT IMPLEMENTED";
  }

  public function toType(): Type {
    return throw "NOT IMPLEMENTED";
  }

  public function parameters(): Array<BoundSchemaType>
    return switch type {
      case QualifiedType(type): type.params;
      case AnonObject(obj): [];
      case LocalParam(param): []; // TODO !!!
    };

  public function toString(): String return switch type {
    case QualifiedType(type): type.toString();
    case AnonObject(obj): obj.toString();
    case LocalParam(param): param; // TODO !!!
  }

  public function toUnboundSchemaType(): UnboundSchemaType {
    return throw "NOT IMPLEMENTED"; // get the compiler type and parse it again
  }
}

enum UnboundSchemaTypeImpl {
  QualifiedType(type: QualifiedType<String>);
  AnonObject(obj: AnonObject);
}

enum BoundSchemaTypeImpl {
  LocalParam(param: String);
  QualifiedType(type: QualifiedType<BoundSchemaType>);
  AnonObject(obj: AnonObject);
}

class QualifiedType<T> {
  public var pack: Array<String>;
  public var module: String;
  public var name: String;
  public var params: Array<T>;
  public function new(pack: Array<String>, module: String, name: String, params: Array<T>) {
    this.pack = pack;
    this.module = module;
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

class AnonObject {
  static var nextId = 0;
  static var anonymMap: Map<String, Int> = new Map();

  public var fields: Array<AnonField>;
  public function new(fields: Array<AnonField>) {
    this.fields = fields;
  }

  public function toComplexType(): ComplexType {
    return ComplexType.TAnonymous(fields.map(field -> {
      pos: Context.currentPos(),
      name: field.name,
      meta: null,
      kind: FieldType.FVar(field.type.toComplexType(), null),
      doc: null,
      access: null,
    }));
  }

  public function toString()
    return '{ ${fields.map(f -> f.toString())} }';

  public function toIdentifier() {
    var key = toString();
    if(!anonymMap.exists(key)) {
      anonymMap.set(key, ++nextId);
    }
    var id = anonymMap.get(key);
    return '__Anonymous__$id';
  }
}

class AnonField {
  public var name: String;
  public var type: BoundSchemaType;
  public function new(name: String, type: BoundSchemaType) {
    this.name = name;
    this.type = type;
  }

  public function toString()
    return '$name: ${type.toString()}';
}

// this is meant to be derived from the first argument of `Generic.schema(Option)`.
// public static function fromExpr(expr: Expr): UnboundSchemaType {
//   return switch Context.typeof(expr) {
//     case TType(_.get() => kind, p):
//       var nameFromKind = extractTypeNameFromKind(kind.name);
//       switch fromTypeName(nameFromKind) {
//         case Some(typeReference):
//           typeReference;
//         case None:
//           var nameFromExpr = ExprTools.toString(expr);
//           switch fromTypeName(nameFromExpr) {
//             case Some(typeReference):
//               typeReference;
//             case None:
//               fatal('Cannot find a type for $nameFromExpr, if you are building a schema for an abstract you have to pass the full path');
//           }
//       }
//     case TAnonymous(_.get() => t):
//       var fields = t.fields.map(function(field) {
//         var nameFromKind = extractTypeNameFromKind(TypeTools.toString(field.type));
//         var type = switch fromTypeName(nameFromKind) {
//           case Some(typeReference):
//             typeReference;
//           case None:
//             fatal('Cannot find a type for $nameFromKind');
//         }
//         return new AnonField(field.name, type);
//       });
//       createAnonym(fields);
//     case other:
//       fatal('unable to build a schema for $other');
//   }
// }

// public static function fromTypeName(typeName: String): Option<UnboundSchemaType> {
//   return (try {
//     Some(Context.getType(typeName));
//   } catch(e: Dynamic) {
//     None;
//   }).flatMap(fromTypeOption);
// }

// public static function fromTypeOption(type: Type): Option<UnboundSchemaType> {
//   return switch type {
//     case TEnum(_.get() => t, p):
//       Some(fromEnumType(t));
//     case TInst(_.get() => t, p):
//       // TODO !!!
//       // switch t.kind {
//       //   case KTypeParameter(_):
//       //     Some(fromClassTypeParameter(t));
//       //   case _:
//           Some(fromClassType(t));
//       // }
//     case TAbstract(_.get() => t, p):
//       Some(fromAbstractType(t));
//     case TAnonymous(_.get() => t):
//       Some(fromAnonType(t));
//     case _:
//       None;
//   }
// }

// public static function fromType(type: Type): UnboundSchemaType {
//   return switch fromTypeOption(type) {
//     case Some(type): type;
//     case None: fatal('unable to find type: ${type}');
//   }
// }

// static function fromEnumType(t: EnumType): UnboundSchemaType
//   return createQualified(new QualifiedType(t.pack, t.module, t.name, t.params.map(p -> p.name)));

// static function fromClassType(t: ClassType): UnboundSchemaType {
//   return createQualified(new QualifiedType(t.pack, t.module, t.name, t.params.map(p -> p.name)));
// }

// static function fromClassTypeParameter(t: ClassType): UnboundSchemaType {
//   // trace("TINST pack: " + t.pack, "module: " + t.module, "name: " + t.name, "params: " + t.params.map(p -> p.name));
//   var parts = t.module.split(".");
//   var pack = t.pack.copy();
//   var module = parts.pop() + "." + pack.pop();
//   var type = t.name;
//   return createQualified(new QualifiedType(pack, module, type, [], true));
// }

// static function fromAbstractType(t: AbstractType): UnboundSchemaType
//   return createQualified(new QualifiedType(t.pack, t.module, t.name, t.params.map(p -> p.name)));

// static function fromAnonType(t: AnonType): UnboundSchemaType {
//   var fields = t.fields.map(field -> new AnonField(field.name, fromType(field.type)));
//   return createAnonym(fields);
// }

class SantasLittleHelpers {
  public static function extractTypeNameFromKind(s: String): String {
    var pattern = ~/^(?:Enum|Class|Abstract)[<](.+)[>]$/;
    return if(pattern.match(s)) {
      pattern.matched(1);
    } else {
      fatal("Unable to extract type name from kind: " + s);
    }
  }
}
