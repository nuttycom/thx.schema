package thx.schema;

import haxe.ds.Option;
import thx.Either;
import thx.fp.Functions.const;
using thx.Eithers;
using thx.Functions;

import utest.Assert;

import thx.schema.SimpleSchema;
import thx.schema.SimpleSchema.*;
import thx.schema.SchemaDSL.*;

using thx.schema.SchemaFExtensions;
using thx.schema.SchemaDynamicExtensions;

class TSimple {
  public var x: Int;

  public function new(x: Int) {
    this.x = x;
  }

  public static function schema<E>(): Schema<E, TSimple> return object(required("x", int(), function(ts: TSimple) return ts.x).map(TSimple.new));
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

  public static function schema<E>(): Schema<E, TComplex> return object(
    ap5(
      TComplex.new,
      required("i", int(), function(tc: TComplex) return tc.i),
      required("f", float(), function(tc: TComplex) return tc.f),
      required("b", bool(), function(tc: TComplex) return tc.b),
      required("a", array(TSimple.schema()), function(tc: TComplex) return tc.a),
      optional("o", TSimple.schema(), function(tc: TComplex) return tc.o)
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

  public static function schema<E>(): Schema<E, TRec> return object(
    ap2(
      TRec.new,
      required("i", int(), function(tc: TRec) return tc.i),
      required("rec", array(lazy(function() return TRec.schema().schema)), function(tc: TRec) return tc.rec)
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
  public static function schema<E>(): Schema<E, TEnum> return oneOf([
    alt("ex", TSimple.schema(), function(s) return EX(s), function(e: TEnum) return switch e { case EX(s): Some(s); case _: None; }),
    alt("ey",
      object(
        ap2(
          function(s: String, i: Int) return { s: s, i: i },
          required("s", string(), function(o: EYO) return o.s),
          required("i", int(), function(o: EYO) return o.i)
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

  public function serr(s: String) return s;

  public function new() { }

  public function testParseSuccess() {
    var obj = { i: 1, f: 2.0, b: false, a: arr, o: ox3 };

    Assert.same(
      Right(new TComplex(1, 2.0, false, [new TSimple(3), new TSimple(4)], Some(new TSimple(3)))),
      TComplex.schema().parseDynamic(serr, obj)
    );
  }

  public function testParseOption() {
    var obj = { i: 1, f: 2.0, b: false, a: arr };

    Assert.same(
      Right(new TComplex(1, 2.0, false, [new TSimple(3), new TSimple(4)], None)),
      TComplex.schema().parseDynamic(serr, obj)
    );
  }

  public function testParseInt() {
    Assert.same(Right(1), int().parseDynamic(serr, 1));
    Assert.same(Right(1), int().parseDynamic(serr, "1"));
    Assert.isTrue(int().parseDynamic(serr, 2.1).either.isLeft());
    Assert.isTrue(int().parseDynamic(serr, "xadf").either.isLeft());
  }

  public function testParseFloat() {
    Assert.same(Right(1), float().parseDynamic(serr, 1));
    Assert.same(Right(1.5), float().parseDynamic(serr, 1.5));
    Assert.same(Right(1.5), float().parseDynamic(serr, "1.5"));
    Assert.isTrue(float().parseDynamic(serr, "NaN").either.exists(Math.isNaN));
    Assert.isFalse(float().parseDynamic(serr, "Inf").either.forall(a -> Math.isFinite(a) || Math.isNaN(a)));
    Assert.isTrue(float().parseDynamic(serr, "xadf").either.isLeft());
  }

  public function testRenderFloat() {
    Assert.same(1.23, float().renderDynamic(1.23));
    Assert.same("NaN", float().renderDynamic(Math.NaN));
    Assert.same("Inf", float().renderDynamic(Math.POSITIVE_INFINITY));
    Assert.same("-Inf", float().renderDynamic(Math.NEGATIVE_INFINITY));
  }

  public function testParseBool() {
    Assert.same(Right(true), bool().parseDynamic(serr, true));
    Assert.same(Right(true), bool().parseDynamic(serr, "true"));
    Assert.isTrue(bool().parseDynamic(serr, "xadf").either.isLeft());
  }

  public function testParseString() {
    Assert.same(Right("asdf"), string().parseDynamic(serr, "asdf"));
    Assert.isTrue(string().parseDynamic(serr, 1).either.isLeft());
    Assert.isTrue(string().parseDynamic(serr, 1.0).either.isLeft());
    Assert.isTrue(string().parseDynamic(serr, true).either.isLeft());
  }

  public function testParseEnum() {
    var x = { ex: { x: 3 } };
    var y = { ey: { s: "hi", i: 1 } };
    var z = { ez: null };

    Assert.same(Right(EX(new TSimple(3))), TEnums.schema().parseDynamic(serr, x));
    Assert.same(Right(EY("hi", 1)), TEnums.schema().parseDynamic(serr, y));
    Assert.same(Right(EZ), TEnums.schema().parseDynamic(serr, z));
  }

  public function testParseRec() {
    var obj = { i: 1, rec: [{ i: 2, rec: [{ i: 3, rec: [] }] }] };

    Assert.same(
      Right(new TRec(1, [new TRec(2, [new TRec(3, [])])])),
      TRec.schema().parseDynamic(serr, obj)
    );
  }

  public function testEnum() {
    var schema: Schema<String, TEnumMulti> = oneOf([
      makeAlt("a", A),
      makeAlt("b", B, { i: int().schema }),
      makeAlt("c", C, { b: bool().schema, f: float().schema }),
      makeAlt("d", D, { s: string().schema, b: bool().schema, f: makeOptional(float()).schema })
    ]);
    Assert.isTrue(schema.parseDynamic(serr, "b").either.isLeft());
    var tests = [A, B(1), C(false, 0.1), D("x", true, Some(3.1415)), D("x", true, None)];
    for(test in tests) {
      var v = schema.renderDynamic(test);
      Assert.same(
        Right(test),
        schema.parseDynamic(serr, v),
        'failed with $v'
      );
    }
  }

  public function testEnumOneArgument() {
    var schema = oneOf([
      makeAlt("b", B, int().schema)
    ]);
    Assert.isTrue(schema.parseDynamic(serr, "b").either.isLeft());
    var tests = [B(1)];
    for(test in tests) {
      var v = schema.renderDynamic(test);
      Assert.same(
        Right(test),
        schema.parseDynamic(serr, v),
        'failed with $v'
      );
    }
  }

  public function testParseMap() {
    var schema = dict(int());
    var tests = [["a"=>1,"b"=>2], new Map()];
    for(test in tests) {
      var v = schema.renderDynamic(test);
      Assert.same(
        Right(test),
        schema.parseDynamic(serr, v),
        'failed with $v'
      );
    }
  }

  public function testParseVersioned() {
    var schema = meta(
      "version", string(),
      (version: String) -> return switch version {
        case "1.0": required("x", int(), function(ts: TSimple) return ts.x).map(TSimple.new);
        case "2.0": required("xenophon", int(), function(ts: TSimple) return ts.x).map(TSimple.new);
        case _: Pure(new TSimple(3));
      },
      const("2.0")
    );

    var oldV = { version: "1.0", x: 1 };
    var newV = { version: "2.0", xenophon: 1 };
    var expected = new TSimple(1);
    Assert.same(Right(expected), schema.parseDynamic(serr, oldV));
    Assert.same(Right(expected), schema.parseDynamic(serr, newV));
    Assert.same(Right(newV), schema.parseDynamic(serr, oldV).map(schema.renderDynamic));
  }
}

enum TEnumMulti {
  A;
  B(i: Int);
  C(b: Bool, f: Float);
  D(s: String, b: Bool, f: Option<Float>);
}
