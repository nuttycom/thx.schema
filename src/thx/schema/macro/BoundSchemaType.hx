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

// this is the type for things inside object literals used like this: Generic.schema({ name: Option<String> })
// and also it is used when looking up schemas during generation
class BoundSchemaType {
  public static function createQualified(type: QualifiedType<BoundSchemaType>)
    return new BoundSchemaType(QualifiedType(type));

  public static function createAnon(obj: AnonObject<BoundSchemaType>)
    return new BoundSchemaType(AnonObject(obj));

  public static function createAnonFromFields(fields: Array<AnonField>, params: Array<BoundSchemaType>)
    return createAnon(new AnonObject(fields, params));

  public static function createTypeDef(type: QualifiedType<BoundSchemaType>)
    return new BoundSchemaType(TypeDef(type));

  public static function fromTypeName(typeName: String): Option<BoundSchemaType> {
    return (try {
      Some(Context.getType(typeName));
    } catch(e: Dynamic) {
      None;
    }).map(fromType);
  }

  public static function createLocalParam(param: String)
    return new BoundSchemaType(LocalParam(param));

  public static function fromTypeOrTypeParam(type: Type, params: Array<BoundSchemaType>) {
    var names = params.map(p -> p.toString());
    function resolve(t: Type) return switch t {
      case TLazy(f): f();
      case other: other;
    }
    type = resolve(type);
    return fromType(type);
  }

  public static function fromType(type: Type): BoundSchemaType {
    // do not follow the type here or you lose the aliased types
    return switch type {
      case TEnum(_.get() => t, p):
        fromEnumType(t, p);
      case TInst(_.get() => t, p):
        fromClassType(t, p);
      case TAbstract(_.get() => t, p):
        fromAbstractType(t, p);
      case TAnonymous(_.get() => t):
        fromAnonType(t);
      case TType(_.get() => t, p):
        fromDefType(t, p);
      case TMono(_.get() => t):
        fromType(t);
      case TFun(_):
        fatal('A schema for the function `${TypeTools.toString(type)}` cannot be generated. Are you trying to generate a schema for an anonymous object that contains a method?');
      case TLazy(f):
        fromType(f());
      case _:
        throw 'Unable to convert type to BoundSchemaType: $type';
    }
  }

  static function fromEnumType(t: EnumType, p: Array<Type>): BoundSchemaType {
    return createQualified(new QualifiedType(t.pack, t.module, t.name, p.map(fromType)));
  }

  static function fromClassType(t: ClassType, p: Array<Type>): BoundSchemaType {
    return switch t.kind {
      case KTypeParameter(_):
        createLocalParam(t.name);
      case _:
        createQualified(new QualifiedType(t.pack, t.module, t.name, p.map(fromType)));
    }
  }

  public static function fromAbstractType(t: AbstractType, p: Array<Type>): BoundSchemaType
    return createQualified(new QualifiedType(t.pack, t.module, t.name, p.map(fromType)));

  static function fromAnonType(t: AnonType): BoundSchemaType {
    var fields = t.fields.map(field -> new AnonField(field.name, BoundSchemaType.fromType(field.type)));
    return createAnonFromFields(fields, []);
  }

  static function fromDefType(t: DefType, p: Array<Type>): BoundSchemaType {
    var params = p.map(fromType);
    return createTypeDef(new QualifiedType(t.pack, t.module, t.name, params));
  }

  public var type: BoundSchemaTypeImpl;
  public function new(type: BoundSchemaTypeImpl) {
    this.type = type;
  }

  public function toComplexType(): ComplexType {
    return switch type {
      case QualifiedType(type): type.toComplexType(t -> t.toComplexType());
      case AnonObject(obj): obj.toComplexType();
      case LocalParam(param): paramAsComplexType(param);
      case TypeDef(type): type.toComplexType(t -> t.toComplexType());
    };
  }

  public function toType(): Type {
    return switch type {
      case QualifiedType(type): type.toType();
      case AnonObject(obj): obj.toType();
      case LocalParam(param): paramAsType(param);
      case TypeDef(type): type.toType();
    };
  }

  public function parameters(): Array<BoundSchemaType>
    return switch type {
      case QualifiedType(type): type.params;
      case AnonObject(obj): obj.params;
      case LocalParam(param): [];
      case TypeDef(type): type.params;
    };

  public function toString(): String return switch type {
    case QualifiedType(type): type.toString();
    case AnonObject(obj): obj.toString();
    case LocalParam(param): param;
    case TypeDef(type): type.toString();
  }

  public function toUnboundSchemaType(?params: Array<BoundSchemaType>): UnboundSchemaType {
    return switch type {
      case LocalParam(param):
        UnboundSchemaType.createQualified(new QualifiedType([], null, param, []));
      case QualifiedType(type) | TypeDef(type):
        UnboundSchemaType.fromType(type.toType());
      case AnonObject(obj):
        var p = (null == params ? obj.params : params).map(p -> p.toString());
        UnboundSchemaType.createAnonFromFields(obj.fields, p);
    };
  }
}

enum BoundSchemaTypeImpl {
  LocalParam(param: String);
  QualifiedType(type: QualifiedType<BoundSchemaType>);
  AnonObject(obj: AnonObject<BoundSchemaType>);
  TypeDef(type: QualifiedType<BoundSchemaType>);
}
