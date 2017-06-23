package thx.schema.macro;

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
using thx.Strings;

class Macros {
#if macro
  public static function extractEnumConstructorsFromType(t: Type): Array<{ name: String, field: EnumField }> {
    var e = TypeTools.getEnum(t);
    return e.names.map(name -> { name: name, field: e.constructs.get(name) });
  }

  public static function extractTypeFromQName(s: String): Type {
    return Context.getType(extractTypeNameFromKind(s));
  }

  public static function extractTypeNameFromKind(s: String): String {
    var pattern = ~/^(?:Enum|Class|Abstract)[<](.+)[>]$/;
    return if(pattern.match(s)) {
      pattern.matched(1);
    } else {
      Context.error("Unable to extract type name from kind: " + s, Context.currentPos());
    }
  }

  public static function extractTypeFromExpression(e: Expr): Type {
    var et = Context.typeof(e);
    return switch et {
      case TType(_.get() => t, p):
        extractTypeFromQName(t.name);
      case _:
        Context.error('Unable to extract type from expression: ${et}' , Context.currentPos());
    };
  }

  public static function extractTypeParamsFromExpression(e: Expr): Array<{ t: Type, name : String }> {
    var et = Context.typeof(e);
    return switch et {
      case TType(_.get() => t, p):
        t.params;
      case _:
        [];
    };
  }

  public static function extractClassTypeParamsFromExpression(e: Expr): Array<{ t: Type, name : String }> {
    return switch extractTypeFromExpression(e) {
      case TInst(_.get() => t, p):
        t.params;
      case _:
        [];
    };
  }


  public static function extractTypeNameFromExpression(e: Expr): String {
    var et = Context.typeof(e);
    return switch et {
      case TType(_.get() => t, _):
        extractTypeNameFromKind(t.name);
      case _:
        Context.error('Unable to extract type name from expression: ${et}' , Context.currentPos());
    };
  }

  public static function extractTypePathFromExpression(e: Expr): Array<String> {
    return extractTypeNameFromExpression(e).split(".");
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
      pos: Context.currentPos(),
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

  static function createProperty(containerType: ComplexType, arg: {t:Type, opt:Bool, name:String}, map: Map<String, Expr>): Expr {
    var schema = lookupSchema(TypeTools.toString(arg.t), map),
        field = arg.name,
        type = TypeTools.toComplexType(arg.t);
    // TODO inspect $schema to see if it is an Option, in that case unwrap and use `optional`
    return macro thx.schema.SchemaDSL.required($v{arg.name}, $schema, function(v : $containerType): $type return Reflect.field(v, $v{field}));
  }

  static function typeToArgumentName(type: String) {
    return 'schema${type.split(".").pop().upperCaseFirst()}';
  }

  static function constructEnumConstructorExpression(type: String, item: { name: String, field: EnumField }, providedSchemas: Map<String, Expr>): Expr {
    var cons = type.split(".").concat([item.name]),
        ctype = TypeTools.toComplexType(Context.getType(type));

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
            objectProperties = args.map(createProperty.bind(containerType, _, providedSchemas)),
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

  static function exprOfMapToMap(typeSchemas: Expr): Map<String, Expr> {
    var map = new Map();
    switch typeSchemas.expr {
      case EConst(CIdent("null")):
      case EArrayDecl(arr):
        for(item in arr) {
          switch Context.typeof(item) {
            case TType(_.toString() => stype, [_, t]) if(stype == "thx.schema.Schema"):
              map.set(TypeTools.toString(t), item);
            case TFun(_, TType(_.toString() => stype, [_, t])) if(stype == "thx.schema.Schema"):
              map.set(TypeTools.toString(t), item);
            case _:
              Context.error('The second argument to the function should be an array of schemas', Context.currentPos());
          }
        }
      case _:
        Context.error('The second argument to the function should be an array of schemas', Context.currentPos());
    }

    return map;
  }

  public static function generateSchemaMap(defaults, typeSchemas: Expr): Map<String, Expr> {
    var typeSchemaMap: Map<String, Expr> = new Map();
    Maps.merge(typeSchemaMap, [defaults, exprOfMapToMap(typeSchemas)]);
    return typeSchemaMap;
  }

  static function wrapTypeInSchema(t: Type): ComplexType {
    var ct = TypeTools.toComplexType(t);
    return macro : thx.schema.SimpleSchema.Schema<E, $ct>;
  }

  static function keepVariables(f: ClassField): Bool {
    return switch f.kind {
      case FVar(AccCall, AccCall): f.meta.has(":isVar");
      case FVar(AccCall, _): true;
      case FVar(AccNormal, _) | FVar(AccNo, _): true;
      case _: false;
    }
  }

  static function extractFieldsFromClass(ctype: Type) {
    return switch ctype {
      case TInst(_.get() => cls, _):
        cls.fields.get();
      case _:
        Context.error('Unable to extract fields from class ${ctype}', Context.currentPos());
        [];
    }
  }

  static function _lookupSchema(structure: TypeStructure, map: Map<String, Expr>): Expr {
    var name = structure.toStringType();

    switch map.getOption(name) {
      case Some(expr):
        return expr;
      case None:
        switch map.getOption(structure.name) {
          case Some(schema):
            if(structure.hasParams()) {
              var args = structure.params
                          .map(p -> _lookupSchema(p, map));
              return macro $schema($a{args});
            } else {
              return schema;
            }
          case None:
            Context.error('Building a schema for this type requires passing a schema for "$name" in the array, which is the second argument', Context.currentPos());
            return null;
        }
    }
  }

  static function lookupSchema(name: String, map: Map<String, Expr>): Expr {
    return _lookupSchema(TypeStructure.fromString(name), map);
  }

  public static function makeEnumSchema<E>(e: Expr, typeSchemaMap: Map<String, Expr>) {
    var tenum = extractTypeFromExpression(e);
    var params = extractTypeParamsFromExpression(e);

    // push all types to map
    params.map(v -> TypeTools.toString(v.t)).each(name -> {
      var n = typeToArgumentName(name);
      typeSchemaMap.set(name, macro $i{n});
    });

    var nenum = extractTypeNameFromExpression(e);
    var list = extractEnumConstructorsFromType(tenum);
    var constructors: Array<Expr> = list.map(constructEnumConstructorExpression.bind(nenum, _, typeSchemaMap));

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
      // DO NOT set the types of the arguments for ctype. The compiler doesn't like that
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

  public static function makeClassSchema<E>(e: Expr, typeSchemaMap: Map<String, Expr>) {
    var tclass = extractTypeFromExpression(e);
    var sclassParts = extractTypePathFromExpression(e);
    var params = extractClassTypeParamsFromExpression(e);

    // push all types to map
    params.map(v -> TypeTools.toString(v.t)).each(name -> {
      var n = typeToArgumentName(name);
      typeSchemaMap.set(name, macro $i{n});
    });

    var fields = extractFieldsFromClass(tclass).filter(keepVariables);
    var n = fields.length;
    var apN = 'ap$n';

    var argsForProps = fields.map(field -> {
      t: field.type,
      name: field.name,
      opt: false
    });

    var cargs = argsForProps.map(arg -> {
      ctype: TypeTools.toComplexType(arg.t),
      name: arg.name,
      opt: false
    });

    var bodyParts = [ macro var inst = Type.createEmptyInstance($p{sclassParts}) ]
                      .concat(cargs.map(arg -> macro Reflect.setField(inst, $v{arg.name}, $i{arg.name})))
                      .append(macro return inst);
    var body = macro $b{bodyParts};

    var containerType = TypeTools.toComplexType(tclass);
    var constructorF = createFunction(null, cargs, body, containerType, []);
    var objectProperties = argsForProps.map(createProperty.bind(containerType, _, typeSchemaMap));
    var apNArgs = [constructorF].concat(objectProperties);

    var argNames = params.map(p -> typeToArgumentName(p.name)).map(a -> macro $i{a});
    var inner = createFunction(
      "_makeSchema",
      params.map(p -> { ctype: wrapTypeInSchema(p.t), name: typeToArgumentName(p.name), opt: false }),
      fields.length == 0 ?
        macro return thx.schema.SimpleSchema.object(PropsBuilder.Pure(Type.createEmptyInstance($p{sclassParts}))) :
        macro return thx.schema.SimpleSchema.object(thx.schema.SchemaDSL.$apN($a{apNArgs})),
      null,
      ["E"].concat(params.map(v -> v.name))
    );
    var r = createFunction(
      "makeSchema",
      // DO NOT set the types of the arguments for ctype. The compiler doesn't like that
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
#end
}

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
