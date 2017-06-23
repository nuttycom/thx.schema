package thx.schema.macro;

import haxe.macro.Context;

class Error {
  public static function fatal<E>(message: String): E {
    Context.error(message, Context.currentPos());
    return null;
  }
}
