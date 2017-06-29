package thx.schema.macro;
import haxe.macro.Context;
import haxe.macro.Type;

class AnonField {
  public static function fromEnumArg(arg: { t: Type, opt: Bool, name: String })
    return new AnonField(arg.name, BoundSchemaType.fromType(arg.t));

  public var name(default, null): String;
  public var type(default, null): BoundSchemaType;
  public function new(name: String, type: BoundSchemaType) {
    this.name = name;
    this.type = type;
  }

  public function toString()
    return '$name: ${type.toString()}';

  public function toClassField(): ClassField {
    return {
      isPublic: true,
      kind: FVar(AccNormal, AccNormal),
      meta: null,
      name: name,
      params: [],
      pos: Context.currentPos(),
      type: type.toType(),
      expr: null,
      doc: null,
      overloads: null
    };
  }
}
