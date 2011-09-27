module sdc.gen.value.type;

import std.string;

import sdc.extract;
import sdc.location;
import sdc.gen.sdcmodule;
import sdc.gen.value.ivalue;
import ast = sdc.ast.all;


enum DType
{
    None,
    Void,
    Bool,
    Char,
    Ubyte,
    Byte,
    Wchar,
    Ushort,
    Short,
    Dchar,
    Uint,
    Int,
    Ulong,
    Long,
    Float,
    Double,
    Real,
    NullPointer,
    Pointer,
    Array,
    StaticArray,
    Const,
    Immutable,
    Complex,
    Struct,
    Enum,
    Class,
    Inferred,
    Scope,
    Function,
}


abstract class Type
{
    Module mod;
    DType dtype;
    
    this(Module mod, DType dtype)
    {
        this.mod = mod;
        this.dtype = dtype;
    }
    
    bool equals(Type t)
    {
        return t.dtype == this.dtype;
    }
    
    abstract Type getBase();
    abstract Value getSizeof();
    abstract Value getInstance(Module, Location);
    abstract void addMember(string name, Type);
    abstract string name();

    /// For backend purposes.
    void* get() { return null; }

    /// ditto
    void set(void*) {}
}

abstract class VoidType : Type
{
    static VoidType create(Module mod)
    {
        return null;    
    }
    
    this(Module mod)
    {
        super(mod, DType.Void);
    }
    
    override string name() { return "void"; }
}

abstract class BoolType : Type
{
    static BoolType create(Module mod)
    {
        return null;    
    }
    
    this(Module mod)
    {
        super(mod, DType.Bool);
    }
    
    override string name() { return "bool"; }
}

abstract class CharType : Type
{
    static CharType create(Module mod)
    {
        return null;
    }
    
    this(Module mod)
    {
        super(mod, DType.Char);
    }
    
    override string name() { return "char"; }
}

abstract class UbyteType : Type
{
    static UbyteType create(Module mod)
    {
        return null;
    }
    
    this(Module mod)
    {
        super(mod, DType.Ubyte);
    }
    
    override string name() { return "ubyte"; }
}

abstract class ByteType : Type
{
    static ByteType create(Module mod)
    {
        return null;
    }
    
    this(Module mod)
    {
        super(mod, DType.Byte);
    }
    
    override string name() { return "byte"; }
}

abstract class WcharType : Type
{
    static WcharType create(Module mod)
    {
        return null;
    }
    
    this(Module mod)
    {
        super(mod, DType.Wchar);
    }
    
    override string name() { return "wchar"; }
}

abstract class UshortType : Type
{
    static UshortType create(Module mod)
    {
        return null;
    }
    
    this(Module mod)
    {
        super(mod, DType.Ushort);
    }
    
    override string name() { return "ushort"; }
}

abstract class ShortType : Type
{
    static ShortType create(Module mod)
    {
        return null;
    }
    
    this(Module mod)
    {
        super(mod, DType.Short);
    }
    
    override string name() { return "short"; }
}

abstract class DcharType : Type
{
    static DcharType create(Module mod)
    {
        return null;
    }
    
    this(Module mod)
    {
        super(mod, DType.Dchar);
    }
    
    override string name() { return "dchar"; }
}

abstract class UintType : Type
{
    static UintType create(Module mod)
    {
        return null;
    }
    
    this(Module mod)
    {
        super(mod, DType.Uint);
    }
    
    override string name() { return "uint"; }
}

abstract class IntType : Type
{
    static IntType create(Module mod)
    {
        return null;
    }
    
    this(Module mod)
    {
        super(mod, DType.Int);
    }
    
    override string name() { return "int"; }
}

abstract class UlongType : Type
{
    static UlongType create(Module mod)
    {
        return null;
    }
    
    this(Module mod)
    {
        super(mod, DType.Ulong);
    }
    
    override string name() { return "ulong"; }
}

abstract class LongType : Type
{
    static LongType create(Module mod)
    {
        return null;
    }
    
    this(Module mod)
    {
        super(mod, DType.Long);
    }
    
    override string name() { return "long"; }
}

abstract class FloatType : Type
{
    static FloatType create(Module mod)
    {
        return null;
    }
    
    this(Module mod)
    {
        super(mod, DType.Float);
    }
    
    override string name() { return "float"; }
}

abstract class DoubleType : Type
{
    static DoubleType create(Module mod)
    {
        return null;
    }
    
    this(Module mod)
    {
        super(mod, DType.Double);
    }
    
    override string name() { return "double"; }
}

abstract class RealType : Type
{
    static RealType create(Module mod)
    {
        return null;
    }
    
    this(Module mod)
    {
        super(mod, DType.Real);
    }
    
    override string name() { return "real"; }
}

abstract class PointerType : Type
{
    Type base;
    
    static PointerType create(Module mod, Type base)
    {
        return null;
    }
    
    this(Module mod, Type base)
    {
        super(mod, DType.Pointer);
        this.base = base;
    }
    
    override Type getBase()
    {
        return base;
    }
    
    override string name() { return base.name() ~ "*"; }
}

abstract class NullPointerType : PointerType
{
    static NullPointerType create(Module mod)
    {
        return null;
    }
    
    this(Module mod)
    {
        super(mod, VoidType.create(mod));
        this.dtype = DType.NullPointer;        
    }
    
    override string name() { return "null"; }
}

abstract class ArrayType : Type
{
    Type base;
    
    static ArrayType create(Module mod, Type base)
    {
        return null;
    }
    
    this(Module mod, Type base)
    {
        super(mod, DType.Array);
        this.base = base;
    }
    
    override Type getBase()
    {
        return base;
    }
    
    override string name() { return base.name() ~ "[]"; } 
}

abstract class StaticArrayType : Type
{
    Type base;
    size_t length;
    
    static StaticArrayType create(Module mod, Type base, size_t length)
    {
        return null;
    }
    
    this(Module mod, Type base, size_t length)
    {
        super(mod, DType.StaticArray);
        this.base = base;
        this.length = length;
    }
    
    override Type getBase()
    {
        return base;
    }
    
    override string name() { return format("%s[%s]", base.name(), length); }   
}

abstract class ConstType : Type
{
    Type base;
    
    static ConstType create(Module mod, Type base)
    {
        return null;
    }
    
    this(Module mod, Type base)
    {
        super(mod, DType.Const);
        this.base = base;
    }
    
    override Type getBase()
    {
        return base;
    }
    
    override string name() { return format("const(%s)", base.name()); }
}

abstract class ImmutableType : Type
{
    Type base;
    
    static ImmutableType create(Module mod, Type base)
    {
        return null;
    }
    
    this(Module mod, Type base)
    {
        super(mod, DType.Immutable);
        this.base = base;
    }
    
    override Type getBase()
    {
        return base;
    }
    
    override string name() { return format("immutable(%s)", base.name()); }
}

abstract class StructType : Type
{
    ast.QualifiedName fullName;
    
    static StructType create(Module mod)
    {
        return null;
    }
    
    this(Module mod)
    {
        super(mod, DType.Struct);
    }
    
    override string name() { return "struct " ~ extractQualifiedName(fullName); } 
}

abstract class ClassType : Type
{
    ast.QualifiedName fullName;
    ClassType parent;
    
    static ClassType create(Module mod, ClassType parent)
    {
        return null;
    }
    
    this(Module mod, ClassType parent)
    {
        super(mod, DType.Class);
        this.parent = parent;
    }
    
    override string name() { return "class " ~ extractQualifiedName(fullName); } 
}

abstract class EnumType : Type
{
    ast.QualifiedName fullName;
    Type base;
    
    static EnumType create(Module mod, EnumType base)
    {
        return null;
    }
    
    this(Module mod, Type base)
    {
        super(mod, DType.Enum);
        this.base = base;
    }
    
    override Type getBase() { return base; }
    
    override string name() { return "enum " ~ extractQualifiedName(fullName); }
}
