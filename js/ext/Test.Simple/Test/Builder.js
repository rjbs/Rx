// $Id$

/*global JSAN, Test, WScript, _global */

// Set up namespace.
if (typeof self != 'undefined') {
    // Browser
    if (typeof Test == 'undefined') Test = {PLATFORM: 'browser'};
    else Test.PLATFORM = 'browser';
} else if (typeof _global != 'undefined') {
    //Director
    if (typeof _global.Test == "undefined") _global.Test = {PLATFORM: 'director'};
    else _global.Test.PLATFORM = 'director';
} else if (typeof WScript != 'undefined') {
    // WSH
    if (typeof Test == 'undefined') Test = {PLATFORM: 'wsh'};
    else Test.PLATFORM = 'wsh';
} else {
    // Assume command-line interpreter.
    if (typeof Test == 'undefined') Test = {PLATFORM: 'interp'};
    else Test.PLATFORM = 'interp';
}

// Constructor.
Test.Builder = function () {
    Test.Builder.Instances.push(this.reset());
    if (!Test.Builder.Test) Test.Builder.Test = this;
};

// Static variables.
Test.Builder.globalScope = typeof JSAN != 'undefined'
  ? JSAN.globalScope
  :  typeof window != 'undefined'
    ? window
    : typeof _global != 'undefined'
      ? _global
      : this;

Test.Builder.VERSION = '0.29';
Test.Builder.Instances = [];
Test.Builder.lineEndingRx = /\r?\n|\r/g;
Test.Builder.StringOps = {
    eq: '==',
    ne: '!=',
    lt: '<',
    gt: '>',
    ge: '>=',
    le: '<='
};

// Stoopid IE.
Test.Builder.LF = typeof navigator != "undefined"
    && navigator.userAgent.toLowerCase().indexOf('msie') + 1
    && Test.Builder.globalScope.opera == undefined
  ? "\r"
  : "\n";

// Static methods.
Test.Builder.Error = function (msg) {
    this.message = msg;
    this.name    = "Test.Builder.Error";
}
Test.Builder.Error.prototype = new Error();

Test.Builder.die = function (msg) {
    throw new Test.Builder.Error(msg);
};

Test.Builder._whoa = function (check, desc) {
    if (!check) return;
    Test.Builder.die(
        "WHOA! " + desc + Test.Builder.LF +
        "This should never happen! Please contact the author immediately!"
    );
};

Test.Builder.typeOf = function (object) {
    var c = Object.prototype.toString.apply(object);
    var name = c.substring(8, c.length - 1);
    if (name != 'Object') return name;
    // It may be a non-core class. Try to extract the class name from
    // the constructor function. This may not work in all implementations.
    if (/function ([^(\s]+)/.test(Function.toString.call(object.constructor))) {
        return RegExp.$1;
    }
    // No idea. :-(
    return name;
};

Test.Builder.instance = function () {
    if (!Test.Builder.Test) return new Test.Builder();
    return Test.Builder.Test;
};

Test.Builder.create = function () {
    var ret = new Test.Builder();
    ret.diag(
        "Test.Builder.create() has been deprecated. "
        + "Use new Test.Builder() instead"
    );
    return ret;
};

// Instance methods.

Test.Builder.prototype.reset = function () {
    this.TestDied      = false;
    this.HavePlan      = false;
    this.NoPlan        = false;
    this.CurrTest      = 0;
    this.ExpectedTests = 0;
    this.UseNums       = true;
    this.NoHeader      = false;
    this.NoEnding      = false;
    this.TestResults   = [];
    this.ToDo          = [];
    this.Buffer        = [];
    this.asyncs        = [0];
    this.asyncID       = 0;
    return this._setupOutput();
};

Test.Builder.prototype._print = function (msg) {
    this.output().call(this, msg);
};

Test.Builder.prototype.warn = function (msg) {
    this.warnOutput().apply(this, arguments);
};

Test.Builder.prototype.plan = function (arg) {
    if (!arg) return;
    if (this.HavePlan) Test.Builder.die("You tried to plan twice!");

    if (!(arg instanceof Object))
        Test.Builder.die("plan() doesn't understand " + arg);
    for (var cmd in arg) {
        if (cmd == 'tests') {
            if (arg[cmd] == null) {
                Test.Bulder.die(
                    "Got an undefined number of tests. Looks like you tried to "
                    + "say how many tests you plan to run but made a mistake."
                    + Test.Builder.LF
                );
            } else if (!arg[cmd]) {
                Test.Builder.die(
                    "You said to run 0 tests! You've got to run something."
                    + Test.Builder.LF
                );
            } else {
                this.expectedTests(arg[cmd]);
            }
        } else if (cmd == 'skipAll') {
            this.skipAll(arg[cmd]);
        } else if (cmd == 'noPlan' && arg[cmd]) {
            this.noPlan();
        } else if ({}.hasOwnProperty) { 
            // see if the param belongs to Object.prototype.
            if (arg.hasOwnProperty(cmd)) {
                Test.Builder.die("plan() doesn't understand "
                    + cmd + (arg[cmd] ? (" " + arg[cmd]) : ''));
            }
        } else {
            // Ignore errors if hasOwnProperty() isn't available, as in 
            // Safari < 2.0.2 and Explorer 5.
        }
    }
};

Test.Builder.prototype.expectedTests = function (max) {
    if (max) {
        if (isNaN(max)) {
            Test.Builder.die(
                "Number of tests must be a postive integer. You gave it '"
                + max + "'." + Test.Builder.LF
            );
        }

        this.ExpectedTests = max.valueOf();
        this.HavePlan       = true;
        if (!this.noHeader()) this._print("1.." + max + Test.Builder.LF);
    }
    return this.ExpectedTests;
};

Test.Builder.prototype.noPlan = function () {
    this.NoPlan   = 1;
    this.HavePlan = 1;
};

Test.Builder.prototype.hasPlan = function () {
    if (this.ExpectedTests) return this.ExpectedTests;
    if (this.NoPlan) return 'noPlan';
};

Test.Builder.prototype.skipAll = function (reason) {
    var out = "1..0";
    if (reason) out += " # Skip " + reason;
    out += Test.Builder.LF;
    this.SkipAll = 1;
    if (!this.noHeader()) this.output()(out);
    // Just throw and catch an exception.
    Test.Builder.globalScope.onerror = function () { return true; }
    throw new Error("__SKIP_ALL__");
};

Test.Builder.prototype.ok = function (test, desc) {
    // test might contain an object that we don't want to accidentally
    // store, so we turn it into a boolean.
    test = !!test;

    if (!this.HavePlan) {
        Test.Builder.die(
            "You tried to run a test without a plan! Gotta have a plan."
        );
    }

    // Append any output to the previous test's results.
    if (this.Buffer.length && this.TestResults.length) {
        this.TestResults[this.TestResults.length - 1].appendOutput(
            this.Buffer.splice(0, this.Buffer.length).join('')
        );
    }

    // I don't think we need to worry about threading in JavaScript.
    this.CurrTest++;

    // In case desc is a string overloaded object, force it to stringify.
    if (desc) desc = desc.toString();

    var startsNumber
    if (desc != null && /^[\d\s]+$/.test(desc)) {
        this.diag( "Your test description is '" + desc + "'. You shouldn't use",
                   Test.Builder.LF,
                   "numbers for your test names. Very confusing.");
    }

    var todo = this._todo();
    // I don't think we need to worry about result beeing shared between
    // threads.
    var out = '';
    var result = new Test.Builder.TestResult();

    if (test) {
        result.setOK(true);
        result.setActualOK(test);
    } else {
        out += 'not ';
        result.setOK(todo ? true : false);
        result.setActualOK(false);
    }

    out += 'ok';
    if (this.useNumbers) out += ' ' + this.CurrTest;

    if (desc == null) {
        result.setDesc('');
    } else {
        desc = desc.replace(Test.Builder.lineEndingRx, Test.Builder.LF + "# ");
        // XXX Does this matter since we don't have a TestHarness?
        desc.split('#').join('\\#'); // # # in a desc can confuse TestHarness.
        out += ' - ' + desc;
        result.setDesc(desc);
    }

    if (todo) {
        todo = todo.replace(Test.Builder.lineEndingRx, Test.Builder.LF + "# ");
        out += " # TODO " + todo;
        result.setReason(todo);
        result.setType('todo');
    } else {
        result.setReason('');
        result.setType('');
    }

    this.TestResults[this.CurrTest - 1] = result;

    out += Test.Builder.LF;
    this._print(out);

    if (!test) {
        // Add URL and line numer using code from http://pastie.org/253058?
        var msg = todo ? "Failed (TODO)" : "Failed";
        this.diag("    " + msg + " test");
    }
    result.setOutput(this.Buffer.splice(0, this.Buffer.length).join(''));
    return test;
};

Test.Builder.prototype.isEq = function (got, expect, desc) {
    if (got == null || expect == null) {
        // undefined only matches undefined and nothing else
        return this.isUndef(got, '==', expect, desc);
    }
    return this.cmpOK(got, '==', expect, desc);
};

Test.Builder.prototype.isNum = function (got, expect, desc) {
    if (got == null || expect == null) {
        // undefined only matches undefined and nothing else
        return this.isUndef(got, '==', expect, desc);
    }
    return this.cmpOK(Number(got), '==', Number(expect), desc);
};

Test.Builder.prototype.isntEq = function (got, dontExpect, desc) {
    if (got == null || dontExpect == null) {
        // undefined only matches undefined and nothing else
        return this.isUndef(got, '!=', dontExpect, desc);
    }
    return this.cmpOK(got, '!=', dontExpect, desc);
};

Test.Builder.prototype.isntNum = function (got, dontExpect, desc) {
    if (got == null || dontExpect == null) {
        // undefined only matches undefined and nothing else
        return this.isUndef(got, '!=', dontExpect, desc);
    }
    return this.cmpOK(Number(got), '!=', Number(dontExpect), desc);
};

Test.Builder.prototype.like = function (val, regex, desc) {
    return this._regexOK(val, regex, '=~', desc);
};

Test.Builder.prototype.unlike = function (val, regex, desc) {
    return this._regexOK(val, regex, '!~', desc);
};

Test.Builder.prototype._regexOK = function (val, regex, cmp, desc) {
    // Create a regex object.
    var type = Test.Builder.typeOf(regex);
    var ok;
    if (type.toLowerCase() == 'string') {
        // Create a regex object.
        regex = new RegExp(regex);
    } else {
        if (type != 'RegExp') {
            ok = this.ok(false, desc);
            this.diag("'" + regex + "' doesn't look much like a regex to me.");
            return ok;
        }
    }

    if (val == null || typeof val != 'string') {
        if (cmp == '=~') {
            // The test fails.
            ok = this.ok(false, desc);
            this._diagLike(val, regex, cmp);
        } else {
            // undefined matches nothing (unlike in Perl, where undef =~ //).
            ok = this.ok(true, desc);
        }
        return ok;
    }

    // Use val.match() instead of regex.test() in case they've set g.
    var test = val.match(regex);
    if (cmp == '!~') test = !test;
    ok = this.ok(test, desc);
    if (!ok) this._diagLike(val, regex, cmp);
    return ok;
};

Test.Builder.prototype._diagLike = function (val, regex, cmp) {
    var match = cmp == '=~' ? "doesn't match" : "      matches";
    return this.diag(
        "                  '" + val + "" + Test.Builder.LF +
        "    " + match + " /" + regex.source + "/"
    );
};

Test.Builder.prototype.cmpOK = function (got, op, expect, desc) {

    var test;
    if (Test.Builder.StringOps[op]) {
        // Force string context.
        test = eval("got.toString() " + Test.Builder.StringOps[op] + " expect.toString()");
    } else {
        test = eval("got " + op + " expect");
    }

    var ok = this.ok(test, desc);
    if (!ok) {
        if (/^(eq|==)$/.test(op)) {
            this._isDiag(got, op, expect);
        } else {
            this._cmpDiag(got, op, expect);
        }
    }
    return ok;
};

Test.Builder.prototype._cmpDiag = function (got, op, expect) {
    if (got != null) got = "'" + got.toString() + "'";
    if (expect != null) expect = "'" + expect.toString() + "'";
    return this.diag("    " + got + Test.Builder.LF + "        " + op
                     + Test.Builder.LF + "    " + expect);
};

Test.Builder.prototype._isDiag = function (got, op, expect) {
    var args = [got, expect];
    for (var i = 0; i < args.length; i++) {
        if (args[i] != null) {
            args[i] = op == 'eq' ? "'" + args[i].toString() + "'" : args[i].valueOf();
        }
    }

    return this.diag(
        "        have: " + args[0] + Test.Builder.LF +
        "        want: " + args[1] + Test.Builder.LF
    );
};

Test.Builder.prototype.BAILOUT = function (reason) {
    this._print("Bail out! " + reason);
    // Just throw and catch an exception.
    Test.Builder.globalScope.onerror = function () {
        // XXX Do something to tell TestHarness it was a bailout?
        return true;
    }
    throw new Error("__BAILOUT__");
};

Test.Builder.prototype.skip = function (why) {
    if (!this.HavePlan)
        Test.Builder.die("You tried to run a test without a plan! Gotta have a plan.");

    // In case desc is a string overloaded object, force it to stringify.
    if (why) why = why.toString().replace(Test.Builder.lineEndingRx,
                                          Test.Builder.LF+ "# ");

    this.CurrTest++;
    this.TestResults[this.CurrTest - 1] = new Test.Builder.TestResult({
        ok:        true,
        actualOK:  true,
        desc:      '',
        type:      'skip',
        reason:    why
    });

    var out = "ok";
    if (this.useNumbers) out += ' ' + this.CurrTest;
    out    += " # skip " + why + Test.Builder.LF;
    this._print(out);
    this.TestResults[this.CurrTest - 1].setOutput(
        this.Buffer.splice(0, this.Buffer.length).join('')
    );
    return true;
};

Test.Builder.prototype.todoSkip = function (why) {
    if (!this.HavePlan)
        Test.Builder.die("You tried to run a test without a plan! Gotta have a plan.");

    // In case desc is a string overloaded object, force it to stringify.
    if (why) why = why.toString().replace(Test.Builder.lineEndingRx,
                                          Test.Builder.LF + "# ");
    

    this.CurrTest++;
    this.TestResults[this.CurrTest - 1] = new Test.Builder.TestResult({
        ok:        true,
        actualOK:  false,
        desc:      '',
        type:      'todo_skip',
        reason:    why
    });

    var out = "not ok";
    if (this.useNumbers) out += ' ' + this.CurrTest;
    out    += " # TODO & SKIP " + why + Test.Builder.LF;
    this._print(out);
    this.TestResults[this.CurrTest - 1].setOutput(
        this.Buffer.splice(0, this.Buffer.length).join('')
    );
    return true;
};

Test.Builder.prototype.skipRest = function (reason) {
    var out = "# Skip";
    if (reason) out += " " + reason;
    out += Test.Builder.LF;
    if (this.NoPlan) this.skip(reason);
    else {
        for (var i = this.CurrTest; i < this.ExpectedTests; i++) {
            this.skip(reason);
        }
    }
    // Just throw and catch an exception.
    Test.Builder.globalScope.onerror = function () { return true; }
    throw new Error("__SKIP_REST__");
};

Test.Builder.prototype.useNumbers = function (useNums) {
    if (useNums != null) this.UseNums = useNums;
    return this.UseNums;
};

Test.Builder.prototype.noHeader = function (noHeader) {
    if (noHeader != null) this.NoHeader = !!noHeader;
    return this.NoHeader;
};

Test.Builder.prototype.noEnding = function (noEnding) {
    if (noEnding != null) this.NoEnding = !!noEnding;
    return this.NoEnding;
};

Test.Builder.prototype.diag = function () {
    if (!arguments.length) return;

    var msg = '# ';
    // Join each agument and escape each line with a #.
    for (var i = 0; i < arguments.length; i++) {
        // Replace any newlines.
        msg += arguments[i].toString().replace(Test.Builder.lineEndingRx,
                                               Test.Builder.LF + "# ");
    }

    // Append a new line to the end of the message if there isn't one.
    if (!(new RegExp(Test.Builder.LF + '$').test(msg)))
        msg += Test.Builder.LF;
    // Append the diag message to the most recent result.
    return this._printDiag(msg);
};

Test.Builder.prototype._printDiag = function () {
    var fn = this.todo() ? this.todoOutput() : this.failureOutput();
    fn.apply(this, arguments);
    return false;
};

Test.Builder.prototype.output = function (fn) {
    if (fn != null) {
        var buffer = this.Buffer;
        this.Output = function (msg) { buffer.push(msg); fn(msg) };
    }
    return this.Output;
};

Test.Builder.prototype.failureOutput = function (fn) {
    if (fn != null) {
        var buffer = this.Buffer;
        this.FailureOutput = function (msg) { buffer.push(msg); fn(msg) };
    }
    return this.FailureOutput;
};

Test.Builder.prototype.todoOutput = function (fn) {
    if (fn != null) {
        var buffer = this.Buffer;
        this.TodoOutput = function (msg) { buffer.push(msg); fn(msg) };
    }
    return this.TodoOutput;
};

Test.Builder.prototype.endOutput = function (fn) {
    if (fn != null) {
        var buffer = this.Buffer;
        this.EndOutput = function (msg) { buffer.push(msg); fn(msg) };
    }
    return this.EndOutput;
};

Test.Builder.prototype.warnOutput = function (fn) {
    if (fn != null) {
        var buffer = this.Buffer;
        this.WarnOutput = function (msg) { buffer.push(msg); fn(msg) };
    }
    return this.WarnOutput;
};

Test.Builder.prototype._setupOutput = function () {
    if (Test.PLATFORM == 'browser') {
        var top = Test.Builder.globalScope;
        var doc = top.document;
        var writer = function (msg) {
            // I'm sure that there must be a more efficient way to do this,
            // but if I store the node in a variable outside of this function
            // and refer to it via the closure, then things don't work right
            // --the order of output can become all screwed up (see
            // buffer.html).  I have no idea why this is.
            var body = doc.body || doc.getElementsByTagName("body")[0];
            var node = doc.getElementById('test_output')
                || doc.getElementById('test');
            if (!node) {
                node = document.createElement('pre');
                node.id = 'test_output';
                body.appendChild(node);
            }

            // This approach is neater, but causes buffering problems when
            // mixed with document.write. See tests/buffer.html.
            //node.appendChild(document.createTextNode(msg));
            //return;
            for (var i = 0; i < node.childNodes.length; i++) {
                if (node.childNodes[i].nodeType == 3 /* Text Node */) {
                    // Append to the node and scroll down.
                    node.childNodes[i].appendData(msg);
                    top.scrollTo( 0, body.offsetHeight || body.scrollHeight );
                    return;
                }
            }

            // If there was no text node, add one.
            node.appendChild(doc.createTextNode(msg));
            top.scrollTo(0, body.offsetHeight || body.scrollHeight);
            return;
        };

        this.output(writer);
        this.failureOutput(function (msg) {
            writer(msg);
        });
        this.todoOutput(writer);
        this.endOutput(writer);

        if (top.alert.apply) {
            this.warnOutput(top.alert, top);
        } else {
            this.warnOutput(function (msg) { top.alert(msg); });
        }

    } else if (Test.PLATFORM == 'director') {
        // Macromedia-Adobe:Director MX 2004 Support
        // XXX Is _player a definitive enough object?
        // There may be an even more explicitly Director object.
        /*global trace */
        this.output(trace);       
        this.failureOutput(trace);
        this.todoOutput(trace);
        this.warnOutput(trace);

    } else if (Test.PLATFORM == 'wsh') {
        // Windows Scripting Host Support
        var printer = function (msg) {
			WScript.StdOut.writeline(msg);
		}
		this.output(printer);
		this.failureOutput(printer);
		this.todoOutput(printer);
		this.warnOutput(printer);

    } else if (Test.PLATFORM == 'interp') {
        // Command-line interpeter.
        var out = function (toOut) { print( toOut.replace(/\n$/, '') ); };
        this.output(out);
        this.failureOutput(out);
        this.todoOutput(out);
        this.warnOutput(out);
	}
    return this;
};

Test.Builder.prototype.currentTest = function (num) {
    if (num == null) return this.CurrTest;

    if (!this.HavePlan)
        Test.Builder.die("Can't change the current test number without a plan!");
    this.CurrTest = num;
    if (num >= this.TestResults.length ) {
        var reason = 'incrementing test number';
        for (var i = this.TestResults.length; i < num; i++) {
            this.TestResults[i] = new Test.Builder.TestResult({
                ok:        true, 
                actualOK:  null,
                reason:    reason,
                type:      'unknown', 
                output:    'ok - ' + reason + Test.Builder.LF
            });
        }
    } else if (num < this.TestResults.length) {
        // IE requires the second argument to truncate the array.
        this.TestResults.splice(num, this.TestResults.length);
    }
    return this.CurrTest;
};

Test.Builder.prototype.summary = function () {
    var results = new Array(this.TestResults.length);
    for (var i = 0; i < this.TestResults.length; i++) {
        var result = this.TestResults[i];
        results[i] = result ? null : result.getOK();
    }
    return results
};

Test.Builder.prototype.details = function () {
    var details = new Array();
    for (var i = 0; i < this.TestResults.length; i++) {
        var result = this.TestResults[i];
        details.push(result ? result.exportDetails() : null);
    }
    return details;
};

Test.Builder.prototype.todo = function (why, howMany) {
    if (howMany) this.ToDo = [why, howMany];
    return this.ToDo[1];
};

Test.Builder.prototype._todo = function () {
    if (this.ToDo[1]) {
        if (this.ToDo[1]--) return this.ToDo[0];
        this.ToDo = [];
    }
    return false;
};

Test.Builder.prototype._sanity_check = function () {
    Test.Builder._whoa(
        this.CurrTest < 0,
        'Says here you ran a negative number of tests!'
    );

    Test.Builder._whoa(
        !this.HavePlan && this.CurrTest, 
        'Somehow your tests ran without a plan!'
    );

    Test.Builder._whoa(
        this.CurrTest != this.TestResults.length,
        'Somehow you got a different number of results than tests ran!'
    );
};

Test.Builder.prototype._notifyHarness = function () {
    var top = Test.Builder.globalScope;
    // Special treatment for the browser harness.
    if (top.parent && top.parent.Test && top.parent.Test.Harness) {
        top.parent.Test.Harness.Done++;
    }
};

Test.Builder.prototype._ending = function () {
    if (this.Ended) return;
    this.Ended = true;
    if (this.noEnding()) {
        this._notifyHarness();
        return;
    }
    this._sanity_check();
    var out = this.endOutput();

    // Figure out if we passed or failed and print helpful messages.
    if( this.TestResults.length ) {
        // The plan?  We have no plan.
        if (this.NoPlan) {
            if (!this.noHeader())
                this._print("1.." + this.CurrTest + Test.Builder.LF);
            this.ExpectedTests = this.CurrTest;
        }

        var numFailed = 0;
        for (var i = 0; i < this.TestResults.length; i++) {
            if (!this.TestResults[i].ok) numFailed++;
        }
        numFailed += Math.abs(
            this.ExpectedTests - this.TestResults.length
        );

        if (this.CurrTest != this.ExpectedTests) {
            out(
                "# Looks like you planned " + this.ExpectedTests + " test"
                + (this.ExpectedTests == 1 ? '' : 's')
                + " but ran " + this.CurrTest + "." + Test.Builder.LF
            );
        } else if (numFailed) {
            out(
                "# Looks like you failed " + numFailed + " test"
                + (numFailed == 1 ? '' : 's') + " of "
                + this.ExpectedTests + "." + Test.Builder.LF
            );
        }

        if (this.TestDied) {
            out(
                "# Looks like your test died just after " 
                + this.CurrTest + "." + Test.Builder.LF
            );
        }

    } else if (!this.SkipAll) {
        // skipAll requires no status output.
        if (this.TestDied) {
            out(
                "# Looks like your test died before it could output anything."
                + Test.Builder.LF
            );
        } else {
            out("# No tests run!" + Test.Builder.LF);
        }
    }
    this._notifyHarness();
};

Test.Builder.prototype.isUndef = function (got, op, expect, desc) {
    // Undefined only matches undefined, so we don't need to cast anything.
    var test = eval("got " + (Test.Builder.StringOps[op] || op) + " expect");
    this.ok(test, desc);
    if (!test) this._isDiag(got, op, expect);
    return test;
};

Test.Builder._finish = function (pkg) {
    if (!pkg) pkg = Test;
    for (var i = 0; i < pkg.Builder.Instances.length; i++) {
        // The main process is always async ID 0.
        if (!pkg.Builder.Instances[i].Ended)
            pkg.Builder.Instances[i].endAsync(0);
    }
};

if (Test.Builder.globalScope) {
    // Set up an onload function to end all tests.
    Test.Builder.globalScope.onload = function (event, pkg) {
        // The package may be passed in if onload() is called explicitly.
        // This is to get around a very weird scoping bug in my version of
        // Firefox. See Test.Harness.Browser.runTest() for this usage.
        Test.Builder._finish(pkg)
    };

    // Set up an exception handler. This is so that we can capture deaths but
    // still output information for TestHarness to pick up.
    Test.Builder.globalScope.onerror = function (msg, url, line) {
        // Output the exception.
        Test.Builder.Test.TestDied = true;
        Test.Builder.Test.diag("Error in " + url + " at line " + line + ": " + msg);
        return true;
    };
};

Test.Builder.prototype.beginAsync = function (timeout) {
	var id = ++this.asyncID;
    var top = Test.Builder.globalScope;
    if (timeout && top && top.setTimeout) {
        // Are there other ways of setting timeout in non-browser settings?
        var aTest = this;
        this.asyncs[id] = top.setTimeout(
            function () { aTest.endAsync(id) }, timeout
        );
    } else {
        // Make sure it's defined.
        this.asyncs[id] = 0;
    }
	return id;
};

Test.Builder.prototype.endAsync = function (id) {
    if (this.asyncs[id] == undefined) return;
    if (this.asyncs[id]) {
		// Remove the timeout
		Test.Builder.globalScope.clearTimeout(this.asyncs[id]);
	}
    if (--this.asyncID < 0) this._ending();
};

Test.Builder.exporter = function (pkg, root) {
    if (typeof root == 'undefined') {
        root = Test.Builder.globalScope;
        if (!root) throw new Error("Platform unknown");
    }
    for (var i = 0; i < pkg.EXPORT.length; i++) {
        if (typeof root[pkg.EXPORT[i]] == 'undefined')
            root[pkg.EXPORT[i]] = pkg[pkg.EXPORT[i]];
    }
};

// Package-private utility class for describing the results of a single test.
Test.Builder.TestResult = function (args) {
    var defaults = Test.Builder.TestResult.defaults;
    for (var name in defaults) {
        this[name] = defaults[name];
    }
    if (args) {
        for (var name in args) {
            // Validate params.
            if ({}.hasOwnProperty) {
                if (   args.hasOwnProperty(name) 
                    && !defaults.hasOwnProperty(name)
                ) {
                    throw new Test.Builder.Error("Invalid parameter: " + name);
                }
            }
            this[name] = args[name];
        }
    }
}

Test.Builder.TestResult.defaults = {
    ok:       null,
    actualOK: null,
    desc:     '',
    reason:   '',
    type:     null,
    output:   '' 
};

// Set up get/set accessors
Test.Builder.TestResult.makeGetSet = function (varName, reCasedName) {
    Test.Builder.TestResult.prototype[ 'get' + reCasedName ] 
        = function () { return this[varName] };
    Test.Builder.TestResult.prototype[ 'set' + reCasedName ] 
        = function (newVal) { this[varName] = newVal };
}
Test.Builder.TestResult.makeGetSet('ok',       'OK');
Test.Builder.TestResult.makeGetSet('actualOK', 'ActualOK'); 
Test.Builder.TestResult.makeGetSet('desc',     'Desc');
Test.Builder.TestResult.makeGetSet('reason',   'Reason');
Test.Builder.TestResult.makeGetSet('type',     'Type');
Test.Builder.TestResult.makeGetSet('output',   'Output');

// Append string to 'output' member var.
Test.Builder.TestResult.prototype.appendOutput = function (more) {
    this.output += more;
};

Test.Builder.TestResult.prototype.exportDetails = function () {
    return {
        ok:        this.ok,
        actual_ok: this.actualOK, // backwards compatible
        desc:      this.desc,
        reason:    this.reason,
        type:      this.type,
        output:    this.output
    };
};

//////////////////////////////////////////////////////////////////////////////
// Package-private utility class for describing the results of a single test.
//////////////////////////////////////////////////////////////////////////////
Test.Builder.TestResult = function (args) {
    var defaults = Test.Builder.TestResult.defaults;
    for (var name in defaults) {
        this[name] = defaults[name];
    }
    if (args) {
        for (var prop in args) {
            // Validate params.
            if ({}.hasOwnProperty
                && args.hasOwnProperty(prop) 
                && !defaults.hasOwnProperty(prop)
            ) {
                throw new Test.Builder.Error("Invalid parameter: " + prop);
            }
            this[prop] = args[prop];
        }
    }
}

Test.Builder.TestResult.defaults = {
    ok:       null,
    actualOK: null,
    desc:     '',
    reason:   '',
    type:     null,
    output:   '' 
};

// Set up get/set accessors
Test.Builder.TestResult.makeGetSet = function (varName, reCasedName) {
    Test.Builder.TestResult.prototype[ 'get' + reCasedName ] 
        = function () { return this[varName] };
    Test.Builder.TestResult.prototype[ 'set' + reCasedName ] 
        = function (newVal) { this[varName] = newVal };
}
Test.Builder.TestResult.makeGetSet('ok',       'OK');
Test.Builder.TestResult.makeGetSet('actualOK', 'ActualOK'); 
Test.Builder.TestResult.makeGetSet('desc',     'Desc');
Test.Builder.TestResult.makeGetSet('reason',   'Reason');
Test.Builder.TestResult.makeGetSet('type',     'Type');
Test.Builder.TestResult.makeGetSet('output',   'Output');

// Append string to 'output' member var.
Test.Builder.TestResult.prototype.appendOutput = function (more) {
    this.output += more;
};

Test.Builder.TestResult.prototype.exportDetails = function () {
    return {
        ok:        this.ok,
        actual_ok: this.actualOK, // backwards compatible
        desc:      this.desc,
        reason:    this.reason,
        type:      this.type,
        output:    this.output
    };
};

