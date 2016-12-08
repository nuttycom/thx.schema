package thx.schema;

import haxe.Json;
import haxe.ds.Option;
import thx.Either;

import utest.Assert;

import thx.schema.SchemaF;
import thx.schema.SimpleSchema.*;
import thx.schema.TestSchema;

using thx.schema.SchemaFExtensions;
using thx.schema.SchemaDynamicExtensions;
using thx.Eithers;

class TestSchemaDynamicExtensions {
  public function new() {}

  public function testRenderDynamic() {
    var ex: TEnum = EX(new TSimple(3));
    var rendered = TEnums.schema().renderDynamic(ex);
    var parsed = TEnums.schema().parse(function(s: String) return s, rendered);
    Assert.same(Right(ex), parsed);
  }
}
