package thx.schema.macro;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import thx.schema.macro.Error.*;
import thx.schema.macro.Utils.*;
import haxe.ds.Option;
using thx.Options;

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
    type = Context.follow(type);
    return switch type {
      case TEnum(_.get() => t, p):
        fromEnumType(t, p);
      case TInst(_.get() => t, p):
        fromClassType(t, p);
      case TAbstract(_.get() => t, p):
        fromAbstractType(t);
      case TAnonymous(_.get() => t):
        fromAnonType(t);
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
        createQualified(new QualifiedType(t.pack, t.module, t.name, p.map(t -> fromType(t))));
    }
  }

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
    return switch type {
      case QualifiedType(type): type.toComplexType(t -> t.toComplexType());
      case AnonObject(obj): obj.toComplexType();
      case LocalParam(param): paramAsComplexType(param);
    };
  }

  public function toType(): Type {
    return switch type {
      case QualifiedType(type): type.toType();
      case AnonObject(obj): obj.toType();
      case LocalParam(param): paramAsType(param);
    };
  }

  public function parameters(): Array<BoundSchemaType>
    return switch type {
      case QualifiedType(type): type.params;
      case AnonObject(obj): []; // TODO !!!
      case LocalParam(param): []; // TODO !!!
    };

  public function toString(): String return switch type {
    case QualifiedType(type): type.toString();
    case AnonObject(obj): obj.toString();
    case LocalParam(param): param; // TODO !!!
  }

  public function toUnboundSchemaType(): UnboundSchemaType {
    var name = toString();
    return switch UnboundSchemaType.fromTypeName(name) {
      case Some(schemaType): schemaType;
      case None: fatal('Unable to generate UnboundSchemaType for $name');
    }
  }
}

enum BoundSchemaTypeImpl {
  LocalParam(param: String);
  QualifiedType(type: QualifiedType<BoundSchemaType>);
  AnonObject(obj: AnonObject);
}
