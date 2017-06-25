package thx.schema.macro;

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
