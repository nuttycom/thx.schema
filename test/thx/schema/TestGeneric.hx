package thx.schema;

import utest.Assert.*;
import thx.schema.Generic.*;
import thx.schema.SimpleSchema.*;
using thx.schema.SchemaDynamicExtensions;
import thx.Either;
import thx.Functions.identity;
import haxe.ds.Option;

import thx.schema.SimpleSchema;

class TestGeneric {
  public function new() {}

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

  // public function testArguments() {
  //   var f = schema(thx.Either);
  //   $type(f);
  //   trace(f());
  //   var f = schema(thx.Tuple.Tuple2);
  //   $type(f);
  //   var f = schema({ name : String, age : Int });
  //   $type(f);
  //   var f = schema({ age : Int, name : String });
  //   $type(f);
  //   var f = schema({ wineName : String, age : Int });
  //   $type(f);
  //   var f = schema({ name : String, age : Int });
  //   $type(f);
  // }

  function roundTripSchema<T>(v : T, schema : Schema<String, T>) {
    var r: {} = schema.renderDynamic(v);
    // trace(r);
    notNull(r);
    same(Right(v), schema.parseDynamic(identity, r));
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
