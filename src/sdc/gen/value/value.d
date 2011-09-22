/**
 * Copyright 2010-2011 Bernard Helyer.
 * Copyright 2010-2011 Jakob Ovrum.
 * This file is part of SDC. SDC is licensed under the GPL.
 * See LICENCE or sdc.d for more details.
 */
module sdc.gen.value.ivalue;

import std.string;

import llvm.c.Core;

import sdc.compilererror;
import sdc.location;
import sdc.gen.sdcmodule;
import sdc.gen.value.value;
import sdc.gen.value.type;
import ast = sdc.ast.all;


/**
 * Value represents an instance of a given type.
 * Every expression, even if temporary, will generate a Value.
 */
abstract class Value
{
    /// The location that this Value was created at.
    Location location;
    /// The access level that this Value inherited.
    ast.Access access;
    /// If Value.lvalue is false, it can't be modified using set. 
    bool lvalue = false;
    
    ast.QualifiedName humanName;  // Optional.
    string mangledName;  // Optional.
    
    /// The Module this Value is associated with.
    package Module mModule;
    /// The type this Value is an instance of.
    package Type mType;
    /**
     * The underlying LLVM value for this Value.
     * All types are stored as pointers to their types,
     * so int's are stored as int*. To get the actual
     * value use the get method.
     */
    package LLVMValueRef mValue;
    /// If true, this value was created at a global scope.
    protected bool mGlobal;
    /// Callbacks that are called before a set takes place.
    protected void delegate(Value val)[] mSetPreCallbacks;
    /// Callbacks that are called after a set takes place.
    protected void delegate(Value va)[] mSetPostCallbacks;
    protected bool mIsKnown = false;
    
    /// All Values should be able to be created with just a Module and a Location.
    this(Module mod, Location loc)
    {
        mModule = mod;
        location = loc;
        access = mod.currentAccess;
        mGlobal = mod.currentScope is mod.globalScope;
    }
    
    /// If true, the value of this Value is known to the compiler.
    @property bool isKnown() { return mIsKnown; }
    @property void isKnown(bool b) { mIsKnown = b; }
    
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
    }
    
    Type type() @property
    {
        return mType;
    }
    
    void type(Type t) @property
    {
        mType = t;
    }
    
    /**
     * Generate code to cast this Value to the given type.
     * This method isn't concerned with narrowing or the like.
     */
    Value performCast(Location location, Type t)
    {
        throw new CompilerPanic(location, "invalid cast");
    }
    
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

    /// Retrieve the actual LLVM value that matches the Type. 
    LLVMValueRef get() { fail("get"); assert(false); }
    
    /// Retrieve a reference to this value as an LLVM constant.
    LLVMValueRef getConstant() { fail("get constant"); assert(false); }
    
    /// Set Value's value. Is affected by lvalue.
    void set(Location location, Value val) { fail("set (by Value)"); assert(false); }
    void set(Location location, LLVMValueRef val) { fail("set (by LLVMValueRef)"); assert(false); }
    /// The same as set, but not affected by lvalue.
    void initialise(Location location, Value val) 
    {
        const bool islvalue = lvalue;
        lvalue = true; 
        set(location, val);
        lvalue = islvalue; 
    }
    void initialise(Location location, LLVMValueRef val) 
    { 
        const bool islvalue = lvalue;
        lvalue = true;
        set(location, val);
        lvalue = islvalue; 
    }
    
    /** 
     * Most of the operators don't modify this instance,
     * instead creating a new one. Even inc and dec.
     * Obvious exceptions are set and initialise.
     */
    
    Value add(Location loc, Value val) { fail(loc, "add"); assert(false); }  /// +
    Value inc(Location loc) { fail(loc, "increment"); assert(false); }  /// v + 1
    Value dec(Location loc) { fail(loc, "decrement"); assert(false); }  /// v - 1
    Value sub(Location loc, Value val) { fail(loc, "subtract"); assert(false); }  /// -
    Value mul(Location loc, Value val) { fail(loc, "multiply"); assert(false); }  /// *
    Value div(Location loc, Value val) { fail(loc, "divide"); assert(false); }  /// /
    Value eq(Location loc, Value val) { fail(loc, "compare equality of"); assert(false); }   /// ==
    Value identity(Location loc, Value val) { return eq(loc, val); }  /// is
    Value nidentity(Location loc, Value val) { return neq(loc, val); }  /// !is
    Value neq(Location loc, Value val) { fail(loc, "compare non-equality of"); assert(false); }  /// !=
    Value gt(Location loc, Value val) { fail(loc, "compare greater-than of"); assert(false); }  /// >
    Value lt(Location loc, Value val) { fail(loc, "compare less-than of"); assert(false); }  /// <
    Value lte(Location loc, Value val) { fail(loc, "compare less-than of"); assert(false); }  /// <=
    Value or(Location loc, Value val) { fail(loc, "or"); assert(false); }  /// |
    Value and(Location loc, Value val) { fail(loc, "and"); assert(false); }  /// &
    Value xor(Location loc, Value val) { fail(loc, "xor"); assert(false); }  /// ^
    Value not(Location loc) { fail(loc, "not"); assert(false); }  /// ~
    Value dereference(Location loc) { fail(loc, "dereference"); assert(false); }  /// *v
    Value index(Location loc, Value val) { fail(loc, "index"); assert(false); }  /// [n]
    Value slice(Location loc, Value from, Value to) { fail(loc, "slice"); assert(false); }  /// [n .. m]  
    Value mod(Location loc, Value val) { fail(loc, "modulo"); assert(false); }  /// %
    Value getSizeof(Location loc) { fail(loc, "getSizeof"); assert(false); }  /// .sizeof
    
    /// ||
    Value logicalOr(Location location, Value val)
    {
        auto boolType = new BoolType(mModule);
        auto a = this.performCast(location, boolType);
        auto b = val.performCast(location, boolType);
        return a.or(location, b);
    }
    
    /// &&
    Value logicalAnd(Location location, Value val)
    {
        auto boolType = new BoolType(mModule);
        auto a = this.performCast(location, boolType);
        auto b = val.performCast(location, boolType);
        return a.and(location, b);
    }
    
    /// !
    Value logicalNot(Location location)
    {
        auto boolType = new BoolType(mModule);
        auto a = this.performCast(location, boolType);
        return a.not(location);
    }
    
    /// &v
    Value addressOf(Location location)
    {
        auto v = new PointerValue(mModule, location, mType);
        v.initialise(location, mValue);
        return v;
    }
    
    Value getProperty(Location loc, string name)
    {
        switch (name) {
        case "getInit":
            return getInit(loc);
        case "sizeof":
            return getSizeof(loc);
        default:
            return null;
        }
    }
    
    Value getMember(Location loc, string name)
    {
        return getProperty(loc, name);
    }
    
    Value call(Location location, Location[] argLocations, Value[] args) { fail("call"); assert(false); }
    Value getInit(Location location) { fail("getInit"); assert(false); }
    Module getModule() { return mModule; }
    
    Value importToModule(Module mod)
    {
        return this;
    }
    
    void addSetPreCallback(void delegate(Value val) callback)
    {
        mSetPreCallbacks ~= callback;
    }
    
    void addSetPostCallback(void delegate(Value val) callback)
    {
        mSetPostCallbacks ~= callback;
    }
    
    void setPreCallbacks()
    {
        foreach (callback; mSetPreCallbacks) {
            callback(this);
        }
    }
    
    void setPostCallbacks()
    {
        foreach (callback; mSetPostCallbacks) {
            callback(this);
        }
    }
    
    void errorIfNotLValue(Location location, string msg = "cannot modify rvalue.")
    {
        if (!lvalue) {
            throw new CompilerError(location, msg);
        }
    }
    
    /**
     * Override this to convert a known value to a string.
     * Is allowed to assume that isKnown is true.
     * Do not call directly - use toKnownString.
     */
    protected string getKnownAsString()
    {
        auto className = typeid(this).name;
        throw new CompilerPanic(location, format("%s does not implement getKnownAsString().", className));
    }
    
    final string toKnownString()
    {
        if (!isKnown) {
            throw new CompilerPanic(location, "attempt to toKnownString() on non-isKnown value.");
        }
        return getKnownAsString();
    }
}
