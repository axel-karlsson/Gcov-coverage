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

auto getUncoveredLines(Lines lines) {
    writeln("None covered lines: ");
    foreach (nocovered; filter!(a => a.executionNr == "#####")(lines.codelines)) {
        //writeln(nocovered.lineNr);
        writeln(toJson(nocovered));

    }
}

//Might be redundant
auto getCoveredLines(Lines lines) {
    writeln("Covered lines: ");
    foreach (covered; filter!(a => isNumeric(a.executionNr))(lines.codelines)) {
        writeln(toJson(covered));
    }
}

auto toJson(CodeLine codeline){
  JSONValue j = ["executionNr": ""];
  j.object["lineNr"] = JSONValue(codeline.lineNr);
  j.object["executionNr"] = JSONValue(codeline.executionNr);
  return j;
}

void main() {
    Lines lines;
    auto file = File("source/test.c.gcov", "r");
    foreach (line; file.byLineCopy.map!(a => splitCodeLine(a))) {
        lines.codelines ~= line;
    }
    writeln(countLineUsage(lines));
    getUncoveredLines(lines);
    getCoveredLines(lines);
}
