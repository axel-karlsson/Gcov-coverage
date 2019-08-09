import std;

struct CppPayload(T) {
    T data;
    alias data this;

    ~this() {
        data.destroy;
    }
}

//from cpp_string.cpp
extern (C++, CppString){
  extern(C++){
    extern (C++) struct CppStr{
      void* cppStr;

      const(void)* ptr();
      int length();
      void destroy();
      void put(char);
    }

    extern (C++) CppStr getStr(const char* text);
    extern (C++) CppStr createCppStr();

  }
}

//Functions for when sending strings between C++ & D
auto cppToD(T)(T t){
    auto cp = RefCounted!(CppPayload!T)(t);
    validate(cast(string) cp.refCountedPayload.ptr[0 .. cp.length]);
    auto s = cast(string) cp.refCountedPayload.ptr[0 .. cp.length].idup;
    return s;
}

auto dToCpp(string d_string){
    auto cs = createCppStr();

    foreach (character; d_string) {
        cs.put(character);
    }
    return cs;
}

//main in llvm-cov.cpp.
extern (C++) int main(int, const (char)**);

void main(string[] args) {
/**
Code to use the external functions should be here.
**/
}
