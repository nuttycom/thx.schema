package thx.schema.algebra;

import haxe.ds.Option;
import thx.fp.Functions.*;
import thx.Validation;
import thx.Validation.*;
import thx.fp.Dynamics;
import thx.fp.Dynamics.*;
using thx.Functions;

// tagless-final encoding of the SchemaAlg algebra
interface SchemaAlg<A> {
  public function bool(): A;
//  public function float(): A;
//  public function int(): A;
//  public function str(): A;
//  public function unit(): A;
  public function object<B>(builder: AlgObjectBuilder<B, B>): A;
//  public function array<B>(elemSchema: Interpreter<B>): A;
//  public function oneOf<B>(alternatives: Array<AlgAlternative<B>>): A;
//  public function iso<B, C>(base: Interpreter<A>, f: B -> C, g: C -> B): A;
}

interface DateSchemaAlg<A> extends SchemaAlg<A> {
  public function date(): A;
}

interface Interpreter<X> {
  function apply<A>(s: SchemaAlg<A>): A;
}

class DynamicParseAlg<A> extends SchemaAlg<VNel<ParseError, A>> {
  var v: Dynamic;
  var path: SPath;

  public function new(v: Dynamic, path: SPath) {
    this.v = v;
    this.path = path;
  }

  public function clone(v: Dynamic, path: SPath) 
    return new DynamicParseAlg(v, path);
  }

  public function bool() return parseBool(this.v).leftMapNel(errAt(this.path))

  public function object<B>(builder: AlgObjectBuilder<B, B>): VNel<ParseError, A> {
    function parseObject<O, E>(builder: ObjectBuilder<O, E>, v: Dynamic, path: SPath): VNel<ParseError, E> {
      // helper function used to unpack existential type I
      inline function go<I>(schema: PropSchema<O, I>, k: ObjectBuilder<O, I -> A>): VNel<ParseError, A> {
        var parsedOpt: VNel<ParseError, I> = switch schema {
          case Required(fieldName, valueSchema, _):
            parseOptionalProperty(v, fieldName, valueSchema.apply(this.clone.bind(_, path / fieldName))).flatMapV.fn(
              _.toSuccessNel(new ParseError('Value $v does not contain field $fieldName and no default was available.', path))
            );

          case Optional(fieldName, valueSchema, _):
            parseOptionalProperty(v, fieldName, parse0.bind(valueSchema, _, path / fieldName));
        };

        return parsedOpt.ap(parseObject(k, v, path), Nel.semigroup());
      }

      return if (Types.isAnonymousObject(v)) {
        switch builder {
          case Pure(a): successNel(a);
          case Ap(s, k): go(s, k);
        };
      } else {
        fail('$v is not an anonymous object structure}).', path);
      };
    }

    parseObject(builder, this.v, this.path);
  }

  inline static public function errAt<A>(path: SPath): String -> ParseError
    return ParseError.new.bind(_, path);
}

class DynDateParser<A> extends DynamicParseAlg<A> implements DateSchemaAlg<VNel<ParseError, A>> {
  public function new(v: Dynamic, path: SPath) {
    super(v, path);
  }

  public function clone(v: Dynamic, path: SPath) {
    return new DynDateParser(v, path)
  }

  public function date() return ... 
}

class IntAlgSchema implements Interpreter<Int> {
  public function new() { } 
  public function apply<A>(s: SchemaAlg<A>): A return s.int();
}

class BoolAlgSchema implements Interpreter<Bool> {
  public function new() { } 
  public function apply<A>(s: SchemaAlg<A>): A return s.bool();
}

class FloatAlgSchema implements Interpreter<Float> {
  public function new() { } 
  public function apply<A>(s: SchemaAlg<A>): A return s.float();
}

class ObjectAlgSchema<X> implements Interpreter<X> {
  private var builder(default, null): AlgObjectBuilder<X, X>;
  public function new(builder: AlgObjectBuilder<X, X>) {
    this.builder = builder;
  }

  public function apply<A>(s: SchemaAlg<A>): A return s.object(this.builder);
}

class ArrayAlgSchema<X> implements Interpreter<X> {
  private var elemSchema(default, null): Interpreter<X>;
  public function new(elemSchema: Interpreter<X>) {
    this.elemSchema = elemSchema;
  }

  public function apply<A>(s: SchemaAlg<A>): A return s.array(this.elemSchema);
}

enum AlgAlternative<A> {
  Prism<A, B>(id: String, base: Interpreter<B>, f: B -> A, g: A -> Option<B>): AlgAlternative<A>;
}

enum AlgPropSchema<O, A> {
  Required<B>(fieldName: String, valueSchema: Interpreter<B>, accessor: O -> B): AlgPropSchema<O, B>;
  Optional<B>(fieldName: String, valueSchema: Interpreter<B>, accessor: O -> Option<B>): AlgPropSchema<O, Option<B>>;
}

/** Free applicative construction of builder for a set of object properties. */
enum AlgObjectBuilder<O, A> {
  Pure(a: A);
  Ap<I>(s: AlgPropSchema<O, I>, k: AlgObjectBuilder<O, I -> A>);
}

class AlgSchemaDSL {
  public static var bool(default, never): Interpreter<Bool> = new BoolAlgSchema();
  public static var int(default, never): Interpreter<Int> = new IntAlgSchema();
  public static var float(default, never): Interpreter<Float> = new FloatAlgSchema();

  public static function object<A>(builder: AlgObjectBuilder<A, A>): Interpreter<A> {
    return new ObjectAlgSchema(builder);
  }

  public static function lift<O, A>(s: AlgPropSchema<O, A>): AlgObjectBuilder<O, A>
    return Ap(s, Pure(function(a: A) return a));

  public static function required<O, A>(fieldName: String, valueSchema: Interpreter<A>, accessor: O -> A): AlgObjectBuilder<O, A>
    return lift(Required(fieldName, valueSchema, accessor));

  public static function optional<O, A>(fieldName: String, valueSchema: Interpreter<A>, accessor: O -> Option<A>): AlgObjectBuilder<O, Option<A>>
    return lift(Optional(fieldName, valueSchema, accessor));
}


class ObjectSchemaExtensions {
  public static function contramap<N, O, A>(o: AlgObjectBuilder<O, A>, f: N -> O): AlgObjectBuilder<N, A> {
    return switch o {
      case Pure(a): Pure(a);
      case Ap(s, k): Ap(PropSchemaExtensions.contramap(s, f), contramap(k, f));
    }
  }

  public static function map<O, A, B>(o: AlgObjectBuilder<O, A>, f: A -> B): AlgObjectBuilder<O, B> {
    return switch o {
      case Pure(a): Pure(f(a));
      case Ap(s, k): Ap(s, map(k, f.compose));
    };
  }

  public static function ap<O, A, B>(o: AlgObjectBuilder<O, A>, f: AlgObjectBuilder<O, A -> B>): AlgObjectBuilder<O, B> {
    return switch f {
      case Pure(g): map(o, g);
      case Ap(s, k): Ap(s, ap(o, map(k, flip)));
    };
  }
}

class PropSchemaExtensions {
  public static function contramap<N, O, A>(s: AlgPropSchema<O, A>, f: N -> O): AlgPropSchema<N, A>
    return switch s {
      case Required(n, s, a): Required(n, s, a.compose(f));
      case Optional(n, s, a): Optional(n, s, a.compose(f));
    };
}

class AlternativeExtensions {
  public static function id<A>(alt: AlgAlternative<A>): String {
    return switch alt {
      case Prism(id, _, _, _): id;
    };
  }
}

