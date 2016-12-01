package thx.schema;

import haxe.Json;
import haxe.ds.Option;
import thx.Either;

import utest.Assert;

import thx.schema.Schema;
import thx.schema.SchemaDSL.*;
import thx.schema.TestSchema;

using thx.schema.SchemaExtensions;
using thx.schema.SchemaGenExtensions;
using thx.Eithers;

class TestSchemaGenExtensions {
  public function new() {}

  public function testGen() {
    var ex: TEnum = EX(new TSimple(0));
    var exemplar = TEnums.schema().exemplar();
    Assert.same(ex, exemplar);
  }
}

