package thx.schema;

import utest.Assert.*;
import thx.schema.SchemaMaker.*;
import thx.schema.SimpleSchema;
import thx.schema.SimpleSchema.*;
import thx.schema.SchemaDSL.*;
import thx.schema.macro.Macros;
using thx.schema.SchemaDynamicExtensions;
import thx.Either;
import thx.Functions.identity;
import haxe.ds.Option;

class TestMacroSchema {
  public function new() {}

  public function testMakeEnumCase1() {
    var schemaf = makeEnum(Case1, [
                    MyInts.schema(),
                    // array(string()),
                    // array(float())
                  ]),
        schema = schemaf(string(), int());

    roundTripSchema(Case1.A, schema);
    roundTripSchema(Case1.B("b"), schema);
    roundTripSchema(Case1.C("b", 2, 0.1, false), schema);
    roundTripSchema(Case1.D({ i: 666 }), schema);
    roundTripSchema(Case1.E(["x", "y"]), schema);
    roundTripSchema(Case1.F([0.1, 0.2]), schema);
    roundTripSchema(Case1.G("1"), schema);
    roundTripSchema(Case1.H([[{ i: 777 }, { i: 666 }]]), schema);
  }

  public function testMacroStuff() {
    same(new TypeStructure("String", []), TypeStructure.fromString("String"));
    same(new TypeStructure("Option", [new TypeStructure("Int", [])]), TypeStructure.fromString("Option<Int>"));
    same(
      new TypeStructure("Either3", [
        new TypeStructure("Either", [new TypeStructure("String", []), new TypeStructure("Int", [])]),
        new TypeStructure("SEither", [new TypeStructure("Bool", []), new TypeStructure("Float", [])]),
        new TypeStructure("FEither", [new TypeStructure("SomeStuff", []), new TypeStructure("Meh", [])]),
      ]),
      TypeStructure.fromString("Either3<Either<String, Int>, SEither<Bool, Float>, FEither<SomeStuff, Meh>>"));
  }

  function roundTripSchema<T>(v : T, schema : Schema<String, T>) {
    var r: T = schema.renderDynamic(v);
    // trace(r);
    same(Right(v), schema.parseDynamic(identity, r));
  }
}

enum Case1<T1, T2> {
  A;
  B(bs: String);
  C(cs: String, ci: Int, cf: Float, cb: Bool);
  D(d: MyInt);
  E(e: Array<String>);
  F(f: Array<Float>);
  G(a: T1);
  H(a: Array<Array<MyInt>>);

  // H(a: Array<T1>);
  // G(e: Either<Int, Float>);
  // E(?s: Null<String>);
  // F(s: Null<String>);
  // D(t: T1);
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
  - cases where E and String diverge

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
