#define OFF_9(Key,F,...) ONE_(Key,F), OFF_8(Key,__VA_ARGS__)
#define OFF_8(Key,F,...) ONE_(Key,F), OFF_7(Key,__VA_ARGS__)
#define OFF_7(Key,F,...) ONE_(Key,F), OFF_6(Key,__VA_ARGS__)
#define OFF_6(Key,F,...) ONE_(Key,F), OFF_5(Key,__VA_ARGS__)
#define OFF_5(Key,F,...) ONE_(Key,F), OFF_4(Key,__VA_ARGS__)
#define OFF_4(Key,F,...) ONE_(Key,F), OFF_3(Key,__VA_ARGS__)
#define OFF_3(Key,F,...) ONE_(Key,F), OFF_2(Key,__VA_ARGS__)
#define OFF_2(Key,F,...) ONE_(Key,F), OFF_1(Key,__VA_ARGS__)
#define OFF_1(Key,F) /* base case */
#define OFF_(N) CAT(OFF_,N)

#define CAT(X,Y) X##Y

