#pragma once

#ifdef THEOS_PACKAGE_SCHEME_ROOTHIDE
#include <roothide.h>
#define PO_PATH_C(path) jbroot(path)
#define PO_PATH_NS(path) jbroot(path)
#else
#include <rootless.h>
#define PO_PATH_C(path) ROOT_PATH(path)
#define PO_PATH_NS(path) ROOT_PATH_NS(path)
#endif
