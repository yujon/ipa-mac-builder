//
//  ldid.hpp
//  websign
//
//  ldid header file wrapper used to add our own logic without modifying ldid source.


#pragma once

#include "ldid.hpp"

namespace ldid
{
    std::string Entitlements(std::string path);
}
