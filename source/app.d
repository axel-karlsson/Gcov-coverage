import std;

//Testing
extern (C++) int foo(int i);


extern (C++, CppString){

  extern(C++){
    extern (C++) struct CppStr{
      void* cppStr;

      const(void)* ptr();
      int length();
      void destroy();
      void put(char);
    }

    extern (C++) CppStr getStr();
    extern (C++) CppStr createCppStr();
  }

}

void main() {
  //foo(5);
  writeln("Wrote createCppStr: ", createCppStr());
  //Should read in Files.
  //Use the external C++ functions to retrieve info.


}
