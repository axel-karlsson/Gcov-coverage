import std;

struct CodeLine {
    string lineNr, executionNr;
    auto toString() const {
        return format(("Line nr %s: Executed %s times"), lineNr, executionNr);
    };
}

struct LineUsageCnt {
    int uncov, unexec;
    auto toString() const {
        return format(("%s unexecuted lines(-). %s none covered lines(#####)"), uncov, unexec);
    }
}

struct Lines {
    CodeLine[] codelines;
}

//Remove???
struct CodeLineRange {
    CodeLine[] codelines;

    this(Lines line) {
        this.codelines = line.codelines;
    }

    @property bool empty() const {
        return codelines.length == 0;
    }

    @property ref CodeLine front() {
        return codelines[0];
    }
}

auto splitCodeLine(string line) {
    string exenr, linenr;
    auto splitted = split(line, ":");
    if (splitted) {
        exenr = strip(splitted[0]);
        linenr = strip(splitted[1]);
    }
    auto splitLine = CodeLine(linenr, exenr);
    return splitLine;
}

//Will improve this later on... With count??
auto countLineUsage(Lines line) {
    LineUsageCnt lineUsage;
    foreach (i; line.codelines) {
        if (i.executionNr == "-" && i.lineNr != "0") {
            lineUsage.uncov++;
        } else if (i.executionNr == "#####") {
            lineUsage.unexec++;
        }
    }
    return lineUsage;
}

auto writeCodeCoverage() {
    //TODO More output somehow?
}

void main() {
    Lines lines;

    auto file = File("source/test.c.gcov", "r");
		foreach (line; file.byLineCopy.map!(a => splitCodeLine(a))) {
        lines.codelines ~= line;
    }
    file.close();
    writeln(countLineUsage(lines));
}
