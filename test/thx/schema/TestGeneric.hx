package thx.schema;

import thx.schema.Generic.*;
import thx.schema.SimpleSchema.*;
import thx.schema.SchemaDSL.*;
import thx.Either;
import haxe.ds.Option;

import thx.schema.SimpleSchema;

class TestGeneric extends TestBase {
  public function testBasicType() {
    var f = schema(Int)();
    roundTripSchema(7, f);
  }

  public function testSimpleClass() {
    var s = schema(SimpleClass)();
    roundTripSchema(new SimpleClass("x", 7), s);
  }

  public function testNestedClasses() {
    var sf = schema(OuterClass)();
    roundTripSchema(new OuterClass("bee", new InnerClass("foo")), sf);
  }

  public function testClassWithTypeParameters() {
    var sf = schema(ClassWithTypeParameters);
    roundTripSchema(new ClassWithTypeParameters("aaa", 0.123, 7), sf(string(), float()));
  }

  public function testRecursiveClass() {
    var sf = schema(RecursiveClass);
    roundTripSchema(
      new RecursiveClass(
        Some(new RecursiveClass(None, 6)),
        7),
      sf(int())
    );
  }

  public function testEmptyClass() {
    var schemaf = schema(EmptyClass);
    roundTripSchema(new EmptyClass(), schemaf());
  }

  public function testClass1() {
    var schemaf = schema(Class1);
    roundTripSchema(new Class1("hi"), schemaf());
  }

  public function testClass2() {
    var schemaf = schema(Class2, [ MyInts.schema ]);
    roundTripSchema(new Class2({ i: 3 }, None), schemaf());
    roundTripSchema(new Class2({ i: 3 }, Some(Right([3.14]))), schemaf());
  }

  public function testClass3() {
    var schemaf = schema(Class3, []);
    roundTripSchema(new Class3("a", 3), schemaf(string(), int()));
  }

  public function testMakeEnumCase1() {
    var schemaf = schema(Case1, [ MyInts.schema ]),
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
    roundTripSchema(Case1.O(Left("a")), schema);
    roundTripSchema(Case1.O(Right(4.0)), schema);
    roundTripSchema(Case1.P(Some(Case1.P(None))), schema);
  }

  public function testEither() {
    var schema = schema(thx.Either)(int(), string());
    roundTripSchema(Left(1), schema);
    roundTripSchema(Right("X"), schema);
  }

  public function testAnonymous() {
    var s = schema({ name: String, email: String })();
    roundTripSchema({ name: "Foo", email: "some@exmaple.com" }, s);
    var s = schema({ name: String, address : { email: String, city: String } })();
    roundTripSchema({ name: "Foo", address : { email: "some@exmaple.com", city: "Boulder" } }, s);
  }

  public function testPartialType() {
    var s = schema(Either)(int(), float());
    roundTripSchema(Left(1), s);
    roundTripSchema(Right(0.1), s);
  }

  public function testTypeAlias() {
    var s = schema(YourInt)();
    roundTripSchema({ i2: 1 }, s);

    var s = schema(NestedTypeAlias)();
    roundTripSchema({ i2: Some({ i2: None }) }, s);

    var s = schema(TypeAliasWithTypeParameters)(string(), int(), float());
    roundTripSchema({
      a : "X",
      b: Some(1),
      c: [0.3, 0.4],
      d: 0.9,
      e: {
        f: "Y",
        g: { i: { i: 10 } }
      }
    }, s);

    var s = schema(NestedTypeAliasWithTypeParameter)(int()),
        value: NestedTypeAliasWithTypeParameter<Int> = {
          a: Some({
            a: None,
            b: None
          }),
          b: Some({
            a: None,
            b: None
          })
        };
    roundTripSchema(value, s);
  }

  public function testTuple() {
    var s = schema(thx.Tuple.Tuple2)(int(), string());
    roundTripSchema(Tuple.of(1, "X"), s);
    var s = schema(thx.Tuple.Tuple)(int(), string());
    roundTripSchema(Tuple.of(1, "X"), s);
    var s = schema(thx.Tuple)(int(), string());
    roundTripSchema(Tuple.of(1, "X"), s);
  }

  public function testPath() {
    var s = schema(thx.Path)();
    roundTripSchema(thx.Path.fromString("/users/some/file"), s);
  }

  public function testMap() {
    var s = schema(Map)(int());
    roundTripSchema(["a" => 1, "b" => 2], s);
  }

  public function testClassWithReferenceToThxCoreTypes() {
    var s = schema(ClassWithReferenceToThxCoreTypes)();
    roundTripSchema(new ClassWithReferenceToThxCoreTypes(Nel.pure("a"), DateTimeUtc.fromString("2017-01-02")), s);
  }

  public function testTimestamp() {
    var timestamp = schema(thx.Timestamp);
    roundTripSchema(thx.Timestamp.fromString("2015-03-29"), timestamp());
    failDeserialization('x', timestamp());
  }
}

class SimpleClass {
  var a: String;
  var b: Int;
  public function new(a: String, b: Int) {
    this.a = a;
    this.b = b;
  }
}

class InnerClass {
  var a: String;
  public function new(a: String) {
    this.a = a;
  }
}

class OuterClass {
  var b: String;
  var inner: InnerClass;
  public function new(b: String, inner: InnerClass) {
    this.b = b;
    this.inner = inner;
  }
}

class ClassWithTypeParameters<A, B> {
  var a: A;
  var b: B;
  var c: Int;
  public function new(a: A, b: B, c: Int) {
    this.a = a;
    this.b = b;
    this.c = c;
  }
}

class RecursiveClass<X> {
  var r: Option<RecursiveClass<X>>;
  var x: X;
  public function new(r: Option<RecursiveClass<X>>, x: X) {
    this.r = r;
    this.x = x;
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
  O(e: Either<T1, Float>);
  P(v: Option<Case1<T1, T2>>);
  // O<T3>(t3: Option<Array<T3>>);
}

enum Case2 {
  A;
  B(di: MyInt, z: haxe.ds.Option<String>);
}

typedef MyInt = { i: Int };
class MyInts {
  public static function schema(): Schema<String, MyInt> {
    return object(ap1(
      (i) -> { i: i },
      required("i", int(), (x:MyInt) -> x.i)
    ));
  }
}

typedef YourInt = { i2: Int };
typedef NestedTypeAlias = { i2: Option<NestedTypeAlias> };
typedef TypeAliasWithTypeParameters<A, B, C> = {
  a: A,
  b: Option<B>,
  c: Array<C>,
  d: Float,
  e: { f: String, g: { i: MyInt } }
}

typedef NestedTypeAliasWithTypeParameter<A> = {
  a: Option<NestedTypeAliasWithTypeParameter<A>>,
  b: Option<NestedTypeAliasWithTypeParameter<String>>
}

typedef IllegalTypedef = {
  f: Void -> Void
}

class ClassWithReferenceToThxCoreTypes {
  public var nel: Nel<String>;
  public var date: DateTimeUtc;
  public function new(nel, date) {
    this.nel = nel;
    this.date = date;
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
      - optional property
    + constructors with no arguments
    - constructors with 1 argument
    + constructors with multiple arguments
    - enum GADT
  + class
  + typedef
  + abstract ?
  - basic schemas for core types (eg: thx.DateTimeUtc)
    + Any
    + Date
    + DateTime
    + DateTimeUtc
    + LocalDate
    + LocalMonthDay
    + LocalYearMonth
    + Nel
    + Time
    + Timestamp

    + ReadonlyArray
    + Tuple (and friends)

    - Uuid
    - Decimal
    - BigInt
    - Int64
    - Rational
    + Path
    + Url
    + QueryString

    + Map
    - Ord
    - Maybe
    - Validation
    - Weekday
    - Char
    - BitMatrix
    - BitSet
    - Result

    - OrderedMap
    - OrderedSet
    - Set
    - HashSet
    - Error and friends?
  + cases where E and String diverge
*/
