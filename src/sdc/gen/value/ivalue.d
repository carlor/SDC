module sdc.gen.value.value;

import std.string;

import sdc.compilererror;
import sdc.location;
import sdc.gen.sdcmodule;
import sdc.gen.value.itype;
import ast = sdc.ast.all;

/**
 * Value represents an instance of a given type.
 */
abstract class Value
{
    /// The Module this Value is associated with.
    Module mod;
    /// The location that this Value was created at.
    Location location;
    /// The type this Value is an instance of.
    Type type;
    
    /// All Values should be able to be created with just a Module and a Location.
    this(Module mod, Location location)
    {
        this.mod = mod;
        this.location = location;
    }
    
    bool isKnown = false;
    /// If isKnown, these are the types the compiler knows about, and contain the actual value.
    union
    {
        bool knownBool;
        byte knownByte;
        ubyte knownUbyte;
        short knownShort;
        ushort knownUshort;
        int knownInt;
        uint knownUint;
        long knownLong;
        ulong knownUlong;
        float knownFloat;  // Oh yes, we all float - and when you're down here with us, you'll float too!
        double knownDouble;
        real knownReal;
        char knownChar;
        wchar knownWchar;
        dchar knownDchar;
        string knownString;
        Value[] knownArray;
        Value knownPointer;
    }
    
    /**
     * Generate code to cast this Value to the given type.
     * This method isn't concerned with narrowing or the like.
     */
    abstract Value performCast(Location, Type);
    
    abstract Value add(Location loc, Value val); /// +
    abstract Value inc(Location loc);  /// v + 1
    abstract Value dec(Location loc); /// v - 1
    abstract Value sub(Location loc, Value val); /// -
    abstract Value mul(Location loc, Value val); /// *
    abstract Value div(Location loc, Value val); /// /
    abstract Value eq(Location loc, Value val); /// ==
    abstract Value identity(Location loc, Value val); /// is
    abstract Value nidentity(Location loc, Value val); /// !is
    abstract Value neq(Location loc, Value val); /// !=
    abstract Value gt(Location loc, Value val); /// >
    abstract Value gte(Location loc, Value val); /// >=
    abstract Value lt(Location loc, Value val); /// <
    abstract Value lte(Location loc, Value val); /// <=
    abstract Value or(Location loc, Value val); /// |
    abstract Value and(Location loc, Value val); /// &
    abstract Value xor(Location loc, Value val); /// ^
    abstract Value not(Location loc); /// ~
    abstract Value dereference(Location loc); /// *v
    abstract Value index(Location loc, Value val); /// [n]
    abstract Value slice(Location loc, Value from, Value to); /// [n .. m]  
    abstract Value modulus(Location loc, Value val); /// %
    abstract Value getSizeof(Location loc); /// .sizeof
    abstract Value addressOf(Location loc); /// &v
    abstract Value call(Location loc, Location[] argLocations, Value[] args); /// v()
    
    Value logicalOr(Location location, Value val)
    {
        auto boolType = BoolType.create(mod);
        auto a = this.performCast(location, boolType);
        auto b =  val.performCast(location, boolType);
        return a.or(location, b);
    }
    
    Value logicalAnd(Location location, Value val)
    {
        auto boolType = BoolType.create(mod);
        auto a = this.performCast(location, boolType);
        auto b =  val.performCast(location, boolType);
        return a.and(location, b);
    }
    
    Value logicalNot(Location location)
    {
        auto boolType = BoolType.create(mod);
        auto a = this.performCast(location, boolType);
        return a.not(location);
    }
    
    abstract void buildInc(Location loc, Value val);
    abstract void buildDec(Location loc, Value val);
    abstract void buildAdd(Location loc, Value lhs, Value rhs);
    abstract void buildSub(Location loc, Value lhs, Value rhs);
    abstract void buildDiv(Location loc, Value lhs, Value rhs);
    abstract void buildMul(Location loc, Value lhs, Value rhs);
    abstract void buildOr (Location loc, Value lhs, Value rhs);
    abstract void buildXor(Location loc, Value lhs, Value rhs);
    abstract void buildAnd(Location loc, Value lhs, Value rhs);
    abstract void buildEq (Location loc, Value lhs, Value rhs);
    abstract void buildNeq(Location loc, Value lhs, Value rhs);
    abstract void buildGt (Location loc, Value lhs, Value rhs);
    abstract void buildGte(Location loc, Value lhs, Value rhs);
    abstract void buildLt (Location loc, Value lhs, Value rhs);
    abstract void buildLte(Location loc, Value lhs, Value rhs);
    abstract void buildOr (Location loc, Value lhs, Value rhs);
    abstract void buildAnd(Location loc, Value lhs, Value rhs);
    abstract void buildXor(Location loc, Value lhs, Value rhs);
    abstract void buildModulus(Location loc, Value lhs, Value rhs);
    abstract void buildNot(Location loc, Value val);
    abstract void buildDereference(Location loc, Value val);
    abstract void buildAddressOf(Location loc, Value val);
}

/**
 * A fully implemented Value that errors on all abstract calls.
 */
class StubValue : Value
{
    this(Module mod, Location location) { super(mod, location); }
    
    void fail(Location location, string s)
    { 
        throw new CompilerError(location, 
            format(`invalid operation: cannot %s value of type "%s".`, s, type.name())
        );
    }
    
    void fail(string s)
    {
        throw new CompilerPanic(format(`attempt to %s value of type "%s" failed.`, s, type.name()));
    }
    
    override Value performCast(Location loc, Type type) { fail(loc, "cast"); assert(false); }
    override Value add(Location loc, Value val) { fail(loc, "add"); assert(false); }
    override Value inc(Location loc) { fail(loc, "increment"); assert(false); }
    override Value dec(Location loc) { fail(loc, "decrement"); assert(false); }
    override Value sub(Location loc, Value val) { fail(loc, "subtract"); assert(false); }
    override Value mul(Location loc, Value val) { fail(loc, "multiply"); assert(false); }
    override Value div(Location loc, Value val) { fail(loc, "divide"); assert(false); }
    override Value eq(Location loc, Value val) { fail(loc, "compare equality of"); assert(false); }
    override Value identity(Location loc, Value val) { return eq(loc, val); }
    override Value nidentity(Location loc, Value val) { return neq(loc, val); }
    override Value neq(Location loc, Value val) { fail(loc, "compare non-equality of"); assert(false); }
    override Value gt(Location loc, Value val) { fail(loc, "compare greater-than of"); assert(false); }
    override Value lt(Location loc, Value val) { fail(loc, "compare less-than of"); assert(false); }
    override Value lte(Location loc, Value val) { fail(loc, "compare less-than of"); assert(false); }
    override Value or(Location loc, Value val) { fail(loc, "or"); assert(false); }
    override Value and(Location loc, Value val) { fail(loc, "and"); assert(false); }
    override Value xor(Location loc, Value val) { fail(loc, "xor"); assert(false); }
    override Value not(Location loc) { fail(loc, "not"); assert(false); }
    override Value addressOf(Location loc) { fail(loc, "address-of"); assert(false); }
    override Value dereference(Location loc) { fail(loc, "dereference"); assert(false); }
    override Value index(Location loc, Value val) { fail(loc, "index"); assert(false); }
    override Value slice(Location loc, Value from, Value to) { fail(loc, "slice"); assert(false); }
    override Value modulus(Location loc, Value val) { fail(loc, "modulo"); assert(false); }
    override Value call(Location loc, Location[] argLocations, Value[] args) { fail(loc, "call"); assert(false); }
}

class VoidValue : StubValue
{
    static VoidValue create(Module mod, Location loc)
    {
        return null;
    }
    
    this(Module mod, Location loc)
    {
        super(mod, loc);
        type = VoidType.create(mod);
    }
    
    override void fail(Location loc, string s)
    {
        throw new CompilerError(loc, "can't perform an action on variable of type 'void'.");
    }
}

class PrimitiveIntValue(DPRIMITIVE, SDCTYPE : Type, string KNOWN) : StubValue
{
    static typeof(this) create(Module mod, Location loc)
    {
        return null;
    }
    
    static typeof(this) create(Module mod, Location loc, DPRIMITIVE n)
    {
        return null;
    } 
    
    this(Module mod, Location loc)
    {
        super(mod, loc);
        type = SDCTYPE.create(mod);
    }
    
    this(Module mod, Location loc, DPRIMITIVE n)
    {
        this(mod, loc);
        isKnown = true;
        mixin(KNOWN ~ " = n");
    }
    
    mixin template BinaryOperation(string OP, string NAME, string BUILDNAME)
    {
        mixin(
        "override Value " ~ NAME ~ "(Location loc, Value val)"
        "{"
        "    auto result = typeof(this).create(mod, loc);"
        "    if (this.isKnown && val.isKnown) {"
        "        result.isKnown = true;"
        "        if (val.type.dtype != this.type.dtype) {"
        `            throw new CompilerPanic(loc, "tried to " ~ NAME ~ " two different types.");`
        "        }"
        "        result." ~ KNOWN ~ " = this." ~ KNOWN ~ OP ~ "val." ~ KNOWN ~ ";"
        "    }"
        "    if (mod.generateCode) {"
        "        result." ~ BUILDNAME ~ "(loc, this, val);"
        "    }"
        "    return result;"
        "}"
        );        
    }
    
    mixin template UnaryOperation(string OP, string NAME, string BUILDNAME)
    {
        mixin(
        "override Value " ~ NAME ~ "(Location loc)"
        "{"
        "    auto result = typeof(this).create(mod, loc);"
        "    if (this.isKnown && val.isKnown) {"
        "        result.isKnown = true;"
        "        result." ~ KNOWN ~ " = " ~ OP ~ KNOWN ~ ";"
        "    }"
        "    if (mod.generateCode) {"
        "        result." ~ BUILDNAME ~ "(loc, this);"
        "    }"
        "    return result;"
        "}"
        );        
    }
    
    mixin template IncrementOperation(string OP)
    {
        static if (OP == "+") {
            enum NAME = "inc";
            enum BUILDNAME = "buildInc"; 
        } else static if (OP == "-") {
            enum NAME = "dec";
            enum BUILDNAME = "buildDec";
        }
        mixin(
        "override Value " ~ NAME ~ "(Location loc)"
        "{"
        "    auto result = typeof(this).create(mod, loc);"
        "    if (this.isKnown) {"
        "        result.isKnown = true;"
        "        result." ~ KNOWN ~ " = this." ~ KNOWN ~ OP ~ "1;"
        "    }"
        "    if (mod.generateCode) {"
        "        result." ~ BUILDNAME ~ "(loc, this);"
        "    }"
        "    return result;"
        "}"
        );
    }
    
    mixin BinaryOperation!("+", "add", "buildAdd");
    mixin BinaryOperation!("-", "sub", "buildSub");
    mixin BinaryOperation!("*", "mul", "buildMul");
    mixin BinaryOperation!("/", "div", "buildDiv");
    mixin BinaryOperation!("|", "or",  "buildOr");
    mixin BinaryOperation!("^", "xor", "buildXor");
    mixin BinaryOperation!("&", "and", "buildAnd");
    mixin BinaryOperation!("==", "eq", "buildEq");
    mixin BinaryOperation!("!=", "neq", "buildNeq");
    mixin BinaryOperation!(">",  "gt", "buildGt");
    mixin BinaryOperation!(">=", "gte", "buildGte");
    mixin BinaryOperation!("<",  "lt", "buildLt");
    mixin BinaryOperation!("<=", "lte", "buildLte");
    mixin BinaryOperation!("|",  "or", "buildOr");
    mixin BinaryOperation!("&", "and", "buildAnd");
    mixin BinaryOperation!("^", "xor", "buildXor");
    mixin BinaryOperation!("%", "modulus", "buildModulu");
    mixin UnaryOperation! ("~", "not", "buildNot");
    mixin IncrementOperation!"+";
    mixin IncrementOperation!"-";
    
    override Value dereference(Location loc)
    {
        auto result = type.getBase().getInstance(mod, loc);
        if (this.isKnown) {
            result.isKnown = true;
            mixin("result." ~ KNOWN ~ " = this.knownPointer." ~ KNOWN ~ ";");
        }
        if (mod.generateCode) {
            result.buildDereference(loc, this);
        }
        return result;
    }
    
    override Value addressOf(Location loc)
    {
        auto result = PointerType.create(mod, type).getInstance(mod, loc);
        if (this.isKnown) {
            result.isKnown = true;
            result.knownPointer = this;
        }
        if (mod.generateCode) {
            result.buildAddressOf(loc, this);
        }
        return result;
    }
}

alias PrimitiveIntValue!(int, IntType, "knownInt") IntValue;
