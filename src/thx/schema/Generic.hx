package thx.schema;

#if macro
import haxe.macro.Expr;
import thx.schema.macro.Arguments;
import thx.schema.macro.TypeBuilder;
#end

class Generic {
  macro public static function schema(exprs: Array<Expr>) {
    var args = Arguments.parseArguments(exprs);

    // TODO !!! remove
    trace("-------------------------------------------\n");
    trace("typeRef:    " + args.typeRef.toString());
    trace("identifier: " + args.typeRef.toIdentifier());
    trace("\n");
    // END REMOVE

    var typename = args.typeRef.toString();
    if(args.typeSchemas.exists(typename))
      return args.typeSchemas.get(typename);

    var path = TypeBuilder.ensure(args.typeRef, args.typeSchemas);
    return macro $p{path};
  }
}
