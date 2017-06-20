package thx.schema.macro;

import haxe.ds.Option;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.TypeTools;
using thx.Options;

class Macros {
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
        trace("GET");
        return t;
      },
      toString: function (): String {
        trace("TO_STRING");
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
        opt: null,
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

  static function createProperty(containerType: ComplexType, arg: {t:Type, opt:Bool, name:String}): Expr {
    var schema = knownSchemas.get(TypeTools.toString(arg.t)),
        field = arg.name,
        type = TypeTools.toComplexType(arg.t);
    return macro thx.schema.SchemaDSL.required($v{arg.name}, $schema, function(v : $containerType): $type return v.$field);
  }

  static function constructEnumConstructorExpression(type: String, item: { name: String, field: EnumField }): Expr {
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
            constructorF = createFunction(null, args, createReturn(object), containerType),
            objectProperties = args.map(createProperty.bind(containerType)),
            apNArgs = [constructorF].concat(objectProperties),
            enumArgs = args.map(a -> a.name).map(n -> macro v.$n),
            destructured = args.map(a -> a.name).map(n -> macro $i{n});

        macro thx.schema.SimpleSchema.alt(
          $v{item.name},
          thx.schema.SimpleSchema.object(thx.schema.SchemaDSL.$apN($a{apNArgs})),
          function(v: $containerType): $ctype return $i{item.name}($a{enumArgs}),
          function(v: $ctype): haxe.ds.Option<$containerType> return switch v {
            case $i{item.name}($a{destructured}): Some($object);
            case _: None;
          }
        );
      case _:
        Context.error("unable to match correct type for enum constructor: " + item.field, Context.currentPos());
    }
  }

  public static function makeEnumSchema(e: Expr) {
    var tenum = extractEnumTypeFromExpression(e);
    var constructors: Array<Expr> = switch tenum {
      case Some(enm):
        var nenum = extractEnumTypeNameFromExpression(e).getOrFail("strange");
        var list = extractEnumConstructorsFromType(enm);
        list.map(constructEnumConstructorExpression.bind(nenum));
      case None:
        Context.error('unable to resolve $e', Context.currentPos());
        [];
    }

    return macro function() return thx.schema.SimpleSchema.oneOf([$a{constructors}]);
  }

  static var knownSchemas = [
    "String" => macro thx.schema.SimpleSchema.string(),
    "Bool" => macro thx.schema.SimpleSchema.bool(),
    "Float" => macro thx.schema.SimpleSchema.float(),
    "Int" => macro thx.schema.SimpleSchema.int(),
  ];
}
