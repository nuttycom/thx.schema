package thx.schema.macro;

import haxe.macro.Context;
import haxe.macro.Expr;
using thx.Arrays;

class Generator {
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
    return {
      access: [APublic, AStatic],
      pos: Context.currentPos(),
      name: "schema",
      kind: FFun({
        args: [], // TODO !!!
        expr: macro return "HI", // TODO !!!
        params: [], // TODO !!!
        ret: null // TODO !!!
      }),
    };
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
}
