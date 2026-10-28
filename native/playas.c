// StellarBladePlayAs's DLL (ue4ss/Mods/StellarBladePlayAsText/dlls/main.dll): the in-game picker's text. UE4SS makes an FText from Lua
// with the engine's FText constructor, which its scan misses in this game (UE4SS.log: "Failed to find FText::FText"),
// so a TextBlock's text is set here instead, as the Stellar Blade Gore mod's sbslice.dll does for its F3 menu, with
// nothing shared with it: its own copy of the code, its own cheat function (SBSnapShot, which that mod doesn't use).
// UE4SS loads this as a C++ mod; it exports no start_mod, so UE4SS logs it as not installable and unloads it: DllMain
// pins it in memory first.
//   ue4ss/Mods/StellarBladePlayAs/playas.hook  Lua -> here: the address of the UFunction /Script/SB.SBCheatManager:SBSnapShot
//                                    (hex). Its native thunk (UFunction::Func, +0xd8) is pointed at exec_playas below
//   ue4ss/Mods/StellarBladePlayAs/playas.ok    here -> Lua: "ok patched ..." or "err <why>"; Lua calls SBSnapShot only after ok
//   ue4ss/Mods/StellarBladePlayAs/playas.ans   here -> Lua: the answer to "T?"
// SBSnapShot's one parameter, an FString, is the command (on the game thread, called from Lua):
//   T?                               "ok" when text can be set, else "err <why>", in playas.ans
//   T<text block>,<its SetText>;<s>  the block's text: an FText made of s, handed to SetText through ProcessEvent
typedef unsigned long long u64;
typedef unsigned int u32;
typedef unsigned short u16;
typedef void *HANDLE;
#define WINAPI __stdcall
#define INVALID ((HANDLE)(long long)-1)
typedef struct { void *base, *alloc; u32 aprot; u16 part; u64 size; u32 state, prot, type; } MBI;

__declspec(dllimport) HANDLE WINAPI CreateThread(void *, u64, u32(WINAPI *)(void *), void *, u32, u32 *);
__declspec(dllimport) void WINAPI Sleep(u32);
__declspec(dllimport) HANDLE WINAPI CreateFileW(const u16 *, u32, u32, void *, u32, u32, HANDLE);
__declspec(dllimport) int WINAPI ReadFile(HANDLE, void *, u32, u32 *, void *);
__declspec(dllimport) int WINAPI WriteFile(HANDLE, const void *, u32, u32 *, void *);
__declspec(dllimport) int WINAPI CloseHandle(HANDLE);
__declspec(dllimport) int WINAPI DeleteFileW(const u16 *);
__declspec(dllimport) void *WINAPI GetModuleHandleW(const u16 *);
__declspec(dllimport) int WINAPI DisableThreadLibraryCalls(void *);
__declspec(dllimport) int WINAPI GetModuleHandleExW(u32, const void *, void **);
__declspec(dllimport) u64 WINAPI VirtualQuery(const void *, MBI *, u64);

#define DIR u"ue4ss\\Mods\\StellarBladePlayAs\\"
static const u16 HOOK[] = DIR u"playas.hook";
static const u16 OK[] = DIR u"playas.ok";
static const u16 ANS[] = DIR u"playas.ans";

// SB-Win64-Shipping.exe (Steam build of 2025-09-10): RVAs, checked against their code, else searched for by it
static u64 RVA_FTEXT_CTOR = 0x285d510;     // FText::FText(FString &&)
static u64 RVA_CONFIG_GETTER = 0x1a977b0;  // the game's constants' getter: GMalloc read at +0x13
static const char SIG_FTEXT[] = "48 8b c4 56 48 83 ec 60 48 89 58 10 48 8b f1";
static const char SIG_CONFIG_GETTER[] = "48 83 ec 28 48 8b 05 ?? ?? ?? ?? 48 85 c0 75 ?? 48 8b 0d ?? ?? ?? ?? 48 85 c9 75 ?? e8 ?? ?? ?? ?? 48 8b 0d ?? ?? ?? ?? 48 8b 01 45 33 c0 ba 98 06 00 00 ff 50 10";
#define FUNC_AT (0xd8 / 8)                 // UFunction::Func (UE 4.26/4.27)
#define PROCESS_EVENT_SLOT (0x218 / 8)     // UObject::ProcessEvent in its vtable
static u64 exe, code_lo, code_hi, gmalloc; // gmalloc: the RVA of FMalloc *GMalloc
static const char *state = "not started";

static void write_file(const u16 *path, const char *s)
{
    HANDLE h = CreateFileW(path, 0x40000000 /*GENERIC_WRITE*/, 1, 0, 2 /*CREATE_ALWAYS*/, 0x80, 0);
    if (h == INVALID) return;
    u32 n = 0, w;
    while (s[n]) n++;
    WriteFile(h, s, n, &w, 0);
    CloseHandle(h);
}
static char *put(char *o, const char *s) { while (*s) *o++ = *s++; *o = 0; return o; }
static int hexval(u32 c)
{
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'a' && c <= 'f') return c - 'a' + 10;
    if (c >= 'A' && c <= 'F') return c - 'A' + 10;
    return -1;
}
static char *put_hex(char *o, u64 v)
{
    char h[17];
    for (int i = 15; i >= 0; i--) { int d = v & 15; h[i] = d < 10 ? '0' + d : 'a' + d - 10; v >>= 4; }
    h[16] = 0;
    int i = 0;
    while (i < 15 && h[i] == '0') i++;
    return put(o, h + i);
}
static int readable(u64 p, u64 n)
{
    if (p < 0x10000 || p > 0x7ffffffeffffull) return 0;
    MBI m;
    if (!VirtualQuery((const void *)p, &m, sizeof m)) return 0;
    if (m.state != 0x1000 || (m.prot & 0x101) || !(m.prot & 0xee)) return 0;
    return p + n <= (u64)m.base + m.size;
}

// ---- the addresses: each function's first bytes ("??": a rip-relative or branch field) ----
static int sig_parse(const char *s, unsigned char *b, unsigned char *m)
{
    int n = 0;
    while (*s && n < 96) {
        while (*s == ' ') s++;
        if (!*s) break;
        if (s[0] == '?') { b[n] = 0; m[n++] = 0; s += 2; continue; }
        b[n] = (unsigned char)(hexval((unsigned char)s[0]) << 4 | hexval((unsigned char)s[1]));
        m[n++] = 1;
        s += 2;
    }
    return n;
}
static int sig_at(u64 rva, const unsigned char *b, const unsigned char *m, int n)
{
    if (rva < code_lo || rva + n > code_hi) return 0;
    const unsigned char *p = (const unsigned char *)(exe + rva);
    for (int i = 0; i < n; i++) if (m[i] && p[i] != b[i]) return 0;
    return 1;
}
// its place when it matches there, else the one place in the code with it, else 0
static u64 sig_find(const char *pat, u64 guess)
{
    unsigned char b[96], m[96];
    int n = sig_parse(pat, b, m);
    if (sig_at(guess, b, m, n)) return guess;
    u64 found = 0;
    const unsigned char *p = (const unsigned char *)exe;
    for (u64 r = code_lo; r + n <= code_hi; r++) {
        if (p[r] != b[0] || !sig_at(r, b, m, n)) continue;
        if (found) return 0;
        found = r;
    }
    return found;
}
static u64 rip_target(u64 rva_of_disp) { return rva_of_disp + 4 + (u64)(long long)*(const int *)(exe + rva_of_disp); }
static void resolve(void)
{
    // the code section: the executable one holding the FText constructor's place, else the biggest executable one
    // (not just the biggest: the Steam exe's packed .link is far bigger than its code, .trace)
    u64 nt = exe + *(const u32 *)(exe + 0x3c), best = 0;
    int nsec = *(const unsigned short *)(nt + 6), opt = *(const unsigned short *)(nt + 0x14);
    const unsigned char *sec = (const unsigned char *)(nt + 0x18 + opt);
    for (int i = 0; i < nsec; i++, sec += 40) {
        u32 va = *(const u32 *)(sec + 12), vs = *(const u32 *)(sec + 8), ch = *(const u32 *)(sec + 36);
        if (!(ch & 0x20000000)) continue; // IMAGE_SCN_MEM_EXECUTE
        if (RVA_FTEXT_CTOR >= va && RVA_FTEXT_CTOR < va + vs) { code_lo = va; code_hi = va + vs; break; }
        if (vs > best) { best = vs; code_lo = va; code_hi = va + vs; }
    }
    RVA_FTEXT_CTOR = sig_find(SIG_FTEXT, RVA_FTEXT_CTOR);
    RVA_CONFIG_GETTER = sig_find(SIG_CONFIG_GETTER, RVA_CONFIG_GETTER);
    gmalloc = RVA_CONFIG_GETTER ? rip_target(RVA_CONFIG_GETTER + 0x13) : 0;
    state = !RVA_FTEXT_CTOR ? "err FText constructor not found (another game build)"
          : !gmalloc ? "err GMalloc not found (another game build)" : 0;
}

// ---- the text ----
typedef void *(*gmalloc_fn)(u64 self, u64 n, u32 align);
typedef void (*gfree_fn)(u64 self, void *p);
typedef void *(*ftext_ctor_fn)(void *self, void *src);
typedef void (*process_event_fn)(u64 obj, u64 fn, void *params);
static u64 the_malloc(void) { u64 g = gmalloc ? *(u64 *)(exe + gmalloc) : 0; return g && *(u64 *)g ? g : 0; }
static const char *text_why(void)
{
    if (state) return state;
    if (!the_malloc()) return "err GMalloc not up";
    return 0;
}
// the string copied into memory from GMalloc (the FText takes it over, the engine frees it), the FText made, handed to
// SetText, and our hold on it let go (SetText keeps its own)
static void set_text(const u16 *txt, int len)
{
    if (text_why()) return;
    int semi = 1;
    while (semi < len && txt[semi] && txt[semi] != ';') semi++;
    if (semi >= len || txt[semi] != ';') return;
    u64 f[2] = { 0, 0 };
    int k = 0;
    for (int i = 1; i < semi && k < 2; i++) {
        int d = hexval(txt[i]);
        if (d >= 0) f[k] = f[k] << 4 | (u64)d;
        else if (txt[i] == ',') k++;
        else return;
    }
    if (!readable(f[0], 8) || !readable(f[1], 8)) return;
    u64 vt = *(u64 *)f[0];
    if (!readable(vt + PROCESS_EVENT_SLOT * 8, 8)) return;
    const u16 *src = txt + semi + 1;
    int n = 0;
    while (semi + 1 + n < len && src[n]) n++;
    u64 g = the_malloc();
    // FString { TCHAR *Data; int Num (with its terminator); int Max }: an empty one has no data
    struct { u16 *data; int num, max; } fs = { 0, 0, 0 };
    if (n > 0) {
        fs.data = (u16 *)((gmalloc_fn)(*(u64 **)g)[2])(g, (u64)(n + 1) * 2, 0);
        if (!fs.data) return;
        for (int i = 0; i < n; i++) fs.data[i] = src[i];
        fs.data[n] = 0;
        fs.num = fs.max = n + 1;
    }
    // FText { TSharedRef<ITextData> (object, controller), u32 flags }
    struct { u64 obj, ctl; u32 flags, pad; } ft = { 0, 0, 0, 0 };
    ((ftext_ctor_fn)(exe + RVA_FTEXT_CTOR))(&ft, &fs);
    if (fs.data) ((gfree_fn)(*(u64 **)g)[6])(g, fs.data); // (moved from: left null; else a copy was made)
    if (!ft.obj || !ft.ctl || !readable(ft.ctl + 8, 4)) return;
    ((process_event_fn)(*(u64 *)(vt + PROCESS_EVENT_SLOT * 8)))(f[0], f[1], &ft);
    int *cnt = (int *)(ft.ctl + 8);
    if (*cnt > 1) __atomic_fetch_sub(cnt, 1, __ATOMIC_ACQ_REL);
}

// SBSnapShot's native thunk, ours: the FFrame's Locals (+0x28) hold its FString parameter at 0
static void exec_playas(void *context, unsigned char *stack, void *result)
{
    (void)context; (void)result;
    unsigned char *p = *(unsigned char **)(stack + 0x28);
    if (!p) return;
    const u16 *txt = *(const u16 **)p;
    int len = *(int *)(p + 8);
    if (!txt || len < 2 || txt[0] != 'T') return;
    if (txt[1] == '?') { const char *w = text_why(); write_file(ANS, w ? w : "ok"); return; }
    set_text(txt, len);
}

// the hook: the UFunction's address from Lua, its thunk pointed here (once: again it is already ours)
static u32 WINAPI worker(void *arg)
{
    (void)arg;
    for (;;) {
        Sleep(250);
        HANDLE h = CreateFileW(HOOK, 0x80000000 /*GENERIC_READ*/, 1, 0, 3 /*OPEN_EXISTING*/, 0x80, 0);
        if (h == INVALID) continue;
        char buf[40];
        u32 got = 0;
        ReadFile(h, buf, sizeof buf - 1, &got, 0);
        CloseHandle(h);
        DeleteFileW(HOOK);
        u64 fn = 0;
        for (u32 i = 0; i < got && hexval((unsigned char)buf[i]) >= 0; i++) fn = fn << 4 | (u64)hexval((unsigned char)buf[i]);
        char msg[160], *o;
        if (state) { write_file(OK, state); continue; }
        if (!readable(fn, FUNC_AT * 8 + 8)) { o = put(msg, "err the UFunction's address isn't readable: "); put_hex(o, fn); write_file(OK, msg); continue; }
        u64 *f = (u64 *)fn;
        if (f[FUNC_AT] != (u64)exec_playas && (f[FUNC_AT] < exe + code_lo || f[FUNC_AT] >= exe + code_hi)) {
            o = put(msg, "err no native thunk at UFunction +0xd8: ");
            put_hex(o, f[FUNC_AT]);
            write_file(OK, msg);
            continue;
        }
        f[FUNC_AT] = (u64)exec_playas;
        o = put(msg, "ok patched, FText at exe+");
        o = put_hex(o, RVA_FTEXT_CTOR);
        o = put(o, ", GMalloc at exe+");
        put_hex(o, gmalloc);
        write_file(OK, msg);
    }
    return 0;
}

int WINAPI DllMain(void *inst, u32 reason, void *reserved)
{
    (void)reserved;
    if (reason == 1 /*DLL_PROCESS_ATTACH*/) {
        DisableThreadLibraryCalls(inst);
        void *self = 0;
        if (!GetModuleHandleExW(0x4 /*FROM_ADDRESS*/ | 0x1 /*PIN*/, (const void *)DllMain, &self)) return 1;
        exe = (u64)GetModuleHandleW(0);
        DeleteFileW(OK);
        DeleteFileW(ANS);
        resolve();
        CreateThread(0, 0, worker, 0, 0, 0);
    }
    return 1;
}
