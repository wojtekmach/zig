export fn entry() void {
    if(true) {} else if(true) {}
    var good = {};
    if(true) ({}) else if(true) ({})
    var bad = {};
}

// implicit semicolon - if-else-if statement
//
// tmp.zig:4:37: error: expected ';' or 'else' after statement
