package thx.schema;

import haxe.ds.Option;
import thx.Either;

import utest.Assert;

import thx.schema.Schema;
import thx.schema.Schema.SchemaDSL.*;

using thx.schema.Schema.SchemaExtensions;
using thx.schema.SchemaDynamicExtensions;
using thx.Eithers;

class TSimple {
  public var x: Int;

  public function new(x: Int) {
    this.x = x;
  }
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
}

enum TEnum {
  X(o: TSimple);
  Y(s: String);
}

class TestSchema {
  static var ox3 = { x : 3 };
  static var ox4 = { x : 4 };
  static var arr = [ox3, ox4];

  static var simpleSchema = object(required("x", int, function(ts: TSimple) return ts.x).map(TSimple.new));

  static var arrs = array(simpleSchema);

  static var complexSchema = object(
    ap5(
      TComplex.new,
      required("i", int, function(tc: TComplex) return tc.i), 
      required("f", float, function(tc: TComplex) return tc.f), 
      required("b", bool, function(tc: TComplex) return tc.b), 
      required("a", arrs, function(tc: TComplex) return tc.a), 
      optional("o", simpleSchema, function(tc: TComplex) return tc.o)
    )
  );

  static var enumSchema = oneOf([
    alt("simple", simpleSchema, function(s) return X(s), function(e: TEnum) return switch e { case X(s): Some(s); case _: None; }),
    alt("str", string, function(s) return Y(s), function(e: TEnum) return switch e { case Y(s): Some(s); case _: None; })
  ]);


  public function new() { }

  public function testParseSuccess() {
    var obj = { i: 1, f: 2.0, b: false, a: arr, o: ox3 };

    Assert.same(
      Right(new TComplex(1, 2.0, false, [new TSimple(3), new TSimple(4)], Some(new TSimple(3)))), 
      complexSchema.parse(obj)
    );
  }

  public function testParseOption() {
    var obj = { i: 1, f: 2.0, b: false, a: arr };

    Assert.same(
      Right(new TComplex(1, 2.0, false, [new TSimple(3), new TSimple(4)], None)), 
      complexSchema.parse(obj)
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
    var x = { simple: { x: 3 } };
    var y = { str: "hi" };

    Assert.same(
      Right(X(new TSimple(3))),
      enumSchema.parse(x)
    );

    Assert.same(
      Right(Y("hi")),
      enumSchema.parse(y)
    );
  }
}

