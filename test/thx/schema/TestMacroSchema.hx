package thx.schema;

import utest.Assert.*;
import thx.schema.SchemaMaker.*;
import thx.Unit;
import thx.schema.SimpleSchema;
using thx.schema.SchemaDynamicExtensions;
import thx.Either;
import thx.Functions.identity;
import haxe.ds.Option;

class TestMacroSchema {
  public function new() {}

  public function testMakeEnumCase1() {
    var schema = makeEnum(Case1)();
    roundTripSchema(A, schema);
    roundTripSchema(B("b"), schema);
    roundTripSchema(C("b", 2), schema);
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
  A;
  B(s: String);
  C(s: String, t: Int);
  // D(t: T);
  // E(t1: T1, t2: T2);
  // F(t1: Option<String>);
}

/*
TODO:
  - cases for constructors
   - optional argument
   - argument with explicit type parameters
   - argument with custom schema
   - argument with type parameters from constructor generic
   - argument is an array of objects
  - enum
    - constructors with no arguments
    - constructors with 1 argument
    - constructors with multiple arguments
  - typedef
  - class
  - abstract ?

A
  B<T>(v : T)


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
