param([Parameter(Mandatory = $true)][string]$LuaDll)
$ErrorActionPreference = 'Stop'
# Use a PowerShell process with the same architecture as the supplied Lua 5.1 DLL.
$source = @'
using System;
using System.Runtime.InteropServices;
public static class LuaTests {
    private const string Dll = "__LUA_DLL__";
    [DllImport(Dll, CallingConvention=CallingConvention.Cdecl)] static extern IntPtr luaL_newstate();
    [DllImport(Dll, CallingConvention=CallingConvention.Cdecl)] static extern void luaL_openlibs(IntPtr state);
    [DllImport(Dll, CallingConvention=CallingConvention.Cdecl)] static extern int luaL_loadfile(IntPtr state, string file);
    [DllImport(Dll, CallingConvention=CallingConvention.Cdecl)] static extern int lua_pcall(IntPtr state, int args, int results, int handler);
    [DllImport(Dll, CallingConvention=CallingConvention.Cdecl)] static extern IntPtr lua_tolstring(IntPtr state, int index, out UIntPtr length);
    [DllImport(Dll, CallingConvention=CallingConvention.Cdecl)] static extern void lua_close(IntPtr state);
    public static void Run(string file) {
        IntPtr state = luaL_newstate();
        if (state == IntPtr.Zero) throw new Exception("Lua state allocation failed");
        try {
            luaL_openlibs(state);
            int status = luaL_loadfile(state, file);
            if (status == 0) status = lua_pcall(state, 0, -1, 0);
            if (status != 0) {
                UIntPtr length;
                throw new Exception(Marshal.PtrToStringAnsi(lua_tolstring(state, -1, out length)));
            }
        } finally { lua_close(state); }
    }
}
'@
Add-Type -TypeDefinition ($source.Replace('__LUA_DLL__', $LuaDll.Replace('\', '\\')))
[LuaTests]::Run((Join-Path $PSScriptRoot 'test_addon.lua'))
