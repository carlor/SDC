module sdc.gen.value.llvm;

import std.exception;

import llvm.c.Core;

import sdc.compilererror;
import sdc.location;
import sdc.gen.value.value;
import sdc.gen.value.variable;


class LLVMVariable : Variable
{
    LLVMValueRef pointer;
    Value value;

    override void set(Location loc, Value value)
    {
        pointer = LLVMBuildAlloca(value.mod.builder, value.type.get(), "Variable.set");
        this.value = value;
    }

    override Value get(Location loc)
    {
        auto v = LLVMBuildLoad(value.mod.builder, pointer, "Variable.get");
        value.type.getInstance(value.mod, loc);
        value.set(v);
        return value;
    }
}

class LLVMIntValue : IntValue
{
    LLVMValueRef llvmValue;
    
    override void* get()
    {
        if (llvmValue is null) {
            if (isKnown) {
                llvmValue = LLVMConstInt(LLVMInt32Type(), knownInt, false);
            } else {
                llvmValue = LLVMGetUndef(LLVMInt32Type());
            }
        }
        return llvmValue;            
    }

    override void set(void* p)
    {
        llvmValue = p;
    }
    
    override void buildAdd(Location loc, Value lhs, Value rhs)
    {
        llvmValue = LLVMBuildAdd(mod.builder, lhs.get(), rhs.get(), "add");
    }
    
    override void buildSub(Location loc, Value lhs, Value rhs)
    {
        llvmValue = LLVMBuildSub(mod.builder, lhs.get(), rhs.get(), "sub");
    }
    
    override void buildMul(Location loc, Value lhs, Value rhs)
    {
        llvmValue = LLVMBuildMul(mod.builder, lhs.get(), rhs.get(), "mul");
    }
    
    override void buildDiv(Location loc, Value lhs, Value rhs)
    {
        llvmValue = LLVMBuildSDiv(mod.builder, lhs.get(), rhs.get(), "div");
    }
}
