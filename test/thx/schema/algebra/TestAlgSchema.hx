package thx.schema.algebra;

import haxe.ds.Option;
import thx.Either;

import utest.Assert;

import thx.schema.algebra.SchemaAlg;
import thx.schema.algebra.SchemaAlg.AlgSchemaDSL.*;
using thx.schema.algebra.SchemaAlg.ObjectSchemaExtensions;
using thx.schema.algebra.SchemaAlg.PropSchemaExtensions;
using thx.schema.algebra.SchemaAlg.AlternativeExtensions;

using thx.Eithers;
using thx.Functions;

import thx.schema.TestSchema;

class TestAlgSchema {
  public function new() { }

  public function testBuildSchema() {
    var tSimpleSchema: SchemaAlg<TSimple> = object(required("x", int, function(ts: TSimple) return ts.x).map(TSimple.new));
  }
}
