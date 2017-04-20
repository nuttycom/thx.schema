package thx.schema;

import utest.Assert;
import thx.Functions.identity;
using thx.Functions;

import thx.schema.SPath;
import thx.schema.SchemaF;
import thx.schema.SimpleSchema.*;
import thx.schema.SchemaSchema.*;
using thx.schema.SchemaFExtensions;

class TestSchemaSchema {
  public function new() { }

  public function testParseSPath() {
    Assert.same(PSuccess(Empty), SPath.parse(""));
    Assert.same(PSuccess(Property("foo", Empty)), SPath.parse("foo"));
    Assert.same(PSuccess(Index(1, Empty)), SPath.parse("[1]"));
    Assert.same(PSuccess(Index(1, Property("baz", Index(1, Index(0, Property("bar", Property("foo", Empty))))))), SPath.parse("foo.bar[0][1].baz[1]"));
    Assert.same(PSuccess("foo.bar[0][1].baz[1]"), SPath.parse("foo.bar[0][1].baz[1]").map.fn(_.render()));
  }

  public function testParseErrorSchema() {
    Assert.notNull(parseErrorSchema(string(), function(s: String) return s));
  }
}
