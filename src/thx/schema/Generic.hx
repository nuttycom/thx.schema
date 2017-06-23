package thx.schema;

#if macro
import haxe.macro.Expr;
import thx.schema.macro.Arguments;
#end

class Generic {
  macro public static function schema(exprs: Array<Expr>) {
    var args = Arguments.parseArguments(exprs);
    trace("-------------------------------------------\n");
    trace("typeRef:    " + args.typeRef.toString());
    trace("identifier: " + args.identifier);
    trace("schemas:    " + args.typeSchemas);
    trace("\n");
    return macro null;
  }
}
