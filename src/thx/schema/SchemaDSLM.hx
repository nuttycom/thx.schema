package thx.schema;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.TypeTools;
import thx.macro.MacroTypes;
using thx.Arrays;

class SchemaDSLM {
  public static function makeVar(id: ExprOf<String>, rest: Array<Expr>) { //, constr: Expr, obj: ExprOf<Dynamic<Schema<Dynamic>>>) {
    if(rest.length == 0)
      Context.error('insufficient arguments', Context.currentPos());
    if(rest.length > 3)
      Context.error('too many arguments', Context.currentPos());
    var constr = rest[0];
    return if(rest.length == 1) {
      macro thx.schema.SchemaDSL.constEnum($id, $constr);
    } else if(rest.length == 2) {
        if(isSchema(rest[1])) {
          make1(id, constr, rest[1]);
        } else {
          var obj = rest[1];
          var fields = SchemaDSLM.getFields(obj);
          make(id, constr, value2Obj(constr, fields), obj);
        }
    } else {
        var extr = rest[1];
        var obj = rest[2];
        make(id, constr, extr, obj);
    }
  }

  public static function make1(id: ExprOf<String>, constr: Expr, sub: Expr) {
    var f = oneValue2Obj(constr);
    return macro thx.schema.SchemaDSL.alt($id, $sub, $constr, $f);
  }

  public static function make<E>(id: ExprOf<String>, constr: Expr, extr: Expr, obj: ExprOf<Dynamic<Schema<Dynamic, E>>>) {
    var valueType = getValueType(constr);
    var fields = getFields(obj);
    var objectType = getObjectType(fields);
    var args = [constrObj(fields, objectType, Context.currentPos())].concat(fields.map(function(field) {
      // TODO optional vs required?
      var name = field.name,
          expr = field.expr,
          ftype = field.ctype;
      return macro required($v{name}, $expr, function(v: $objectType): $ftype return v.$name);
    }));

    var apf = 'ap${fields.length}';
    var s2v = obj2Value(constr, fields, objectType, valueType);
    return macro thx.schema.SchemaDSL.alt($id, thx.schema.SchemaDSL.object($i{apf}($a{args})), $s2v, $extr);
  }

  static function isSchema(e: Expr) {
    return switch Context.typeof(e) {
      case TEnum(_, [_, type]): true; // TODO make the match stricter
      case TFun(_, TEnum(_, [_, type])): true;
      case _: false;
    };
  }

  static function getFields(e: Expr) {
    var fieldData = switch e.expr {
      case EObjectDecl(fields): fields;
      case _: Context.error('argument `obj` should be an object literal [found $e]', Context.currentPos());
    }
    if(fieldData.length < 1) {
      Context.error('function constr should have at least one argument', Context.currentPos());
    }
    return fieldData.map(function(field) {
      var t = switch Context.typeof(field.expr) {
        case TEnum(_, [_, type]): type; // TODO make the match stricter
        case TFun(_, TEnum(_, [_, type])): type;
        case _: Context.error('invalid schema type for `{$field.field}` [found ${field.expr}]', Context.currentPos());
      }
      return {
        type: t,
        ctype: TypeTools.toComplexType(t),
        name: field.field,
        expr: field.expr,
        pos: field.expr.pos
      };
    });
  }

  static function getValueType(e: Expr) {
    var t = Context.typeof(e);
    if(!MacroTypes.isFunction(t)) {
      Context.error('argument constr should be a function [found $e]', Context.currentPos());
    }
    return MacroTypes.qualifyType(MacroTypes.getFunctionReturn(t));
  }

  static function getObjectType(fields) {
    return TAnonymous(fields.map(function(field): Field {
      return {
        access: [APublic],
        doc: null,
        meta: null,
        pos: field.pos,
        name: field.name,
        kind: FVar(field.ctype, null)
      };
    }));
  }

  static function obj2Value(constr: Expr, fields, objectType: ComplexType, valueType: ComplexType) {
    var args = fields.map(function(field) {
          var name = field.name;
          return macro o.$name;
        });
    return macro function(o: $objectType): $valueType return $constr($a{args}); // TODO
  }

  static function value2Obj(constr: Expr, fields: Array<{ pos: Position, name: String, ctype: ComplexType }>) {
    var objectType = getObjectType(fields),
        valueType = getValueType(constr),
        args = fields.map(function(field): String return field.name).map(function(name): Expr return macro $i{name}),
        obj = {
          expr: EObjectDecl(fields.map(function(field) {
              var name = field.name;
              return {
                field: name,
                expr: macro $i{name}
              }
            })),
          pos: Context.currentPos()
        };
    return macro function(v: $valueType): haxe.ds.Option<$objectType> return switch v {
      case $constr($a{args}): Some($obj);
      case _: None;
    }
  }

  static function oneValue2Obj(constr: Expr) {
    var valueType = getValueType(constr);
    return macro function(v: $valueType) return switch v {
      case $constr(v): Some(v);
      case _: None;
    }
  }

  static function constrObj(fields: Array<{ type: haxe.macro.Type, ctype: ComplexType, name: String, pos: Position }>, returnType: ComplexType, pos: Position) {
    var body = EObjectDecl(fields.map(function(field) {
          var name = field.name;
          return {
            field: name,
            expr: macro $i{name}
          }
        })),
        ret = EReturn({ expr: body, pos: pos }),
        fun = EFunction('constrObj', {
          args: fields.map(function(field) return { name: field.name, type: field.ctype, opt: false, meta: null, value: null }),
          expr: { expr: ret, pos: pos },
          params: [],
          ret: returnType
        });
    return {
      expr: fun,
      pos: pos
    };
  }
}
