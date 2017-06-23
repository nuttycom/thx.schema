package thx.schema;

import utest.Assert.*;
import thx.schema.Generic.*;
// import thx.schema.SimpleSchema;
import thx.schema.SimpleSchema.*;
// import thx.schema.SchemaDSL.*;
// import thx.schema.macro.Macros;
using thx.schema.SchemaDynamicExtensions;
import thx.Either;
import thx.Functions.identity;
import haxe.ds.Option;

import thx.schema.SimpleSchema;

class TestGeneric {
  public function new() {}

  // public static function schema<E, A, B>(schemaA: Schema<E, A>, schemaB: Schema<E, B>): Schema<E, G<A, B>> {
  //   return thx.schema.SimpleSchema.object(
  //     thx.schema.SchemaDSL.ap3(
  //       function createInstanceThx_schema_TestGeneric_G(a:A, b:B,
  // c:StdTypes.Int):thx.schema.TestGeneric.G<A, B> {
  //         var inst = Type.createEmptyInstance(thx.schema.TestGeneric.G);
  //         Reflect.setField(inst, "a", a);
  //         Reflect.setField(inst, "b", b);
  //         Reflect.setField(inst, "c", c);
  //         return inst;
  //       },
  //       thx.schema.SchemaDSL.required(
  //         "a",
  //         schemaA,
  //         function(v:thx.schema.TestGeneric.G<A, B>): A return Reflect.field(v, "a") // TODO <- change return type
  //       ),
  //       thx.schema.SchemaDSL.required(
  //         "b",
  //         schemaB,
  //         function(v:thx.schema.TestGeneric.G<A, B>): B return Reflect.field(v, "b") // TODO <- change return type
  //       ),
  //       thx.schema.SchemaDSL.required(
  //         "c", thx.schema.SimpleSchema.int(),
  //         function(v:thx.schema.TestGeneric.G<A, B>):StdTypes.Int return Reflect.field(v, "c")
  //       )
  //     )
  //   );
  // }

  // public function testArguments() {
  //   var f = schema(String);
  //   $type(f);
  //   var f = schema(ClassWithTypeParameters);
  //   $type(f);
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

  public function testClassWithTypeParameters() {
    var sf = schema(ClassWithTypeParameters);
    roundTripSchema(new ClassWithTypeParameters("aaa", 0.123, 7), sf(string(), float()));
  }

  // public function testRecursiveClass() {
  //   var sf = schema(RecursiveClass);
  //   roundTripSchema(
  //     new RecursiveClass(
  //       Some(new RecursiveClass(None, 6)),
  //       7),
  //     sf(int())
  //   );
  // }

  function roundTripSchema<T>(v : T, schema : Schema<String, T>) {
    var r: T = schema.renderDynamic(v);
    // trace(r);
    same(Right(v), schema.parseDynamic(identity, r));
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

// TODO
class RecursiveClass<X> {
  var r: Option<RecursiveClass<X>>;
  var x: X;
  public function new(r: Option<RecursiveClass<X>>, x: X) {
    this.r = r;
    this.x = x;
  }
}
