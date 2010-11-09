/**
 * Copyright 2010 Bernard Helyer.
 * This file is part of SDC. SDC is licensed under the GPL.
 * See LICENCE or sdc.d for more details.
 */
module sdc.gen.sdcmodule;

import std.conv;
import std.exception;
import std.process;
import std.stdio;
import std.string;

import llvm.c.Analysis;
import llvm.c.BitWriter;
import llvm.c.Core;
import llvm.c.transforms.Scalar;

import sdc.compilererror;
import sdc.util;
import sdc.global;
import sdc.location;
import sdc.extract.base;
import sdc.gen.type;
import sdc.gen.value;


/**
 * Module encapsulates the code generated for a module.
 * 
 * Also, GOD OBJECT
 */ 
class Module
{
    ast.QualifiedName name;
    LLVMContextRef context;
    LLVMModuleRef  mod;
    LLVMBuilderRef builder;
    Scope globalScope;
    Scope currentScope;
    Path currentPath;
    ast.DeclarationDefinition[] functionBuildList;
    FunctionValue currentFunction;
    Value base;
    Value callingAggregate;
    ast.Linkage currentLinkage = ast.Linkage.ExternD;
    ast.Access currentAccess = ast.Access.Public;
    bool isAlias;  // ewwww
    TranslationUnit[] importedTranslationUnits;
    string arch;

    this(ast.QualifiedName name)
    {
        if (name is null) {
            throw new CompilerPanic("Module called with null name argument.");
        }
        this.name = name;
        context = LLVMGetGlobalContext();
        mod     = LLVMModuleCreateWithNameInContext(toStringz(extractQualifiedName(name)), context);
        builder = LLVMCreateBuilderInContext(context);
        
        globalScope = new Scope();
        currentScope = globalScope;
    }
        
    ~this()
    {
        LLVMDisposeModule(mod);
        LLVMDisposeBuilder(builder);
    }
    
    /**
     * Verify that the generated bit code is correct.
     * If it isn't, an error will be printed and the process will be aborted.
     */
    void verify()
    {
        auto failed = LLVMVerifyModule(mod, LLVMVerifierFailureAction.PrintMessage, null);
        if (failed) {
            LLVMDumpModule(mod);
            throw new CompilerPanic("Module verification failed.");
        }
    }
    
    /**
     * Dump a human readable form of the generated code to stderr.
     */
    void dump()
    {
        LLVMDumpModule(mod);
    }
    
    /**
     * Write the bitcode to a specified file.
     */
    void writeBitcodeToFile(string filename)
    {
        LLVMWriteBitcodeToFile(mod, toStringz(filename));
    }
    
    void writeNativeAssemblyToFile(string fromFilename, string toFilename)
    {
        auto cmd = format(`llc -march=%s -o "%s" "%s"`, arch, toFilename, fromFilename);
        system(cmd);
    }
    
    /**
     * Optimise the generated code in place.
     */
    void optimise()
    {
        auto passManager = LLVMCreatePassManager();
        scope (exit) LLVMDisposePassManager(passManager);
        LLVMAddInstructionCombiningPass(passManager);
        LLVMAddPromoteMemoryToRegisterPass(passManager);
        LLVMRunPassManager(passManager, mod);
    }

    void pushScope()
    {
        mScopeStack ~= new Scope();
        currentScope = mScopeStack[$ - 1];
    }
    
    void popScope()
    {
        assert(mScopeStack.length >= 1);
        mScopeStack = mScopeStack[0 .. $ - 1];
        currentScope = mScopeStack.length >= 1 ? mScopeStack[$ - 1] : globalScope;
    }
    
    Store search(string name)
    {
        // "Look up the symbol in the current scope."
        auto store = localSearch(name);
        if (store !is null) {
            // "If found, lookup ends successfully."
            goto exit;
        }
        
        // "Look up the symbol in the current module's scope."
        store = globalScope.get(name);
        if (store !is null) {
            // "If found, lookup ends successfully."
            goto exit;
        }
        
        // "Look up the symbol in _all_ imported modules."
        assert(store is null);
        foreach (tu; importedTranslationUnits) {
            void checkAccess(ast.Access access)
            {
                if (access != ast.Access.Public) {
                    throw new CompilerError("cannot access symbol '" ~ name ~ "', as it is declared private.");
                }
            }
            auto tustore = tu.gModule.globalScope.get(name);
            if (tustore is null) {
                continue;
            }
            
            if (tustore.storeType == StoreType.Value) {
                checkAccess(tustore.value.access);
                tustore = new Store(tustore.value.importToModule(this));
            } else if (tustore.storeType == StoreType.Type) {
                checkAccess(tustore.type.access);
                tustore = new Store(tustore.type.importToModule(this));
            }

            if (store is null) {
                store = tustore;
                continue;
            }

            /* "If found in more than one module, 
             *  and the symbol is not the name of a function,
             *  fail with 'duplicated symbol' error message."
             */
            if (store.storeType == StoreType.Value && store.value.type.dtype != DType.Function) {
                throw new CompilerError("duplicate symbol '" ~ name ~ "'.");
            } else {
                /* "...if the symbol is the name of a function,
                 *  apply cross-module overload resolution."
                 */
                throw new CompilerPanic("no cross-module overload resolution!");
            }            
        }
        
    exit:
        return store;
    }
    
    Store localSearch(string name)
    {
        /* This isn't just `foreach (localScope; retro(mScopeStack))`  
         * because of a bug manifested in std.range.retro.
         * WORKAROUND 2.048-2.049
         * Unfortunately, it has resisted being boiled down
         * into a simple test case.
         */
        for (int i = mScopeStack.length - 1; i >= 0; i--) {
            auto localScope = mScopeStack[i];
            auto v = localScope.get(name);
            if (v !is null) {
                return v;
            }
        }
        return null;
    }
    
    void pushPath(PathType type)
    {
        mPathStack ~= new Path(type);
        currentPath = mPathStack[$ - 1];
    }
    
    void popPath()
    {
        assert(mPathStack.length >= 1);
        auto oldPath = currentPath;
        mPathStack = mPathStack[0 .. $ - 1];
        currentPath = mPathStack.length >= 1 ? mPathStack[$ - 1] : null;
        if (oldPath !is null && currentPath !is null && oldPath.type == PathType.Inevitable) {
            currentPath.functionEscaped = oldPath.functionEscaped;
        }
    }
    
    /**
     * Returns: the depth of the current scope.
     *          A value of zero means the current scope is global.
     */
    int scopeDepth() @property
    {
        return mScopeStack.length;
    }
    
    /**
     * Set a given version identifier for this module.
     */
    void setVersion(Location loc, string s)
    {
        if (isReserved(s)) {
            throw new CompilerError(loc, format("can't set reserved version identifier '%s'.", s));
        }
        if (s in mVersionIdentifiers || isVersionIdentifierSet(s)) {
            throw new CompilerError(loc, format("version identifier '%s' is already set.", s));
        }
        mVersionIdentifiers[s] = true;
    }
    
    void setDebug(Location loc, string s)
    {
        if (s in mDebugIdentifiers || isDebugIdentifierSet(s)) {
            throw new CompilerError(loc, format("debug identifier '%s' is already set.", s));
        }
        mDebugIdentifiers[s] = true;
    }
    
    bool isVersionSet(string s)
    {
        mTestedVersionIdentifiers[s] = true;
        auto result = isVersionIdentifierSet(s);
        if (!result) {
            result = (s in mVersionIdentifiers) !is null;
        }
        return result;
    }
    
    bool isDebugSet(string s)
    {
        mTestedDebugIdentifiers[s] = true;
        auto result = isDebugIdentifierSet(s);
        if (!result) {
            result = (s in mDebugIdentifiers) !is null;
        }
        return result;
    }
    
    bool hasVersionBeenTested(string s)
    {
        return (s in mTestedVersionIdentifiers) !is null;
    }
    
    bool hasDebugBeenTested(string s)
    {
        return (s in mTestedDebugIdentifiers) !is null;
    }
    
    /**
     * This is here for when you need to generate code in a contex
     * that will be discarded.
     * Usually to get the type of a given expression without side effects,
     * e.g. `int i; typeof(i++) j; assert(i == 0);`
     * 
     * WARNING: Do NOT gen code/use values generated by a dup'd module --
     *          THE CODE GENERATED WILL BE INVALID/INCORRECT.   :)
     */
    Module dup() @property
    {
        auto mod = new Module(name);
        
        mod.globalScope = globalScope.importToModule(mod);
        mod.currentScope = currentScope.importToModule(mod);
        mod.currentPath = currentPath;
        mod.functionBuildList = functionBuildList.dup;
        if (currentFunction !is null) {
            mod.currentFunction = cast(FunctionValue) currentFunction.importToModule(mod);
        }
        if (base !is null) {
            mod.base = base.importToModule(mod);
        }
        if (callingAggregate !is null) {
            mod.callingAggregate = callingAggregate.importToModule(mod);
        }
        mod.currentLinkage = currentLinkage;
        mod.currentAccess = currentAccess;
        mod.isAlias = isAlias;
        mod.importedTranslationUnits = mod.importedTranslationUnits.dup;
        mod.arch = arch;
        
        foreach (_scope; mScopeStack) {
            mod.mScopeStack ~= _scope.importToModule(mod);
        }
        mod.mPathStack = mPathStack.dup;
        mod.mFailureList = mFailureList;
        mod.mVersionIdentifiers = mVersionIdentifiers;
        mod.mTestedVersionIdentifiers = mTestedVersionIdentifiers;
        mod.mDebugIdentifiers = mDebugIdentifiers;
        mod.mTestedDebugIdentifiers = mTestedDebugIdentifiers;
        
        return mod;
    }
    
    void addFailure(LookupFailure lookupFailure)
    {
        mFailureList ~= lookupFailure;
    }
    
    const(LookupFailure[]) lookupFailures() @property
    {
        return mFailureList;
    }
        
    protected Scope[] mScopeStack;
    protected Path[] mPathStack;
    protected LookupFailure[] mFailureList;
    protected bool[string] mVersionIdentifiers;
    protected bool[string] mTestedVersionIdentifiers;
    protected bool[string] mDebugIdentifiers;
    protected bool[string] mTestedDebugIdentifiers;
}

struct LookupFailure
{
    string name;
    Location location;
}

enum StoreType
{
    Value,
    Type,
    Scope,
}

class Store
{
    StoreType storeType;
    Object object;
    
    this(Value value)
    {
        storeType = StoreType.Value;
        object = value;
    }
    
    this(Type type)
    {
        storeType = StoreType.Type;
        object = type;
    }
    
    this(Scope _scope)
    {
        storeType = StoreType.Scope;
        object = _scope;
    }
    
    Value value() @property
    {
        assert(storeType == StoreType.Value);
        auto val = cast(Value) object;
        assert(val);
        return val;
    }
    
    Type type() @property
    {
        assert(storeType == StoreType.Type);
        auto type = cast(Type) object;
        assert(type);
        return type;
    }
    
    Scope getScope() @property
    {
        assert(storeType == StoreType.Scope);
        auto _scope = cast(Scope) object;
        assert(_scope);
        return _scope;
    }
    
    Store importToModule(Module mod)
    {
        Store store;
        final switch (storeType) with (StoreType) {
        case Value:
            return new Store(value.importToModule(mod));
        case Type:
            return new Store(type.importToModule(mod));
        case Scope:
            return new Store(getScope());
        }
    }
}

class Scope
{
    void add(string name, Store store)
    {
        mSymbolTable[name] = store;
    }
    
    Store get(string name)
    {
        auto p = name in mSymbolTable;
        return p is null ? null : *p;
    }
    
    Scope importToModule(Module mod)
    {
        auto _scope = new Scope();
        foreach (name, store; mSymbolTable) {
            _scope.add(name, store.importToModule(mod));
        }
        return _scope;
    }
    
    Store[string] mSymbolTable;
}

enum PathType
{
    Inevitable,
    Optional,
}

class Path
{
    this(PathType type)
    {
        this.type = type;
    }
    
    PathType type;
    bool functionEscaped;
}
