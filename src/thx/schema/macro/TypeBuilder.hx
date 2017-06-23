package thx.schema.macro;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import haxe.macro.TypeTools;
using thx.Arrays;

class TypeBuilder {
  static var generatedPath = ["thx", "schema", "generated"];

  public static function getModuleName(identifier: String): String
    return getModulePath(identifier).join(".");

  public static function getModulePath(identifier: String): Array<String>
    return generatedPath.concat([identifier]);

  public static function getPath(identifier: String): Array<String>
    return getModulePath(identifier).concat(["schema"]);

  static function generateTypeDefinition(identifier: String, typeReference: TypeReference, typeSchemas: Map<String, Expr>):TypeDefinition {
    return {
      pos: Context.currentPos(),
      pack: generatedPath,
      name: identifier,
      kind: TDClass(null, null, false),
      fields: [generateSchemaField(typeReference, typeSchemas)]
    };
  }

  static function generateSchemaField(typeReference: TypeReference, typeSchemas: Map<String, Expr>): Field {
    addTypeParametersToTypeSchemas(typeReference, typeSchemas);
    var schema = SchemaBuilder.generateSchema(typeReference, typeSchemas);
    // trace(schemaArgsFromTypeReference(typeReference));
    // trace(paramsFromTypeReference(typeReference));
    // trace(ExprTools.toString(schema));
    // trace(returnFromTypeReference(typeReference));
    return {
      access: [APublic, AStatic],
      pos: Context.currentPos(),
      name: "schema",
      kind: FFun({
        args: schemaArgsFromTypeReference(typeReference),
        expr: macro return $schema,
        params: paramsFromTypeReference(typeReference),
        ret: returnFromTypeReference(typeReference),
      }),
    };
  }

  static function addTypeParametersToTypeSchemas(typeReference: TypeReference, typeSchemas: Map<String, Expr>) {
    // TODO this mixing is maybe not correct because it propagates to schemas generated as side effects
    var base = typeReference.toString();
    var params = typeReference.parameters().map(function(p) {
      var n = variableNameFromTypeParameter(p);
      return {
        type: '$base.$p',
        expr: macro $i{n}
      };
    });

    params.each(p -> typeSchemas.set(p.type, p.expr));
  }

  static function schemaArgsFromTypeReference(typeReference: TypeReference) {
    return typeReference.parameters().map(function(p) {
      var type = TypeReference.paramAsComplexType(p);
      var schemaType = macro : thx.schema.SimpleSchema.Schema<E, $type>;
      return {
        value: null,
        type: schemaType,
        opt: false,
        name: variableNameFromTypeParameter(p),
        meta: null,
      };
    });
  }

  static function paramsFromTypeReference(typeReference: TypeReference) {
    return paramNamesFromTypeReference(typeReference).map(p -> {
      params: null,
      name: p,
      meta: null,
      constraints: null
    });
  }

  static function paramNamesFromTypeReference(typeReference: TypeReference) {
    return ["E"].concat(typeReference.parameters());
  }

  static function returnFromTypeReference(typeReference: TypeReference): ComplexType {
    var type = typeReference.asComplexType();
    return macro : thx.schema.SimpleSchema.Schema<E, $type>;
  }

  public static var generated = [];
  public static function ensure(typeReference: TypeReference, typeSchemas: Map<String, Expr>): Array<String> {
    var identifier = typeReference.toIdentifier();
    // TODO !!! check compilation with server
    if(!generated.contains(identifier)) {
      generated.push(identifier);
      var module = getModuleName(identifier);
      var typeDefinition = generateTypeDefinition(identifier, typeReference, typeSchemas);
      Context.defineModule(module, [typeDefinition]);
    }
    return getPath(identifier);
  }

  public static function variableNameFromTypeParameter(p: String)
    return 'schema$p';
}
