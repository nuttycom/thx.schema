package thx.schema.macro;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import thx.schema.macro.Utils.*;

class AnonObject<T> {
  static var nextId = 0;
  static var anonymMap: Map<String, Int> = new Map();

  public static function fromEnumArgs<T>(args: Array<{ t: Type, opt: Bool, name: String }>): AnonObject<T>
    return new AnonObject(args.map(AnonField.fromEnumArg), []);

  public var fields: Array<AnonField>;
  public var params: Array<T>;
  public function new(fields: Array<AnonField>, params: Array<T>) {
    this.fields = fields;
    this.params = params;
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

  public function toSetterObject() {
    return createExpressionFromDef(EObjectDecl(fields.map(f -> {
      field: f.name,
      expr: macro $i{f.name}
    })));
  }

  public function toString()
    return '{ ${fields.map(f -> f.toString()).join(", ")} }';

  public function toIdentifier() {
    var key = toString();
    if(!anonymMap.exists(key)) {
      anonymMap.set(key, ++nextId);
    }
    var id = anonymMap.get(key);
    return '__Anonymous__$id';
  }

  public function toType(): Type {
    var anonType: AnonType = {
            fields: fields.map(f -> f.toClassField()),
            status: AOpened
          };
    return Type.TAnonymous(createRef(anonType));
  }
}
