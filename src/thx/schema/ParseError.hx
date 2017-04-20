package thx.schema;

import thx.schema.SPath;

class ParseError<E> {
  public var error(default, null): E;
  public var path(default, null): SPath;

  public function new(error: E, path: SPath) {
    this.error = error;
    this.path = path;
  }

  public function toString(): String {
    return '${path.render()}: ${error}';
  }
}

