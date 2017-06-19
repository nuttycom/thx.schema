package thx.schema;

import utest.Assert.*;
import thx.schema.SchemaMaker.*;
import thx.Unit;
import thx.schema.SimpleSchema;
using thx.schema.SchemaDynamicExtensions;
import thx.Either;
import thx.Functions.identity;

class TestMacroSchema {
  public function new() {}

  public function testMakeEnumCase1() {
    var schema = makeEnum(Case1)();
    roundTripSchema(A1, schema);
    roundTripSchema(B1, schema);
  }

  public function testMakeEnumCase2() {
    var schema = makeEnum(Case2)();
    roundTripSchema(A2, schema);
    roundTripSchema(B2("b"), schema);
  }

  function roundTripSchema<T>(v : T, schema : Schema<String, T>) {
    var r: T = schema.renderDynamic(v);
    same(Right(v), schema.parseDynamic(identity, r));
  }

  // public function testMe() {
  //   var f: Schema<E, Case1> = someShit.mkSchema(Case1)(Case2.sghema, err: String -> E); // : Schema<String, Case1>
  //   f: Schema<E, Case2> -> Schema<E, Case1>
  // }
}

enum Case1 {
  A1;
  B1;
}

enum Case2 {
  A2;
  B2(s: String);
}

enum Case3 {
  A3;
  B3(s: String, t: Int);
}

enum Case4<T> {
  A4;
  B4(t: T);
}

enum Case5<T1, T2> {
  A5;
  B5(t1: T1, t2: T2);
}

/*
TODO:
  - enum
    - constructors with no arguments
    - constructors with 1 argument
    - constructors with multiple arguments
  - typedef
  - class
  - abstract ?


*/

// class MyData implements Data {
//   // var a: Int;
//   @:schema(blah.Franco.schema)
//   var a: Case1; // <- ???
//   var b: MyDataTwo;
// }


// class MyDataTwo implements Data {
//   var a: Int;
// }


// Maybe
//   @:singleArgument
//   Some: // {some: { value: value }} || {some: value}
//   None: // none: {}

// enum Case1 {
//   A;
//   B(case2: Case2);
// }

// class Case1s {

// }
