#include "cpp_string.hpp"
#include <iostream>

using namespace std;


//Enable strings to be sent back and forth (C++ - D)
namespace CppString {

void CppBytes::destroy() {
    delete[] ptr;
}
const void* CppStr::ptr() {
    return cppStr->c_str();
}
int CppStr::length() {
    return cppStr->size();
}
void CppStr::destroy() {
    delete cppStr;
}
void CppStr::put(char c){
    cppStr->append(ONE_CHARACTER, c);
}
CppBytes getBytes(const char* text, int length) {
    CppBytes r;

    r.ptr = new uint8_t[length];
    r.length = length;

    memcpy(r.ptr, text, length);

    return r;
}
CppStr getStr(const char* text) {
    CppStr r;
    r.cppStr = new std::string(text);

    return r;
}
CppStr createCppStr(){
    return getStr("");
}
} // CppString
