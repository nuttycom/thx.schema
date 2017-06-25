package thx.schema.macro;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import haxe.macro.Type;
import haxe.macro.TypeTools;
import thx.schema.macro.Error.*;
import thx.schema.macro.Utils.*;
import thx.schema.macro.BoundSchemaType;
import haxe.ds.Option;
using thx.Options;

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
        fatal('Unable to build a schema for $other');
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
        throw 'Unable to convert type to UnboundSchemaType: $type';
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

  public function toIdentifier() return switch type {
    case QualifiedType(type): type.toIdentifier();
    case AnonObject(obj): obj.toIdentifier();
  }

  public function parameters(): Array<String>
    return switch type {
      case QualifiedType(type): type.params;
      case AnonObject(obj): [];
    };

  static function stringParamAsComplexType(p: String)
    return TPath({ name: p, pack: [], params: [] });

  public function toComplexType(): ComplexType {
    return switch type {
      case QualifiedType(type): type.toComplexType(stringParamAsComplexType);
      case AnonObject(obj): obj.toComplexType();
    };
  }

  public function toType(): Type {
    return switch type {
      case QualifiedType(type): type.toType();
      case AnonObject(obj): obj.toType();
    };
  }

  public function toString(): String
    return switch type {
      case QualifiedType(type): type.toString();
      case AnonObject(obj): obj.toString();
    };
}

enum UnboundSchemaTypeImpl {
  QualifiedType(type: QualifiedType<String>);
  AnonObject(obj: AnonObject);
}
