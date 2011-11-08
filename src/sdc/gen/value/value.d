module sdc.gen.value.value;

import std.string;

import sdc.aglobal;
import sdc.compilererror;
import sdc.location;
import sdc.gen.sdcmodule;
import sdc.gen.value.type;
import sdc.gen.value.variable;
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
    abstract Value addressOf(Location loc); /// &v
    abstract Value call(Location loc, Location[] argLocations, Value[] args); /// v()
    abstract Value getMember(Location loc, string name);  /// v.name
    
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

    Value set(Location location, Value value)
    {
        throw new CompilerPanic(location, "Value.set is to only be used on VariableValues.");
    }
    
    abstract void buildCast(Location loc, Value from);
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
    abstract void buildModulus(Location loc, Value lhs, Value rhs);
    abstract void buildNot(Location loc, Value val);
    abstract void buildDereference(Location loc, Value val);
    abstract void buildAddressOf(Location loc, Value val);
    abstract void buildIndex(Location loc, Value indexee, Value index);
    
    /// For backend purposes. HACK
    void* get()
    {
        return null;
    }

    /// ditto
    void set(void*)
    {
    }
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
    override Value getMember(Location, string) { fail(loc, "getMember"); assert(false); }
    override void buildCast(Location loc, Value from) { fail(loc, "buildCast"); assert(false); }
    override void buildInc(Location loc, Value val) { fail(loc, "buildInc"); assert(false); }
    override void buildDec(Location loc, Value val) { fail(loc, "buildDec"); assert(false); }
    override void buildAdd(Location loc, Value lhs, Value rhs) { fail(loc, "buildAdd"); assert(false); }
    override void buildSub(Location loc, Value lhs, Value rhs) { fail(loc, "buildSub"); assert(false); }
    override void buildMul(Location loc, Value lhs, Value rhs) { fail(loc, "buildMul"); assert(false); }
    override void buildDiv(Location loc, Value lhs, Value rhs) { fail(loc, "buildDiv"); assert(false); }
    override void buildOr(Location loc, Value lhs, Value rhs) { fail(loc, "buildOr"); assert(false); }
    override void buildXor(Location loc, Value lhs, Value rhs) { fail(loc, "buildXor"); assert(false); }
    override void buildAnd(Location loc, Value lhs, Value rhs) { fail(loc, "buildAnd"); assert(false); }
    override void buildEq(Location loc, Value lhs, Value rhs) { fail(loc, "buildEq"); assert(false); }
    override void buildNeq(Location loc, Value lhs, Value rhs) { fail(loc, "buildNeq"); assert(false); }
    override void buildGt(Location loc, Value lhs, Value rhs) { fail(loc, "buildGt"); assert(false); }
    override void buildGte(Location loc, Value lhs, Value rhs) { fail(loc, "buildGte"); assert(false); }
    override void buildLt(Location loc, Value lhs, Value rhs) { fail(loc, "buildLt"); assert(false); }
    override void buildLte(Location loc, Value lhs, Value rhs) { fail(loc, "buildLte"); assert(false); }
    override void buildModulus(Location loc, Value lhs, Value rhs) { fail(loc, "buildModulus"); assert(false); }
    override void buildNot(Location loc, Value val) { fail(loc, "buildNot"); assert(false); }
    override void buildDereference(Location loc, Value val) { fail(loc, "buildDereference"); assert(false); }
    override void buildAddressOf(Location loc, Value val) { fail(loc, "buildAddressOf"); assert(false); }
    override void buildIndex(Location loc, Value a, Value b) { fail(loc, "buildIndex"); assert(false); }
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
        "    } else {"
        "        result." ~ BUILDNAME ~ "(loc, this, val);"
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
        "    } else {"
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
    mixin BinaryOperation!("%", "modulus", "buildModulus");
    mixin IncrementOperation!"+";
    mixin IncrementOperation!"-";
    
    override Value not(Location loc)
    {
        auto result = typeof(this).create(mod, loc);
        result.isKnown = this.isKnown;
        if (this.isKnown) {
            mixin("result." ~ KNOWN ~ " = ~this." ~ KNOWN ~ ";");
        } else {
            result.buildNot(loc, this);
        }
        return result;
    }
    
    override Value addressOf(Location loc)
    {
        auto result = PointerType.create(mod, type).getInstance(mod, loc);
        result.isKnown = this.isKnown;
        if (this.isKnown) {
            result.knownPointer = this;
        } else {
            result.buildAddressOf(loc, this);
        }
        return result;
    }
    
    override Value performCast(Location loc, Type to)
    {
        auto result = to.getInstance(mod, loc);
        result.isKnown = this.isKnown;
        if (result.isKnown) {
            mixin("result." ~ KNOWN ~ " = this." ~ KNOWN ~ ";");
        } else {
            result.buildCast(loc, this);
        }
        return result;
    }
}

alias PrimitiveIntValue!(bool, BoolType, "knownBool") BoolValue;
alias PrimitiveIntValue!(byte, ByteType, "knownByte") ByteValue;
alias PrimitiveIntValue!(ubyte, UbyteType, "knownUbyte") UbyteValue;
alias PrimitiveIntValue!(short, ShortType, "knownShort") ShortValue;
alias PrimitiveIntValue!(ushort, UshortType, "knownUshort") UshortValue;
alias PrimitiveIntValue!(int, IntType, "knownInt") IntValue;
alias PrimitiveIntValue!(uint, UintType, "knownUint") UintValue;
alias PrimitiveIntValue!(long, LongType, "knownLong") LongValue;
alias PrimitiveIntValue!(ulong, UlongType, "knownUlong") UlongValue;
alias PrimitiveIntValue!(char, CharType, "knownChar") CharValue;
alias PrimitiveIntValue!(wchar, WcharType, "knownWchar") WcharValue;
alias PrimitiveIntValue!(dchar, DcharType, "knownDchar") DcharValue;

class ScopeValue : StubValue
{
    Scope _scope;

    this(Module mod, Location location, Scope _scope)
    {
        super(mod, location);
        this._scope = _scope;
    }

    override Value getMember(Location loc, string member)
    {
        auto store = _scope.get(name);
        if (store is null) {
            return null;
        }
        if (store.storeType == StoreType.Scope) {
            return new ScopeValue(mod, location, store.getScope());
        } else if (store.storeType == StoreType.Value) {
            return _scope.get(name).value;
        } else if (store.storeType == StoreType.Function) {
            return new Functions(mod, location, store.getFunctions());
        } else {
            assert(false, to!string(store.storeType));
        }
    }
}

/**
 * Variable wrapper.
 * See: sdc.gen.value.variable.Variable
 */
class VariableValue : StubValue
{
    Variable variable;
    mixin template PassThrough(string SIGNATURE, string CALL)
    {
        mixin("override Value " ~ SIGNATURE ~ "{"
              "    return variable.get(l)." ~ CALL ~ ";"
              "}");
    }

    mixin PassThrough!("performCast(Location l, Type t)", "performCast(l, t)");
    mixin PassThrough!("add(Location l, Value v)", "add(l, v)");
    mixin PassThrough!("inc(Location l)", "inc(l)");
    mixin PassThrough!("dec(Location l)", "dec(l)");
    mixin PassThrough!("sub(Location l, Value v)", "sub(l, v)");
    mixin PassThrough!("mul(Location l, Value v)", "mul(l, v)");
    mixin PassThrough!("div(Location l, Value v)", "div(l, v)");
    mixin PassThrough!("eq(Location l, Value v)", "eq(l, v)");
    mixin PassThrough!("identity(Location l, Value v)", "identity(l, v)");
    mixin PassThrough!("nidentity(Location l, Value v)", "nidentity(l, v)");
}
