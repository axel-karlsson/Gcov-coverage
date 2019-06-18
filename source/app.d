import std.stdio;
import std.string;
import std.range.primitives : empty;

struct CodeLine
{
	string line_nr, execution_nr;
	auto  toString() const
	{
		return format(("Line nr %s: Executed %s times"), line_nr, execution_nr);
	};
}

struct Lines{
	CodeLine[] codelines;
}

struct CodeLineRange{
	CodeLine[] codelines;

	this(Lines line){
		this.codelines = line.codelines;
	}
	@property bool empty() const{
		return codelines.length == 0;
	}
	@property ref CodeLine front(){
		return codelines[0];
	}
}

auto split_codeline(ref string line){

	string exenr, linenr;
	auto splitted = split(line, ":");
	if(splitted)
	{
		exenr = strip(splitted[0]);
		linenr = strip(splitted[1]);
	}
	auto split_line = CodeLine(linenr, exenr);
	return split_line;
}

auto count_line_usage(Lines line){
	//TODO

}

auto addToRange(ref CodeLine line, ref Lines ranges){
	ranges.codelines ~= line;
	return ranges;

}

void main()
{
	CodeLine line;
	Lines ranges;

	File file = File("source/test.c.gcov", "r");
	while(!file.eof()){
		auto gcov = file.readln();
		 line = split_codeline(gcov);
		 ranges = addToRange(line, ranges);
	}
	file.close();

	writeln(ranges);

}
