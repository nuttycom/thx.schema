package thx.schema;

import utest.Assert.*;
import thx.schema.SchemaMaker.*;
import thx.Unit;
import thx.schema.SimpleSchema;
import thx.schema.SimpleSchema.*;
import thx.schema.SchemaDSL.*;
using thx.schema.SchemaDynamicExtensions;
import thx.Either;
import thx.Functions.identity;
import haxe.ds.Option;

class TestMacroSchema {
  public function new() {}

  public function testMakeEnumCase1() {
    var schema = makeEnum(Case1, [ MyInts.schema() ])();
    roundTripSchema(Case1.A, schema);
    roundTripSchema(Case1.B("b"), schema);
    roundTripSchema(Case1.C("b", 2, 0.1, false), schema);
  }

  // public function testFailPassingSchema() {
  //   var schema = makeEnum(Case2, [])();
  //   trace(schema);
  // }

  public function testMacroStuff() {
    same({name: "String", params: []}, thx.schema.macro.Macros.nameToStructure("String"));
    same({name: "Option", params: [{name: "Int", params: []}]}, thx.schema.macro.Macros.nameToStructure("Option<Int>"));
    same({
      name: "Either3", params: [{
        name: "Either",
        params: [{ name: "String", params: [] }, { name: "Int", params: [] }]
      }, {
        name: "SEither",
        params: [{ name: "Bool", params: [] }, { name: "Float", params: [] }]
      }, {
        name: "FEither",
        params: [{ name: "SomeStuff", params: [] }, { name: "Meh", params: [] }]
      }]
    }, thx.schema.macro.Macros.nameToStructure("Either3<Either<String, Int>, SEither<Bool, Float>, FEither<SomeStuff, Meh>>"));
  }

  function roundTripSchema<T>(v : T, schema : Schema<String, T>) {
    var r: T = schema.renderDynamic(v);
    same(Right(v), schema.parseDynamic(identity, r));
  }
}

enum Case1<T1, T2> {
  A;
  B(bs: String);
  C(cs: String, ci: Int, cf: Float, cb: Bool);
  D(di: MyInt);
  // E(?s: Null<String>);
  // F(s: Null<String>);
  // D(t: T1);
  // E(t: Array<T1>);
  // F(t1: T1, t2: T2);
  // G(t1: Option<String>);
  // H<T3>(t3: Option<Array<T3>>);
}

enum Case2 {
  A;
  B(di: MyInt, z: haxe.ds.Option<String>);
}

typedef MyInt = { i: Int };
class MyInts {
  public static function schema<E>(): Schema<E, MyInt> {
    return object(ap1(
      (i) -> { i: i },
      required("i", int(), (x:MyInt) -> x.i)
    ));
  }
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
