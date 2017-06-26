package thx.schema;

#if macro
import haxe.macro.Expr;
import thx.schema.macro.Arguments;
import thx.schema.macro.TypeBuilder;
#end

class Generic {
  macro public static function schema(exprs: Array<Expr>) {
    var args = Arguments.parseArguments(exprs);
    var typename = args.typeSchema.toString();
    if(args.typeSchemas.exists(typename))
      return args.typeSchemas.get(typename);

    var path = TypeBuilder.ensure(args.typeSchema, args.typeSchemas);
    return macro $p{path};
  }
}
