package thx.schema.macro;

import haxe.macro.Context;
import haxe.macro.Expr;
using thx.Arrays;

class TypeBuilder {
  static var generatedPath = ["thx", "schema", "generated"];

  public static function getModuleName(identifier: String): String
    return getModulePath(identifier).join(".");

  public static function getModulePath(identifier: String): Array<String>
    return generatedPath.concat([identifier]);

  public static function getPath(identifier: String): Array<String>
    return getModulePath(identifier).concat(["schema"]);

  static function generateTypeDefinition(identifier: String, schemaType: UnboundSchemaType, typeSchemas: Map<String, Expr>):TypeDefinition {
    return {
      pos: Context.currentPos(),
      pack: generatedPath,
      name: identifier,
      kind: TDClass(null, null, false),
      fields: [generateSchemaField(schemaType, typeSchemas)]
    };
  }

  static function generateSchemaField(schemaType: UnboundSchemaType, typeSchemas: Map<String, Expr>): Field {
    var schema = SchemaBuilder.generateSchema(schemaType.toBoundSchemaType(), typeSchemas);
    return {
      access: [APublic, AStatic],
      pos: Context.currentPos(),
      name: "schema",
      kind: FFun({
        args: schemaArgsFromUnboundSchemaType(schemaType),
        expr: macro return $schema,
        params: paramsFromUnboundSchemaType(schemaType),
        ret: returnFromTypeReference(schemaType),
      }),
    };
  }

  static function schemaArgsFromUnboundSchemaType(schemaType: UnboundSchemaType) {
    return schemaType.parameters().map(function(p) {
      var type = UnboundSchemaType.paramAsComplexType(p);
      var schemaType = macro : thx.schema.SimpleSchema.Schema<String, $type>;
      return {
        value: null,
        type: schemaType,
        opt: false,
        name: variableNameFromTypeParameter(p),
        meta: null,
      };
    });
  }

  static function paramsFromUnboundSchemaType(schemaType: UnboundSchemaType) {
    return paramNamesFromUnboundSchemaType(schemaType).map(p -> {
      params: null,
      name: p,
      meta: null,
      constraints: null
    });
  }

  static function paramNamesFromUnboundSchemaType(schemaType: UnboundSchemaType) {
    return schemaType.parameters();
  }

  static function returnFromTypeReference(schemaType: UnboundSchemaType): ComplexType {
    var type = schemaType.toComplexType();
    return macro : thx.schema.SimpleSchema.Schema<String, $type>;
  }

  public static var generated = [];
  public static function ensure(schemaType: UnboundSchemaType, typeSchemas: Map<String, Expr>, ?identifier: String): Array<String> {
    if(null == identifier) identifier = schemaType.toIdentifier();
    // TODO !!! check compilation with server
    if(!generated.contains(identifier)) {
      generated.push(identifier);
      var module = getModuleName(identifier);
      var typeDefinition = generateTypeDefinition(identifier, schemaType, typeSchemas);
      trace(new haxe.macro.Printer("  ").printTypeDefinition(typeDefinition));
      Context.defineModule(module, [typeDefinition]);
    }
    return getPath(identifier);
  }

  public static function variableNameFromTypeParameter(p: String)
    return 'schema$p';
}
