package thx.schema.macro;

import haxe.ds.Option;
#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import haxe.macro.Type;
import haxe.macro.TypeTools;
#end
using thx.Maps;
using thx.Arrays;
using thx.Options;

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
      case TType(_.get() => t, _):
        extractTypeFromEnumQName(t.name);
      case _:
        None;
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

  static function createFunction(name: Null<String>, args: Array<{t:Type, opt:Bool, name:String}>, body: Expr, returd: ComplexType): Expr {
    return createExpressionFromDef(EFunction(name, {
      args: args.map(a -> ({
        name: a.name,
        type: TypeTools.toComplexType(a.t),
        opt: a.opt,
        meta: null,
        value: null
      } : FunctionArg)),
      ret: returd,
      expr: body
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

  static function createProperty(containerType: ComplexType, arg: {t:Type, opt:Bool, name:String}, map: Map<String, Expr>): Expr {
    var schema = lookupSchema(TypeTools.toString(arg.t), map),
        field = arg.name,
        type = TypeTools.toComplexType(arg.t);
        // schemaExpr = schemaInfo.holes.reduce(function(expr, hole) {
        //   trace(hole);
        //   var arg = map.get(hole);
        //   trace(arg);
        //   if(arg == null) Context.error("Poop my pants for " + hole, Context.currentPos());
        //   return macro $expr($arg);
        // }, schemaInfo.expr);
    // trace(schemaInfo.holes);
    // trace(field);
    // trace(schemaExpr);
    return macro thx.schema.SchemaDSL.required($v{arg.name}, $schema, function(v : $containerType): $type return v.$field);
  }

  static function constructEnumConstructorExpression(type: String, item: { name: String, field: EnumField }, holesMap): Expr {
    var cons = type.split(".").concat([item.name]),
        ctype = TypeTools.toComplexType(Context.getType(type));
    // TODO get constructor arguments and switch
    return switch item.field.type {
      case TEnum(_):
        // trace("ALIVE CONST? " + item.name);
        macro thx.schema.SimpleSchema.constEnum($v{item.name}, $p{cons});
      case TFun(args, returd):
        var n = args.length,
            apN = 'ap$n',
            containerType = createAnonymTypeFromArgs(args),
            object = createSetObject(args),
            constructorF = createFunction(null, args, createReturn(object), containerType),
            objectProperties = args.map(createProperty.bind(containerType, _, holesMap)),
            apNArgs = [constructorF].concat(objectProperties),
            enumArgs = args.map(a -> a.name).map(n -> macro v.$n),
            destructured = args.map(a -> a.name).map(n -> macro $i{n});
        // trace("ALIVE? " + item.name);
        var r = macro thx.schema.SimpleSchema.alt(
          $v{item.name},
          thx.schema.SimpleSchema.object(thx.schema.SchemaDSL.$apN($a{apNArgs})),
          function(v: $containerType): $ctype return $p{cons}($a{enumArgs}),
          function(v: $ctype): haxe.ds.Option<$containerType> return switch v {
            case $p{cons}($a{destructured}): Some($object);
            case _: None;
          }
        );
        // trace(ExprTools.toString(r));
        r;
      case _:
        Context.error("unable to match correct type for enum constructor: " + item.field, Context.currentPos());
    }
  }

  static function exprOfMapToMap(typeSchemas: Expr): Map<String, Expr> {
    var map = new Map();
    // trace(typeSchemas.expr);
    switch typeSchemas.expr {
      case EConst(CIdent("null")):
      case EArrayDecl(arr):
        for(item in arr) {
          // TType(thx.schema.Schema,[TMono(<mono>),TType(thx.schema.MyInt,[])])
          switch Context.typeof(item) {
            case TType(_.toString() => stype, [_, TType(t, [])]) if(stype == "thx.schema.Schema"):
              map.set(t.toString(), item);
            case _:
              Context.error('The second argument to the function should be an array of schemas', Context.currentPos());
          }
          // switch item.expr {
          //   case EBinop(OpArrow, left, right):
          //     // var l = Context.typeof(left);
          //     var r = Context.typeof(right);
          //     // trace(l);
          //     trace(r);
          //   case _:
          //     Context.error('The second argument to the functions should be a map literal from type identifiers to schemas', Context.currentPos());
          // }
        }
      case _:
        Context.error('The second argument to the function should be an array of schemas', Context.currentPos());
    }
    // trace(typeSchemas);

    return map;
  }

  static function generateSchemaMap(typeSchemas: Expr) {
    var typeSchemaMap: Map<String, Expr> = new Map();
    Maps.merge(typeSchemaMap, [[
        "String" => macro thx.schema.SimpleSchema.string(),
        "Bool" => macro thx.schema.SimpleSchema.bool(),
        "Float" => macro thx.schema.SimpleSchema.float(),
        "Int" => macro thx.schema.SimpleSchema.int(),
        "Null" => macro thx.schema.SimpleSchema.array
      ], exprOfMapToMap(typeSchemas)]);
    return typeSchemaMap;
  }

  public static function makeEnumSchema<E>(e: Expr, typeSchemas: ExprOf<Map<String, thx.schema.SimpleSchema.Schema<E, Dynamic>>>) {
    var tenum = extractEnumTypeFromExpression(e);

    var typeSchemaMap = generateSchemaMap(typeSchemas);
    var constructors: Array<Expr> = switch tenum {
      case Some(enm):
        var nenum = extractEnumTypeNameFromExpression(e).getOrFail("strange");
        var list = extractEnumConstructorsFromType(enm);
        list.map(constructEnumConstructorExpression.bind(nenum, _, typeSchemaMap));
      case None:
        Context.error('Unable to resolve $e', Context.currentPos());
        [];
    }

    return macro function() return thx.schema.SimpleSchema.oneOf([$a{constructors}]);
  }

  static function lookupSchema(name: String, map: Map<String, Expr>) {
    var structure = nameToStructure(name);
    return switch map.getOption(structure.name) {
      case Some(schema):
        schema;
      case None:
        Context.error('Building a schema for this type requires passing a schema for "$name" in the array, which is the second argument', Context.currentPos());
        null;
    }


    // function _lookupSchema(acc: { expr: Expr, holes: Array<String> }, structure: TypeStructure): { expr: Expr, holes: Array<String> } {
    //   var maybeSchema = findSchema(structure.name);
    //   return  switch [maybeSchema, structure.params.length == 0] {
    //     case [Some(schema), true]:
    //       {
    //         expr : macro ${acc.expr}($schema),
    //         holes: acc.holes
    //       };
    //     case [None, true]:
    //       {
    //         expr : acc.expr,
    //         holes: acc.holes.concat([structure.name])
    //       };
    //     case [Some(schema), false]:
    //       {
    //         expr : acc.expr,
    //         holes: acc.holes
    //       };
    //     case [None, false]:
    //       {
    //         expr : acc.expr,
    //         holes: acc.holes
    //       };
    //   }
    // }
    // var maybeSchema = findSchema(structure.name);
    // return  switch [maybeSchema, structure.params.length == 0] {
    //   case [Some(schema), true]:
    //     {
    //       expr : schema,
    //       holes: []
    //     };
    //   case [None, true]:
    //     {
    //       expr : macro function(e) return e,
    //       holes: [structure.name]
    //     };
    //   case [Some(schemaf), false]:
    //     trace(structure.params);
    //     var acc = {
    //       expr : schemaf,
    //       holes: []
    //     };
    //     structure.params.reduce(_lookupSchema, acc)
    //   case [None, false]:
    //     var acc = {
    //       expr : macro function(e) return e, // TODO
    //       holes: [structure.name]
    //     };
    //     structure.params.reduce(_lookupSchema, acc)
    // }
    // return _lookupSchema(structure, { expr: macro (function(e) return e), holes: [] });
  }
#end

  public static function nameToStructure(name: String): TypeStructure {
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
      {
        name: pWithParams.matched(1),
        params: splitParams(pWithParams.matched(2)).map(nameToStructure),
      };
    } else {
      {
        name: name,
        params: []
      };
    }
  }
}

typedef TypeStructure = {
  name: String,
  params: Array<TypeStructure>
}
