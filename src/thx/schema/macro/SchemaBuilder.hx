package thx.schema.macro;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.TypeTools;
import thx.schema.macro.Error.*;
import thx.schema.macro.Types;
using thx.Arrays;

class SchemaBuilder {
  // here are passed things like Option<Array<A>> or Either<Option<String>> where A is a type paramter of the container schema
  public static function lookupSchema(schemaType: BoundSchemaType, typeSchemas: Map<String, Expr>): Expr {
    var type = schemaType.toString();
    if(typeSchemas.exists(type)) {
      return typeSchemas.get(type);
    } else {
      var path = TypeBuilder.ensure(schemaType.toUnboundSchemaType(), typeSchemas);
      return macro $p{path};
    }
  }

  public static function generateSchema(schemaType: BoundSchemaType, typeSchemas: Map<String, Expr>): Expr {
    return switch [schemaType.toType(), schemaType.type] {
      case [TInst(_.get() => cls, _),     BoundSchemaTypeImpl.QualifiedType(qtype)]: generateClassSchema(cls,    qtype, typeSchemas);
      case [TEnum(_.get() => enm, _),     BoundSchemaTypeImpl.QualifiedType(qtype)]: generateEnumSchema(enm,     qtype, typeSchemas);
      case [TAbstract(_.get() => abs, _), BoundSchemaTypeImpl.QualifiedType(qtype)]: generateAbstractSchema(abs, qtype, typeSchemas);
      // TODO
      case [TAnonymous(_.get() => anon),  BoundSchemaTypeImpl.AnonObject(obj)]:      generateAnonSchema(anon,    obj,   typeSchemas);
      case _: fatal('Cannot generate schema for unsupported type ${schemaType.toString()}');
    }
  }

  static function generateClassSchema(cls: ClassType, qtype: QualifiedType<BoundSchemaType>, typeSchemas: Map<String, Expr>) {
    var fields = cls.fields.get();
    var n = fields.length;
    return if(n == 0) {
      var path = qtype.parts();
      macro thx.schema.SimpleSchema.object(PropsBuilder.Pure(Type.createEmptyInstance($p{path})));
    } else {
      // generate constructor function
      var constructor = generateClassConstructorF(fields.map(classFieldToFunctionArgument), qtype);
      // generate fields
      var properties = fields.map(createPropertyFromClassField.bind(qtype, typeSchemas, _));
      // capture apN and ap arguments
      var apN = 'ap$n';
      var apNArgs = [constructor].concat(properties);
      // return schema
      var body = macro thx.schema.SimpleSchema.object(thx.schema.SchemaDSL.$apN($a{apNArgs}));
      body;
    }
  }

  static function classFieldToFunctionArgument(cf: ClassField): FunctionArgument {
    return {
      ctype: TypeTools.toComplexType(cf.type),
      opt: false,
      name: cf.name
    };
  }

  static function generateClassConstructorF(args: Array<FunctionArgument>, qtype: QualifiedType<BoundSchemaType>) {
    var path = qtype.parts(),
        bodyParts = [
            macro var inst = Type.createEmptyInstance($p{path})
          ]
          .concat(args.map(arg -> macro Reflect.setField(inst, $v{arg.name}, $i{arg.name})))
          .append(macro return inst);
    return createFunction("createInstance" + qtype.toIdentifier(), args, macro $b{bodyParts}, qtype.toComplexType(b -> b.toComplexType()), []);
  }

  static function generateEnumSchema(enm: EnumType, schemaType: QualifiedType<BoundSchemaType>, typeSchemas: Map<String, Expr>) {
    return macro null; // TODO
  }

  static function generateAbstractSchema(abs: AbstractType, schemaType: QualifiedType<BoundSchemaType>, typeSchemas: Map<String, Expr>) {
    return macro null; // TODO
  }

  static function generateAnonSchema(anon: AnonType, anonObject: AnonObject, typeSchemas: Map<String, Expr>) {
    return macro null; // TODO
  }

  static function createFunction(name: Null<String>, args: Array<FunctionArgument>, body: Expr, returnType: Null<ComplexType>, typeParams: Array<String>): Expr {
    return createExpressionFromDef(EFunction(name, {
      args: args.map(a -> ({
        name: a.name,
        type: a.ctype,
        opt: a.opt,
        meta: null,
        value: null
      } : FunctionArg)),
      ret: returnType,
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

  static function createPropertyFromClassField(qtype: QualifiedType<BoundSchemaType>, typeSchemas: Map<String, Expr>, cf: ClassField): Expr {
    var argType = BoundSchemaType.fromType(cf.type),
        argName = cf.name;
    trace(argType.parameters());
    return createProperty(qtype, argType, argName, typeSchemas);
  }

  // static function createProperty(qtype: ComplexType, map: Map<String, Expr>, arg: {t:Type, opt:Bool, name:String}): Expr {
  static function createProperty(qtype: QualifiedType<BoundSchemaType>, argType: BoundSchemaType, argName: String, typeSchemas: Map<String, Expr>): Expr {
    var schema = lookupSchema(argType, typeSchemas),
        containerType = qtype.toComplexType(f -> f.toComplexType()),
        type = argType.toComplexType();

    return macro thx.schema.SchemaDSL.required($v{argName}, $schema, function(v : $containerType): $type return Reflect.field(v, $v{argName}));
  }
}

typedef FunctionArgument = {
  ctype: Null<ComplexType>,
  opt: Bool,
  name: String
};
