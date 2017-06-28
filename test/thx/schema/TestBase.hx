package thx.schema;

import thx.schema.SimpleSchema;
using thx.schema.SchemaDynamicExtensions;
import thx.Functions.identity;
import utest.Assert.*;

class TestBase {
  public function new() {}

  function roundTripSchema<T>(v: T, schema: Schema<String, T>, ?pos: haxe.PosInfos) {
    var r: Dynamic = schema.renderDynamic(v);
    // trace(r);
    notNull(r);
    switch schema.parseDynamic(identity, r) {
      case Right(p):
        same(v, p, 'expected $p to be equal to $v with serialized $r', pos);
      case Left(e):
        fail(e.toArray().join("\n").toString(), pos);
    }
  }

  function failDeserialization<Ser, T>(serialized: Ser, schema: Schema<String, T>, ?pos: haxe.PosInfos) {
    switch schema.parseDynamic(identity, serialized) {
      case Right(p):
        fail('deserializing `$serialized` should have failed but generated `$p`', pos);
      case Left(e):
        // haxe.Log.trace(e.toArray().map(e -> e.toString()).join(";\n"), pos);
        pass(pos);
    }
  }
}
