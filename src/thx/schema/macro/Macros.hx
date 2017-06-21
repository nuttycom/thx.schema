package thx.schema.macro;

import haxe.ds.Option;
#if macro
import haxe.macro.ComplexTypeTools;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import haxe.macro.Type;
import haxe.macro.TypeTools;
#end
using thx.Maps;
using thx.Arrays;
using thx.Options;
using thx.Strings;

class Macros {
#if macro
  public static function extractEnumConstructorsFromType(t: Type): Array<{ name: String, field: EnumField }> {
    var e = TypeTools.getEnum(t);
    return e.names.map(name -> { name: name, field: e.constructs.get(name) });
  }

  public static function extractTypeFromEnumQName(s: String): Option<Type> {
    return extractTypeNameFromEnum(s).map(Context.getType);
  }

  public static function extractTypeNameFromEnum(s: String): Option<String> {
    var pattern = ~/^Enum[<](.+)[>]$/;
    return if(pattern.match(s)) {
      Some(pattern.matched(1));
    } else {
      None;
    }
  }

  public static function extractEnumTypeFromExpression(e: Expr): Option<Type> {
    var et = Context.typeof(e);
    return switch et {
      case TType(_.get() => t, p):
        extractTypeFromEnumQName(t.name);
      case _:
        None;
    };
  }

  public static function extractTypeParamsFromExpression(e: Expr): Array<{ t: Type, name : String }> {
    var et = Context.typeof(e);

    return switch et {
      case TType(_.get() => t, _):
        t.params;
      case _:
        [];
    };
  }


  public static function extractEnumTypeNameFromExpression(e: Expr): Option<String> {
    var et = Context.typeof(e);
    return switch et {
      case TType(_.get() => t, _):
        extractTypeNameFromEnum(t.name);
      case _:
        None;
    };
  }

  static function createRef<T>(t: T): Ref<T> {
    return {
      get: function (): T {
        return t;
      },
      toString: function (): String {
        return Std.string(t);
      }
    };
  }

  static function createFieldFromFunctionArg(arg: {t:Type, opt:Bool, name:String}): Field {
    return {
      name: arg.name,
      pos: Context.currentPos(), // TODO
      kind: FVar(TypeTools.toComplexType(arg.t))
    };
  }

  static function createAnonymTypeFromArgs(args: Array<{t:Type, opt:Bool, name:String}>) {
    var fields: Array<Field> = args.map(createFieldFromFunctionArg);
    return ComplexType.TAnonymous(fields);
  }

  static function createFunction(name: Null<String>, args: Array<{ctype: Null<ComplexType>, opt:Bool, name:String}>, body: Expr, returd: Null<ComplexType>, typeParams: Array<String>): Expr {
    return createExpressionFromDef(EFunction(name, {
      args: args.map(a -> ({
        name: a.name,
        type: a.ctype,
        opt: a.opt,
        meta: null,
        value: null
      } : FunctionArg)),
      ret: returd,
      expr: body,
      params : typeParams.map(n -> {
        name: n,
        constraints: null,
        params: null,
        meta: null
      })
    }));
  }

  static function createExpressionFromDef(e: ExprDef) {
    return {
      expr: e,
      pos: Context.currentPos()
    };
  }

  static function createSetObject(args: Array<{t:Type, opt:Bool, name:String}>) {
    return createExpressionFromDef(EObjectDecl(args.map(a -> {
      field: a.name,
      expr: macro $i{a.name}
    })));
  }

  static function createReturn(expr: Expr): Expr {
    return createExpressionFromDef(EReturn(expr));
  }

  static function createProperty(containerType: ComplexType, arg: {t:Type, opt:Bool, name:String}, map: Map<String, SchemaExpr>, typeParameters: Array<String>): Expr {
    var schema = lookupSchema(TypeTools.toString(arg.t), map, typeParameters),
        field = arg.name,
        type = TypeTools.toComplexType(arg.t);
        // schemaExpr = schemaInfo.holes.reduce(function(expr, hole) {
        //   trace(hole);
        //   var arg = map.get(hole);
        //   trace(arg);
        //   if(arg == null) Context.error("Poop my pants for " + hole, Context.currentPos());
        //   return macro $expr($arg);
        // }, schemaInfo.expr);
    return switch schema {
      case SchemaExpr(schema):
        macro thx.schema.SchemaDSL.required($v{arg.name}, $schema, function(v : $containerType): $type return v.$field);
      case SchemaFExpr(schemaf, holes):
        var eholes = holes.map(hole -> switch hole {
          case T(typeToArgumentName(_) => name): macro $i{name};
          case Known(expr): expr;
        });
        // TODO !!! grab all known holes and throw a nice exception
        macro thx.schema.SchemaDSL.required($v{arg.name}, $schemaf($a{eholes}), function(v : $containerType): $type return v.$field);
    }
  }

  static function typeToArgumentName(type: String) {
    return 'schema${type.split(".").pop().upperCaseFirst()}';
  }

  static function constructEnumConstructorExpression(type: String, item: { name: String, field: EnumField }, providedSchemas: Map<String, SchemaExpr>, typeParameters: Array<String>): Expr {
    var cons = type.split(".").concat([item.name]),
        ctype = TypeTools.toComplexType(Context.getType(type));
    // TODO get constructor arguments and switch
    return switch item.field.type {
      case TEnum(_):
        macro thx.schema.SimpleSchema.constEnum($v{item.name}, $p{cons});
      case TFun(args, returd):
        var n = args.length,
            apN = 'ap$n',
            containerType = createAnonymTypeFromArgs(args),
            object = createSetObject(args),
            cargs = args.map(arg -> {
              ctype: TypeTools.toComplexType(arg.t),
              name: arg.name,
              opt: arg.opt
            }),
            constructorF = createFunction(null, cargs, createReturn(object), containerType, []),
            objectProperties = args.map(createProperty.bind(containerType, _, providedSchemas, typeParameters)),
            apNArgs = [constructorF].concat(objectProperties),
            enumArgs = args.map(a -> a.name).map(n -> macro v.$n),
            destructured = args.map(a -> a.name).map(n -> macro $i{n});
        var r = macro thx.schema.SimpleSchema.alt(
          $v{item.name},
          thx.schema.SimpleSchema.object(thx.schema.SchemaDSL.$apN($a{apNArgs})),
          function(v: $containerType): $ctype return $p{cons}($a{enumArgs}),
          function(v: $ctype): haxe.ds.Option<$containerType> return switch v {
            case $p{cons}($a{destructured}): Some($object);
            case _: None;
          }
        );
        r;
      case _:
        Context.error("unable to match correct type for enum constructor: " + item.field, Context.currentPos());
    }
  }

  static function exprOfMapToMap(typeSchemas: Expr): Map<String, SchemaExpr> {
    var map = new Map();
    switch typeSchemas.expr {
      case EConst(CIdent("null")):
      case EArrayDecl(arr):
        for(item in arr) {
          switch Context.typeof(item) {
            case TType(_.toString() => stype, [_, t]) if(stype == "thx.schema.Schema"):
              map.set(TypeTools.toString(t), SchemaExpr(item));
            case _:
              Context.error('The second argument to the function should be an array of schemas', Context.currentPos());
          }
        }
      case _:
        Context.error('The second argument to the function should be an array of schemas', Context.currentPos());
    }

    return map;
  }

  static function generateSchemaMap(typeSchemas: Expr): Map<String, SchemaExpr> {
    var typeSchemaMap: Map<String, SchemaExpr> = new Map();
    Maps.merge(typeSchemaMap, [[
        "String" => SchemaExpr(macro thx.schema.SimpleSchema.string()),
        "Bool" => SchemaExpr(macro thx.schema.SimpleSchema.bool()),
        "Float" => SchemaExpr(macro thx.schema.SimpleSchema.float()),
        "Int" => SchemaExpr(macro thx.schema.SimpleSchema.int()),
        "Array" => SchemaFExpr(macro thx.schema.SimpleSchema.array, [T("T")]),
        // "Null" => macro thx.schema.SimpleSchema.array // TODO !!!
      ], exprOfMapToMap(typeSchemas)]);
    return typeSchemaMap;
  }

  public static function makeEnumSchema<E>(e: Expr, typeSchemas: Expr) {
    var tenum = extractEnumTypeFromExpression(e);
    var params = extractTypeParamsFromExpression(e);

    var typeSchemaMap = generateSchemaMap(typeSchemas);
    var typeParamsArguments = [];
    var constructors: Array<Expr> = switch tenum {
      case Some(enm):
        var typeParameters = params.map(v -> TypeTools.toString(v.t));
        // typeParamsArguments = params.map(typeToArgumentName);

        var nenum = extractEnumTypeNameFromExpression(e).getOrFail("strange");
        var list = extractEnumConstructorsFromType(enm);
        var r = list.map(constructEnumConstructorExpression.bind(nenum, _, typeSchemaMap, typeParameters));
        r;
      case None:
        Context.error('Unable to resolve $e', Context.currentPos());
        [];
    }

    // schemaf = function makeSchema(a, b) {
    //   function _makeSchema<T1, T2>(a: T1, b: T2) {
    //     return null;
    //   }
    //   return _makeSchema(a, b);
    // }



    // TODO we need holes as named arguments, DO NOT set the types of the arguments. The compiler doesn't like that
    var argNames = params.map(p -> typeToArgumentName(p.name)).map(a -> macro $i{a});
    var inner = createFunction(
      "_makeSchema",
      params.map(p -> { ctype: wrapTypeInSchema(p.t), name: typeToArgumentName(p.name), opt: false }),
      macro return thx.schema.SimpleSchema.oneOf([$a{constructors}]),
      null,
      ["E"].concat(params.map(v -> v.name))
    );
    var r = createFunction(
      "makeSchema",
      params.map(p -> { ctype: null, name: typeToArgumentName(p.name), opt: false }),
      macro {
        $inner;
        return _makeSchema($a{argNames});
      },
      null,
      []
    );
    return r;
  }

  static function wrapTypeInSchema(t: Type): ComplexType {
    var ct = TypeTools.toComplexType(t);
    return macro : thx.schema.SimpleSchema.Schema<E, $ct>;
  }

  static function lookupSchema(name: String, map: Map<String, SchemaExpr>, typeParameters: Array<String>): SchemaExpr {
    if(typeParameters.contains(name)) {
      var n = typeToArgumentName(name);
      return SchemaExpr(macro $i{n});
    }

    var structure = TypeStructure.fromString(name);
    return switch map.getOption(structure.toStringType()) {
      case Some(schemaExpr):
        schemaExpr;
      case None:
        switch map.getOption(structure.name) {
          case Some(schemaExpr):
            // traverse parameters
            // if param is known we look it up and apply it to SchemaFExpr -> SchemaExpr

            // Array<String>

            // Array<T>
            // String

            // TODO !!! what to do with the parameters?
            schemaExpr;
          case None:
            // TODO !!! what to do at all?
            Context.error('Building a schema for this type requires passing a schema for "$name" in the array, which is the second argument', Context.currentPos());
            null;
        }
    }
  }
#end
}

#if macro
enum Hole {
  T(name: String);
  Known(expr: Expr);
}

enum SchemaExpr {
  SchemaExpr(schema: Expr);
  SchemaFExpr(schema: Expr, holes: Array<Hole>);
}
#end

class TypeStructure {
  public static function fromString(name: String) {
    var pWithParams = ~/^([^<]+)(?:[<](.+)[>])/;
    function splitParams(s: String): Array<String> {
      var capturePos = [],
          counter = 0;
      for(i in 0...s.length) {
        var c = s.substring(i, i+1);
        if(c == "," && counter == 0) {
          capturePos.push(i);
        } else if(c == "<") {
          counter++;
        } else if(c == ">") {
          counter--;
        }
      }
      var pairs = [-1].concat(capturePos).zip(capturePos.concat([s.length]));
      return pairs.map(p -> s.substring(p._0+1, p._1)).map(StringTools.trim);
    }
    return if(pWithParams.match(name)) {
      new TypeStructure(pWithParams.matched(1), splitParams(pWithParams.matched(2)).map(fromString));
    } else {
      new TypeStructure(name, []);
    }
  }

  public var name: String;
  public var params: Array<TypeStructure>;

  public function new(name, params) {
    this.name = name;
    this.params = params;
  }

  public function hasParams()
    return params.length > 0;

  public function toStringType() {
    // space is actually important here
    var rest = if(hasParams()) '<${params.map(p -> p.toStringType()).join(", ")}>' else "";
    return name + rest;
  }
}
