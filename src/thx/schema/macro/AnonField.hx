package thx.schema.macro;
import haxe.macro.Type;

class AnonField {
  public static function fromEnumArg(arg: { t: Type, opt: Bool, name: String })
    return new AnonField(arg.name, BoundSchemaType.fromType(arg.t));

  public var name: String;
  public var type: BoundSchemaType;
  public function new(name: String, type: BoundSchemaType) {
    this.name = name;
    this.type = type;
  }

  public function toString()
    return '$name: ${type.toString()}';
}
