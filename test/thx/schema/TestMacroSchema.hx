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
    // var se = SimpleSchema.core.either;
    var schemaf = makeEnum(Case1, [
                    MyInts.schema()
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
    roundTripSchema(Case1.I(["1"]), schema);
    roundTripSchema(Case1.J(Left(1)), schema);
    roundTripSchema(Case1.J(Right(0.1)), schema);
    roundTripSchema(Case1.K("x", 7), schema);
    roundTripSchema(Case1.L(None), schema);
    roundTripSchema(Case1.L(Some("1")), schema);
    roundTripSchema(Case1.M(null), schema);
    roundTripSchema(Case1.M("Not Null"), schema);
    roundTripSchema(Case1.N(), schema);
    roundTripSchema(Case1.N(null), schema);
    roundTripSchema(Case1.N("Not Null"), schema);
  }

  public function testEmptyClass() {
    var schemaf = makeClass(EmptyClass);
    roundTripSchema(new EmptyClass(), schemaf());
  }

  public function testClass1() {
    var schemaf = makeClass(Class1);
    roundTripSchema(new Class1("hi"), schemaf());
  }

  public function testClass2() {
    var schemaf = makeClass(Class2, [
      MyInts.schema()
    ]);
    roundTripSchema(new Class2({ i: 3 }, None), schemaf());
    roundTripSchema(new Class2({ i: 3 }, Some(Right([3.14]))), schemaf());
  }

  public function testClass3() {
    var schemaf = makeClass(Class3, []);
    roundTripSchema(new Class3("a", 3), schemaf(string(), int()));
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
  I(a: Array<T1>);
  J(e: Either<Int, Float>);
  K(t1: T1, t2: T2);
  L(t1: Option<String>);
  M(s: Null<String>);
  N(?s: String);
  // O(e: Either<T1, Float>);

  // O<T3>(t3: Option<Array<T3>>);
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

class EmptyClass {
  public function new() {}
}

class Class1 {
  public var s: String;
  var s1: String = "z";
  public var s2(null, null) = "z";
  public var i = 3;
  public var f(default, null) = 3.0;
  public var f1(get, null): Float;
  @:isVar public var f2(get, set): Float;

  public function new(s) {
    this.s = s;
    f1 = 3;
    f2 = 4.0;
  }

  public function getI() {
    return this.i;
  }

  function get_f1() {
    return f1;
  }

  function get_f2() {
    return f2;
  }

  function set_f2(v: Float) {
    return f2 = v;
  }
}

class Class2 {
  public var myInt: MyInt;
  public var myOpt: Option<Either<String, Array<Float>>>;

  public function new(myInt, myOpt) {
    this.myInt = myInt;
    this.myOpt = myOpt;
  }
}

class Class3<T1, T2> {
  public var t1: T1;
  public var t2: T2;

  public function new(t1, t2) {
    this.t1 = t1;
    this.t2 = t2;
  }
}
/*
TODO:
  - enum
    - cases for constructors
      + optional argument
      + argument with explicit type parameters
      + argument with custom schema
      - argument is an array of objects
      - argument with type parameters from constructor generic
    + constructors with no arguments
    - constructors with 1 argument
    + constructors with multiple arguments
  - class
  - typedef
  - abstract ?
  - basic schemas for core types (eg: thx.DateTimeUtc)
    - Any
    - Date
    - DateTime
    - DateTimeUtc
    - LocalDate
    - LocalMonthDay
    - LocalYearMonth
    - Nel
    - Time
    - TimePeriod
    - Timestamp

    - Tuple (and friends)
    - Map
    - Ord
    - Maybe
    - ReadonlyArray
    - Validation
    - Weekday
    - Uuid
    - Decimal
    - Char
    - BitMatrix
    - BitSet
    - BigInt
    - Rational
    - Int64
    - Path
    - Url
    - QueryString
    - Result

    - HashSet
    - OrderedMap
    - OrderedSet
    - Set
    - Error and friends?
  - cases where E and String diverge
*/
