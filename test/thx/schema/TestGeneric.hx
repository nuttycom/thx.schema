package thx.schema;

import utest.Assert.*;
import thx.schema.Generic.*;
// import thx.schema.SimpleSchema;
// import thx.schema.SimpleSchema.*;
// import thx.schema.SchemaDSL.*;
// import thx.schema.macro.Macros;
// using thx.schema.SchemaDynamicExtensions;
// import thx.Either;
// import thx.Functions.identity;
// import haxe.ds.Option;

class TestGeneric {
  public function new() {}

  public function testArguments() {
    var f = schema(String);
    $type(f);
    var f = schema(G);
    $type(f);
    var f = schema(thx.Either);
    $type(f);
    trace(f());
    var f = schema(thx.Tuple.Tuple2);
    $type(f);
    var f = schema({ name : String, age : Int });
    $type(f);
    var f = schema({ age : Int, name : String });
    $type(f);
    var f = schema({ wineName : String, age : Int });
    $type(f);
    var f = schema({ name : String, age : Int });
    $type(f);
  }
}

class G<A, B> {

}
