#include <node_api.h>
extern int GoProbe(void);
static napi_value init(napi_env env, napi_value exports) {
    for (int i = 0; i < 10; i++) {
        if (GoProbe() != 42) {
            napi_throw_error(env, NULL, "Go runtime probe failed");
            return NULL;
        }
    }
    napi_value value;
    napi_create_int32(env, 42, &value);
    napi_set_named_property(env, exports, "result", value);
    return exports;
}
NAPI_MODULE(NODE_GYP_MODULE_NAME, init)
