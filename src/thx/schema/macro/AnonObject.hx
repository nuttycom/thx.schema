package thx.schema.macro;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import thx.schema.macro.Utils.*;
import haxe.ds.Option;

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

  public function toType(): Type {
    throw "TODO NOT IMPLEMENTED";
    return Type.TAnonymous(createRef({
      fields: [], // TODO
      status: AClosed
    }));
  }
}
