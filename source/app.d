import std;

alias gcov_unsigned_t = Typedef!uint32_t;
alias gcov_position_t = Typedef!uint32_t;

//alias GCOV_TAG_FUNCTION = (uint32_t)0x01000000;
//MAGIC
enum uint32_t GCOV_NOTE_MAGIC = 0x67636461; //gcno
enum uint32_t GCOV_DATA_MAGIC = 0x67636e6f; //gcda

//TAGS
enum uint32_t GCOV_TAG_FUNCTION = 0x01000000;
enum uint32_t GCOV_TAG_BLOCKS = 0x01410000;
enum uint32_t GCOV_TAG_LINES = 0x01450000;
enum uint32_t GCOV_TAG_ARCS = 0x01430000;

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

struct coverageInfo { //TODO: Usage?
    int lines;
    int lines_executed;

    int branches;
    int branches_executed;
    int branches_taken;

    int calls;
    int calls_executed;

    char* name;
}

struct Lines {
    CodeLine[] codelines;
}

struct FileHeader {
    int32_t magic, versionn, stamp;
}

struct Header {
    int32_t tag;
    int32_t length;
}

class GcovParser {
public:

    bool parse() {
        if (!verify()) {
            return false;
        }
        const uint8_t* cur = m_data + FileHeader.sizeof;
        ptrdiff_t left = cast(ptrdiff_t)(m_dataSize - FileHeader.sizeof);

        while (1) {
            const Header* header = cast(Header*) cur; //struct pointers in D???

            /*if(onRecord(header, cur + (*header).sizeof)){
              return false;
              }*/ //TODO: Check if needed

            size_t curLen = header.sizeof + header.length * 4;
            left -= curLen;

            if (left <= 0) {
                break;
            }
            *cast(uint8_t*)&cur += curLen; //TODO: Can this amazing hack be done any better?
        }
        return true;
    }

protected:

    this(const uint8_t* data, size_t dataSize) {
        m_data = data;
        m_dataSize = dataSize;
    }

    bool verify() {
        const FileHeader* header = cast(FileHeader*) m_data;
        return !(header.magic != GCOV_DATA_MAGIC && header.magic != GCOV_NOTE_MAGIC); //return false if not gcda or gcno

    }

    bool onRecord(const Header* header, const uint8_t* data) = 0; //virtual func

    const uint8_t* readString(const uint8_t* p, ref string outt) {
        int32_t length = *cast(const int32_t*) p;
        const char* c_str = cast(const char*)&p[4];

        outt = to!string(c_str);
        return padPointer(p + length * 4 + 4); // Including the length field?

    }

    //TODO: When using 32-bit pointers, could be convienient.
    /*const int32_t * readString(const int32_t * p, ref string outt){
  return cast (const int32_t *) readString(cast (const uint8_t *) p, outt);
  }*/

    const uint8_t* padPointer(const uint8_t* p) {
        ulong addr = cast(ulong) p;

        if ((addr & 3) != 0) {
            *cast(uint8_t*)&p += 4 - (addr & 3); //TODO: Very hacky
        }
        return cast(uint8_t*) p;
    }

private:
    const uint8_t* m_data;
    size_t m_dataSize;

}

class GcdaParser {
public:
    this(const uint8_t* data, size_t dataSize) {
    }

    auto countersForFunction(int32_t func) {

    }

    auto getCounter(int32_t func, int32_t counter) {

    }

    //TBA
    /*auto onRecord(const Header *header, const uint8_t *data) {
  switch (header.tag) {
  case GCOV_TAG_FUNCTION:
  onAnnounceFunction(header, data);
  break;
  case GCOV_TAG_BLOCKS:
  onBlocks(header, data);
  break;
  case GCOV_TAG_LINES:
  onLines(header, data);
  break;
  case GCOV_TAG_ARCS:
  onArcs(header, data);
  break;
  default:
  break;
  }*/
protected:

    alias CounterList_t = Typedef!int64_t[];
};

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

auto toJson(CodeLine codeline) {
    JSONValue j = ["executionNr" : ""];
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
