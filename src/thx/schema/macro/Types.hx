package thx.schema.macro;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import haxe.macro.Type;
import haxe.macro.TypeTools;
import thx.schema.macro.Error.*;
import thx.schema.macro.Types.SantasLittleHelpers.*;
import haxe.ds.Option;
using thx.Options;

class UnboundSchemaType {
  public static function createQualified(type: QualifiedType<String>)
    return new UnboundSchemaType(QualifiedType(type));

  public static function createAnon(obj: AnonObject<BoundSchemaType>)
    return new UnboundSchemaType(AnonObject(obj));

  public static function createAnonFromFields(fields: Array<AnonField<BoundSchemaType>>)
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
}

// this is the type for things inside object literals used like this: Generic.schema({ name: Option<String> })
// and also it is used when looking up schemas during generation
class BoundSchemaType {
  public static function createQualified(type: QualifiedType<BoundSchemaType>)
    return new BoundSchemaType(QualifiedType(type));

  public static function createAnon(obj: AnonObject<BoundSchemaType>)
    return new BoundSchemaType(AnonObject(obj));

  public static function createAnonFromFields(fields: Array<AnonField<BoundSchemaType>>)
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
}

enum UnboundSchemaTypeImpl {
  QualifiedType(type: QualifiedType<String>);
  AnonObject(obj: AnonObject<BoundSchemaType>);
}

enum BoundSchemaTypeImpl {
  LocalParam(param: String);
  QualifiedType(type: QualifiedType<BoundSchemaType>);
  AnonObject(obj: AnonObject<BoundSchemaType>);
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
}

class AnonObject<T> {
  public var fields: Array<AnonField<T>>;
  public function new(fields: Array<AnonField<T>>) {
    this.fields = fields;
  }
}

class AnonField<T> {
  public var fieldName: String;
  public var type: T;
  public function new(fieldName: String, type: T) {
    this.fieldName = fieldName;
    this.type = type;
  }
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
