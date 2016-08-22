package thx.schema;

import haxe.ds.Option;
import thx.Either;

import utest.Assert;

import thx.schema.Schema;
import thx.schema.SchemaDSL.*;

using thx.schema.SchemaExtensions;
using thx.schema.SchemaDynamicExtensions;
using thx.Eithers;
using thx.Functions;

class TSimple {
  public var x: Int;

  public function new(x: Int) {
    this.x = x;
  }

  public static var schema(default, never): Schema<TSimple> = object(required("x", int, function(ts: TSimple) return ts.x).map(TSimple.new));
}

class TComplex {
  public var i: Int;
  public var f: Float;
  public var b: Bool;
  public var a: Array<TSimple>;
  public var o: Option<TSimple>;

  public function new(i: Int, f: Float, b: Bool, a: Array<TSimple>, o: Option<TSimple>) {
    this.i = i;
    this.f = f;
    this.b = b;
    this.a = a;
    this.o = o;
  }

  public static var schema(default, never): Schema<TComplex> = object(
    ap5(
      TComplex.new,
      required("i", int, function(tc: TComplex) return tc.i),
      required("f", float, function(tc: TComplex) return tc.f),
      required("b", bool, function(tc: TComplex) return tc.b),
      required("a", array(TSimple.schema), function(tc: TComplex) return tc.a),
      optional("o", TSimple.schema, function(tc: TComplex) return tc.o)
    )
  );
}

class TRec {
  public var i: Int;
  public var rec: Array<TRec>;

  public function new(i: Int, rec: Array<TRec>) {
    this.i = i;
    this.rec = rec;
  }

  public static var schema(default, never): Schema<TRec> = object(
    ap2(
      TRec.new,
      required("i", int, function(tc: TRec) return tc.i),
      required("rec", array(lazy(function() return TRec.schema)), function(tc: TRec) return tc.rec)
    )
  );
}

enum TEnum {
  EX(o: TSimple);
  EY(s: String, i: Int);
  EZ;
}

@sequence(s, i)
typedef EYO = {s: String, i: Int}

class TEnums {
  public static var schema: Schema<TEnum> = oneOf([
    alt("ex", TSimple.schema, function(s) return EX(s), function(e: TEnum) return switch e { case EX(s): Some(s); case _: None; }),
    alt("ey", 
      object(
        ap2(
          function(s: String, i: Int) return { s: s, i: i },
          required("s", string, function(o: EYO) return o.s),
          required("i", int, function(o: EYO) return o.i)
        )
      ),
      function(o: EYO) return EY(o.s, o.i), 
      function(e: TEnum) return switch e { case EY(s, i): Some({s: s, i: i}); case _: None; }
    ),
    alt("ez", constant(EZ), function(s) return EZ   , function(e: TEnum) return switch e { case EZ:    Some(null); case _: None; })
  ]);
}

class TestSchema {
  static var ox3 = { x : 3 };
  static var ox4 = { x : 4 };
  static var arr = [ox3, ox4];

  public function new() { }

  public function testParseSuccess() {
    var obj = { i: 1, f: 2.0, b: false, a: arr, o: ox3 };

    Assert.same(
      Right(new TComplex(1, 2.0, false, [new TSimple(3), new TSimple(4)], Some(new TSimple(3)))),
      TComplex.schema.parse(obj)
    );
  }

  public function testParseOption() {
    var obj = { i: 1, f: 2.0, b: false, a: arr };

    Assert.same(
      Right(new TComplex(1, 2.0, false, [new TSimple(3), new TSimple(4)], None)),
      TComplex.schema.parse(obj)
    );
  }

  public function testParseInt() {
    Assert.same(Right(1), int.parse(1));
    Assert.same(Right(1), int.parse("1"));
    Assert.isTrue(int.parse(2.1).either.isLeft());
    Assert.isTrue(int.parse("xadf").either.isLeft());
  }

  public function testParseFloat() {
    Assert.same(Right(1), float.parse(1));
    Assert.same(Right(1.5), float.parse(1.5));
    Assert.same(Right(1.5), float.parse("1.5"));
    Assert.isTrue(float.parse("xadf").either.isLeft());
  }

  public function testParseBool() {
    Assert.same(Right(true), bool.parse(true));
    Assert.same(Right(true), bool.parse("true"));
    Assert.isTrue(bool.parse("xadf").either.isLeft());
  }

  public function testParseString() {
    Assert.same(Right("asdf"), string.parse("asdf"));
    Assert.isTrue(string.parse(1).either.isLeft());
    Assert.isTrue(string.parse(1.0).either.isLeft());
    Assert.isTrue(string.parse(true).either.isLeft());
  }

  public function testParseEnum() {
    var x = { ex: { x: 3 } };
    var y = { ey: { s: "hi", i: 1 } };
    var z = { ez: null };

    Assert.same(Right(EX(new TSimple(3))), TEnums.schema.parse(x));
    Assert.same(Right(EY("hi", 1)), TEnums.schema.parse(y));
    Assert.same(Right(EZ), TEnums.schema.parse(z));
  }

  public function testParseRec() {
    var obj = { i: 1, rec: [{ i: 2, rec: [{ i: 3, rec: [] }] }] };

    Assert.same(
      Right(new TRec(1, [new TRec(2, [new TRec(3, [])])])),
      TRec.schema.parse(obj)
    );
  }

  public function testEnum() {
    var schema = oneOf([
      makeAlt("a", A),
      makeAlt("b", B, { i: int }),
      makeAlt("c", C, { b: bool, f: float }),
      makeAlt("d", D, { s: string, b: bool, f: makeOptional(float) })
    ]);
    Assert.isTrue(schema.parse("b").either.isLeft());
    var tests = [A, B(1), C(false, 0.1), D("x", true, Some(3.1415)), D("x", true, None)];
    for(test in tests) {
      var v = schema.renderDynamic(test);
      Assert.same(
        Right(test),
        schema.parse(v),
        'failed with $v'
      );
    }
  }

  public function testEnumOneArgument() {
    var schema = oneOf([
      makeAlt("b", B, int)
    ]);
    Assert.isTrue(schema.parse("b").either.isLeft());
    var tests = [B(1)];
    for(test in tests) {
      var v = schema.renderDynamic(test);
      Assert.same(
        Right(test),
        schema.parse(v),
        'failed with $v'
      );
    }
  }
}

enum TEnumMulti {
  A;
  B(i: Int);
  C(b: Bool, f: Float);
  D(s: String, b: Bool, f: Option<Float>);
}
