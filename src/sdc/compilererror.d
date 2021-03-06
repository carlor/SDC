/**
 * Copyright 2010 Bernard Helyer.
 * Copyright 2011 Jakob Ovrum.
 * This file is part of SDC.
 * See LICENCE or sdc.d for more details.
 */ 
module sdc.compilererror;

import std.algorithm;
import std.stdio;
import std.string;

import sdc.aglobal;
import sdc.terminal;
import sdc.location;

class CompilerError : Exception
{
    Location location;
    
    CompilerError more; // Optional
    string fixHint; // Optional
    
    this(string message)
    {
        super(format(errorFormat(), message));
    }
    
    this(string message, CompilerError more)
    {
        this.more = more;
        this(message);
    }
    
    this(Location loc, string message)
    {
        super(format(locationFormat(), loc.toString(), message));
        location = loc;
    }
    
    this(Location loc, string message, CompilerError more)
    {
        this.more = more;
        this(loc, message);
    }
    
    protected:
    string errorFormat()
    {
        return "error: %s";
    }
    
    string locationFormat()
    {
        return "%s: error: %s";
    }
}

class CompilerPanic : CompilerError
{
    this(string message)
    {
        super(message);
    }
    
    this(Location loc, string message)
    {
        super(loc, message);
    }
    
    protected override:
    string errorFormat()
    {
        return "panic: %s";
    }
    
    string locationFormat()
    {
        return "%s: panic: %s";
    }
}

class CompilerErrorNote : CompilerError
{
    this(string message)
    {
        super(message);
    }
    
    this(Location loc, string message)
    {
        super(loc, message);
    }
    
    protected override:
    string errorFormat()
    {
        return "note: %s";
    }
    
    string locationFormat()
    {
        return "%s: note: %s";
    }
}

class MissingSemicolonError : CompilerError
{
    this(Location loc, string type)
    {
        loc.column += loc.length;
        loc.length = 1;
        super(loc, format("missing ';' after %s.", type));
        
        fixHint = ";";
    }
}

class MissingColonError : CompilerError
{
    this(Location loc, string type)
    {
        loc.column += loc.length;
        loc.length = 1;
        super(loc, format("missing ':' after %s.", type));
        
        fixHint = ":";
    }
}

class PairMismatchError : CompilerError
{
    this(Location pairStart, Location loc, string type, string token)
    {
        loc.column += loc.length;
        loc.length = token.length;
        super(loc, format("expected '%s' to close %s.", token, type));
        fixHint = token;
        
        more = new CompilerErrorNote(pairStart, format("%s started here.", type));
    }
}

// For catching purposes
class ArgumentMismatchError : CompilerError
{
    static immutable ptrdiff_t unspecified = -1;
    ptrdiff_t argNumber = unspecified;
    
    this(Location loc, string message)
    {
        super(loc, message);
    }
    
    this(Location loc, string message, ptrdiff_t argNumber)
    {
        this.argNumber = argNumber;
        super(loc, message);
    }
}

void errorMessageOnly(Location loc, string message)
{
    stderr.writeln(format("%s: error: %s", loc.toString(), message));
}

void warning(Location loc, Warning id)
{
    if (disableAllWarnings || disabledWarnings.count(id) > 0) {
        return;
    }
    if (treatWarningsAsErrors || errorWarnings.count(id) > 0) {
        throw new CompilerError("treating warning as error.", new CompilerError(loc, warningToMessage(id)));
    }
    stderr.writefln("%s: warning (ID:%s): %s", loc.toString(), cast(uint) id, warningToMessage(id));
    outputCaretDiagnostics(loc, null);
}

enum Warning : uint
{
    NestedBlockComment,
    UnreachableStatement,
}

private string warningToMessage(Warning id)
{
    final switch (id) with (Warning) {
    case NestedBlockComment:
        return "'/*' inside of block comment.";
    case UnreachableStatement:
        return "statement is unreachable.";
    }
    assert(false);
}
