import std;

struct CodeLine {
    string lineNr, executionNr;
    auto toString() const {
        return format(("Line nr %s: Executed %s times"), lineNr, executionNr);
    };
}

struct LineUsageCnt {
    int uncov, unexec, cov;
    auto toString() const {
        return format(("%s unexecuted lines(-). %s none covered lines(#####). %s covered lines"),
                uncov, unexec, cov);
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
    exenr = strip(splitted[0]);
    linenr = strip(splitted[1]);

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
        } else if (isNumeric(i.executionNr)) {
            lineUsage.cov++;
        }
    }
    return lineUsage;
}

//Print the uncovered lines
auto getUncoveredLines(Lines lines) {
    writeln("None covered lines: ");
    foreach (uncovered; filter!(a => a.executionNr == "#####")(lines.codelines)) {
        writeln(uncovered.lineNr);
    }
}
//Might be redundant
auto getCoveredLines(Lines lines) {
    writeln("Covered lines: ");
    foreach (covered; filter!(a => isNumeric(a.executionNr))(lines.codelines)) {
        writeln(covered.lineNr);
    }
}

void main() {
    Lines lines;

    auto file = File("source/test.c.gcov", "r");
    foreach (line; file.byLineCopy.map!(a => splitCodeLine(a))) {
        lines.codelines ~= line;
    }
    file.close();
    writeln(countLineUsage(lines));
    getUncoveredLines(lines);
    getCoveredLines(lines);
}
