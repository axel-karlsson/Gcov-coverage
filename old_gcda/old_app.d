import std;

alias gcov_unsigned_t = Typedef!uint32_t;
alias gcov_position_t = Typedef!uint32_t;

//MAGIC
enum uint32_t GCOV_NOTE_MAGIC = 0x67636461; //gcno
enum uint32_t GCOV_DATA_MAGIC = 0x67636e6f; //gcda
enum uint32_t SUMMARY_MAGIC = 0x456d696c;

//TAGS
enum uint32_t GCOV_TAG_PROGRAM_SUMMARY = 0xa3000000;
//enum uint32_t GCOV_TAG_SUMMARY_LENGTH(NUM)  \ (1 + GCOV_COUNTERS_SUMMABLE * (10 + 3 * 2) + (NUM) * 5)
enum uint32_t GCOV_TAG_FUNCTION = 0x01000000;
enum uint32_t GCOV_TAG_BLOCKS = 0x01410000;
enum uint32_t GCOV_TAG_LINES = 0x01450000;
enum uint32_t GCOV_TAG_ARCS = 0x01430000;
enum uint32_t GCOV_TAG_COUNTER_BASE = 0x01a10000;

//Arc flags
enum ArcFlag {
    ON_TREE = 1 << 0,
    FAKE = 1 << 1,
    FALLTHROUGH = 1 << 2
}

//TODO: Usage
struct SummaryStruct {
    uint32_t magic;
    uint32_t versionn;
    uint32_t includeInTotals;
    uint32_t nLines;
    uint32_t nExecutedLines;
    string name;
}

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

struct FileHeader {
    int32_t magic, versionn, stamp;
}

struct Header {
    int32_t tag;
    int32_t length;
}

class GcovParser {
public:

    auto parse() {
        if (!verify()) {
            return false;
        }

        const uint8_t* cur = m_data + FileHeader.sizeof;
        ptrdiff_t left = cast(ptrdiff_t)(m_dataSize - FileHeader.sizeof);

        while (1) {
          writeln("Loop");
            const Header* header = cast(Header*) cur;

            if (!onRecord(header, cur + header.sizeof)) {
                writeln(cur);
                return false;
            }
            size_t curLen = header.sizeof + header.length * 4;
            if (left <= 0) {
                break;
            }
            *cast(uint8_t*)&cur += curLen; //TODO: Can this be done any better?
        }
        return true;
    }

protected:

    this(const uint8_t* data, size_t dataSize) {
        m_data = data;
        m_dataSize = dataSize;
    }

    bool verify() {
        const FileHeader* fileheader = cast(FileHeader*) m_data;
        writeln("fileheader: ",fileheader);
        return !(fileheader.magic != GCOV_DATA_MAGIC && fileheader.magic != GCOV_NOTE_MAGIC); //return false if not gcda or gcno
    }

    bool onRecord(const Header* header, const uint8_t* data) {
      writeln("In here");
        return 0;
    }

    const uint8_t* readString(const uint8_t* p, ref string outt) {
        int32_t length = *cast(const int32_t*) p;
        const char* c_str = cast(const char*)&p[4];
        outt = to!string(c_str);
        return padPointer(p + length * 4 + 4); // Including the length field?
    }

    //TODO: When using 32-bit pointers, could be convenient.
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

class GcnoParser : GcovParser {
public:
    this(const uint8_t* data, size_t dataSize) {
        super(data, dataSize);
        m_functionId = -1;
    }

    //Holder-class for fn/bb -> file/line, used for something
    class BasicBlockMapping {
    public:
        int32_t m_func;
        int32_t m_basicblock;
        string m_file;
        int32_t m_line;
        int32_t m_index;

        this(const ref BasicBlockMapping other) {
            m_func = other.m_func;
            m_basicblock = other.m_basicblock;
            m_file = other.m_file;
            m_line = other.m_line;
            m_index = other.m_index;
        }

        this(int32_t func, int32_t basicBlock, const ref string file, int32_t line, int32_t index) {
            m_func = func;
            m_basicblock = basicBlock;
            m_file = file;
            m_line = line;
            m_index = index;
        }
    };

    class Arc {
    public:
        int32_t m_func;
        int32_t m_srcBlock;
        int32_t m_dstBlock;

        this(const ref Arc other) {
            m_func = other.m_func;
            m_srcBlock = other.m_srcBlock;
            m_dstBlock = other.m_dstBlock;
        }

        this(int32_t func, int32_t srcBlock, int32_t dstBlock) {
            m_func = func;
            m_srcBlock = srcBlock;
            m_dstBlock = dstBlock;
        }
    };

    //These might not be needed
    alias BasicBlockList_t = Typedef!BasicBlockMapping;
    alias FunctionList_t = Typedef!(int32_t);
    alias ArcList_t = Typedef!Arc;

    const ref auto getBasicBlocks() {
        return m_basicBlocks;
    }

    const ref auto getFunctions() {
        return m_function;
    }

    const ref auto getArcs() {
        return m_arcs;
    }

protected:
    override bool onRecord(const Header* header, const uint8_t* data) {
        switch (header.tag) {
          writeln("Yo");
        case GCOV_TAG_FUNCTION:
        writeln("FunctionOnrecordGcno");
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
        }

        return 0;
    }

private:
    auto onAnnounceFunction(const Header* header, const uint8_t* data) {
        const int32_t* p32 = cast(const int32_t*) data;
        uint8_t* p8 = cast(uint8_t*) data;
        int32_t ident = p32[0];
        p8 = readString(p8 + 3 * 4, m_function);
        p8 = readString(p8, m_file);
        m_functionId = ident;

        m_functions ~= cast(FunctionList_t) m_functionId; //Weird cast needed?
        writeln("GCNO function %d: %s \n", m_functionId, m_file);
    }

    auto onBlocks(const Header* header, const uint8_t* data) {
        //TODO: Not sure if implementation is needed.
    }

    auto onLines(const Header* header, const uint8_t* data) {
        int32_t* p32 = cast(int32_t*) data;
        int32_t blockNo = p32[0];
        int32_t* last = cast(int32_t*) p32[header.length]; //More fun casting

        int32_t n = 0; //Index

        p32++; //Skipping the blockNo

        //Iterate through the lines
        //TODO: Improve the iteration...
        while (p32 < last) {

            int32_t line = *p32;

            //The filename
            //TODO: Oversee the casting being done here.
            if (line == 0) {
                string name;
                ubyte* curFilenameLine = cast(ubyte*)(p32 + 1);
                p32 = cast(int32_t*) readString(curFilenameLine, name);
                if (name != "") {
                    m_file = name;
                }
                continue;
            }
            p32++;

            writeln("GCNO basic block in function %d, nr %d %s:%d",
                    m_functionId, blockNo, m_file, line);
            m_basicBlocks ~= cast(BasicBlockList_t) new BasicBlockMapping(m_functionId,
                    blockNo, m_file, line, n);
            n++;
        }
    }

    auto onArcs(const Header* header, const uint8_t* data) {
        int32_t* p32 = cast(int32_t*) data;
        int32_t blockNo = p32[0];
        int32_t* last = cast(int32_t*) p32[header.length]; //More fun casting

        uint arc = 0; //Index

        p32++; //Skipping the blockNo

        //Iterate through the lines
        //TODO: Improve the iteration...
        while (p32 < last) {

            int32_t destBlock = p32[0];
            int32_t flags = p32[1];

            if (!(flags & ArcFlag.ON_TREE)) {
                m_arcs ~= cast(ArcList_t) new Arc(m_functionId, blockNo, destBlock);
            }
            p32 += 2;
            arc++;

            writeln("GCNO arc in function %d, nr %d %s:%d", m_functionId,
                    blockNo, destBlock, flags);
        }
    }

    string m_file;
    string m_function;
    int32_t m_functionId;
    FunctionList_t[] m_functions;
    BasicBlockList_t[] m_basicBlocks;
    ArcList_t[] m_arcs;
};

//For gcda files
class GcdaParser : GcovParser {
public:

    this(const uint8_t* data, size_t dataSize) {
        super(data, dataSize);
        m_functionId = -1;
    }

    auto countersForFunction(int32_t func) {
        if (func < 0) {
            writeln("Garbage");
        }
        //TODO: find func in m_functionToCounters and return -1 if it is equal to m_functionToCounters.end()
        writeln("countersForFunction", func);
        return m_functionToCounters[func].length;
    }

    //List of counter
    auto getCounter(int32_t func, int32_t counter) {

        CounterList_t cur = m_functionToCounters[func];

        if (func < 0 || counter < 0) {
            writeln("getcounter Garbage");
        }

        if (cast(size_t) counter >= cur.length) {
            return -1;
        }

        return cast(int64_t) cur[counter];
    }

protected:
    override bool onRecord(const Header* header, const uint8_t* data) {
        switch (header.tag) {
        case GCOV_TAG_FUNCTION:
        writeln("FunctionOnrecordGcda");
            onAnnounceFunction(header, data);
            break;
        case GCOV_TAG_COUNTER_BASE:
            onCounterBase(header, data);
            break;
        default:
            break;
        }
        return 0;
    }

    auto onAnnounceFunction(const Header* header, const uint8_t* data) {
        const int32_t* p32 = cast(int32_t*) data;
        int32_t ident = p32[0];

        m_functionId = ident;
    }

    auto onCounterBase(const Header* header, const uint8_t* data) {
        const int32_t* p32 = cast(int32_t*) data;
        int32_t count = header.length; //64-bit value.

        //Store counters in list
        CounterList_t counters;
        //TODO: Improve this iteration...
        for (int32_t i = 0; i < count; i += 2) {

            //TODO: Check on this shifting...
            uint64_t v64 = cast(uint64_t) p32[i] | cast(uint64_t) p32[i + 1] << 32;

            counters ~= cast(int64_t) v64;
            writeln("GCDA counter %d %lld", i);
        }

        m_functionToCounters[m_functionId] = counters;

    }

    alias CounterList_t = Typedef!(int64_t[]);
    alias FunctionToCountersMap_t = Typedef!(CounterList_t[int32_t]);

    int32_t m_functionId;
    FunctionToCountersMap_t m_functionToCounters;

};

auto splitCodeLine(string line) {
    string exenr, linenr;
    auto splitted = split(line, ":");
    exenr = strip(splitted[0]);
    linenr = strip(splitted[1]);
    auto splitLine = CodeLine(linenr, exenr);
    return splitLine;
}

//TODO: Will improve this later on... With count??
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

//Temporary
auto testParse(ref File gcnoFile) {
    uint8_t[1000] data;
    writeln(gcnoFile.rawRead(data));

    size_t datasize = data.sizeof;
    GcdaParser gcdaparser = new GcdaParser(data.ptr, datasize);
    writeln(gcdaparser.verify());
    writeln(gcdaparser.parse());
    return gcdaparser;
}

void mai() {
    Lines lines;
    auto file = File("source/test.c.gcov", "r");
    foreach (line; file.byLineCopy.map!(a => splitCodeLine(a))) {
        lines.codelines ~= line;
    }

    auto gcnoFile = File("ExampleFile/test.gcno", "rb");
    auto gcdaFile = File("ExampleFile/test.gcda", "r");
    testParse(gcdaFile);

}
