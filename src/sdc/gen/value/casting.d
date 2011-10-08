/**
 * Copyright 2011 Bernard Helyer.
 * This file is part of SDC. SDC is licensed under the GPL.
 * See LICENCE or sdc.d for more details.
 */
module sdc.gen.value.casting;

import sdc.compilererror;
import sdc.location;
import sdc.gen.sdcmodule;
import sdc.gen.value.type;
import sdc.gen.value.value;
import ast = sdc.ast.all;

enum OnFailure
{
    DieWithError,
    ReturnNull,
}

Type astTypeToBackendType(ast.Type type, Module mod, OnFailure onFailure)
{   
    Type t;
    switch (type.type) {
    case ast.TypeType.Primitive:
        t = primitiveTypeToBackendType(cast(ast.PrimitiveType) type.node, mod);
        break;
    case ast.TypeType.UserDefined:
        t = userDefinedTypeToBackendType(cast(ast.UserDefinedType) type.node, mod, onFailure);
        break;
    case ast.TypeType.Inferred:
        //t = new InferredType(mod);
        assert(false);
    case ast.TypeType.ConstType:
        //        t = new ConstType(mod, astTypeToBackendType(cast(ast.Type) type.node, mod, onFailure));
        assert(false);
    case ast.TypeType.ImmutableType:
        //        t = new ImmutableType(mod, astTypeToBackendType(cast(ast.Type) type.node, mod, onFailure));
        assert(false);
    case ast.TypeType.Typeof:
        //        t = genTypeof(cast(ast.TypeofType) type.node, mod);
        assert(false);
    case ast.TypeType.FunctionPointer:
        //        t = genFunctionPointerType(cast(ast.FunctionPointerType) type.node, mod, onFailure);
        assert(false);
    default:
        throw new CompilerPanic(type.location, "unhandled type type.");
    }
    
    if (t is null) {
        return null;
    }        
    
    foreach (suffix; retro(type.suffixes)) {
        if (suffix.type == ast.TypeSuffixType.Pointer) {
            t = PointerType.create(mod, t);
        } else if (suffix.type == ast.TypeSuffixType.Array) {
            t = ArrayType.create(mod, t);
        } else {
            throw new CompilerPanic(type.location, "unimplemented type suffix.");
        }
    }
    
    foreach (storageType; type.storageTypes) switch (storageType) with (ast.StorageType) {
    case Const:
        // t = new ConstType(mod, t);
        //break;
        assert(false);
    case Auto:
        break;
    case Static:
        break;
    default:
        throw new CompilerPanic(type.location, "unimplemented storage type.");
    }
    
    return t;
}

void binaryOperatorImplicitCast(Location location, Value* lhs, Value* rhs)
{    
    if (lhs.type.dtype == rhs.type.dtype) {
        return;
    }
    
    if (lhs.type.dtype == DType.Pointer || // pointer arithmetic
        lhs.type.dtype == DType.NullPointer || rhs.type.dtype == DType.NullPointer) {
        return;
    }
 
    if (lhs.type.dtype > rhs.type.dtype) {
        *rhs = implicitCast(location, *rhs, lhs.type);
    } else {
        *lhs = implicitCast(location, *lhs, rhs.type);
    }
}

Value implicitCast(Location location, Value v, Type toType)
{
    Value[] aliasThisMatches;
    foreach (aliasThis; v.type.aliasThises) {
        // The type has an alias this declaration, so try it.
        auto aliasValue = v.getMember(location, aliasThis);
        if (aliasValue is null) {
            throw new CompilerPanic(location, "invalid alias this.");
        }
        if (aliasValue.type.dtype == DType.Function) {
            // If the alias points to a function, call it.
            auto asFunction = enforce(cast(FunctionType) aliasValue.type);
            if (asFunction.parentAggregate !is v.type) {
                throw new CompilerError(location, "alias this refers to non member function '" ~ aliasThis ~ "'.");
            }
            if (asFunction.parameterTypes.length != 0) {
                auto address = v.addressOf(location);
                if (asFunction.parameterTypes.length > 1 || asFunction.parameterTypes[0] != address.type) {
                    throw new CompilerError(location, "alias this refers to function with non this parameter.");
                } 
                aliasValue = aliasValue.call(location, [v.location], [v.addressOf(location)]);
            } else {
                aliasValue = aliasValue.call(location, null, null);
            }
        }
        try { 
            auto aliasV = implicitCast(location, aliasValue, toType);
            aliasThisMatches ~= aliasV;
        } catch (CompilerError) {
            // Try other alias thises, or just the base type.
        }
    }
    
    if (aliasThisMatches.length > 1) {
        throw new CompilerError(location, "multiple valid alias this declarations.");
    } else if (aliasThisMatches.length == 1) {
        return aliasThisMatches[0];
    }
    
    switch(toType.dtype) {
    case DType.Pointer:
        if (v.type.dtype == DType.NullPointer) {
            return v;
        } else if (v.type.dtype == DType.Pointer) {
            if (toType.getBase().dtype == DType.Void) {
                // All pointers are implicitly castable to void*.
                return v.performCast(location, toType); 
            }
            
            if (toType.getBase().dtype == DType.Const) {
                return implicitCast(location, v, toType.getBase());
            }
            
            /+if (toType.getBase().dtype == v.type.getBase().dtype) {
                return v;
            }+/
        } else if (v.type.dtype == DType.Array) {
            if (v.type.getBase().dtype == toType.getBase().dtype) {
                return v.getMember(location, "ptr");
            }
        }
        break;
    case DType.Array:
        if (v.type.dtype == DType.Array) {
            if (v.type.getBase().dtype == toType.getBase().dtype) {
                return v;
            }
        }
        break;
    case DType.Class:
        if (v.type.dtype == DType.NullPointer) {
            auto asClass = enforce(cast(ClassType) toType);
            return v.performCast(location, new PointerType(v.mModule, asClass.structType)); 
        }
        return v;  // TMP
    case DType.Const:
        return new ConstValue(v.getModule(), location, v);
    case DType.Immutable:
        return new ImmutableValue(v.getModule(), location, v);
    default:
        if (canImplicitCast(location, v.type, toType)) {
            return v.performCast(location, toType);
        }
        break;
    }
    
    // TODO: do this earlier when equals() is better supported.
    if (toType.equals(v.type)) {
        return v;
    } else {
        throw new CompilerError(location, format("cannot implicitly cast '%s' to '%s'.", v.type.name(), toType.name()));
    }
}

bool canImplicitCast(Location location, Type from, Type to)
{
    switch (from.dtype) with (DType) {
    case Bool:
        return true;
    case Char:
    case Ubyte:
    case Byte:
        return to.dtype >= Char;
    case Wchar:
    case Ushort:
    case Short:
        return to.dtype >= Wchar;
    case Dchar:
    case Uint:
    case Int:
        return to.dtype >= Dchar;
    case Ulong:
    case Long:
        return to.dtype >= Ulong;
    case Float:
    case Double:
    case Real:
        return to.dtype >= Float;
    case Pointer:
    case NullPointer:
        return to.dtype == Pointer || to.dtype == NullPointer;
    case Const:
        if (to.isRef) {
            throw new CompilerError(location, "cannot pass a const value as a ref parameter.");
        }
        return canImplicitCast(location, from.getBase(), to) && !hasMutableIndirection(to);
    case Immutable:
        if (to.isRef) {
            throw new CompilerError(location, "cannot pass a immutable value as a ref parameter.");
        }
        return canImplicitCast(location, from.getBase(), to) && !hasMutableIndirection(to);
    default:
        return false;
    }
}

// incomplete
bool hasMutableIndirection(Type t)
{
    if (t.dtype == DType.Class || t.dtype == DType.Array || t.dtype == DType.Pointer) {
        return true;
    }
    return false;
}