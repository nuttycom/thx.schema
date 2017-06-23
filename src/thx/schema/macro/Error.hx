package thx.schema.macro;

import haxe.macro.Context;

class Error {
  public static function fatal(message: String) {
    Context.error(message, Context.currentPos());
    return null;
  }
}
