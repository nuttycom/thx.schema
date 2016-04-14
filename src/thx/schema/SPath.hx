package thx.schema;

enum SPathADT {
  Property(name: String, tail: SPath);
  Index(idx: Int, tail: SPath);
  Empty;
}

abstract SPath (SPathADT) from SPathADT to SPathADT {
  public function render(): String return switch this {
    case Property(name, xs): 
      if (xs == Empty) name else '${xs.render()}.$name';

    case Index(idx, xs):
      if (xs == Empty) '[$idx]' else '${xs.render()}[$idx]';

    case Empty: "";
  }

  public static var root(get, null): SPath;
  inline static function get_root(): SPath return Empty;

  @:op(A / B)
  public function property(name: String): SPath
    return Property(name, this);
  
  // fun fact: in haXe, multiplication and division have the same precedence,
  // and always associate to the left. So we can use * for array indexing,
  // and avoid a lot of spurious parentheses when creating complex paths.
  @:op(A * B)
  public function index(idx: Int): SPath
    return Index(idx, this);

  @:op(A + B)
  public function append(other: SPath): SPath return switch this {
    case Property(name, xs): Property(name, xs.append(other));
    case Index(idx, xs): Index(idx, xs.append(other));                             
    case Empty: this;
  }

  public function reverse(): SPath {
    function go(path: SPath, acc: SPath): SPath {
      return switch path {
        case Property(name, xs): go(xs, Property(name, acc));
        case Index(idx, xs): go(xs, Index(idx, acc));
        case Empty: acc;
      };
    }

    return go(this, Empty);
  }

  public function toString() {
    return switch this {
      case Property(name, xs): '${xs.toString()}/$name';
      case Index(idx, xs): '${xs.toString()}[$idx]';
      case Empty: "";
    };
  }
}
